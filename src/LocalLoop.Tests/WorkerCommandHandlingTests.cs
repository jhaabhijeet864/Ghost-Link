using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using LocalLoop.Core;
using LocalLoop.Service;
using LocalLoop.Service.Parsing;
using LocalLoop.Service.Policy;
using LocalLoop.Service.Audit;
using Xunit;

namespace LocalLoop.Tests
{
    public class WorkerCommandHandlingTests
    {
        private readonly Mock<ILogger<Worker>> _mockLogger;
        private readonly Mock<ILogger<PairingManager>> _mockPairingLogger;
        private readonly MockIntentParser _mockParser;
        private readonly PolicyEngine _policyEngine;
        private readonly TestAuditLogger _testAuditLogger;
        private readonly MockWebSocketServer _mockWebSocketServer;
        private readonly TestableWorker _worker;

        public WorkerCommandHandlingTests()
        {
            _mockLogger = new Mock<ILogger<Worker>>();
            _mockPairingLogger = new Mock<ILogger<PairingManager>>();
            _mockParser = new MockIntentParser();
            _policyEngine = new PolicyEngine();
            _testAuditLogger = new TestAuditLogger();
            _mockWebSocketServer = new MockWebSocketServer();

            _worker = new TestableWorker(
                _mockLogger.Object,
                _mockParser,
                _policyEngine,
                _testAuditLogger,
                _mockWebSocketServer,
                new PairingManager(_mockPairingLogger.Object),
                "TestPipe_" + Guid.NewGuid().ToString("N")[..8]
            );
        }

