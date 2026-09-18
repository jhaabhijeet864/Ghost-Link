using System;
using System.Diagnostics;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using LocalLoop.Core;

namespace LocalLoop.Bridge.Adapters
{
    public class ProcessAdapter : IAdapter
    {
        public bool Supports(AutomationLevel level) => level == AutomationLevel.Level2_Process;

        public async Task ExecuteAsync(CommandIntent intent, IpcContext context)
        {
            if (string.IsNullOrEmpty(intent.Target))
                throw new ArgumentException("Target executable is required for ProcessAdapter");

            var psi = new ProcessStartInfo
            {
                FileName = intent.Target,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            if (intent.Parameters != null && intent.Parameters.Count > 0)
            {
                var argsBuilder = new StringBuilder();
                foreach (var kvp in intent.Parameters)
                {
                    if (string.IsNullOrEmpty(kvp.Key))
                        argsBuilder.Append($"{kvp.Value} ");
                    else
                        argsBuilder.Append($"{kvp.Key} {kvp.Value} ");
                }
                psi.Arguments = argsBuilder.ToString().Trim();
            }

            using var process = new Process { StartInfo = psi };
            
            process.OutputDataReceived += async (s, e) =>
            {
                if (e.Data != null)
                {
                    var appEvent = new AppEvent
                    {
                        Type = "process_stdout",
                        Payload = JsonSerializer.Serialize(new { target = intent.Target, data = e.Data })
                    };
                    await context.OnEventCreated(appEvent);
                }
            };

            process.ErrorDataReceived += async (s, e) =>
            {
                if (e.Data != null)
                {
                    var appEvent = new AppEvent
                    {
                        Type = "process_stderr",
                        Payload = JsonSerializer.Serialize(new { target = intent.Target, data = e.Data })
                    };
                    await context.OnEventCreated(appEvent);
                }
            };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            await process.WaitForExitAsync();

            var completionEvent = new AppEvent
            {
                Type = "process_exited",
                Payload = JsonSerializer.Serialize(new { target = intent.Target, exitCode = process.ExitCode })
            };
            await context.OnEventCreated(completionEvent);
        }
    }
}
