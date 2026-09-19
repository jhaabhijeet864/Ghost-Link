using System;
using System.Text.Json.Serialization;

namespace LocalLoop.Core
{
    public class ActiveAgentSession
    {
        [JsonPropertyName("sessionId")]
        public string SessionId { get; set; } = Guid.NewGuid().ToString();

        [JsonPropertyName("agentType")]
        public string AgentType { get; set; } = string.Empty;

        [JsonPropertyName("title")]
        public string Title { get; set; } = string.Empty;

        [JsonPropertyName("processId")]
        public int ProcessId { get; set; }

        [JsonPropertyName("status")]
        public string Status { get; set; } = "Active";

        [JsonPropertyName("workingDirectory")]
        public string WorkingDirectory { get; set; } = string.Empty;

        [JsonPropertyName("lastActiveTimestamp")]
        public DateTime LastActiveTimestamp { get; set; } = DateTime.UtcNow;
    }
}
