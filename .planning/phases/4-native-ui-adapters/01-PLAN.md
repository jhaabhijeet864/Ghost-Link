# Phase 4, Wave 1: Adapter Core & Process Control

## Goal
Set up the capability discovery framework and the lowest-level native adapter (Process Control).

## Implementation Steps

### 1. Define Automation Level Enum
**Target:** `src/LocalLoop.Bridge/Adapters/AutomationLevel.cs`
**Action:** Create an enum `AutomationLevel` with values:
- `Level1_Native`
- `Level2_Process`
- `Level3_UIAutomation`
- `Level6_Screenshot`

### 2. Define Adapter Interface
**Target:** `src/LocalLoop.Bridge/Adapters/IAdapter.cs`
**Action:** Create the `IAdapter` interface with:
- `bool Supports(AutomationLevel level)`
- `Task ExecuteAsync(CommandIntent intent)`

### 3. Create Adapter Registry / Factory
**Target:** `src/LocalLoop.Bridge/Adapters/AdapterFactory.cs`
**Action:** Implement a factory that takes an app name/target and returns the best available `IAdapter` based on known capabilities.

### 4. Implement Process Adapter
**Target:** `src/LocalLoop.Bridge/Adapters/ProcessAdapter.cs`
**Action:** Implement `IAdapter` for `Level2_Process`. 
- Use `System.Diagnostics.Process` to start commands.
- Asynchronously read `StandardOutput` and `StandardError`.
- Buffer lines into chunks and send via IPC using `IpcMessage` to avoid flooding the event store.
