using Xunit;
using LocalLoop.Bridge.Adapters;

namespace LocalLoop.Tests
{
    public class AdapterFactoryTests
    {
        [Fact]
        public void RegisterAdapter_StoresAdapter()
        {
            var factory = new AdapterFactory();
            var adapter = new ProcessAdapter();
            factory.RegisterAdapter(adapter);

            var resolved = factory.GetAdapter(AutomationLevel.Level2_Process);

            Assert.NotNull(resolved);
            Assert.IsType<ProcessAdapter>(resolved);
        }

        [Fact]
        public void GetAdapter_ReturnsNull_WhenNotFound()
        {
            var factory = new AdapterFactory();
            
            var resolved = factory.GetAdapter(AutomationLevel.Level6_Screenshot);

            Assert.Null(resolved);
        }
    }
}
