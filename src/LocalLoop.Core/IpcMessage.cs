using System.Text.Json.Serialization;

namespace LocalLoop.Core
{
    public class IpcMessage
    {
        [JsonPropertyName("type")]
        public string Type { get; set; } = string.Empty;

        [JsonPropertyName("data")]
        public string Data { get; set; } = string.Empty;
    }
}
