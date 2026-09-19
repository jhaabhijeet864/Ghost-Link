using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.ChatCompletion;
using Microsoft.SemanticKernel.Connectors.OpenAI;
using LocalLoop.Core;

#pragma warning disable SKEXP0010

namespace LocalLoop.Service.Parsing
{
    public interface IIntentParser
    {
        Task<CommandIntent> ParseAsync(string naturalLanguage, string deviceId, CancellationToken cancellationToken = default);
    }

    public class IntentParser : IIntentParser
    {
        private readonly ILogger<IntentParser> _logger;
        private readonly Kernel _kernel;
        private readonly IChatCompletionService _chatService;

        private const string SystemPrompt = @"
You are a command parser for a remote system administration tool. Parse the user's natural language into a structured JSON intent.

ALLOWED ACTIONS (verbs):
- read, view, show, get, list, tail, watch, cat, less, more
- write, create, edit, modify, update, append, replace
- execute, run, start, launch, invoke, call
- stop, kill, terminate, end, cancel
- restart, reboot, reload
- install, add, download, pull
- uninstall, remove, delete, purge
- search, find, grep, locate
- copy, move, rename
- compress, extract, zip, unzip, tar
- backup, restore
- status, check, monitor, inspect

ALLOWED TARGETS (nouns):
- process, service, application, app, program
- file, directory, folder, log, config, configuration
- container, docker, image, volume
- build, pipeline, job, task
- server, database, db, connection
- port, network, firewall, rule
- package, dependency, module, library
- test, suite, spec
- git, repo, repository, branch, commit

RISK LEVELS:
- Low: Read-only operations (read, view, show, list, tail, watch, status, check, search, find)
- Medium: Write operations that modify state but are recoverable (write, create, edit, modify, update, copy, move, rename, install, restart, compress, extract, backup)
- High: Destructive or irreversible operations (stop, kill, terminate, delete, remove, uninstall, purge, execute, run, start with elevated privileges)

OUTPUT FORMAT (strict JSON):
{
  ""action"": ""<single allowed verb>"",
  ""target"": ""<single allowed noun>"",
  ""parameters"": { ""<key>"": ""<value>"" },
  ""riskLevel"": ""Low|Medium|High"",
  ""explanation"": ""Brief explanation of what the command does and why it has this risk level""
}

RULES:
1. Output ONLY valid JSON. No markdown, no explanations outside JSON.
2. If the request is ambiguous, choose the MOST CONSERVATIVE interpretation (higher risk).
3. If the request maps to multiple actions, pick the PRIMARY action.
4. Extract explicit parameters only. Do not assume defaults for dangerous parameters.
5. If the request cannot be parsed into allowed actions/targets, return riskLevel ""High"" with action ""unknown"".
6. The explanation must justify the risk level.
";

        public IntentParser(ILogger<IntentParser> logger, IConfiguration configuration)
        {
            _logger = logger;

            var builder = Kernel.CreateBuilder();
            
            var apiKey = configuration["SemanticKernel:ApiKey"] ?? Environment.GetEnvironmentVariable("SEMANTIC_KERNEL_API_KEY");
            var modelId = configuration["SemanticKernel:ModelId"] ?? "gpt-4o-mini";
            var endpoint = configuration["SemanticKernel:Endpoint"];

            if (!string.IsNullOrEmpty(endpoint) && !string.IsNullOrEmpty(apiKey))
            {
                builder.AddAzureOpenAIChatCompletion(modelId, endpoint, apiKey);
            }
            else if (!string.IsNullOrEmpty(apiKey))
            {
                builder.AddOpenAIChatCompletion(modelId, apiKey);
            }
            else
            {
                _logger.LogWarning("No Semantic Kernel API key configured. Using mock parser for development.");
            }

            _kernel = builder.Build();
            
            try
            {
                _chatService = _kernel.GetRequiredService<IChatCompletionService>();
            }
            catch
            {
                _chatService = null!;
            }
        }

        public async Task<CommandIntent> ParseAsync(string naturalLanguage, string deviceId, CancellationToken cancellationToken = default)
        {
            var intentId = Guid.NewGuid().ToString();
            
            if (_chatService == null)
            {
                _logger.LogWarning("No LLM configured, returning mock intent for: {Input}", naturalLanguage);
                return CreateMockIntent(naturalLanguage, deviceId, intentId);
            }

            try
            {
                var prompt = $"{SystemPrompt}\n\nUser command: {naturalLanguage}";
                
                var executionSettings = new OpenAIPromptExecutionSettings
                {
                    MaxTokens = 500,
                    Temperature = 0.1,
                    TopP = 0.9,
                    ResponseFormat = "json_object"
                };

                var result = await _chatService.GetChatMessageContentAsync(
                    prompt,
                    executionSettings,
                    _kernel,
                    cancellationToken);

                var json = result.Content?.Trim() ?? "{}";
                _logger.LogDebug("LLM raw response: {Json}", json);

                var parsed = JsonSerializer.Deserialize<CommandIntent>(json, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (parsed == null)
                {
                    throw new JsonException("Failed to deserialize intent");
                }

                parsed.IntentId = intentId;
                parsed.DeviceId = deviceId;
                parsed.Timestamp = DateTime.UtcNow;
                parsed.Status = "Parsed";

                ValidateAndSanitizeIntent(parsed);

                _logger.LogInformation("Parsed intent {IntentId}: {Action} {Target} (Risk: {RiskLevel})",
                    intentId, parsed.Action, parsed.Target, parsed.RiskLevel);

                return parsed;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to parse intent, returning safe fallback");
                return CreateSafeFallbackIntent(naturalLanguage, deviceId, intentId, ex.Message);
            }
        }

        private void ValidateAndSanitizeIntent(CommandIntent intent)
        {
            var allowedActions = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "read", "view", "show", "get", "list", "tail", "watch", "cat", "less", "more",
                "write", "create", "edit", "modify", "update", "append", "replace",
                "execute", "run", "start", "launch", "invoke", "call",
                "stop", "kill", "terminate", "end", "cancel",
                "restart", "reboot", "reload",
                "install", "add", "download", "pull",
                "uninstall", "remove", "delete", "purge",
                "search", "find", "grep", "locate",
                "copy", "move", "rename",
                "compress", "extract", "zip", "unzip", "tar",
                "backup", "restore",
                "status", "check", "monitor", "inspect"
            };

            var allowedTargets = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "process", "service", "application", "app", "program",
                "file", "directory", "folder", "log", "config", "configuration",
                "container", "docker", "image", "volume",
                "build", "pipeline", "job", "task",
                "server", "database", "db", "connection",
                "port", "network", "firewall", "rule",
                "package", "dependency", "module", "library",
                "test", "suite", "spec",
                "git", "repo", "repository", "branch", "commit"
            };

