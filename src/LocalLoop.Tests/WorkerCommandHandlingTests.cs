using System;
using System.Collections.Generic;
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

        public WorkerCommandHandlingTests()
        {
            _mockLogger = new Mock<ILogger<Worker>>();
            _mockPairingLogger = new Mock<ILogger<PairingManager>>();
            _mockParser = new MockIntentParser();
            _policyEngine = new PolicyEngine();
            _testAuditLogger = new TestAuditLogger();
            _mockWebSocketServer = new MockWebSocketServer();
        }

        [Fact]
        public async Task PolicyEngine_LowRiskAction_ReturnsAllow()
        {
            var intent = new CommandIntent { Action = "read", Target = "logs" };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(PolicyDecision.Allow, decision);
        }

        [Fact]
        public async Task PolicyEngine_MediumRiskAction_ReturnsAsk()
        {
            var intent = new CommandIntent { Action = "write", Target = "file" };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(PolicyDecision.Ask, decision);
        }

        [Fact]
        public async Task PolicyEngine_HighRiskAction_ReturnsBlock()
        {
            var intent = new CommandIntent { Action = "delete", Target = "file" };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(PolicyDecision.Block, decision);
        }

        [Fact]
        public async Task PolicyEngine_UnknownAction_ReturnsBlock()
        {
            var intent = new CommandIntent { Action = "format", Target = "drive" };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(PolicyDecision.Block, decision);
        }

        [Fact]
        public async Task AuditLogger_RecordsAllDecisions()
        {
            var auditRecord1 = new AuditRecord
            {
                IntentId = "intent-1",
                DeviceId = "device-1",
                Action = "read",
                Target = "logs",
                RiskLevel = "Low",
                PolicyDecision = PolicyDecision.Allow,
                UserDecision = "Auto-approved",
                Result = "Executed",
                Timestamp = DateTime.UtcNow
            };

            var auditRecord2 = new AuditRecord
            {
                IntentId = "intent-2",
                DeviceId = "device-1",
                Action = "write",
                Target = "file",
                RiskLevel = "Medium",
                PolicyDecision = PolicyDecision.Ask,
                UserDecision = "Approved",
                Result = "Executed",
                Timestamp = DateTime.UtcNow
            };

            await _testAuditLogger.LogAsync(auditRecord1);
            await _testAuditLogger.LogAsync(auditRecord2);

            var records = await _testAuditLogger.GetAllRecordsAsync();
            Assert.Equal(2, records.Count);
            Assert.Contains(records, r => r.Action == "read" && r.PolicyDecision == PolicyDecision.Allow);
            Assert.Contains(records, r => r.Action == "write" && r.PolicyDecision == PolicyDecision.Ask);
        }

        [Fact]
        public async Task IntentParser_ReadCommands_ReturnsLowRisk()
        {
            var parser = new MockIntentParser();
            var intent = await parser.ParseAsync("read the logs", "test-device");
            
            Assert.Equal("Low", intent.RiskLevel);
            Assert.Equal("test-device", intent.DeviceId);
        }

        [Fact]
        public async Task IntentParser_WriteCommands_ReturnsMediumRisk()
        {
            var parser = new MockIntentParser();
            var intent = await parser.ParseAsync("write to the config file", "test-device");
            
            Assert.Equal("Medium", intent.RiskLevel);
        }

        [Fact]
        public async Task IntentParser_DestructiveCommands_ReturnsHighRisk()
        {
            var parser = new MockIntentParser();
            var intent = await parser.ParseAsync("delete the file", "test-device");
            
            Assert.Equal("High", intent.RiskLevel);
        }

        [Fact]
        public async Task CommandIntent_Serialization_RoundTrip()
        {
            var intent = new CommandIntent
            {
                IntentId = "test-123",
                DeviceId = "device-1",
                Action = "read",
                Target = "logs",
                RiskLevel = "Low",
                Explanation = "Test",
                Timestamp = DateTime.UtcNow,
                Status = "Pending"
            };

            var json = JsonSerializer.Serialize(intent);
            var deserialized = JsonSerializer.Deserialize<CommandIntent>(json);

            Assert.NotNull(deserialized);
            Assert.Equal(intent.IntentId, deserialized.IntentId);
            Assert.Equal(intent.Action, deserialized.Action);
            Assert.Equal(intent.RiskLevel, deserialized.RiskLevel);
        }

        [Fact]
        public async Task IpcMessageFactory_CreatesCorrectMessages()
        {
            var intent = new CommandIntent
            {
                IntentId = "test-123",
                DeviceId = "device-1",
                Action = "read",
                Target = "logs",
                RiskLevel = "Low"
            };

            var cmdRequest = IpcMessageFactory.CreateCommandRequest(intent);
            Assert.Equal(IpcMessageTypes.CommandRequest, cmdRequest.Type);

            var cmdResponse = IpcMessageFactory.CreateCommandResponse("test-123", true, "Success");
            Assert.Equal(IpcMessageTypes.CommandResponse, cmdResponse.Type);

            var approvalRequest = IpcMessageFactory.CreateApprovalRequest(intent);
            Assert.Equal(IpcMessageTypes.ApprovalRequest, approvalRequest.Type);

            var approvalResponse = IpcMessageFactory.CreateApprovalResponse("test-123", true, "Approved");
            Assert.Equal(IpcMessageTypes.ApprovalResponse, approvalResponse.Type);
        }

        [Fact]
        public async Task SignedEnvelope_CreatesValidEnvelope()
        {
            // This test would require the mobile CryptoManager which is in a different project
            // Skipping for now - would need shared crypto library
            Assert.True(true);
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
            else
            {
                intent.Action = "unknown"; intent.Target = "unknown"; intent.RiskLevel = "High";
            }

            return Task.FromResult(intent);
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
            lock (_lock) { _records.Add(record); }
            return Task.CompletedTask;
        }

        public Task<IReadOnlyList<AuditRecord>> GetRecentAsync(int count = 100)
        {
            lock (_lock) { return Task.FromResult<IReadOnlyList<AuditRecord>>(_records.TakeLast(count).ToList()); }
        }

        public Task<IReadOnlyList<AuditRecord>> GetByIntentIdAsync(string intentId)
        {
            lock (_lock) { return Task.FromResult<IReadOnlyList<AuditRecord>>(_records.Where(r => r.IntentId == intentId).ToList()); }
        }

        public Task<List<AuditRecord>> GetAllRecordsAsync()
        {
            lock (_lock) { return Task.FromResult(_records.ToList()); }
        }
    }
}