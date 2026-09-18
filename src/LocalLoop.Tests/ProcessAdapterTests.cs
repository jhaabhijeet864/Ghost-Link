using System.Collections.Generic;
using System.Threading.Tasks;
using Xunit;
using LocalLoop.Bridge.Adapters;
using LocalLoop.Core;

namespace LocalLoop.Tests
{
    public class ProcessAdapterTests
    {
        [Fact]
        public async Task ExecuteAsync_RunsProcess_FiresIpcEvents()
        {
            var adapter = new ProcessAdapter();
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
                Target = "cmd.exe",
                Parameters = new Dictionary<string, string>
                {
                    { "/c", "echo hello" }
                }
            };

            await adapter.ExecuteAsync(intent, context);

            Assert.Contains(eventsFired, e => e.Type == "process_stdout" && e.Payload.Contains("hello"));
            Assert.Contains(eventsFired, e => e.Type == "process_exited");
        }
    }
}
