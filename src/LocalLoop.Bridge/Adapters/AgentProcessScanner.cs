using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using LocalLoop.Core;

namespace LocalLoop.Bridge.Adapters
{
    public class AgentProcessScanner
    {
        public static List<ActiveAgentSession> ScanActiveAgents()
        {
            var sessions = new List<ActiveAgentSession>();

            try
            {
                var processes = Process.GetProcesses();

                foreach (var proc in processes)
                {
                    try
                    {
                        string processName = proc.ProcessName.ToLowerInvariant();
                        string title = proc.MainWindowTitle;

                        // 1. Antigravity IDE / VS Code based agent
                        if (processName == "code" && !string.IsNullOrWhiteSpace(title))
                        {
                            bool isAntigravity = title.IndexOf("Antigravity", StringComparison.OrdinalIgnoreCase) >= 0;
                            sessions.Add(new ActiveAgentSession
                            {
                                SessionId = $"ide-{proc.Id}",
                                AgentType = isAntigravity ? "AntigravityIDE" : "VSCode",
                                Title = title,
                                ProcessId = proc.Id,
                                Status = "Active",
                                LastActiveTimestamp = DateTime.UtcNow
                            });
                        }
                        // 2. Antigravity CLI (agy)
                        else if (processName == "agy" || processName == "antigravity")
                        {
                            sessions.Add(new ActiveAgentSession
                            {
                                SessionId = $"agy-{proc.Id}",
                                AgentType = "AntigravityCli",
                                Title = string.IsNullOrWhiteSpace(title) ? "Antigravity CLI Session" : title,
                                ProcessId = proc.Id,
                                Status = "Active",
                                LastActiveTimestamp = DateTime.UtcNow
                            });
                        }
                        // 3. Claude Code CLI
                        else if (processName == "claude")
                        {
                            sessions.Add(new ActiveAgentSession
                            {
                                SessionId = $"claude-{proc.Id}",
                                AgentType = "ClaudeCode",
                                Title = string.IsNullOrWhiteSpace(title) ? "Claude Code CLI" : title,
                                ProcessId = proc.Id,
                                Status = "Active",
                                LastActiveTimestamp = DateTime.UtcNow
                            });
                        }
                        // 4. OpenCode CLI
                        else if (processName == "opencode")
                        {
                            sessions.Add(new ActiveAgentSession
                            {
                                SessionId = $"opencode-{proc.Id}",
                                AgentType = "OpenCode",
                                Title = string.IsNullOrWhiteSpace(title) ? "OpenCode Session" : title,
                                ProcessId = proc.Id,
                                Status = "Active",
                                LastActiveTimestamp = DateTime.UtcNow
                            });
                        }
                    }
                    catch
                    {
                        // Ignore individual process access denied errors
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[AgentProcessScanner] Error scanning processes: {ex.Message}");
            }

            return sessions;
        }
    }
}
