using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace LocalLoop.Core
{
    public class CommandIntent
    {
        [JsonPropertyName("intentId")]
        public string IntentId { get; set; } = Guid.NewGuid().ToString();

        [JsonPropertyName("deviceId")]
        public string DeviceId { get; set; } = string.Empty;

        [JsonPropertyName("action")]
        public string Action { get; set; } = string.Empty;

        [JsonPropertyName("target")]
        public string Target { get; set; } = string.Empty;

        [JsonPropertyName("parameters")]
        public Dictionary<string, string> Parameters { get; set; } = new();

        [JsonPropertyName("riskLevel")]
        public string RiskLevel { get; set; } = "Low";

        [JsonPropertyName("explanation")]
        public string Explanation { get; set; } = string.Empty;

        [JsonPropertyName("timestamp")]
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        [JsonPropertyName("status")]
        public string Status { get; set; } = "Pending";
    }

    public enum PolicyDecision
    {
        Allow,
        Ask,
        Block
    }

    public class AuditRecord
    {
        [JsonPropertyName("auditId")]
        public string AuditId { get; set; } = Guid.NewGuid().ToString();

        [JsonPropertyName("intentId")]
        public string IntentId { get; set; } = string.Empty;

        [JsonPropertyName("deviceId")]
        public string DeviceId { get; set; } = string.Empty;

        [JsonPropertyName("action")]
        public string Action { get; set; } = string.Empty;

        [JsonPropertyName("target")]
        public string Target { get; set; } = string.Empty;

        [JsonPropertyName("riskLevel")]
        public string RiskLevel { get; set; } = string.Empty;

        [JsonPropertyName("policyDecision")]
        public PolicyDecision PolicyDecision { get; set; }

        [JsonPropertyName("userDecision")]
        public string UserDecision { get; set; } = string.Empty;

        [JsonPropertyName("result")]
        public string Result { get; set; } = string.Empty;

        [JsonPropertyName("timestamp")]
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }
}
