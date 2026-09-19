using System;
using System.IO;
using System.IO.Pipes;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using LocalLoop.Core;
using LocalLoop.Service.Parsing;
using LocalLoop.Service.Policy;
using LocalLoop.Service.Audit;

namespace LocalLoop.Service
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly EventRepository _repository;
        private readonly IIntentParser _intentParser;
        private readonly IPolicyEngine _policyEngine;
        private readonly IAuditLogger _auditLogger;
        private readonly WebSocketServer _webSocketServer;
        private readonly PairingManager _pairingManager;
        private const string PipeName = "LocalLoop_ControlPipe";

        private readonly Dictionary<string, TaskCompletionSource<IpcMessage>> _pendingApprovals = new();
        private readonly SemaphoreSlim _approvalsLock = new(1, 1);

        public Worker(
            ILogger<Worker> logger,
            IIntentParser intentParser,
            IPolicyEngine policyEngine,
            IAuditLogger auditLogger,
            WebSocketServer webSocketServer,
            PairingManager pairingManager)
        {
            _logger = logger;
            _repository = new EventRepository();
            _intentParser = intentParser;
            _policyEngine = policyEngine;
            _auditLogger = auditLogger;
            _webSocketServer = webSocketServer;
            _pairingManager = pairingManager;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("LocalLoop Service starting at: {time}", DateTimeOffset.Now);

            // Start WebSocket server
            _ = Task.Run(async () =>
            {
                try
                {
                    await _webSocketServer.StartAsync(8080);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "WebSocket server error");
                }
            }, stoppingToken);

            // Handle WebSocket messages
            _webSocketServer.MessageReceived += HandleWebSocketMessageAsync;

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await using var pipeServer = new NamedPipeServerStream(PipeName, PipeDirection.InOut, 1, PipeTransmissionMode.Message, PipeOptions.Asynchronous);
                    
                    _logger.LogInformation("Waiting for Desktop Bridge connection on pipe '{PipeName}'...", PipeName);
                    await pipeServer.WaitForConnectionAsync(stoppingToken);
                    _logger.LogInformation("Desktop Bridge connected!");

                    var sessionEvent = new AppEvent
                    {
                        SessionId = Guid.NewGuid().ToString(),
                        Type = "session_created",
                        Payload = JsonSerializer.Serialize(new { Message = "Desktop Bridge Connected" })
                    };
                    await _repository.AppendEventAsync(sessionEvent);
                    _logger.LogInformation("Event saved: session_created for session {SessionId}", sessionEvent.SessionId);

                    using var reader = new StreamReader(pipeServer);
                    using var writer = new StreamWriter(pipeServer) { AutoFlush = true };

                    while (pipeServer.IsConnected && !stoppingToken.IsCancellationRequested)
                    {
                        var messageLine = await reader.ReadLineAsync(stoppingToken);
                        if (messageLine == null) break;

                        _logger.LogInformation("Received from Bridge: {Message}", messageLine);

                        await HandleMessageAsync(messageLine, writer, stoppingToken);
                    }
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error in Named Pipe Server");
                    await Task.Delay(1000, stoppingToken);
                }
            }
        }

        private async Task HandleWebSocketMessageAsync(string message)
        {
            try
            {
                var ipcMessage = JsonSerializer.Deserialize<IpcMessage>(message);
                if (ipcMessage == null) return;

                switch (ipcMessage.Type)
                {
                    case IpcMessageTypes.CommandRequest:
                        await ProcessWebSocketCommandRequest(ipcMessage);
                        break;
                    case IpcMessageTypes.ApprovalResponse:
                        await HandleApprovalResponseFromWebSocket(ipcMessage);
                        break;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error handling WebSocket message");
            }
        }

        private async Task ProcessWebSocketCommandRequest(IpcMessage message)
        {
            try
            {
                var intent = JsonSerializer.Deserialize<CommandIntent>(message.Data);
                if (intent == null) return;

                _logger.LogInformation("Processing WebSocket command: {Action} {Target} (Risk: {RiskLevel})", intent.Action, intent.Target, intent.RiskLevel);

                var decision = _policyEngine.Evaluate(intent);
                
                var auditRecord = new AuditRecord
                {
                    IntentId = intent.IntentId,
                    DeviceId = intent.DeviceId,
                    Action = intent.Action,
                    Target = intent.Target,
                    RiskLevel = intent.RiskLevel,
                    PolicyDecision = decision,
                    Timestamp = DateTime.UtcNow
                };

                switch (decision)
                {
                    case PolicyDecision.Allow:
                        intent.Status = "Approved";
                        auditRecord.UserDecision = "Auto-approved (Low risk)";
                        auditRecord.Result = "Executed";
                        await _auditLogger.LogAsync(auditRecord);
                        
                        var response = IpcMessageFactory.CreateCommandResponse(intent.IntentId, true, "Command auto-approved and executed");
                        await _webSocketServer.BroadcastAsync(JsonSerializer.Serialize(response));
                        break;

                    case PolicyDecision.Ask:
                        intent.Status = "PendingApproval";
                        auditRecord.UserDecision = "Pending user approval";
                        await _auditLogger.LogAsync(auditRecord);

                        var approvalRequest = IpcMessageFactory.CreateApprovalRequest(intent);
                        await _webSocketServer.BroadcastAsync(JsonSerializer.Serialize(approvalRequest));
                        break;

                    case PolicyDecision.Block:
                        intent.Status = "Blocked";
                        auditRecord.UserDecision = "Blocked by policy";
                        auditRecord.Result = "Rejected";
                        await _auditLogger.LogAsync(auditRecord);

                        var blockResponse = IpcMessageFactory.CreateCommandResponse(
                            intent.IntentId, false, "", $"Command blocked by policy (Risk: {intent.RiskLevel})");
                        await _webSocketServer.BroadcastAsync(JsonSerializer.Serialize(blockResponse));
                        break;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing WebSocket command request");
                var error = IpcMessageFactory.CreateError($"Command processing failed: {ex.Message}");
                await _webSocketServer.BroadcastAsync(JsonSerializer.Serialize(error));
            }
        }

        private async Task HandleApprovalResponseFromWebSocket(IpcMessage message)
        {
            try
            {
                var response = JsonSerializer.Deserialize<ApprovalResponse>(message.Data);
                if (response == null) return;

                await _approvalsLock.WaitAsync();
                try
                {
                    if (_pendingApprovals.TryGetValue(response.IntentId, out var tcs))
                    {
                        var approvalResult = IpcMessageFactory.CreateCommandResponse(
                            response.IntentId,
                            response.Approved,
                            response.Approved ? "Command approved by user" : "Command rejected by user",
                            response.Approved ? "" : "User rejected the command");

                        tcs.TrySetResult(approvalResult);
                    }
                }
                finally
                {
                    _approvalsLock.Release();
                }

                var auditRecord = new AuditRecord
                {
                    IntentId = response.IntentId,
                    DeviceId = response.DeviceId,
                    Action = response.Action,
                    Target = response.Target,
                    RiskLevel = response.RiskLevel,
                    PolicyDecision = PolicyDecision.Ask,
                    UserDecision = response.Approved ? "Approved" : "Rejected",
                    Result = response.Approved ? "Executed" : "Rejected",
                    Timestamp = DateTime.UtcNow
                };
                await _auditLogger.LogAsync(auditRecord);

                // Broadcast result to all connected clients
                var resultMsg = IpcMessageFactory.CreateCommandResponse(
                    response.IntentId,
                    response.Approved,
                    response.Approved ? "Command approved by user" : "Command rejected by user",
                    response.Approved ? "" : "User rejected the command");
                await _webSocketServer.BroadcastAsync(JsonSerializer.Serialize(resultMsg));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error handling WebSocket approval response");
            }
        }

        private async Task HandleMessageAsync(string messageLine, StreamWriter writer, CancellationToken stoppingToken)
        {
            try
            {
                var message = JsonSerializer.Deserialize<IpcMessage>(messageLine);
                if (message == null) return;

                switch (message.Type)
                {
                    case IpcMessageTypes.CommandRequest:
                        await HandleCommandRequest(message, writer, stoppingToken);
                        break;

                    case IpcMessageTypes.ApprovalResponse:
                        await HandleApprovalResponse(message, stoppingToken);
                        break;

                    default:
                        var ack = IpcMessageFactory.CreateAck(message.CorrelationId);
                        await writer.WriteLineAsync(JsonSerializer.Serialize(ack));
                        break;
                }
            }
            catch (IOException ex)
            {
                _logger.LogInformation("Pipe disconnected while sending response: {Message}", ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error handling message");
                try
                {
                    var errorMsg = IpcMessageFactory.CreateError(ex.Message);
                    await writer.WriteLineAsync(JsonSerializer.Serialize(errorMsg));
                }
                catch (IOException) { /* Client disconnected */ }
            }
        }

        private async Task HandleCommandRequest(IpcMessage message, StreamWriter writer, CancellationToken stoppingToken)
        {
            try
            {
                var intent = JsonSerializer.Deserialize<CommandIntent>(message.Data);
                if (intent == null)
                {
                    var error = IpcMessageFactory.CreateError("Invalid command intent", message.CorrelationId);
                    await writer.WriteLineAsync(JsonSerializer.Serialize(error));
                    return;
                }

                _logger.LogInformation("Processing command: {Action} {Target} (Risk: {RiskLevel})", intent.Action, intent.Target, intent.RiskLevel);

                var decision = _policyEngine.Evaluate(intent);
                
                var auditRecord = new AuditRecord
                {
                    IntentId = intent.IntentId,
                    DeviceId = intent.DeviceId,
                    Action = intent.Action,
                    Target = intent.Target,
                    RiskLevel = intent.RiskLevel,
                    PolicyDecision = decision,
                    Timestamp = DateTime.UtcNow
                };

                switch (decision)
                {
                    case PolicyDecision.Allow:
                        intent.Status = "Approved";
                        auditRecord.UserDecision = "Auto-approved (Low risk)";
                        auditRecord.Result = "Executed";
                        await _auditLogger.LogAsync(auditRecord);
                        
                        var response = IpcMessageFactory.CreateCommandResponse(intent.IntentId, true, "Command auto-approved and executed");
                        await writer.WriteLineAsync(JsonSerializer.Serialize(response));
                        break;

                    case PolicyDecision.Ask:
                        intent.Status = "PendingApproval";
                        auditRecord.UserDecision = "Pending user approval";
                        await _auditLogger.LogAsync(auditRecord);

                        var tcs = new TaskCompletionSource<IpcMessage>();
                        await _approvalsLock.WaitAsync();
                        try
                        {
                            _pendingApprovals[intent.IntentId] = tcs;
                        }
                        finally
                        {
                            _approvalsLock.Release();
                        }

                        var approvalRequest = IpcMessageFactory.CreateApprovalRequest(intent, message.CorrelationId);
                        await writer.WriteLineAsync(JsonSerializer.Serialize(approvalRequest));

                        try
                        {
                            using var cts = CancellationTokenSource.CreateLinkedTokenSource(stoppingToken);
                            cts.CancelAfter(TimeSpan.FromMinutes(2));
                            
                            var approvalResponse = await tcs.Task.WaitAsync(cts.Token);
                            await writer.WriteLineAsync(JsonSerializer.Serialize(approvalResponse));
                        }
                        catch (OperationCanceledException)
                        {
                            intent.Status = "Timeout";
                            auditRecord.UserDecision = "Timeout (2 min)";
                            auditRecord.Result = "Rejected";
                            await _auditLogger.LogAsync(auditRecord);

                            var timeoutResponse = IpcMessageFactory.CreateCommandResponse(
                                intent.IntentId, false, "", "Approval timeout - command rejected");
                            await writer.WriteLineAsync(JsonSerializer.Serialize(timeoutResponse));
                        }
                        finally
                        {
                            await _approvalsLock.WaitAsync();
                            _pendingApprovals.Remove(intent.IntentId);
                            _approvalsLock.Release();
                        }
                        break;

                    case PolicyDecision.Block:
                        intent.Status = "Blocked";
                        auditRecord.UserDecision = "Blocked by policy";
                        auditRecord.Result = "Rejected";
                        await _auditLogger.LogAsync(auditRecord);

                        var blockResponse = IpcMessageFactory.CreateCommandResponse(
                            intent.IntentId, false, "", $"Command blocked by policy (Risk: {intent.RiskLevel})");
                        await writer.WriteLineAsync(JsonSerializer.Serialize(blockResponse));
                        break;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing command request");
                var error = IpcMessageFactory.CreateError($"Command processing failed: {ex.Message}", message.CorrelationId);
                await writer.WriteLineAsync(JsonSerializer.Serialize(error));
            }
        }

        private async Task HandleApprovalResponse(IpcMessage message, CancellationToken stoppingToken)
        {
            try
            {
                var response = JsonSerializer.Deserialize<ApprovalResponse>(message.Data);
                if (response == null) return;

                await _approvalsLock.WaitAsync();
                try
                {
                    if (_pendingApprovals.TryGetValue(response.IntentId, out var tcs))
                    {
                        var approvalResult = IpcMessageFactory.CreateCommandResponse(
                            response.IntentId,
                            response.Approved,
                            response.Approved ? "Command approved by user" : "Command rejected by user",
                            response.Approved ? "" : "User rejected the command");

                        tcs.TrySetResult(approvalResult);
                    }
                }
                finally
                {
                    _approvalsLock.Release();
                }

                var auditRecord = new AuditRecord
                {
                    IntentId = response.IntentId,
                    DeviceId = response.DeviceId,
                    Action = response.Action,
                    Target = response.Target,
                    RiskLevel = response.RiskLevel,
                    PolicyDecision = PolicyDecision.Ask,
                    UserDecision = response.Approved ? "Approved" : "Rejected",
                    Result = response.Approved ? "Executed" : "Rejected",
                    Timestamp = DateTime.UtcNow
                };
                await _auditLogger.LogAsync(auditRecord);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error handling approval response");
            }
        }

        private class ApprovalResponse
        {
            public string IntentId { get; set; } = string.Empty;
            public string DeviceId { get; set; } = string.Empty;
            public string Action { get; set; } = string.Empty;
            public string Target { get; set; } = string.Empty;
            public string RiskLevel { get; set; } = string.Empty;
            public bool Approved { get; set; }
        }
    }
}
