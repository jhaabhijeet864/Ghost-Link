using System.Text.Json.Serialization;

namespace LocalLoop.Core
{
    public class IpcMessage
    {
        [JsonPropertyName("type")]
        public string Type { get; set; } = string.Empty;

        [JsonPropertyName("data")]
        public string Data { get; set; } = string.Empty;

        [JsonPropertyName("correlationId")]
        public string CorrelationId { get; set; } = string.Empty;
    }

    public static class IpcMessageTypes
    {
        public const string CommandRequest = "command_request";
        public const string CommandResponse = "command_response";
        public const string ApprovalRequest = "approval_request";
        public const string ApprovalResponse = "approval_response";
        public const string AuditEvent = "audit_event";
        public const string Ack = "ack";
        public const string Error = "error";
    }

    public static class IpcMessageFactory
    {
        public static IpcMessage CreateCommandRequest(CommandIntent intent, string correlationId = "")
        {
            return new IpcMessage
            {
                Type = IpcMessageTypes.CommandRequest,
                Data = System.Text.Json.JsonSerializer.Serialize(intent),
                CorrelationId = correlationId
            };
        }

        public static IpcMessage CreateCommandResponse(string intentId, bool success, string result = "", string error = "")
        {
            var data = System.Text.Json.JsonSerializer.Serialize(new
            {
                intentId,
                success,
                result,
                error
            });
            return new IpcMessage
            {
                Type = IpcMessageTypes.CommandResponse,
                Data = data
            };
        }

        public static IpcMessage CreateApprovalRequest(CommandIntent intent, string correlationId = "")
        {
            return new IpcMessage
            {
                Type = IpcMessageTypes.ApprovalRequest,
                Data = System.Text.Json.JsonSerializer.Serialize(intent),
                CorrelationId = correlationId
            };
        }

        public static IpcMessage CreateApprovalResponse(string intentId, bool approved, string userDecision)
        {
            var data = System.Text.Json.JsonSerializer.Serialize(new
            {
                intentId,
                approved,
                userDecision
            });
            return new IpcMessage
            {
                Type = IpcMessageTypes.ApprovalResponse,
                Data = data
            };
        }

        public static IpcMessage CreateAuditEvent(AuditRecord audit)
        {
            return new IpcMessage
            {
                Type = IpcMessageTypes.AuditEvent,
                Data = System.Text.Json.JsonSerializer.Serialize(audit)
            };
        }

        public static IpcMessage CreateError(string message, string correlationId = "")
        {
            return new IpcMessage
            {
                Type = IpcMessageTypes.Error,
                Data = System.Text.Json.JsonSerializer.Serialize(new { message }),
                CorrelationId = correlationId
            };
        }

        public static IpcMessage CreateAck(string correlationId = "")
        {
            return new IpcMessage
            {
                Type = IpcMessageTypes.Ack,
                Data = "OK",
                CorrelationId = correlationId
            };
        }
    }
}
