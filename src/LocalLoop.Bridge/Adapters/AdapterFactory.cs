using System.Collections.Generic;
using System.Linq;

namespace LocalLoop.Bridge.Adapters
{
    public class AdapterFactory
    {
        private readonly List<IAdapter> _adapters = new();

        public void RegisterAdapter(IAdapter adapter)
        {
            _adapters.Add(adapter);
        }

        public IAdapter GetAdapter(AutomationLevel level)
        {
            return _adapters.FirstOrDefault(a => a.Supports(level));
        }
    }
}