        [Fact]
        public async Task HandleCommandRequest_LowRiskAction_ReturnsAutoApproved()
        {
            var intent = new CommandIntent
            {
                IntentId = "test-intent-1",
                DeviceId = "test-device",
                Action = "read",
                Target = "logs",
                RiskLevel = "Low",
                Explanation = "Read-only operation",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            var requestJson = JsonSerializer.Serialize(request);

            var mockWriter = new StringWriter();
            await _worker.HandleMessageAsyncForTest(requestJson, mockWriter, CancellationToken.None);

            var response = mockWriter.ToString().Trim();
            Assert.NotNull(response);

            var responseMsg = JsonSerializer.Deserialize<IpcMessage>(response!);
            Assert.Equal(IpcMessageTypes.CommandResponse, responseMsg!.Type);

            var data = JsonSerializer.Deserialize<CommandResponseData>(responseMsg.Data!);
            Assert.True(data.Success);
            Assert.Equal("Command auto-approved and executed", data.Result);

            var auditRecords = await _testAuditLogger.GetAllRecordsAsync();
            Assert.Single(auditRecords);
            Assert.Equal(PolicyDecision.Allow, auditRecords[0].PolicyDecision);
            Assert.Equal("Auto-approved (Low risk)", auditRecords[0].UserDecision);
        }

        [Fact]
        public async Task HandleCommandRequest_MediumRiskAction_SendsApprovalRequest()
        {
            var intent = new CommandIntent
            {
                IntentId = "test-intent-2",
                DeviceId = "test-device",
                Action = "write",
                Target = "file",
                RiskLevel = "Medium",
                Explanation = "Write operation",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            var requestJson = JsonSerializer.Serialize(request);

            var mockWriter = new StringWriter();
            await _worker.HandleMessageAsyncForTest(requestJson, mockWriter, CancellationToken.None);

            var response = mockWriter.ToString().Trim();
            Assert.NotNull(response);

            var responseMsg = JsonSerializer.Deserialize<IpcMessage>(response!);
            Assert.Equal(IpcMessageTypes.ApprovalRequest, responseMsg!.Type);

            var approvalIntent = JsonSerializer.Deserialize<CommandIntent>(responseMsg.Data!);
            Assert.Equal("PendingApproval", approvalIntent!.Status);
            Assert.Equal("write", approvalIntent.Action);

            var auditRecords = await _testAuditLogger.GetAllRecordsAsync();
            Assert.Single(auditRecords);
            Assert.Equal(PolicyDecision.Ask, auditRecords[0].PolicyDecision);
            Assert.Equal("Pending user approval", auditRecords[0].UserDecision);
        }

        [Fact]
        public async Task HandleCommandRequest_HighRiskAction_ReturnsBlocked()
        {
            var intent = new CommandIntent
            {
                IntentId = "test-intent-3",
                DeviceId = "test-device",
                Action = "delete",
                Target = "file",
                RiskLevel = "High",
                Explanation = "Destructive operation",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            var requestJson = JsonSerializer.Serialize(request);

            var mockWriter = new StringWriter();
            await _worker.HandleMessageAsyncForTest(requestJson, mockWriter, CancellationToken.None);

            var response = mockWriter.ToString().Trim();
            Assert.NotNull(response);

            var responseMsg = JsonSerializer.Deserialize<IpcMessage>(response!);
            Assert.Equal(IpcMessageTypes.CommandResponse, responseMsg!.Type);

            var data = JsonSerializer.Deserialize<CommandResponseData>(responseMsg.Data!);
            Assert.False(data.Success);
            Assert.Contains("blocked by policy", data.Error!.ToLowerInvariant());

            var auditRecords = await _testAuditLogger.GetAllRecordsAsync();
            Assert.Single(auditRecords);
            Assert.Equal(PolicyDecision.Block, auditRecords[0].PolicyDecision);
            Assert.Equal("Blocked by policy", auditRecords[0].UserDecision);
        }

        [Fact]
        public async Task HandleApprovalResponse_Approved_ReturnsSuccess()
        {
            var intent = new CommandIntent
            {
                IntentId = "test-intent-4",
                DeviceId = "test-device",
                Action = "write",
                Target = "file",
                RiskLevel = "Medium",
                Explanation = "Write operation",
                Timestamp = DateTime.UtcNow,
                Status = "PendingApproval"
            };

            var approvalRequest = IpcMessageFactory.CreateApprovalRequest(intent);
            var requestJson = JsonSerializer.Serialize(approvalRequest);

            var mockWriter = new StringWriter();
            await _worker.HandleMessageAsyncForTest(requestJson, mockWriter, CancellationToken.None);

            var approvalResponseLine = mockWriter.ToString().Trim();
            var approvalRequestMsg = JsonSerializer.Deserialize<IpcMessage>(approvalResponseLine!);
            var approvalIntent = JsonSerializer.Deserialize<CommandIntent>(approvalRequestMsg!.Data!);

            var approvalResponse = IpcMessageFactory.CreateApprovalResponse(approvalIntent.IntentId, true, "Approved");
            var approvalResponseJson = JsonSerializer.Serialize(approvalResponse);

            mockWriter.GetStringBuilder().Clear();
            await _worker.HandleMessageAsyncForTest(approvalResponseJson, mockWriter, CancellationToken.None);

            var finalResponse = mockWriter.ToString().Trim();
            Assert.NotNull(finalResponse);

            var finalMsg = JsonSerializer.Deserialize<IpcMessage>(finalResponse!);
            Assert.Equal(IpcMessageTypes.CommandResponse, finalMsg!.Type);

            var data = JsonSerializer.Deserialize<CommandResponseData>(finalMsg.Data!);
            Assert.True(data.Success);
            Assert.Equal("Command approved by user", data.Result);

            var auditRecords = await _testAuditLogger.GetAllRecordsAsync();
            Assert.Equal(2, auditRecords.Count);

            var approvalAudit = auditRecords.Find(r => r.UserDecision == "Approved");
            Assert.NotNull(approvalAudit);
            Assert.Equal(PolicyDecision.Ask, approvalAudit.PolicyDecision);
            Assert.Equal("Approved", approvalAudit.UserDecision);
            Assert.Equal("Executed", approvalAudit.Result);
        }

        [Fact]
        public async Task HandleApprovalResponse_Rejected_ReturnsFailure()
        {
            var intent = new CommandIntent
            {
                IntentId = "test-intent-5",
                DeviceId = "test-device",
                Action = "write",
                Target = "file",
                RiskLevel = "Medium",
                Explanation = "Write operation",
                Timestamp = DateTime.UtcNow,
                Status = "PendingApproval"
            };

            var approvalRequest = IpcMessageFactory.CreateApprovalRequest(intent);
            var requestJson = JsonSerializer.Serialize(approvalRequest);

            var mockWriter = new StringWriter();
            await _worker.HandleMessageAsyncForTest(requestJson, mockWriter, CancellationToken.None);

            var approvalResponseLine = mockWriter.ToString().Trim();
            var approvalRequestMsg = JsonSerializer.Deserialize<IpcMessage>(approvalResponseLine!);
            var approvalIntent = JsonSerializer.Deserialize<CommandIntent>(approvalRequestMsg!.Data!);

            var approvalResponse = IpcMessageFactory.CreateApprovalResponse(approvalIntent.IntentId, false, "Rejected");
            var approvalResponseJson = JsonSerializer.Serialize(approvalResponse);

            mockWriter.GetStringBuilder().Clear();
            await _worker.HandleMessageAsyncForTest(approvalResponseJson, mockWriter, CancellationToken.None);

            var finalResponse = mockWriter.ToString().Trim();
            Assert.NotNull(finalResponse);

            var finalMsg = JsonSerializer.Deserialize<IpcMessage>(finalResponse!);
            Assert.Equal(IpcMessageTypes.CommandResponse, finalMsg!.Type);

            var data = JsonSerializer.Deserialize<CommandResponseData>(finalMsg.Data!);
            Assert.False(data.Success);
            Assert.Equal("User rejected the command", data.Error);

            var auditRecords = await _testAuditLogger.GetAllRecordsAsync();
            var rejectionAudit = auditRecords.Find(r => r.UserDecision == "Rejected");
            Assert.NotNull(rejectionAudit);
            Assert.Equal("Rejected", rejectionAudit.UserDecision);
            Assert.Equal("Rejected", rejectionAudit.Result);
        }

        [Fact]
        public async Task HandleCommandRequest_UnknownAction_ClassifiedAsHighRisk()
        {
            var intent = new CommandIntent
            {
                IntentId = "test-intent-6",
                DeviceId = "test-device",
                Action = "format",
                Target = "drive",
                RiskLevel = "High",
                Explanation = "Unknown action",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var request = IpcMessageFactory.CreateCommandRequest(intent);
            var requestJson = JsonSerializer.Serialize(request);

            var mockWriter = new StringWriter();
            await _worker.HandleMessageAsyncForTest(requestJson, mockWriter, CancellationToken.None);

            var response = mockWriter.ToString().Trim();
            Assert.NotNull(response);

            var responseMsg = JsonSerializer.Deserialize<IpcMessage>(response!);
            Assert.Equal(IpcMessageTypes.CommandResponse, responseMsg!.Type);

            var data = JsonSerializer.Deserialize<CommandResponseData>(responseMsg.Data!);
            Assert.False(data.Success);
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
            return Task.FromResult(new CommandIntent());
        }
    }

    public class MockWebSocketServer : WebSocketServer
    {
        public MockWebSocketServer() : base(new PairingManager(NullLogger<PairingManager>.Instance), NullLogger<WebSocketServer>.Instance) { }
        
        public override Task StartAsync(int port) => Task.CompletedTask;
        public override Task BroadcastAsync(string message) => Task.CompletedTask;
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

    public class TestableWorker : Worker
    {
        public TestableWorker(
            ILogger<Worker> logger,
            IIntentParser intentParser,
            IPolicyEngine policyEngine,
            IAuditLogger auditLogger,
            WebSocketServer webSocketServer,
            PairingManager pairingManager,
            string pipeName) 
            : base(logger, intentParser, policyEngine, auditLogger, webSocketServer, pairingManager, pipeName)
        {
        }

        public async Task HandleMessageAsyncForTest(string messageLine, TextWriter writer, CancellationToken stoppingToken)
        {
            var memoryStream = new MemoryStream();
            var streamWriter = new StreamWriter(memoryStream) { AutoFlush = true };
            await base.HandleMessageAsync(messageLine, streamWriter, stoppingToken);
            await streamWriter.FlushAsync();
            
            memoryStream.Position = 0;
            using var reader = new StreamReader(memoryStream);
            var result = await reader.ReadToEndAsync();
            await writer.WriteAsync(result);
        }
    }
}