---
phase: 2
title: Cross-Platform Expansion
status: pending
---

# Phase 2: Cross-Platform Expansion

## Goal
Reach the primary demographic of early AI dev-tool adopters (macOS/Linux) by decoupling the daemon from Windows-specific APIs and standardizing the Model Context Protocol (MCP) hook interface.

## Context
Currently, `LocalLoop.Service` relies on Windows-specific technologies:
- `System.Security.Cryptography.ProtectedData` (DPAPI) for the Ed25519 Secret Store.
- Hardcoded IPC mechanisms that may not be robustly cross-platform without interface abstraction.
- Tight coupling with `LocalLoop.Bridge` which utilizes `FlaUI` (Windows UI Automation).

## Execution Waves

### Wave 1: Secret Store Abstraction (Cross-Platform Crypto)
1. **Abstract `PairingManager` DPAPI Dependency**:
   - Define an `ISecretStore` interface in `LocalLoop.Core/Security/ISecretStore.cs` with `Protect(byte[])` and `Unprotect(byte[])` methods.
   - Implement `WindowsDpapiSecretStore.cs` using the existing `System.Security.Cryptography.ProtectedData` logic.
   - Implement `CrossPlatformFileSecretStore.cs` as a fallback using standard AES-256 (or simply storing keys with strict file permissions on macOS/Linux `chmod 600`).
2. **Dependency Injection**:
   - Refactor `PairingManager.cs` to depend on `ISecretStore` rather than directly calling `ProtectedData`.
   - Update `Program.cs` in `LocalLoop.Service` to register the correct `ISecretStore` based on `RuntimeInformation.IsOSPlatform(OSPlatform.Windows)`.

### Wave 2: Standardize MCP / Hook Interface Format
1. **Define `IMcpHookAdapter`**:
   - Create a clean adapter interface in `LocalLoop.Core/Adapters/IMcpHookAdapter.cs` that any local AI agent can hook into via standard JSON-RPC or REST over localhost.
2. **Remove Hardcoded UI Automation Hooks from Service**:
   - Ensure `LocalLoop.Service` contains ZERO references to `FlaUI` or Windows desktop APIs. All UI automation must strictly remain inside `LocalLoop.Bridge`.
   - The Service should only accept inputs via the MCP interface, WebSockets, or Named Pipes (which map to Unix Domain Sockets automatically in .NET 8).

### Wave 3: Cross-Compilation Build Targets
1. **Update `LocalLoop.Service.csproj`**:
   - Ensure the project can be published for `osx-arm64`, `osx-x64`, `linux-x64`, and `linux-arm64`.
2. **Test IPC Pipe Names**:
   - Ensure the Named Pipe name `LocalLoop_ControlPipe` doesn't violate macOS/Linux socket naming conventions. (On *nix, .NET creates a file in `/tmp/` using the pipe name. We must ensure there are no illegal characters).

## Verification criteria
- `LocalLoop.Service` compiles successfully on `linux-x64` (`dotnet build -r linux-x64`).
- `ISecretStore` successfully abstracts DPAPI for Windows and provides a *nix fallback.
- xUnit tests pass for the new `ISecretStore` implementations.
