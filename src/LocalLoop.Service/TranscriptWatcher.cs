using System;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace LocalLoop.Service
{
    public class TranscriptWatcher : IDisposable
    {
        private readonly string _brainDir;
        private string? _currentTranscriptPath;
        private FileSystemWatcher? _watcher;
        private long _lastPosition = 0;
        private readonly Action<string> _onNewActivity;

        public TranscriptWatcher(Action<string> onNewActivity)
        {
            _onNewActivity = onNewActivity;
            var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            _brainDir = Path.Combine(userProfile, ".gemini", "antigravity-ide", "brain");
        }

        public void Start()
        {
            if (!Directory.Exists(_brainDir)) return;

            // Find latest modified conversation directory
            var latestDir = new DirectoryInfo(_brainDir)
                .GetDirectories()
                .OrderByDescending(d => d.LastWriteTimeUtc)
                .FirstOrDefault();

            if (latestDir != null)
            {
                var transcriptPath = Path.Combine(latestDir.FullName, ".system_generated", "logs", "transcript.jsonl");
                if (File.Exists(transcriptPath))
                {
                    WatchFile(transcriptPath);
                }
            }
        }

        private void WatchFile(string filePath)
        {
            _currentTranscriptPath = filePath;
            
            using (var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            {
                _lastPosition = 0; 
                ReadNewLines();
            }

            var dir = Path.GetDirectoryName(filePath);
            if (dir == null) return;

            _watcher = new FileSystemWatcher(dir, Path.GetFileName(filePath))
            {
                NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size,
                EnableRaisingEvents = true
            };

            _watcher.Changed += (s, e) => ReadNewLines();
        }

        private void ReadNewLines()
        {
            if (_currentTranscriptPath == null || !File.Exists(_currentTranscriptPath)) return;

            try
            {
                using var fs = new FileStream(_currentTranscriptPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                if (fs.Length < _lastPosition)
                {
                    // File was truncated or recreated
                    _lastPosition = 0;
                }

                fs.Position = _lastPosition;
                using var reader = new StreamReader(fs);
                
                string? line;
                while ((line = reader.ReadLine()) != null)
                {
                    if (!string.IsNullOrWhiteSpace(line))
                    {
                        _onNewActivity(line);
                    }
                }
                
                _lastPosition = fs.Position;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[TranscriptWatcher] Error reading file: {ex.Message}");
            }
        }

        public void Dispose()
        {
            _watcher?.Dispose();
        }
    }
}
