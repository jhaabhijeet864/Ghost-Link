# Phase 1, Plan 2: Desktop Bridge & Named Pipes IPC

## Overview
Establish the secure communication bridge between the foreground Desktop Bridge and the background LocalLoop Service using Named Pipes.

## Tasks
- [ ] **1. Bridge Initialization**
  - Create a new C# .NET 8 Console App: `dotnet new console -n LocalLoop.Bridge`.
  - Add `LocalLoop.Core` as a reference to `LocalLoop.Bridge`.
  - Add the `LocalLoop.Bridge` project to the solution.

- [ ] **2. Shared IPC Protocol Models**
  - In `LocalLoop.Core`, define simple message structures for serialization (e.g., `IpcMessage` containing a `Type` and `Data`).
  - Use `System.Text.Json` for serialization.

- [ ] **3. Named Pipe Server (in LocalLoop.Service)**
  - Implement `NamedPipeServerService` inside the Worker Service.
  - Use `NamedPipeServerStream` bound to `LocalLoop_ControlPipe`.
  - Accept connections and read/write JSON strings asynchronously.
  - When a client connects, append a `session_created` event to the `EventRepository`.

- [ ] **4. Named Pipe Client (in LocalLoop.Bridge)**
  - Implement a `NamedPipeClientStream` targeting `LocalLoop_ControlPipe`.
  - Connect to the server on startup and send a simple handshake message.
  - Listen for messages in an asynchronous loop and log them to the console.

## Requirements Covered
- **WIN-02**: Desktop Bridge runs inside interactive session.
- **WIN-03**: Secure IPC via Named pipes connects Service and Bridge.

## Testing
- Run `LocalLoop.Service` via `dotnet run`.
- Run `LocalLoop.Bridge` via `dotnet run`.
- Ensure the Service logs the connection and inserts a `session_created` event into the SQLite DB.
- Ensure the Bridge can send a handshake and receive an acknowledgment.
