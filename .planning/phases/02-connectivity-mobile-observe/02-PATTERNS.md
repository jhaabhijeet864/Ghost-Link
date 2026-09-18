# Phase 2: Pattern Mapping

## Backend (C# / Windows)

### 1. `src/LocalLoop.Bridge/PairingWindow.cs` (New)
**Role:** Renders the QR code natively and handles the "Allow pairing?" confirmation prompt (D-07). Also manages active device lists and revoke options (D-08).
**Data Flow:** Receives the pairing token from the Service via IPC, generates a QR code embedding the token and IP, displays the UI, and sends the user's confirmation back to the Service.
**Closest Analog:** `src/LocalLoop.Bridge/Program.cs` (Handles IPC messaging to the Service).
**Concrete Excerpt (`src/LocalLoop.Bridge/Program.cs`):**
```csharp
using var pipeClient = new NamedPipeClientStream(".", PipeName, PipeDirection.InOut, PipeOptions.Asynchronous);
await pipeClient.ConnectAsync();
var handshake = new IpcMessage { Type = "handshake", Data = "Bridge online" };
await writer.WriteLineAsync(JsonSerializer.Serialize(handshake));
```

### 2. `src/LocalLoop.Service/WebSocketServer.cs` (New)
**Role:** Manages secure WebSocket connections for event streaming (D-11).
**Data Flow:** Listens for connections, validates Ed25519 signatures from connection headers (D-14), syncs events from the provided Flutter offset (D-13), and streams new `AppEvent` payloads as JSON.
**Closest Analog:** `src/LocalLoop.Service/Worker.cs` (Background task currently acting as the server for the named pipe connection).
**Concrete Excerpt (`src/LocalLoop.Service/Worker.cs`):**
```csharp
await using var pipeServer = new NamedPipeServerStream(PipeName, PipeDirection.InOut, 1, PipeTransmissionMode.Message, PipeOptions.Asynchronous);
_logger.LogInformation("Waiting for Desktop Bridge connection on pipe '{PipeName}'...", PipeName);
await pipeServer.WaitForConnectionAsync(stoppingToken);
```

### 3. `src/LocalLoop.Service/PairingManager.cs` (New)
**Role:** Manages 1:1 paired device keys and authentication logic (D-06).
**Data Flow:** Generates ephemeral tokens, validates pairing requests, stores the paired Flutter app's Ed25519 public key, and revokes old keys.
**Closest Analog:** `src/LocalLoop.Service/EventRepository.cs` (Handles database storage operations).
**Concrete Excerpt (`src/LocalLoop.Service/EventRepository.cs`):**
```csharp
public async Task AppendEventAsync(AppEvent evt)
{
    using var connection = new SqliteConnection(_connectionString);
    await connection.OpenAsync();
    
    var query = @"
        INSERT INTO Events (Id, SessionId, Type, Timestamp, Payload)
        VALUES (@Id, @SessionId, @Type, @Timestamp, @Payload)";
        
    await connection.ExecuteAsync(query, evt);
}
```

### 4. `src/LocalLoop.Tests/WebSocketIntegrationTests.cs` (New)
**Role:** Test suite to validate WebSocket streaming, connection drops, and offset syncing.
**Data Flow:** Acts as a mock client to connect to `WebSocketServer`, sends mock signatures, and verifies the JSON event stream synchronization.
**Closest Analog:** `src/LocalLoop.Tests/IpcIntegrationTests.cs` (Tests server/client communication streams).
**Concrete Excerpt (`src/LocalLoop.Tests/IpcIntegrationTests.cs`):**
```csharp
[Fact]
public async Task NamedPipe_ServerAndClient_CanCommunicate()
{
    var pipeName = $"LocalLoop_TestPipe_{Guid.NewGuid()}";
    
    // Arrange Server
    var serverTask = Task.Run(async () => { /* server setup */ });
    
    // Arrange Client
    var clientTask = Task.Run(async () => { /* client setup */ });
    
    // Act & Assert
    await Task.WhenAll(serverTask, clientTask);
    Assert.True(messageReceived);
}
```

## Mobile (Flutter / Dart)

*Note: As per CONTEXT.md, the mobile app is a greenfield initialization, meaning there are no existing reusable assets or direct analogs in the codebase. The following structure implements the Domain-Driven Design layout defined in RESEARCH.md.*

### 5. `mobile/lib/main.dart` & `mobile/lib/core/router/app_router.dart` (New)
**Role:** App entry point, Riverpod provider scope initialization, routing, and deep link handler.
**Data Flow:** Initializes `flutter_riverpod`, listens to `localloop://pair?...` incoming URIs (via `app_links` or `uni_links`), and routes the user seamlessly to the pairing screen.
**Closest Analog:** None (Greenfield).

### 6. `mobile/lib/core/security/crypto_manager.dart` (New)
**Role:** Handles Ed25519 cryptography and key persistence (D-04).
**Data Flow:** Generates a keypair on the first run using the Dart `cryptography` package, securely stores the private key in `flutter_secure_storage`, and signs WebSocket authentication payloads.
**Closest Analog:** None (Greenfield).

### 7. `mobile/lib/core/network/websocket_client.dart` (New)
**Role:** Manages the persistent WebSocket connection (D-11).
**Data Flow:** Connects to the local Windows service IP/port embedded in the QR code, provides the Ed25519 signature in headers, and streams incoming JSON events directly to the local SQLite database. Implements "Sync from Offset" logic upon reconnection (D-13) and mDNS fallback for IP rediscovery (D-05).
**Closest Analog:** None (Greenfield).

### 8. `mobile/lib/data/database/app_database.dart` (New)
**Role:** Offline-first local state persistence (D-16).
**Data Flow:** Uses `sqflite` (or `drift`) to append events pushed from the WebSocket. Acts as the single source of truth for the UI state.
**Closest Analog:** None (Greenfield, though conceptually analogous to the backend `EventRepository.cs`).

### 9. `mobile/lib/features/observe/presentation/observe_screen.dart` (New)
**Role:** The main Observe Mode UI (MOB-02).
**Data Flow:** Listens to `flutter_riverpod` providers (which react to SQLite appends) to display active logs, agent status, and workspaces (D-17). Displays a Global Connection Status Banner managed by a Riverpod `StateNotifier` when disconnected (D-18). Also includes a "Disconnect & Forget Desktop" button (D-09).
**Closest Analog:** None (Greenfield).
