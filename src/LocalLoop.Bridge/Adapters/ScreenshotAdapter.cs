#pragma warning disable CA1416
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using LocalLoop.Core;
using System.Text.Json;

namespace LocalLoop.Bridge.Adapters
{
    public class ScreenshotAdapter : IAdapter
    {
        public bool Supports(AutomationLevel level) => level == AutomationLevel.Level6_Screenshot;

        public async Task ExecuteAsync(CommandIntent intent, IpcContext context)
        {
            int width = GetSystemMetrics(0); // SM_CXSCREEN
            int height = GetSystemMetrics(1); // SM_CYSCREEN
            
            if (width == 0 || height == 0)
            {
                width = 1920;
                height = 1080;
            }

            using var bmp = new Bitmap(width, height);
            using var gfx = Graphics.FromImage(bmp);
            
            gfx.CopyFromScreen(0, 0, 0, 0, new Size(width, height), CopyPixelOperation.SourceCopy);

            using var ms = new MemoryStream();
            bmp.Save(ms, ImageFormat.Jpeg);
            var base64 = Convert.ToBase64String(ms.ToArray());

            var appEvent = new AppEvent
            {
                Type = "screenshot_captured",
                Payload = JsonSerializer.Serialize(new { encoding = "jpeg", data = base64 })
            };
            
            await context.OnEventCreated(appEvent);
        }

        [DllImport("user32.dll")]
        private static extern int GetSystemMetrics(int nIndex);
    }
}
