using System.Collections.Generic;
using System.Threading.Tasks;
using LocalLoop.Bridge.Adapters;
using LocalLoop.Core;
using Xunit;

namespace LocalLoop.Tests
{
    public class ScreenshotAdapterE2ETests
    {
        [Fact]
        public async Task ExecuteAsync_CapturesScreenshot_ReturnsBase64()
        {
            var adapter = new ScreenshotAdapter();
            var eventsFired = new List<AppEvent>();
            
            var context = new IpcContext
            {
                OnEventCreated = (e) => 
                {
                    eventsFired.Add(e);
                    return Task.CompletedTask;
                }
            };

            var intent = new CommandIntent
            {
                Action = "take_screenshot"
            };

            await adapter.ExecuteAsync(intent, context);

            Assert.Contains(eventsFired, e => e.Type == "screenshot_captured");
            var screenshotEvent = eventsFired.Find(e => e.Type == "screenshot_captured");
            Assert.NotNull(screenshotEvent);
            Assert.NotNull(screenshotEvent.Payload);
            // Verify payload is a non-empty base64 string
            Assert.True(screenshotEvent.Payload.Length > 100); 
        }
    }
}
