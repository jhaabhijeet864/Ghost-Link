using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace LocalLoop.Core
{
    public class CommandIntent
    {
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
    }
}
