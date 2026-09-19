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
        private readonly string _pipeName;

        private readonly Dictionary<string, TaskCompletionSource<IpcMessage>> _pendingApprovals = new();
        private readonly SemaphoreSlim _approvalsLock = new(1, 1);
        private StreamWriter? _activeBridgeWriter;
        private readonly SemaphoreSlim _bridgeWriterLock = new(1, 1);

        public Worker(
            ILogger<Worker> logger,
            IIntentParser intentParser,
            IPolicyEngine policyEngine,
            IAuditLogger auditLogger,
            WebSocketServer webSocketServer,
            PairingManager pairingManager,
            string pipeName = "LocalLoop_ControlPipe")
        {
            _logger = logger;
            _repository = new EventRepository();
            _intentParser = intentParser;
            _policyEngine = policyEngine;
            _auditLogger = auditLogger;
            _webSocketServer = webSocketServer;
            _pairingManager = pairingManager;
            _pipeName = pipeName;
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
                    var pipeServer = new NamedPipeServerStream(
                        _pipeName,
                        PipeDirection.InOut,
                        NamedPipeServerStream.MaxAllowedServerInstances,
                        PipeTransmissionMode.Byte,
                        PipeOptions.Asynchronous);

                    _logger.LogInformation("Waiting for Desktop Bridge connection on pipe '{PipeName}'...", _pipeName);
                    await pipeServer.WaitForConnectionAsync(stoppingToken);
                    _logger.LogInformation("Desktop Bridge connected!");

                    _ = Task.Run(() => ServePipeClientAsync(pipeServer, stoppingToken), stoppingToken);
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

        private async Task ServePipeClientAsync(NamedPipeServerStream pipeServer, CancellationToken ct)
        {
            await using (pipeServer)
            {
                var sessionEvent = new AppEvent
                {
                    SessionId = Guid.NewGuid().ToString(),
                    Type = "session_created",
                    Payload = JsonSerializer.Serialize(new { Message = "Desktop Bridge Connected" })
                };
                await _repository.AppendEventAsync(sessionEvent);

                using var reader = new StreamReader(pipeServer, System.Text.Encoding.UTF8);
                await using var writer = new StreamWriter(pipeServer, System.Text.Encoding.UTF8) { AutoFlush = true };

                await _bridgeWriterLock.WaitAsync(ct);
                try { _activeBridgeWriter = writer; }
                finally { _bridgeWriterLock.Release(); }

                try
                {
                    while (pipeServer.IsConnected && !ct.IsCancellationRequested)
                    {
                    var messageLine = await reader.ReadLineAsync(ct);
                    if (messageLine == null) break;

                    _logger.LogInformation("Received from Bridge: {Message}", messageLine);

                    var msgObj = JsonSerializer.Deserialize<IpcMessage>(messageLine);
                    if (msgObj != null && msgObj.Type == "handshake")
                    {
                        try {
                            var doc = JsonDocument.Parse(msgObj.Data);
                            if (doc.RootElement.TryGetProperty("Token", out var tokenElement))
                            {
                                _pairingManager.SetPairingToken(tokenElement.GetString() ?? "");
                                _logger.LogInformation("Pairing token updated by Bridge.");
                            }
                        } catch { }
                    }

                    await HandleMessageAsync(messageLine, writer, ct);
                }
            }
            finally
            {
                await _bridgeWriterLock.WaitAsync();
                try { if (_activeBridgeWriter == writer) _activeBridgeWriter = null; }
                finally { _bridgeWriterLock.Release(); }
            }
        }
        }

        private async Task HandleWebSocketMessageAsync(string message)
        {
            try
            {
                using var doc = JsonDocument.Parse(message);
                var root = doc.RootElement;

                // Check for signed action envelope
                if (root.TryGetProperty("body", out var bodyEl) && root.TryGetProperty("signature", out var sigEl))
                {
                    var signatureBase64 = sigEl.GetString() ?? "";
                    var canonicalBody = bodyEl.GetRawText();
                    var publicKey = bodyEl.TryGetProperty("publicKey", out var pkEl) ? pkEl.GetString() ?? "" : "";
                    var timestamp = bodyEl.TryGetProperty("timestamp", out var tsEl) ? tsEl.GetInt64() : 0;

                    // Anti-Replay: Reject messages skewed by more than 30 seconds
                    var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                    if (Math.Abs(now - timestamp) > 30)
                    {
                        _logger.LogWarning("Rejecting action envelope: timestamp skew exceeded (Skew: {Diff}s)", now - timestamp);
                        return;
                    }

                    if (!_pairingManager.ValidateSignatureRaw(canonicalBody, signatureBase64, publicKey))
                    {
                        _logger.LogWarning("Rejecting action envelope: Invalid signature from key {Key}", publicKey);
                        return;
                    }

                    var actionType = bodyEl.TryGetProperty("type", out var atEl) ? atEl.GetString() ?? "" : "";
                    var payloadText = bodyEl.TryGetProperty("payload", out var plEl) ? plEl.GetRawText() : "{}";

                    var unwrapIpc = new IpcMessage { Type = actionType, Data = payloadText };
                    await DispatchWebSocketIpcMessage(unwrapIpc);
                    return;
                }

                // Fallback direct IPC message
                var ipcMessage = JsonSerializer.Deserialize<IpcMessage>(message);
                if (ipcMessage != null)
                {
                    await DispatchWebSocketIpcMessage(ipcMessage);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error handling WebSocket message");
            }
        }

        private async Task DispatchWebSocketIpcMessage(IpcMessage ipcMessage)
        {
            switch (ipcMessage.Type)
            {
                case IpcMessageTypes.CommandRequest:
                    await ProcessWebSocketCommandRequest(ipcMessage);
                    break;
                case IpcMessageTypes.ApprovalResponse:
                    await HandleApprovalResponseFromWebSocket(ipcMessage);
                    break;
                case IpcMessageTypes.InjectPrompt:
                    if (_activeBridgeWriter != null)
                    {
                        await _bridgeWriterLock.WaitAsync();
                        try
                        {
                            if (_activeBridgeWriter != null)
                            {
                                await _activeBridgeWriter.WriteLineAsync(JsonSerializer.Serialize(ipcMessage));
                            }
                        }
                        finally
                        {
                            _bridgeWriterLock.Release();
                        }
                    }
                    break;
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

                        if (_activeBridgeWriter != null)
                        {
                            await _bridgeWriterLock.WaitAsync();
                            try
                            {
                                if (_activeBridgeWriter != null)
                                {
                                    var bridgeCmd = IpcMessageFactory.CreateCommandRequest(intent);
                                    await _activeBridgeWriter.WriteLineAsync(JsonSerializer.Serialize(bridgeCmd));
                                }
                            }
                            finally
                            {
                                _bridgeWriterLock.Release();
                            }
                        }
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

        internal virtual async Task HandleMessageAsync(string messageLine, StreamWriter writer, CancellationToken stoppingToken)
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

                    case IpcMessageTypes.AgentSessions:
                        await _webSocketServer.BroadcastAsync(JsonSerializer.Serialize(message));
                        break;

                    case IpcMessageTypes.AppEvent:
                        try
                        {
                            var appEvt = JsonSerializer.Deserialize<AppEvent>(message.Data);
                            if (appEvt != null)
                            {
                                await _repository.AppendEventAsync(appEvt);
                            }
                        }
                        catch { }
                        await _webSocketServer.BroadcastAsync(JsonSerializer.Serialize(message));
                        break;

                    case IpcMessageTypes.CommandResponse:
                        await _webSocketServer.BroadcastAsync(JsonSerializer.Serialize(message));
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
