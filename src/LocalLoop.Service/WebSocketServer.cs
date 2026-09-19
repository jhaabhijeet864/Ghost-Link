using System;
using System.Collections.Concurrent;
using System.Net;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using LocalLoop.Core;
using Microsoft.Extensions.Logging;

namespace LocalLoop.Service
{
    public class WebSocketServer
    {
        private readonly PairingManager _pairingManager;
        private readonly ILogger<WebSocketServer> _logger;
        private readonly ConcurrentDictionary<string, WebSocket> _connections = new();

        public event Func<string, Task>? MessageReceived;

        public WebSocketServer(PairingManager pairingManager, ILogger<WebSocketServer> logger)
        {
            _pairingManager = pairingManager;
            _logger = logger;
        }

        public virtual async Task StartAsync(int port)
        {
            HttpListener? httpListener = null;
            try
            {
                httpListener = new HttpListener();
                httpListener.Prefixes.Add($"http://*:{port}/");
                httpListener.Start();
                _logger.LogInformation("WebSocket server listening on wildcard prefix http://*:{Port}/", port);
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Wildcard binding failed ({Message}). Falling back to localhost & local IP prefixes.", ex.Message);
                try { httpListener?.Close(); } catch { }

                httpListener = new HttpListener();
                httpListener.Prefixes.Add($"http://localhost:{port}/");
                httpListener.Prefixes.Add($"http://127.0.0.1:{port}/");

                try
                {
                    var host = Dns.GetHostEntry(Dns.GetHostName());
                    foreach (var ip in host.AddressList.Where(a => a.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork))
                    {
                        var prefix = $"http://{ip}:{port}/";
                        if (!httpListener.Prefixes.Contains(prefix))
                        {
                            httpListener.Prefixes.Add(prefix);
                        }
                    }
                    httpListener.Start();
                    _logger.LogInformation("WebSocket server listening on local IP prefixes for port {Port}", port);
                }
                catch (Exception ipEx)
                {
                    _logger.LogWarning("Local IP binding requires URL reservation or admin elevation ({Message}). Falling back to localhost only.", ipEx.Message);
                    try { httpListener.Close(); } catch { }
                    httpListener = new HttpListener();
                    httpListener.Prefixes.Add($"http://localhost:{port}/");
                    httpListener.Prefixes.Add($"http://127.0.0.1:{port}/");
                    httpListener.Start();
                    _logger.LogInformation("WebSocket server successfully listening on localhost:{Port}", port);
                }
            }

            while (true)
            {
                var context = await httpListener.GetContextAsync();
                if (context.Request.IsWebSocketRequest)
                {
                    _ = HandleNewWebSocketRequest(context);
                }
                else
                {
                    context.Response.StatusCode = 400;
                    context.Response.Close();
                }
            }
        }

