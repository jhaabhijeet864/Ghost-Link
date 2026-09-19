using System;
using System.IO;
using System.IO.Pipes;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;
using LocalLoop.Core;
using LocalLoop.Service;
using LocalLoop.Service.Parsing;
using LocalLoop.Service.Policy;
using LocalLoop.Service.Audit;
using Xunit;

namespace LocalLoop.Tests
{
    public class WorkerIntegrationTests : IAsyncLifetime
    {
        private readonly string _testPipeName = "LocalLoop_TestPipe_" + Guid.NewGuid().ToString("N")[..8];
        private Worker _worker = null!;
        private ServiceProvider _serviceProvider = null!;
        private NamedPipeClientStream _pipeClient = null!;
        private StreamReader _reader = null!;
        private StreamWriter _writer = null!;

        public async Task InitializeAsync()
        {
            var services = new ServiceCollection();
            services.AddLogging(builder => builder.AddDebug().SetMinimumLevel(LogLevel.Debug));
            services.AddSingleton<IIntentParser, MockIntentParser>();
            services.AddSingleton<IPolicyEngine, PolicyEngine>();
            services.AddSingleton<IAuditLogger, TestAuditLogger>();
            services.AddSingleton<PairingManager>();
            services.AddSingleton<WebSocketServer>(sp => new WebSocketServer(
                sp.GetRequiredService<PairingManager>(),
                sp.GetRequiredService<ILogger<WebSocketServer>>()));

            _serviceProvider = services.BuildServiceProvider();

            _worker = new Worker(
                _serviceProvider.GetRequiredService<ILogger<Worker>>(),
                _serviceProvider.GetRequiredService<IIntentParser>(),
                _serviceProvider.GetRequiredService<IPolicyEngine>(),
                _serviceProvider.GetRequiredService<IAuditLogger>(),
                _serviceProvider.GetRequiredService<WebSocketServer>(),
                _serviceProvider.GetRequiredService<PairingManager>()
            );

            _ = Task.Run(() => _worker.StartAsync(CancellationToken.None));

            await Task.Delay(500);

            _pipeClient = new NamedPipeClientStream(".", _testPipeName, PipeDirection.InOut, PipeOptions.Asynchronous);
            await _pipeClient.ConnectAsync(1000);

            _reader = new StreamReader(_pipeClient);
            _writer = new StreamWriter(_pipeClient) { AutoFlush = true };
        }

        public async Task DisposeAsync()
        {
            _writer?.Dispose();
            _reader?.Dispose();
            _pipeClient?.Dispose();
            await _worker.StopAsync(CancellationToken.None);
            _serviceProvider?.Dispose();
        }

        [Fact]
        public async Task CommandRequest_LowRiskAction_AutoApprovedAndExecuted()
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                DeviceId = "test-device",
                Action = "read",
                Target = "logs",
                RiskLevel = "Low",
                Explanation = "Read-only operation",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            await _writer.WriteLineAsync(JsonSerializer.Serialize(request));

            var responseLine = await _reader.ReadLineAsync();
            var response = JsonSerializer.Deserialize<IpcMessage>(responseLine!);

            Assert.NotNull(response);
            Assert.Equal(IpcMessageTypes.CommandResponse, response.Type);

            var data = JsonSerializer.Deserialize<CommandResponseData>(response.Data!);
            Assert.True(data.Success);
            Assert.Equal("Command auto-approved and executed", data.Result);
        }

        [Fact]
        public async Task CommandRequest_MediumRiskAction_SendsApprovalRequest()
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                DeviceId = "test-device",
                Action = "write",
                Target = "file",
                RiskLevel = "Medium",
                Explanation = "Write operation",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            await _writer.WriteLineAsync(JsonSerializer.Serialize(request));

            var responseLine = await _reader.ReadLineAsync();
            var response = JsonSerializer.Deserialize<IpcMessage>(responseLine!);

            Assert.NotNull(response);
            Assert.Equal(IpcMessageTypes.ApprovalRequest, response.Type);

