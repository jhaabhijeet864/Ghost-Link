using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using LocalLoop.Core;

namespace LocalLoop.Bridge.Adapters
{
    public class AntigravityTranscriptWatcher
    {
        private readonly string _brainRoot;
        private CancellationTokenSource? _cts;
        private Task? _watcherTask;
        private readonly Func<AppEvent, Task> _eventCallback;

        public AntigravityTranscriptWatcher(Func<AppEvent, Task> eventCallback)
        {
            _eventCallback = eventCallback;
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            _brainRoot = Path.Combine(userProfile, ".gemini", "antigravity-ide", "brain");
        }

        public void Start()
        {
            if (_watcherTask != null) return;

            _cts = new CancellationTokenSource();
            _watcherTask = Task.Run(() => WatchLoopAsync(_cts.Token));
        }

        public void Stop()
        {
            _cts?.Cancel();
            _watcherTask = null;
        }

        private async Task WatchLoopAsync(CancellationToken ct)
        {
            long lastReadPosition = 0;
            string? currentTranscriptPath = null;

            while (!ct.IsCancellationRequested)
            {
                try
                {
                    string? activeTranscript = FindActiveTranscriptPath();

                    if (!string.IsNullOrEmpty(activeTranscript))
                    {
                        if (activeTranscript != currentTranscriptPath)
                        {
                            currentTranscriptPath = activeTranscript;
                            // Start reading near the end or read recent lines
                            var fileInfo = new FileInfo(currentTranscriptPath);
                            lastReadPosition = Math.Max(0, fileInfo.Length - 8192); // Read last ~8KB on initial attach
                        }

                        if (File.Exists(currentTranscriptPath))
                        {
                            using var fs = new FileStream(currentTranscriptPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                            if (fs.Length > lastReadPosition)
                            {
                                fs.Seek(lastReadPosition, SeekOrigin.Begin);
                                using var reader = new StreamReader(fs);

                                string? line;
                                while ((line = await reader.ReadLineAsync()) != null)
                                {
                                    if (!string.IsNullOrWhiteSpace(line))
                                    {
                                        var appEvent = new AppEvent
                                        {
                                            Type = "agent_activity",
                                            SessionId = Path.GetFileName(Path.GetDirectoryName(Path.GetDirectoryName(currentTranscriptPath))) ?? "antigravity",
                                            Timestamp = DateTime.UtcNow,
                                            Payload = line
                                        };

                                        await _eventCallback(appEvent);
                                    }
                                }

                                lastReadPosition = fs.Position;
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[AntigravityTranscriptWatcher] Error: {ex.Message}");
                }

                await Task.Delay(500, ct);
            }
        }

        private string? FindActiveTranscriptPath()
        {
            if (!Directory.Exists(_brainRoot)) return null;

            try
            {
                var dirInfo = new DirectoryInfo(_brainRoot);
                var latestConvDir = dirInfo.GetDirectories()
                    .Where(d => d.Name != "tempmediaStorage")
                    .OrderByDescending(d => d.LastWriteTimeUtc)
                    .FirstOrDefault();

                if (latestConvDir != null)
                {
                    string candidate = Path.Combine(latestConvDir.FullName, ".system_generated", "logs", "transcript.jsonl");
                    if (File.Exists(candidate))
                    {
                        return candidate;
                    }
                }
            }
            catch
            {
                // Directory read error
            }

            return null;
        }
    }
}
