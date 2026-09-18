using System;
using System.IO;
using System.IO.Pipes;
using System.Text.Json;
using System.Threading.Tasks;
using LocalLoop.Core;

namespace LocalLoop.Bridge
{
    class Program
    {
        private const string PipeName = "LocalLoop_ControlPipe";

        static async Task Main(string[] args)
        {
            Console.WriteLine("LocalLoop Desktop Bridge starting...");
            Console.WriteLine($"Connecting to {PipeName}...");

            try
            {
                using var pipeClient = new NamedPipeClientStream(".", PipeName, PipeDirection.InOut, PipeOptions.Asynchronous);
                
                // Wait for the Service to start
                await pipeClient.ConnectAsync();
                Console.WriteLine("Connected to LocalLoop Service!");

                using var reader = new StreamReader(pipeClient);
                using var writer = new StreamWriter(pipeClient) { AutoFlush = true };

                // Send handshake
                var handshake = new IpcMessage { Type = "handshake", Data = "Bridge online" };
                await writer.WriteLineAsync(JsonSerializer.Serialize(handshake));

                // Listen for responses in a background task
                _ = Task.Run(async () =>
                {
                    while (pipeClient.IsConnected)
                    {
                        var response = await reader.ReadLineAsync();
                        if (response != null)
                        {
                            Console.WriteLine($"[Service] {response}");
                        }
                    }
                });

                Console.WriteLine("Press ENTER to exit.");
                Console.ReadLine();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error connecting to Service: {ex.Message}");
            }
        }
    }
}
