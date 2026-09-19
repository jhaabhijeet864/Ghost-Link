using System;
using System.IO;
using System.IO.Pipes;
using System.Net;
using System.Net.Sockets;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using LocalLoop.Core;

namespace LocalLoop.Bridge
{
    static class Program
    {
        private const string PipeName = "LocalLoop_ControlPipe";
        private static PairingWindow _pairingWindow;

        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Generate a token for this session
            string token = Guid.NewGuid().ToString();
            string ip = GetLocalIPAddress();
            int port = 8080; // Default WebSocket port for LocalLoop.Service

            _pairingWindow = new PairingWindow(token, ip, port);

            // Start the bridge connection in the background
            Task.Run(() => RunBridgeAsync(token));

            // Run the UI message loop
            Application.Run(_pairingWindow);
        }

        static async Task RunBridgeAsync(string pairingToken)
        {
            try
            {
                using var pipeClient = new NamedPipeClientStream(".", PipeName, PipeDirection.InOut, PipeOptions.Asynchronous);
                
                await pipeClient.ConnectAsync();
                
                using var reader = new StreamReader(pipeClient);
                using var writer = new StreamWriter(pipeClient) { AutoFlush = true };

                // Send handshake with token
                var handshake = new IpcMessage { Type = "handshake", Data = JsonSerializer.Serialize(new { Token = pairingToken }) };
                await writer.WriteLineAsync(JsonSerializer.Serialize(handshake));

                while (pipeClient.IsConnected)
                {
                    var response = await reader.ReadLineAsync();
                    if (response != null)
                    {
                        // TODO: Handle service messages
                    }
                }
            }
            catch (Exception ex)
            {
                // Let the UI know or log
            }
        }

        static string GetLocalIPAddress()
        {
            var host = Dns.GetHostEntry(Dns.GetHostName());
            foreach (var ip in host.AddressList)
            {
                if (ip.AddressFamily == AddressFamily.InterNetwork)
                {
                    return ip.ToString();
                }
            }
            return "127.0.0.1";
        }
    }
}
