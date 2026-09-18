using System;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using LocalLoop.Service;
using LocalLoop.Core;

namespace LocalLoop.Tests
{
    public class EventRepositoryTests
    {
        [Fact]
        public async Task AppendAndRetrieveEvents_WorksCorrectly()
        {
            // Arrange - use a unique in-memory db for this test
            var dbPath = $"file:{Guid.NewGuid()}?mode=memory&cache=shared";
            var repo = new EventRepository(dbPath);
            
            var sessionId = Guid.NewGuid().ToString();
            var evt1 = new AppEvent { SessionId = sessionId, Type = "test_1", Payload = "{}" };
            var evt2 = new AppEvent { SessionId = sessionId, Type = "test_2", Payload = "{}" };
            
            // Act
            await repo.AppendEventAsync(evt1);
            await repo.AppendEventAsync(evt2);
            
            var retrieved = (await repo.GetEventsBySessionAsync(sessionId)).ToList();
            
            // Assert
            Assert.Equal(2, retrieved.Count);
            Assert.Equal("test_1", retrieved[0].Type);
            Assert.Equal("test_2", retrieved[1].Type);
        }
    }
}
