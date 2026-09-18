# Phase 1, Plan 1: LocalLoop Service & Event Store

## Overview
Initialize the background service responsible for maintaining the SQLite append-only event store and managing the global state.

## Tasks
- [ ] **1. Project Initialization**
  - Create a new C# .NET 8 Worker Service project: `dotnet new worker -n LocalLoop.Service`.
  - Create a shared class library: `dotnet new classlib -n LocalLoop.Core`.
  - Add `LocalLoop.Core` as a reference to `LocalLoop.Service`.
  - Add the solution file and link the projects.

- [ ] **2. Dependency Setup**
  - In `LocalLoop.Service`, install NuGet packages: `Microsoft.Data.Sqlite` and `Dapper`.

- [ ] **3. Event Model & Database Schema**
  - In `LocalLoop.Core`, define the `AppEvent` record: `Id` (string/guid), `SessionId` (string), `Type` (string), `Timestamp` (DateTime), `Payload` (JSON string).
  - In `LocalLoop.Service`, create an `EventRepository` class.
  - Implement a database initialization method that runs on startup to create the `Events` table if it does not exist.

- [ ] **4. Repository Methods**
  - Implement `AppendEventAsync(AppEvent evt)` using Dapper to insert the event into SQLite.
  - Implement `GetEventsBySessionAsync(string sessionId)` using Dapper.

## Requirements Covered
- **WIN-01**: LocalLoop Service handles storage (SQLite event store).

## Testing
- Verify manually by starting the service and checking that the SQLite database file (`localloop.db`) is created locally.
