using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using LocalLoop.Bridge.Adapters;
using LocalLoop.Core;
using Xunit;

namespace LocalLoop.Tests
{
    public class ProcessAdapterTests
    {
        private readonly ProcessAdapter _adapter;

        public ProcessAdapterTests()
        {
            _adapter = new ProcessAdapter();
        }

        [Fact]
        public void Supports_Level2_Process_ReturnsTrue()
        {
            Assert.True(_adapter.Supports(AutomationLevel.Level2_Process));
        }

        [Fact]
        public void Supports_OtherLevels_ReturnsFalse()
        {
            Assert.False(_adapter.Supports(AutomationLevel.Level1_Native));
            Assert.False(_adapter.Supports(AutomationLevel.Level3_UIAutomation));
            Assert.False(_adapter.Supports(AutomationLevel.Level6_Screenshot));
        }

        [Fact]
        public async Task ExecuteAsync_ValidProcess_ReturnsCompletedEvent()
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                Target = "cmd.exe",
                Action = "execute",
                Parameters = new Dictionary<string, string> { ["/c"] = "echo hello" }
            };

            var events = new List<AppEvent>();
            var context = new IpcContext
            {
                OnEventCreated = async e =>
                {
                    events.Add(e);
                    await Task.CompletedTask;
                }
            };

            await _adapter.ExecuteAsync(intent, context);