        private async Task HandleNewWebSocketRequest(HttpListenerContext context)
        {
            var publicKey = context.Request.QueryString["publicKey"];
            var pairingSecret = context.Request.QueryString["pairingSecret"];

            if (string.IsNullOrEmpty(publicKey))
            {
                context.Response.StatusCode = 401;
                context.Response.Close();
                return;
            }

            // Initial pairing flow
            if (!string.IsNullOrEmpty(pairingSecret))
            {
                // Validate the pairing secret
                if (_pairingManager.ValidatePairingSecret(pairingSecret))
                {
                    _pairingManager.RegisterKey(publicKey);
                    _pairingManager.InvalidatePairingSecret(); // Single-use token burn
                }
            }

            if (!_pairingManager.IsKeyRegistered(publicKey))
            {
                context.Response.StatusCode = 401;
                context.Response.Close();
                return;
            }

            var webSocketContext = await context.AcceptWebSocketAsync(null);
            var socket = webSocketContext.WebSocket;

            // Challenge-Response Auth Phase with timestamped nonce
            var challenge = _pairingManager.GenerateChallenge();
            var challengeMsg = JsonSerializer.Serialize(new { type = "auth_challenge", challenge });
            await socket.SendAsync(new ArraySegment<byte>(Encoding.UTF8.GetBytes(challengeMsg)), WebSocketMessageType.Text, true, CancellationToken.None);

            var buffer = new byte[1024 * 4];
            var result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
            
            if (result.MessageType == WebSocketMessageType.Text)
            {
                var msgText = Encoding.UTF8.GetString(buffer, 0, result.Count);
                try
                {
                    using var doc = JsonDocument.Parse(msgText);
                    if (doc.RootElement.TryGetProperty("type", out var typeEl) && typeEl.GetString() == "auth_response" &&
                        doc.RootElement.TryGetProperty("signature", out var sigEl))
                    {
                        var signature = sigEl.GetString() ?? "";
                        if (_pairingManager.ValidateSignature(challenge, signature, publicKey))
                        {
                            var connectionId = Guid.NewGuid().ToString();
                            _connections[connectionId] = socket;
                            
                            // Acknowledge auth
                            var ackMsg = JsonSerializer.Serialize(new { type = "auth_ack" });
                            await socket.SendAsync(new ArraySegment<byte>(Encoding.UTF8.GetBytes(ackMsg)), WebSocketMessageType.Text, true, CancellationToken.None);

                            _ = HandleConnectionAsync(connectionId, socket);
                            return; // Auth successful, exit handshake
                        }
                    }
                }
                catch { /* Parse error */ }
            }

            // Auth failed
            await socket.CloseAsync(WebSocketCloseStatus.PolicyViolation, "Authentication Failed", CancellationToken.None);
        }

        private async Task HandleConnectionAsync(string connectionId, WebSocket webSocket)
        {
            var buffer = new byte[1024 * 8];
            while (webSocket.State == WebSocketState.Open)
            {
                try
                {
                    using var ms = new MemoryStream();
                    WebSocketReceiveResult result;
                    do
                    {
                        result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                        if (result.MessageType == WebSocketMessageType.Close)
                        {
                            await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, string.Empty, CancellationToken.None);
                            _connections.TryRemove(connectionId, out _);
                            return;
                        }

                        ms.Write(buffer, 0, result.Count);
                    }
                    while (!result.EndOfMessage);

                    if (result.MessageType == WebSocketMessageType.Text)
                    {
                        var message = Encoding.UTF8.GetString(ms.ToArray());

                        // Heartbeat ping handling
                        try
                        {
                            using var doc = JsonDocument.Parse(message);
                            if (doc.RootElement.TryGetProperty("type", out var typeEl) && typeEl.GetString() == "ping")
                            {
                                var pong = JsonSerializer.Serialize(new { type = "pong", timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() });
                                await webSocket.SendAsync(new ArraySegment<byte>(Encoding.UTF8.GetBytes(pong)), WebSocketMessageType.Text, true, CancellationToken.None);
                                continue;
                            }
                        }
                        catch { /* Regular message payload */ }

                        if (MessageReceived != null)
                        {
                            await MessageReceived(message);
                        }
                    }
                }
                catch (WebSocketException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing incoming frame on connection {ConnectionId}", connectionId);
                    break;
                }
            }
            _connections.TryRemove(connectionId, out _);
        }

        public virtual async Task BroadcastAsync(string message)
        {
            var bytes = Encoding.UTF8.GetBytes(message);
            var segment = new ArraySegment<byte>(bytes);
            
            foreach (var kvp in _connections)
            {
                var connId = kvp.Key;
                var socket = kvp.Value;
                if (socket.State != WebSocketState.Open)
                {
                    _connections.TryRemove(connId, out _);
                    continue;
                }

                try
                {
                    await socket.SendAsync(segment, WebSocketMessageType.Text, true, CancellationToken.None);
                }
                catch
                {
                    _connections.TryRemove(connId, out _);
                }
            }
        }
    }
}
