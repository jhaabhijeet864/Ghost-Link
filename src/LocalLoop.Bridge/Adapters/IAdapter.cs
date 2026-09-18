using System;
using System.Threading.Tasks;
using LocalLoop.Core;

namespace LocalLoop.Bridge.Adapters
{
    public class IpcContext
    {
        public Func<AppEvent, Task> OnEventCreated { get; set; } = _ => Task.CompletedTask;
    }

    public interface IAdapter
    {
        bool Supports(AutomationLevel level);
        Task ExecuteAsync(CommandIntent intent, IpcContext context);
    }
}
