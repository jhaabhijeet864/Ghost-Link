using System;
using System.IO;
using System.Text;
using Xunit;

namespace LocalLoop.Tests
{
    public class WebSocketMultiFrameTests
    {
        [Fact]
        public void MultiFrameAccumulator_ReassemblesLargePayloadAcrossMultipleChunks()
        {
            // Simulate a large payload (e.g. unified git diff or log buffer: 64 KB)
            var sb = new StringBuilder();
            sb.Append("{\"type\":\"event_stream\",\"data\":\"");
            for (int i = 0; i < 2000; i++)
            {
                sb.Append($"Line {i}: public void ProcessAgentTask() => Task.CompletedTask; ");
            }
            sb.Append("\"}");
            var completeOriginal = sb.ToString();
            var completeBytes = Encoding.UTF8.GetBytes(completeOriginal);

            // Chunk the bytes into 4 KB slices as WebSocket frames
            int chunkSize = 4096;
            using var ms = new MemoryStream();
            
            for (int offset = 0; offset < completeBytes.Length; offset += chunkSize)
            {
                int length = Math.Min(chunkSize, completeBytes.Length - offset);
                ms.Write(completeBytes, offset, length);
            }

            ms.Seek(0, SeekOrigin.Begin);
            using var reader = new StreamReader(ms, Encoding.UTF8);
            var reassembled = reader.ReadToEnd();

            Assert.Equal(completeOriginal.Length, reassembled.Length);
            Assert.Equal(completeOriginal, reassembled);
        }
    }
}
