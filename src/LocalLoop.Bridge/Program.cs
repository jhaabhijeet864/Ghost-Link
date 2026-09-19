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
using LocalLoop.Bridge.Adapters;

namespace LocalLoop.Bridge
{
    static class Program
    {
        private const string PipeName = "LocalLoop_ControlPipe";
        private static PairingWindow? _pairingWindow;
        private static readonly SemaphoreSlim _writeLock = new(1, 1);
        private static StreamWriter? _currentWriter;

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

            Console.WriteLine($"==========================================");
            Console.WriteLine($"[Bridge] PAIRING TOKEN : {token}");
            Console.WriteLine($"[Bridge] WORKSTATION IP: {ip}:{port}");
            Console.WriteLine($"==========================================");

            // Start the bridge connection in the background
            Task.Run(() => RunBridgeLoopAsync(token));

            // Run the UI message loop
            Application.Run(_pairingWindow);
        }

        static async Task RunBridgeLoopAsync(string pairingToken)
        {
            while (true)
            {
                try
                {
                    await RunBridgeSessionAsync(pairingToken);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Bridge] Connection error: {ex.Message}. Reconnecting in 2s...");
                }
                await Task.Delay(2000);
            }
        }

        static async Task RunBridgeSessionAsync(string pairingToken)
        {
            using var pipeClient = new NamedPipeClientStream(".", PipeName, PipeDirection.InOut, PipeOptions.Asynchronous);
            await pipeClient.ConnectAsync(5000);

            using var reader = new StreamReader(pipeClient);
            await using var writer = new StreamWriter(pipeClient) { AutoFlush = true };
            _currentWriter = writer;

            // 1. Send handshake with token
            var handshake = new IpcMessage { Type = "handshake", Data = JsonSerializer.Serialize(new { Token = pairingToken }) };
            await SendIpcMessageAsync(handshake);

            // 2. Start Transcript Watcher
            var transcriptWatcher = new AntigravityTranscriptWatcher(async appEvent =>
            {
                var eventMsg = new IpcMessage
                {
                    Type = IpcMessageTypes.AppEvent,
                    Data = JsonSerializer.Serialize(appEvent)
                };
                await SendIpcMessageAsync(eventMsg);
            });
            transcriptWatcher.Start();

            // 3. Start Agent Process Scanner timer (every 4 seconds)
            using var scanCts = new CancellationTokenSource();
            _ = Task.Run(async () =>
            {
                while (!scanCts.IsCancellationRequested && pipeClient.IsConnected)
                {
                    try
                    {
                        var agents = AgentProcessScanner.ScanActiveAgents();
                        var scanMsg = new IpcMessage
                        {
                            Type = IpcMessageTypes.AgentSessions,
                            Data = JsonSerializer.Serialize(agents)
                        };
                        await SendIpcMessageAsync(scanMsg);
                    }
                    catch { }
                    await Task.Delay(4000, scanCts.Token);
                }
            }, scanCts.Token);

            try
            {
                while (pipeClient.IsConnected)
                {
                    var response = await reader.ReadLineAsync();
                    if (response == null) break;

                    try
                    {
                        var msg = JsonSerializer.Deserialize<IpcMessage>(response);
                        if (msg != null)
                        {
                            if (msg.Type == IpcMessageTypes.InjectPrompt || msg.Type == "inject_prompt")
                            {
                                string promptText = msg.Data;
                                string? targetWindow = null;
                                try
                                {
                                    using var doc = JsonDocument.Parse(msg.Data);
                                    if (doc.RootElement.TryGetProperty("prompt", out var pEl))
                                        promptText = pEl.GetString() ?? "";
                                    if (doc.RootElement.TryGetProperty("targetWindow", out var tEl))
                                        targetWindow = tEl.GetString();
                                }
                                catch { }

                                bool injected = await IdePromptInjector.InjectPromptAsync(promptText, targetWindow);
                                var resp = IpcMessageFactory.CreateCommandResponse(msg.CorrelationId, injected, injected ? "Prompt injected into IDE" : "Failed to inject prompt");
                                await SendIpcMessageAsync(resp);
                            }
                            else if (msg.Type == IpcMessageTypes.CommandRequest)
                            {
                                var intent = JsonSerializer.Deserialize<CommandIntent>(msg.Data);
                                if (intent != null && intent.Action == "inject_prompt")
                                {
                                    string prompt = intent.Parameters.TryGetValue("prompt", out var p) ? p : intent.Target;
                                    string? target = intent.Parameters.TryGetValue("targetWindow", out var tw) ? tw : null;
                                    bool success = await IdePromptInjector.InjectPromptAsync(prompt, target);
                                    var resp = IpcMessageFactory.CreateCommandResponse(intent.IntentId, success, success ? "Prompt injected" : "Failed to inject prompt");
                                    await SendIpcMessageAsync(resp);
                                }
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[Bridge] Error processing message: {ex.Message}");
                    }
                }
            }
            finally
            {
                transcriptWatcher.Stop();
                scanCts.Cancel();
                _currentWriter = null;
            }
        }

        private static async Task SendIpcMessageAsync(IpcMessage msg)
        {
            if (_currentWriter == null) return;

            await _writeLock.WaitAsync();
            try
            {
                if (_currentWriter != null)
                {
                    await _currentWriter.WriteLineAsync(JsonSerializer.Serialize(msg));
                }
            }
            finally
            {
                _writeLock.Release();
            }
        }

        static string GetLocalIPAddress()
        {
            var host = Dns.GetHostEntry(Dns.GetHostName());
            foreach (var ip in host.AddressList)
            {
                if (ip.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(ip))
                {
                    return ip.ToString();
                }
            }
            return "127.0.0.1";
        }
    }
}
