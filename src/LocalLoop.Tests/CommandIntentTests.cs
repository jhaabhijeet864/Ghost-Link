using System.Collections.Generic;
using System.Text.Json;
using LocalLoop.Core;
using Xunit;

namespace LocalLoop.Tests
{
    public class CommandIntentTests
    {
        [Fact]
        public void Serialize_ProducesExpectedJson()
        {
            var intent = new CommandIntent
            {
                Action = "run_process",
                Target = "echo",
                Parameters = new Dictionary<string, string> { { "msg", "hello" } },
                RiskLevel = "low"
            };

            var json = JsonSerializer.Serialize(intent);
            
            Assert.Contains("\"action\":\"run_process\"", json);
            Assert.Contains("\"target\":\"echo\"", json);
            Assert.Contains("\"parameters\":{\"msg\":\"hello\"}", json);
            Assert.Contains("\"riskLevel\":\"low\"", json);
        }

        [Fact]
        public void Deserialize_PopulatesObject()
        {
            var json = @"{""action"":""run_process"",""target"":""echo"",""parameters"":{""msg"":""hello""},""riskLevel"":""low""}";

            var intent = JsonSerializer.Deserialize<CommandIntent>(json);

            Assert.NotNull(intent);
            Assert.Equal("run_process", intent.Action);
            Assert.Equal("echo", intent.Target);
            Assert.NotNull(intent.Parameters);
            Assert.Equal("hello", intent.Parameters["msg"]);
            Assert.Equal("low", intent.RiskLevel);
        }
    }
}
