using System;
using System.Net;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace LocalLoop.Service
{
    public class WebSocketServer
    {
        private readonly PairingManager _pairingManager;
        
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
                    _ = HandleConnectionAsync(webSocketContext.WebSocket);
                }
                else
                {
                    context.Response.StatusCode = 400;
                    context.Response.Close();
                }
            }
        }

        private async Task HandleConnectionAsync(WebSocket webSocket)
        {
            var buffer = new byte[1024 * 4];
            while (webSocket.State == WebSocketState.Open)
            {
                var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, string.Empty, CancellationToken.None);
                }
                else if (result.MessageType == WebSocketMessageType.Text)
                {
                    // Echo for now
                    await webSocket.SendAsync(new ArraySegment<byte>(buffer, 0, result.Count), WebSocketMessageType.Text, result.EndOfMessage, CancellationToken.None);
                }
            }
        }
    }
}
