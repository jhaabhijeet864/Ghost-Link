using System;
using System.Linq;
using System.Threading.Tasks;
using LocalLoop.Core;
using FlaUI.Core;
using FlaUI.Core.AutomationElements;
using FlaUI.UIA2;
using FlaUI.UIA3;
using System.Diagnostics;
using System.Text.Json;

namespace LocalLoop.Bridge.Adapters
{
    public class FlaUiAdapter : IAdapter
    {
        public bool Supports(AutomationLevel level) => level == AutomationLevel.Level3_UIAutomation;

        public async Task ExecuteAsync(CommandIntent intent, IpcContext context)
        {
            if (string.IsNullOrEmpty(intent.Target))
                throw new ArgumentException("Process name is required as target for FlaUiAdapter");

            var processes = Process.GetProcessesByName(intent.Target);
            if (processes.Length == 0)
                throw new Exception($"Could not find running process with name {intent.Target}");

            var process = processes.First();
            var app = Application.Attach(process.Id);

            AutomationBase automation = new UIA3Automation();
            try
            {
                var mainWindow = app.GetMainWindow(automation);
                if (mainWindow == null)
                {
                    automation.Dispose();
                    automation = new UIA2Automation();
                    mainWindow = app.GetMainWindow(automation);
                }

                if (mainWindow == null)
                    throw new Exception("Could not find main window for application");

                if (intent.Action == "focus")
                {
                    mainWindow.Focus();
                    var appEvent = new AppEvent
                    {
                        Type = "flaui_action_completed",
                        Payload = JsonSerializer.Serialize(new { action = "focus", success = true })
                    };
                    await context.OnEventCreated(appEvent);
                }
                else if (intent.Action == "click")
                {
                    if (intent.Parameters != null && intent.Parameters.TryGetValue("elementName", out var name))
                    {
                        var element = mainWindow.FindFirstDescendant(cf => cf.ByName(name))?.AsButton();
                        if (element != null)
                        {
                            element.Invoke();
                            var appEvent = new AppEvent
                            {
                                Type = "flaui_action_completed",
                                Payload = JsonSerializer.Serialize(new { action = "click", target = name, success = true })
                            };
                            await context.OnEventCreated(appEvent);
                        }
                    }
                }
            }
            finally
            {
                automation.Dispose();
            }
        }
    }
}