            var approvalData = JsonSerializer.Deserialize<CommandIntent>(response.Data!);
            Assert.Equal("PendingApproval", approvalData.Status);
        }

        [Fact]
        public async Task CommandRequest_HighRiskAction_BlockedByPolicy()
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                DeviceId = "test-device",
                Action = "delete",
                Target = "file",
                RiskLevel = "High",
                Explanation = "Destructive operation",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            await _writer.WriteLineAsync(JsonSerializer.Serialize(request));

            var responseLine = await _reader.ReadLineAsync();
            var response = JsonSerializer.Deserialize<IpcMessage>(responseLine!);

            Assert.NotNull(response);
            Assert.Equal(IpcMessageTypes.CommandResponse, response.Type);

            var data = JsonSerializer.Deserialize<CommandResponseData>(response.Data!);
            Assert.False(data.Success);
            Assert.Contains("blocked by policy", data.Error!.ToLowerInvariant());
        }

        [Fact]
        public async Task ApprovalResponse_Approved_ReturnsSuccess()
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                DeviceId = "test-device",
                Action = "write",
                Target = "file",
                RiskLevel = "Medium",
                Explanation = "Write operation",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            await _writer.WriteLineAsync(JsonSerializer.Serialize(request));

            var approvalRequestLine = await _reader.ReadLineAsync();
            var approvalRequest = JsonSerializer.Deserialize<IpcMessage>(approvalRequestLine!);
            var approvalIntent = JsonSerializer.Deserialize<CommandIntent>(approvalRequest.Data!);

            var approvalResponse = IpcMessageFactory.CreateApprovalResponse(approvalIntent.IntentId, true, "Approved");
            await _writer.WriteLineAsync(JsonSerializer.Serialize(approvalResponse));

            var finalResponseLine = await _reader.ReadLineAsync();
            var finalResponse = JsonSerializer.Deserialize<IpcMessage>(finalResponseLine!);

            Assert.Equal(IpcMessageTypes.CommandResponse, finalResponse.Type);
            var data = JsonSerializer.Deserialize<CommandResponseData>(finalResponse.Data!);
            Assert.True(data.Success);
        }

        [Fact]
        public async Task ApprovalResponse_Rejected_ReturnsFailure()
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                DeviceId = "test-device",
                Action = "write",
                Target = "file",
                RiskLevel = "Medium",
                Explanation = "Write operation",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            await _writer.WriteLineAsync(JsonSerializer.Serialize(request));

            var approvalRequestLine = await _reader.ReadLineAsync();
            var approvalRequest = JsonSerializer.Deserialize<IpcMessage>(approvalRequestLine!);
            var approvalIntent = JsonSerializer.Deserialize<CommandIntent>(approvalRequest.Data!);

            var approvalResponse = IpcMessageFactory.CreateApprovalResponse(approvalIntent.IntentId, false, "Rejected");
            await _writer.WriteLineAsync(JsonSerializer.Serialize(approvalResponse));

            var finalResponseLine = await _reader.ReadLineAsync();
            var finalResponse = JsonSerializer.Deserialize<IpcMessage>(finalResponseLine!);

            Assert.Equal(IpcMessageTypes.CommandResponse, finalResponse.Type);
            var data = JsonSerializer.Deserialize<CommandResponseData>(finalResponse.Data!);
            Assert.False(data.Success);
            Assert.Equal("User rejected the command", data.Error);
        }

        [Fact]
        public async Task AuditLog_RecordsAllDecisions()
        {
            var auditLogger = _serviceProvider.GetRequiredService<IAuditLogger>() as TestAuditLogger;
            Assert.NotNull(auditLogger);

            var lowRiskIntent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                DeviceId = "test-device",
                Action = "read",
                Target = "logs",
                RiskLevel = "Low"
            };

            var request = IpcMessageFactory.CreateCommandRequest(lowRiskIntent);
            await _writer.WriteLineAsync(JsonSerializer.Serialize(request));
            await _reader.ReadLineAsync();

            await Task.Delay(100);

            var mediumRiskIntent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                DeviceId = "test-device",
                Action = "write",
                Target = "file",
                RiskLevel = "Medium"
            };

            request = IpcMessageFactory.CreateCommandRequest(mediumRiskIntent);
            await _writer.WriteLineAsync(JsonSerializer.Serialize(request));
            var approvalLine = await _reader.ReadLineAsync();

            var approvalRequest = JsonSerializer.Deserialize<IpcMessage>(approvalLine!);
            var approvalIntent = JsonSerializer.Deserialize<CommandIntent>(approvalRequest.Data!);

            var approvalResponse = IpcMessageFactory.CreateApprovalResponse(approvalIntent.IntentId, true, "Approved");
            await _writer.WriteLineAsync(JsonSerializer.Serialize(approvalResponse));
            await _reader.ReadLineAsync();

            await Task.Delay(100);

            var auditRecords = await auditLogger!.GetAllRecordsAsync();
            Assert.True(auditRecords.Count >= 2);

            var lowRiskAudit = auditRecords.Find(r => r.Action == "read" && r.RiskLevel == "Low");
            Assert.NotNull(lowRiskAudit);
            Assert.Equal(PolicyDecision.Allow, lowRiskAudit.PolicyDecision);
            Assert.Equal("Auto-approved (Low risk)", lowRiskAudit.UserDecision);

            var mediumRiskAudit = auditRecords.Find(r => r.Action == "write" && r.RiskLevel == "Medium");
            Assert.NotNull(mediumRiskAudit);
            Assert.Equal(PolicyDecision.Ask, mediumRiskAudit.PolicyDecision);
            Assert.Equal("Approved", mediumRiskAudit.UserDecision);
        }

        private class CommandResponseData
        {
            public string IntentId { get; set; } = string.Empty;
            public bool Success { get; set; }
            public string Result { get; set; } = string.Empty;
            public string Error { get; set; } = string.Empty;
        }
    }

    public class MockIntentParser : IIntentParser
    {
        public Task<CommandIntent> ParseAsync(string naturalLanguage, string deviceId, CancellationToken cancellationToken = default)
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                DeviceId = deviceId,
                Action = "unknown",
                Target = "unknown",
                RiskLevel = "High",
                Explanation = "Mock parser",
                Timestamp = DateTime.UtcNow
            };

            var lower = naturalLanguage.ToLowerInvariant();

            if (lower.Contains("read") || lower.Contains("view") || lower.Contains("show") || lower.Contains("list") || lower.Contains("tail"))
            {
                intent.Action = "read"; intent.Target = "logs"; intent.RiskLevel = "Low";
            }
            else if (lower.Contains("write") || lower.Contains("create") || lower.Contains("edit"))
            {
                intent.Action = "write"; intent.Target = "file"; intent.RiskLevel = "Medium";
            }
            else if (lower.Contains("delete") || lower.Contains("remove") || lower.Contains("kill") || lower.Contains("stop"))
            {
                intent.Action = "delete"; intent.Target = "file"; intent.RiskLevel = "High";
            }
            else if (lower.Contains("restart"))
            {
                intent.Action = "restart"; intent.Target = "service"; intent.RiskLevel = "Medium";
            }
            else if (lower.Contains("execute") || lower.Contains("run"))
            {
                intent.Action = "execute"; intent.Target = "command"; intent.RiskLevel = "High";
            }

            return Task.FromResult(intent);
        }
    }

    public class TestAuditLogger : IAuditLogger
    {
        private readonly List<AuditRecord> _records = new();
        private readonly object _lock = new();

        public Task LogAsync(AuditRecord record)
        {
            lock (_lock)
            {
                _records.Add(record);
            }
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<AuditRecord>> GetRecentAsync(int count = 100)
        {
            lock (_lock)
            {
                return Task.FromResult<IReadOnlyList<AuditRecord>>(_records.TakeLast(count).ToList());
            }
        }

        public Task<IReadOnlyList<AuditRecord>> GetByIntentIdAsync(string intentId)
        {
            lock (_lock)
            {
                return Task.FromResult<IReadOnlyList<AuditRecord>>(_records.Where(r => r.IntentId == intentId).ToList());
            }
        }

        public Task<List<AuditRecord>> GetAllRecordsAsync()
        {
            lock (_lock)
            {
                return Task.FromResult(_records.ToList());
            }
        }
    }
}