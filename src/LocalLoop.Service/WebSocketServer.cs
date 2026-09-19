using System;
using System.Collections.Concurrent;
using System.Net;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using LocalLoop.Core;

namespace LocalLoop.Service
{
    public class WebSocketServer
    {
        private readonly PairingManager _pairingManager;
        private readonly ConcurrentDictionary<string, WebSocket> _connections = new();

        public event Func<string, Task>? MessageReceived;

        public WebSocketServer(PairingManager pairingManager)
        {
            _pairingManager = pairingManager;
        }

        public async Task StartAsync(int port)
        {
            var httpListener = new HttpListener();
            httpListener.Prefixes.Add($"http://localhost:{port}/");
            httpListener.Start();

            while (true)
            {
                var context = await httpListener.GetContextAsync();
                if (context.Request.IsWebSocketRequest)
                {
                    var signature = context.Request.Headers["X-LocalLoop-Signature"];
                    var token = context.Request.QueryString["token"];

                    if (string.IsNullOrEmpty(signature) || !_pairingManager.ValidateSignature(token ?? "", signature))
                    {
                        context.Response.StatusCode = 401;
                        context.Response.Close();
                        continue;
                    }

                    var webSocketContext = await context.AcceptWebSocketAsync(null);
                    var socket = webSocketContext.WebSocket;
                    var connectionId = Guid.NewGuid().ToString();
                    _connections[connectionId] = socket;
                    
                    _ = HandleConnectionAsync(connectionId, socket);
                }
                else
                {
                    context.Response.StatusCode = 400;
                    context.Response.Close();
                }
            }
        }

        private async Task HandleConnectionAsync(string connectionId, WebSocket webSocket)
        {
            var buffer = new byte[1024 * 4];
            while (webSocket.State == WebSocketState.Open)
            {
                try
                {
                    var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, string.Empty, CancellationToken.None);
                        break;
                    }
                    else if (result.MessageType == WebSocketMessageType.Text)
                    {
                        var message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                        if (MessageReceived != null)
                        {
                            await MessageReceived(message);
                        }
                    }
                }
                catch (Exception)
                {
                    break;
                }
            }
            _connections.TryRemove(connectionId, out _);
        }

        public async Task BroadcastAsync(string message)
        {
            var bytes = Encoding.UTF8.GetBytes(message);
            var segment = new ArraySegment<byte>(bytes);
            
            foreach (var kvp in _connections)
            {
                try
                {
                    if (kvp.Value.State == WebSocketState.Open)
                    {
                        await kvp.Value.SendAsync(segment, WebSocketMessageType.Text, true, CancellationToken.None);
                    }
                }
                catch
                {
                    // Ignore send errors, connection will be cleaned up
                }
            }
        }

        public async Task SendToDeviceAsync(string deviceId, string message)
        {
            // For now, broadcast to all connections. In the future, track deviceId per connection.
            await BroadcastAsync(message);
        }
    }
}
