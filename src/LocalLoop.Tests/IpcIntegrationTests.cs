using System;
using System.IO;
using System.IO.Pipes;
using System.Text.Json;
using System.Threading.Tasks;
using Xunit;
using LocalLoop.Core;

namespace LocalLoop.Tests
{
    public class IpcIntegrationTests
    {
        [Fact]
        public async Task NamedPipe_ServerAndClient_CanCommunicate()
        {
            var pipeName = $"LocalLoop_TestPipe_{Guid.NewGuid()}";
            var messageReceived = false;

            // Arrange Server
            var serverTask = Task.Run(async () =>
            {
                using var pipeServer = new NamedPipeServerStream(pipeName, PipeDirection.InOut, 1, PipeTransmissionMode.Message, PipeOptions.Asynchronous);
                await pipeServer.WaitForConnectionAsync();
                
                using var reader = new StreamReader(pipeServer);
                var messageLine = await reader.ReadLineAsync();
                
                if (messageLine != null)
                {
                    var msg = JsonSerializer.Deserialize<IpcMessage>(messageLine);
                    if (msg?.Type == "handshake")
                    {
                        messageReceived = true;
                    }
                }
            });

            // Arrange Client
            var clientTask = Task.Run(async () =>
            {
                using var pipeClient = new NamedPipeClientStream(".", pipeName, PipeDirection.InOut, PipeOptions.Asynchronous);
                await pipeClient.ConnectAsync(5000); // 5 second timeout
                
                using var writer = new StreamWriter(pipeClient) { AutoFlush = true };
                var handshake = new IpcMessage { Type = "handshake", Data = "Bridge online" };
                await writer.WriteLineAsync(JsonSerializer.Serialize(handshake));
            });

            // Act & Assert
            await Task.WhenAll(serverTask, clientTask);
            Assert.True(messageReceived);
        }
    }
}
