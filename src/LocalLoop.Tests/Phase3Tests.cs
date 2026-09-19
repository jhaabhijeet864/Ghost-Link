using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using LocalLoop.Core;
using LocalLoop.Service.Parsing;
using LocalLoop.Service.Policy;
using Xunit;

namespace LocalLoop.Tests
{
    public class IntentParserTests
    {
        private readonly Mock<ILogger<IntentParser>> _mockLogger;
        private readonly IConfiguration _configuration;
        private readonly IntentParser _parser;

        public IntentParserTests()
        {
            _mockLogger = new Mock<ILogger<IntentParser>>();
            
            var configBuilder = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["SemanticKernel:ApiKey"] = "",
                    ["SemanticKernel:ModelId"] = "gpt-4o-mini",
                });
            _configuration = configBuilder.Build();

            _parser = new IntentParser(_mockLogger.Object, _configuration);
        }

        [Theory]
        [InlineData("read the logs", "Low")]
        [InlineData("show me the process list", "Low")]
        [InlineData("view the status of services", "Low")]
        [InlineData("list all running processes", "Low")]
        [InlineData("tail the application log", "Low")]
        [InlineData("check the build status", "Low")]
        [InlineData("search for error messages", "Low")]
        [InlineData("monitor the server", "Low")]
        public async Task ParseAsync_ReadCommands_ReturnsLowRisk(string input, string expectedRisk)
        {
            var intent = await _parser.ParseAsync(input, "test-device");

            Assert.Equal(expectedRisk, intent.RiskLevel);
            Assert.NotEmpty(intent.Explanation);
            Assert.Equal("test-device", intent.DeviceId);
            Assert.NotEqual(default, intent.Timestamp);
        }

        [Theory]
        [InlineData("write to the config file", "Medium")]
        [InlineData("create a new directory", "Medium")]
        [InlineData("edit the configuration", "Medium")]
        [InlineData("update the package", "Medium")]
        [InlineData("restart the web server", "Medium")]
        [InlineData("install the dependency", "Medium")]
        [InlineData("backup the database", "Medium")]
        public async Task ParseAsync_WriteCommands_ReturnsMediumRisk(string input, string expectedRisk)
        {
            var intent = await _parser.ParseAsync(input, "test-device");

            Assert.Equal(expectedRisk, intent.RiskLevel);
            Assert.NotEmpty(intent.Explanation);
            Assert.Equal("test-device", intent.DeviceId);
        }

        [Theory]
        [InlineData("stop the process", "High")]
        [InlineData("kill the node process", "High")]
        [InlineData("terminate the application", "High")]
        [InlineData("delete the file", "High")]
        [InlineData("remove the container", "High")]
        [InlineData("run the script", "High")]
        [InlineData("execute the build", "High")]
        [InlineData("uninstall the package", "High")]
        public async Task ParseAsync_DestructiveCommands_ReturnsHighRisk(string input, string expectedRisk)
        {
            var intent = await _parser.ParseAsync(input, "test-device");

            Assert.Equal(expectedRisk, intent.RiskLevel);
            Assert.NotEmpty(intent.Explanation);
            Assert.Equal("test-device", intent.DeviceId);
        }

        [Fact]
        public async Task ParseAsync_UnknownCommand_ReturnsHighRisk()
        {
            var intent = await _parser.ParseAsync("format the hard drive", "test-device");

            Assert.Equal("High", intent.RiskLevel);
        }

        [Fact]
        public async Task ParseAsync_EmptyInput_ReturnsValidIntent()
        {
            var intent = await _parser.ParseAsync("", "test-device");

            Assert.NotNull(intent);
            Assert.NotEmpty(intent.IntentId);
            Assert.Equal("test-device", intent.DeviceId);
            Assert.NotEqual(default, intent.Timestamp);
        }

        [Fact]
        public async Task ParseAsync_SetsCorrectMetadata()
        {
            var intent = await _parser.ParseAsync("read the logs", "device-123");

            Assert.Equal("device-123", intent.DeviceId);
            Assert.NotEqual(default, intent.Timestamp);
            Assert.Equal("Parsed", intent.Status);
            Assert.NotNull(intent.Parameters);
        }
    }

    public class PolicyEngineTests
    {
        private readonly PolicyEngine _policyEngine = new();

        [Theory]
        [InlineData("read", "file", PolicyDecision.Allow)]
        [InlineData("view", "log", PolicyDecision.Allow)]
        [InlineData("show", "process", PolicyDecision.Allow)]
        [InlineData("list", "directory", PolicyDecision.Allow)]
        [InlineData("status", "server", PolicyDecision.Allow)]
        [InlineData("check", "build", PolicyDecision.Allow)]
        [InlineData("monitor", "network", PolicyDecision.Allow)]
        public void Evaluate_ReadOnlyActions_ReturnsAllow(string action, string target, PolicyDecision expected)
        {
            var intent = new CommandIntent { Action = action, Target = target };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(expected, decision);
        }

        [Theory]
        [InlineData("write", "file", PolicyDecision.Ask)]
        [InlineData("create", "directory", PolicyDecision.Ask)]
        [InlineData("edit", "config", PolicyDecision.Ask)]
        [InlineData("update", "package", PolicyDecision.Ask)]
        [InlineData("restart", "service", PolicyDecision.Ask)]
        [InlineData("install", "package", PolicyDecision.Ask)]
        [InlineData("backup", "database", PolicyDecision.Ask)]
        public void Evaluate_WriteActions_ReturnsAsk(string action, string target, PolicyDecision expected)
        {
            var intent = new CommandIntent { Action = action, Target = target };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(expected, decision);
        }

        [Theory]
        [InlineData("execute", "script", PolicyDecision.Block)]
        [InlineData("run", "command", PolicyDecision.Block)]
        [InlineData("stop", "process", PolicyDecision.Block)]
        [InlineData("kill", "process", PolicyDecision.Block)]
        [InlineData("delete", "file", PolicyDecision.Block)]
        [InlineData("remove", "container", PolicyDecision.Block)]
        [InlineData("uninstall", "package", PolicyDecision.Block)]
        public void Evaluate_DestructiveActions_ReturnsBlock(string action, string target, PolicyDecision expected)
        {
            var intent = new CommandIntent { Action = action, Target = target };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(expected, decision);
        }

        [Fact]
        public void Evaluate_UnknownAction_ReturnsBlock()
        {
            var intent = new CommandIntent { Action = "format", Target = "drive" };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(PolicyDecision.Block, decision);
        }

        [Fact]
        public void Evaluate_AlwaysBlockAction_ReturnsBlock()
        {
            var intent = new CommandIntent { Action = "wipe", Target = "disk" };
            var decision = _policyEngine.Evaluate(intent);
            Assert.Equal(PolicyDecision.Block, decision);
        }

        [Theory]
        [InlineData("read", "file", true)]
        [InlineData("view", "log", true)]
        [InlineData("write", "file", false)]
        [InlineData("delete", "file", false)]
        public void IsActionAllowed_ReturnsExpected(string action, string target, bool expected)
        {
            var result = _policyEngine.IsActionAllowed(action, target);
            Assert.Equal(expected, result);
        }
    }
}