            var validRiskLevels = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "Low", "Medium", "High"
            };

            if (!allowedActions.Contains(intent.Action))
            {
                intent.Action = "unknown";
                intent.RiskLevel = "High";
                intent.Explanation = $"Action '{intent.Action}' is not in the allowed list. Classified as High risk.";
            }

            if (!allowedTargets.Contains(intent.Target))
            {
                intent.Target = "unknown";
                if (intent.RiskLevel == "Low") intent.RiskLevel = "Medium";
                intent.Explanation += $" Target '{intent.Target}' is not recognized.";
            }

            if (!validRiskLevels.Contains(intent.RiskLevel))
            {
                intent.RiskLevel = "High";
            }

            if (intent.Parameters == null)
            {
                intent.Parameters = new Dictionary<string, string>();
            }
        }

        private CommandIntent CreateMockIntent(string input, string deviceId, string intentId)
        {
            var lower = input.ToLowerInvariant();
            
            string action = "unknown";
            string target = "unknown";
            string riskLevel = "High";
            string explanation = "Mock parser - no LLM configured";

            if (lower.Contains("read") || lower.Contains("view") || lower.Contains("show") || lower.Contains("list") || lower.Contains("tail") || lower.Contains("check") || lower.Contains("search") || lower.Contains("monitor") || lower.Contains("inspect") || lower.Contains("status"))
            {
                action = "read"; riskLevel = "Low"; explanation = "Read-only operation";
            }
            else if (lower.Contains("stop") || lower.Contains("kill") || lower.Contains("terminate"))
            {
                action = "stop"; riskLevel = "High"; explanation = "Destructive operation - stops process";
            }
            else if (lower.Contains("delete") || lower.Contains("remove") || lower.Contains("uninstall") || lower.Contains("purge"))
            {
                action = "delete"; riskLevel = "High"; explanation = "Destructive operation - removes data";
            }
            else if (lower.Contains("restart") || lower.Contains("reboot") || lower.Contains("reload"))
            {
                action = "restart"; riskLevel = "Medium"; explanation = "Service restart - modifies state";
            }
            else if (lower.Contains("execute") || lower.Contains("run") || lower.Contains(" launch") || lower.Contains("start ") || lower.StartsWith("start"))
            {
                action = "execute"; riskLevel = "High"; explanation = "Execution operation - runs code";
            }
            else if (lower.Contains("write") || lower.Contains("create") || lower.Contains("edit") || lower.Contains("modify") || lower.Contains("update") || lower.Contains("append") || lower.Contains("install") || lower.Contains("download") || lower.Contains("pull") || lower.Contains("backup"))
            {
                action = "write"; riskLevel = "Medium"; explanation = "Write operation - modifies state";
            }

            if (lower.Contains("process") || lower.Contains("service") || lower.Contains("application") || lower.Contains("app") || lower.Contains("program"))
                target = "process";
            else if (lower.Contains("file") || lower.Contains("log") || lower.Contains("config"))
                target = "file";
            else if (lower.Contains("docker") || lower.Contains("container") || lower.Contains("image") || lower.Contains("volume"))
                target = "container";
            else if (lower.Contains("build") || lower.Contains("pipeline") || lower.Contains("job") || lower.Contains("task"))
                target = "build";
            else if (lower.Contains("server") || lower.Contains("database") || lower.Contains("db") || lower.Contains("connection"))
                target = "server";
            else if (lower.Contains("package") || lower.Contains("dependency") || lower.Contains("module") || lower.Contains("library"))
                target = "package";
            else if (lower.Contains("directory") || lower.Contains("folder"))
                target = "directory";
            else if (lower.Contains("network") || lower.Contains("port") || lower.Contains("firewall"))
                target = "network";

            return new CommandIntent
            {
                IntentId = intentId,
                DeviceId = deviceId,
                Action = action,
                Target = target,
                Parameters = new Dictionary<string, string>(),
                RiskLevel = riskLevel,
                Explanation = explanation,
                Timestamp = DateTime.UtcNow,
                Status = "Parsed"
            };
        }

        private CommandIntent CreateSafeFallbackIntent(string input, string deviceId, string intentId, string error)
        {
            return new CommandIntent
            {
                IntentId = intentId,
                DeviceId = deviceId,
                Action = "unknown",
                Target = "unknown",
                Parameters = new Dictionary<string, string>(),
                RiskLevel = "High",
                Explanation = $"Parse failed: {error}. Classified as High risk for safety.",
                Timestamp = DateTime.UtcNow,
                Status = "ParseError"
            };
        }
    }
}

#pragma warning restore SKEXP0010