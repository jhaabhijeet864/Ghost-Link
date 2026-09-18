using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Data.Sqlite;
using Dapper;
using LocalLoop.Core;

namespace LocalLoop.Service
{
    public class EventRepository
    {
        private readonly string _connectionString;

        public EventRepository(string dbPath = "localloop.db")
        {
            _connectionString = $"Data Source={dbPath}";
            InitializeDatabase();
        }

        private void InitializeDatabase()
        {
            using var connection = new SqliteConnection(_connectionString);
            connection.Open();
            
            var tableCmd = connection.CreateCommand();
            tableCmd.CommandText = @"
                CREATE TABLE IF NOT EXISTS Events (
                    Id TEXT PRIMARY KEY,
                    SessionId TEXT NOT NULL,
                    Type TEXT NOT NULL,
                    Timestamp TEXT NOT NULL,
                    Payload TEXT NOT NULL
                )";
            tableCmd.ExecuteNonQuery();
        }

        public async Task AppendEventAsync(AppEvent evt)
        {
            using var connection = new SqliteConnection(_connectionString);
            await connection.OpenAsync();
            
            var query = @"
                INSERT INTO Events (Id, SessionId, Type, Timestamp, Payload)
                VALUES (@Id, @SessionId, @Type, @Timestamp, @Payload)";
                
            await connection.ExecuteAsync(query, evt);
        }

        public async Task<IEnumerable<AppEvent>> GetEventsBySessionAsync(string sessionId)
        {
            using var connection = new SqliteConnection(_connectionString);
            await connection.OpenAsync();
            
            var query = "SELECT * FROM Events WHERE SessionId = @SessionId ORDER BY Timestamp ASC";
            return await connection.QueryAsync<AppEvent>(query, new { SessionId = sessionId });
        }
    }
}
