using System;
using System.IO;
using System.IO.Pipes;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using LocalLoop.Core;

namespace LocalLoop.Service
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly EventRepository _repository;
        private const string PipeName = "LocalLoop_ControlPipe";

        public Worker(ILogger<Worker> logger)
        {
            _logger = logger;
            _repository = new EventRepository(); // Simple initialization for Phase 1
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("LocalLoop Service starting at: {time}", DateTimeOffset.Now);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await using var pipeServer = new NamedPipeServerStream(PipeName, PipeDirection.InOut, 1, PipeTransmissionMode.Message, PipeOptions.Asynchronous);
                    
                    _logger.LogInformation("Waiting for Desktop Bridge connection on pipe '{PipeName}'...", PipeName);
                    await pipeServer.WaitForConnectionAsync(stoppingToken);
                    _logger.LogInformation("Desktop Bridge connected!");

                    // Create session created event
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

                        var responseMsg = new IpcMessage { Type = "ack", Data = "Message received by Service" };
                        await writer.WriteLineAsync(JsonSerializer.Serialize(responseMsg));
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
    }
}
