using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Threading.Tasks;
using System.Collections.Concurrent;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

var app = builder.Build();

app.UseWebSockets();

// Simple in-memory state for prototype
var activeSockets = new ConcurrentDictionary<string, WebSocket>();
var pendingApprovals = new ConcurrentDictionary<string, TaskCompletionSource<bool>>();

app.MapPost("/hook/pretooluse", async (HttpContext context, ILogger<Program> logger) =>
{
    var requestBody = await JsonSerializer.DeserializeAsync<JsonElement>(context.Request.Body);
    logger.LogInformation("Received Claude Code PreToolUse Hook");

    if (requestBody.TryGetProperty("toolCall", out var toolCall) &&
        toolCall.TryGetProperty("name", out var toolName))
    {
        var tool = toolName.GetString();
        logger.LogWarning("AGENT ATTEMPTING TOOL USE: {ToolName}", tool);
        
        if (activeSockets.IsEmpty)
        {
            logger.LogWarning("No mobile device connected. Denying automatically.");
            return Results.Json(new { decision = "deny", reason = "No mobile device connected for approval." });
        }

        var approvalId = Guid.NewGuid().ToString();
        var tcs = new TaskCompletionSource<bool>();
        pendingApprovals[approvalId] = tcs;

        // Construct command payload
        var commandPayload = JsonSerializer.Serialize(new
        {
            type = "command_request",
            id = approvalId,
            tool = tool,
            details = toolCall.ToString(),
            risk = "High"
        });

        // Broadcast to mobile
        var bytes = Encoding.UTF8.GetBytes(commandPayload);
        foreach (var socket in activeSockets.Values)
        {
            if (socket.State == WebSocketState.Open)
            {
                await socket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
            }
        }

        logger.LogInformation("Sent approval request {ApprovalId} to mobile device. Waiting for Face ID response...", approvalId);

        // Wait for response with timeout (2 minutes)
        var delayTask = Task.Delay(TimeSpan.FromMinutes(2));
        var completedTask = await Task.WhenAny(tcs.Task, delayTask);

        pendingApprovals.TryRemove(approvalId, out _);

        if (completedTask == tcs.Task)
        {
            bool approved = await tcs.Task;
            if (approved)
            {
                logger.LogInformation("Mobile device APPROVED request {ApprovalId}", approvalId);
                return Results.Json(new { decision = "allow" });
            }
            else
            {
                logger.LogWarning("Mobile device DENIED request {ApprovalId}", approvalId);
                return Results.Json(new { decision = "deny", reason = "Denied by user via mobile device" });
            }
        }
        else
        {
            logger.LogWarning("Approval request {ApprovalId} TIMED OUT", approvalId);
            return Results.Json(new { decision = "deny", reason = "Approval timeout" });
        }
    }

    logger.LogError("Failed to parse toolCall from hook payload.");
    return Results.Json(new { decision = "deny", reason = "Invalid payload structure" });
});

app.Map("/ws", async context =>
{
    if (context.WebSockets.IsWebSocketRequest)
    {
        var webSocket = await context.WebSockets.AcceptWebSocketAsync();
        var connId = Guid.NewGuid().ToString();
        activeSockets[connId] = webSocket;
        app.Logger.LogInformation("Mobile device connected via WebSocket ({ConnId})", connId);

        var buffer = new byte[1024 * 4];
        while (webSocket.State == WebSocketState.Open)
        {
            try
            {
                var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    break;
                }
                
                var msgText = Encoding.UTF8.GetString(buffer, 0, result.Count);
                using var doc = JsonDocument.Parse(msgText);
                
                // Expecting { "type": "approval_response", "id": "...", "approved": true/false }
                if (doc.RootElement.TryGetProperty("type", out var typeEl) && typeEl.GetString() == "approval_response" &&
                    doc.RootElement.TryGetProperty("id", out var idEl) &&
                    doc.RootElement.TryGetProperty("approved", out var approvedEl))
                {
                    var id = idEl.GetString();
                    var isApproved = approvedEl.GetBoolean();
                    
                    if (id != null && pendingApprovals.TryGetValue(id, out var tcs))
                    {
                        tcs.TrySetResult(isApproved);
                    }
                }
            }
            catch
            {
                break;
            }
        }
        
        activeSockets.TryRemove(connId, out _);
        app.Logger.LogInformation("Mobile device disconnected ({ConnId})", connId);
    }
    else
    {
        context.Response.StatusCode = 400;
    }
});

app.Logger.LogInformation("LocalLoop.Cli Daemon started.");
app.Logger.LogInformation("- Hook Endpoint: http://localhost:11111/hook/pretooluse");
app.Logger.LogInformation("- WebSocket:     ws://localhost:11111/ws");
app.Run("http://localhost:11111");
