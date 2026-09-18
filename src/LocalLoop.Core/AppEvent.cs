using System;

namespace LocalLoop.Core
{
    public class AppEvent
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public string SessionId { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public string Payload { get; set; } = "{}";
    }
}