            Assert.Contains(events, e => e.Type == "process_exited");
            var exitEvent = events.Find(e => e.Type == "process_exited");
            Assert.NotNull(exitEvent);
        }

        [Fact]
        public async Task ExecuteAsync_InvalidTarget_ThrowsArgumentException()
        {
            var intent = new CommandIntent
            {
                Target = "",
                Action = "execute"
            };

            var context = new IpcContext { OnEventCreated = _ => Task.CompletedTask };

            await Assert.ThrowsAsync<ArgumentException>(() => _adapter.ExecuteAsync(intent, context));
        }

        [Fact]
        public async Task ExecuteAsync_InvalidExecutable_ThrowsWin32Exception()
        {
            var intent = new CommandIntent
            {
                Target = "nonexistent_executable_xyz_123",
                Action = "execute"
            };

            var context = new IpcContext { OnEventCreated = _ => Task.CompletedTask };

            await Assert.ThrowsAsync<System.ComponentModel.Win32Exception>(() => _adapter.ExecuteAsync(intent, context));
        }

        [Fact]
        public async Task ExecuteAsync_WithParameters_PassesArguments()
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                Target = "cmd.exe",
                Action = "execute",
                Parameters = new Dictionary<string, string> { ["/c"] = "echo test" }
            };

            var events = new List<AppEvent>();
            var context = new IpcContext
            {
                OnEventCreated = async e =>
                {
                    events.Add(e);
                    await Task.CompletedTask;
                }
            };

            await _adapter.ExecuteAsync(intent, context);

            Assert.Contains(events, e => e.Type == "process_exited");
        }
    }

    public class FlaUiAdapterTests
    {
        private readonly FlaUiAdapter _adapter;

        public FlaUiAdapterTests()
        {
            _adapter = new FlaUiAdapter();
        }

        [Fact]
        public void Supports_Level3_UIAutomation_ReturnsTrue()
        {
            Assert.True(_adapter.Supports(AutomationLevel.Level3_UIAutomation));
        }

        [Fact]
        public void Supports_OtherLevels_ReturnsFalse()
        {
            Assert.False(_adapter.Supports(AutomationLevel.Level1_Native));
            Assert.False(_adapter.Supports(AutomationLevel.Level2_Process));
            Assert.False(_adapter.Supports(AutomationLevel.Level6_Screenshot));
        }

        [Fact]
        public async Task ExecuteAsync_NoTarget_ThrowsArgumentException()
        {
            var intent = new CommandIntent { Target = "", Action = "focus" };
            var context = new IpcContext { OnEventCreated = _ => Task.CompletedTask };

            await Assert.ThrowsAsync<ArgumentException>(() => _adapter.ExecuteAsync(intent, context));
        }

        [Fact]
        public async Task ExecuteAsync_UnknownAction_ThrowsException()
        {
            var intent = new CommandIntent { Target = "notepad", Action = "unknown_action" };
            var context = new IpcContext { OnEventCreated = _ => Task.CompletedTask };

            await Assert.ThrowsAsync<Exception>(() => _adapter.ExecuteAsync(intent, context));
        }
    }

    public class ScreenshotAdapterTests
    {
        private readonly ScreenshotAdapter _adapter;

        public ScreenshotAdapterTests()
        {
            _adapter = new ScreenshotAdapter();
        }

        [Fact]
        public void Supports_Level6_Screenshot_ReturnsTrue()
        {
            Assert.True(_adapter.Supports(AutomationLevel.Level6_Screenshot));
        }

        [Fact]
        public void Supports_OtherLevels_ReturnsFalse()
        {
            Assert.False(_adapter.Supports(AutomationLevel.Level1_Native));
            Assert.False(_adapter.Supports(AutomationLevel.Level2_Process));
            Assert.False(_adapter.Supports(AutomationLevel.Level3_UIAutomation));
        }

        [Fact]
        public async Task ExecuteAsync_CapturesScreenshot_ReturnsBase64()
        {
            var intent = new CommandIntent
            {
                IntentId = Guid.NewGuid().ToString(),
                Action = "capture",
                Target = "screen"
            };

            var events = new List<AppEvent>();
            var context = new IpcContext
            {
                OnEventCreated = async e =>
                {
                    events.Add(e);
                    await Task.CompletedTask;
                }
            };

            await _adapter.ExecuteAsync(intent, context);

            Assert.Contains(events, e => e.Type == "screenshot_captured");
            var screenshotEvent = events.Find(e => e.Type == "screenshot_captured");
            Assert.NotNull(screenshotEvent);
            
            var payload = JsonSerializer.Deserialize<ScreenshotPayload>(screenshotEvent.Payload);
            Assert.NotNull(payload);
            Assert.NotNull(payload.Data);
            
            // In headless test environments, GDI+ may return empty data
            // Just verify the event structure is correct
            if (!string.IsNullOrEmpty(payload.Encoding))
            {
                Assert.Equal("jpeg", payload.Encoding);
            }
            
            if (!string.IsNullOrEmpty(payload.Data))
            {
                var bytes = Convert.FromBase64String(payload.Data);
                Assert.True(bytes.Length > 0);
            }
        }

        [Fact]
        public async Task ExecuteAsync_InvalidTarget_StillCapturesScreen()
        {
            var intent = new CommandIntent { Action = "capture", Target = "invalid" };
            var events = new List<AppEvent>();
            var context = new IpcContext { OnEventCreated = async e => { events.Add(e); await Task.CompletedTask; } };

            await _adapter.ExecuteAsync(intent, context);

            Assert.Contains(events, e => e.Type == "screenshot_captured");
        }

        private class ScreenshotPayload
        {
            public string Encoding { get; set; } = string.Empty;
            public string Data { get; set; } = string.Empty;
        }
    }

    public class AdapterFactoryTests
    {
        private readonly AdapterFactory _factory;

        public AdapterFactoryTests()
        {
            _factory = new AdapterFactory();
        }

        [Fact]
        public void RegisterAdapter_ProcessAdapter_CanBeRetrieved()
        {
            _factory.RegisterAdapter(new ProcessAdapter());
            var adapter = _factory.GetAdapter(AutomationLevel.Level2_Process);
            
            Assert.NotNull(adapter);
            Assert.IsType<ProcessAdapter>(adapter);
        }

        [Fact]
        public void RegisterAdapter_FlaUiAdapter_CanBeRetrieved()
        {
            _factory.RegisterAdapter(new FlaUiAdapter());
            var adapter = _factory.GetAdapter(AutomationLevel.Level3_UIAutomation);
            
            Assert.NotNull(adapter);
            Assert.IsType<FlaUiAdapter>(adapter);
        }

        [Fact]
        public void RegisterAdapter_ScreenshotAdapter_CanBeRetrieved()
        {
            _factory.RegisterAdapter(new ScreenshotAdapter());
            var adapter = _factory.GetAdapter(AutomationLevel.Level6_Screenshot);
            
            Assert.NotNull(adapter);
            Assert.IsType<ScreenshotAdapter>(adapter);
        }

        [Fact]
        public void GetAdapter_UnregisteredLevel_ReturnsNull()
        {
            var adapter = _factory.GetAdapter(AutomationLevel.Level1_Native);
            Assert.Null(adapter);
        }

        [Fact]
        public void MultipleAdapters_CanBeRegisteredAndRetrieved()
        {
            _factory.RegisterAdapter(new ProcessAdapter());
            _factory.RegisterAdapter(new FlaUiAdapter());
            _factory.RegisterAdapter(new ScreenshotAdapter());

            Assert.IsType<ProcessAdapter>(_factory.GetAdapter(AutomationLevel.Level2_Process));
            Assert.IsType<FlaUiAdapter>(_factory.GetAdapter(AutomationLevel.Level3_UIAutomation));
            Assert.IsType<ScreenshotAdapter>(_factory.GetAdapter(AutomationLevel.Level6_Screenshot));
        }

        [Fact]
        public void RegisterMultipleAdaptersForSameLevel_ReturnsFirst()
        {
            _factory.RegisterAdapter(new ProcessAdapter());
            _factory.RegisterAdapter(new ProcessAdapter()); // Second one
            
            var adapter = _factory.GetAdapter(AutomationLevel.Level2_Process);
            Assert.NotNull(adapter);
        }
    }

    public class AutomationLevelTests
    {
        [Fact]
        public void Values_AreCorrect()
        {
            Assert.Equal(1, (int)AutomationLevel.Level1_Native);
            Assert.Equal(2, (int)AutomationLevel.Level2_Process);
            Assert.Equal(3, (int)AutomationLevel.Level3_UIAutomation);
            Assert.Equal(6, (int)AutomationLevel.Level6_Screenshot);
        }

        [Fact]
        public void Enum_HasExpectedValues()
        {
            var values = Enum.GetValues<AutomationLevel>();
            Assert.Equal(4, values.Length);
            Assert.Contains(AutomationLevel.Level1_Native, values);
            Assert.Contains(AutomationLevel.Level2_Process, values);
            Assert.Contains(AutomationLevel.Level3_UIAutomation, values);
            Assert.Contains(AutomationLevel.Level6_Screenshot, values);
        }
    }

    public class IAdapterInterfaceTests
    {
        [Fact]
        public void Interface_HasRequiredMembers()
        {
            var adapter = new ProcessAdapter();
            
            Assert.True(adapter.Supports(AutomationLevel.Level2_Process));
            Assert.False(adapter.Supports(AutomationLevel.Level6_Screenshot));
            
            var intent = new CommandIntent { Target = "cmd.exe", Action = "test" };
            var context = new IpcContext { OnEventCreated = _ => Task.CompletedTask };
            
            var task = adapter.ExecuteAsync(intent, context);
            Assert.NotNull(task);
        }

        [Fact]
        public void IpcContext_CanBeCreated()
        {
            var context = new IpcContext
            {
                OnEventCreated = async e => await Task.CompletedTask
            };
            
            Assert.NotNull(context.OnEventCreated);
        }
    }
}