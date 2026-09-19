using System.IO;
using System.Text.Json;
using LocalLoop.Core;

namespace LocalLoop.Service.Audit
{
    public interface IAuditLogger
    {
        Task LogAsync(AuditRecord record);
        Task<IReadOnlyList<AuditRecord>> GetRecentAsync(int count = 100);
        Task<IReadOnlyList<AuditRecord>> GetByIntentIdAsync(string intentId);
    }

    public class AuditLogger : IAuditLogger
    {
        private readonly string _auditFilePath;
        private readonly SemaphoreSlim _fileLock = new(1, 1);

        public AuditLogger(string? basePath = null)
        {
            var path = basePath ?? Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "audit");
            Directory.CreateDirectory(path);
            _auditFilePath = Path.Combine(path, "audit.log.jsonl");
        }

        public async Task LogAsync(AuditRecord record)
        {
            if (record == null) return;

            var json = JsonSerializer.Serialize(record);
            
            await _fileLock.WaitAsync();
            try
            {
                await File.AppendAllTextAsync(_auditFilePath, json + Environment.NewLine);
            }
            finally
            {
                _fileLock.Release();
            }
        }

        public async Task<IReadOnlyList<AuditRecord>> GetRecentAsync(int count = 100)
        {
            if (!File.Exists(_auditFilePath))
                return Array.Empty<AuditRecord>();

            var lines = await File.ReadAllLinesAsync(_auditFilePath);
            var records = new List<AuditRecord>();

            foreach (var line in lines.Reverse().Take(count))
            {
                if (string.IsNullOrWhiteSpace(line)) continue;
                
                try
                {
                    var record = JsonSerializer.Deserialize<AuditRecord>(line);
                    if (record != null)
                        records.Add(record);
                }
                catch
                {
                    // Skip malformed lines
                }
            }

            return records;
        }

        public async Task<IReadOnlyList<AuditRecord>> GetByIntentIdAsync(string intentId)
        {
            if (!File.Exists(_auditFilePath))
                return Array.Empty<AuditRecord>();

            var lines = await File.ReadAllLinesAsync(_auditFilePath);
            var records = new List<AuditRecord>();

            foreach (var line in lines)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;
                
                try
                {
                    var record = JsonSerializer.Deserialize<AuditRecord>(line);
                    if (record != null && record.IntentId == intentId)
                        records.Add(record);
                }
                catch
                {
                    // Skip malformed lines
                }
            }

            return records;
        }
    }
}