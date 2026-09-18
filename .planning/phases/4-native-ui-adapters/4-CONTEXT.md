# Phase 4 Context: Native & UI Automation Adapters

## Domain
Hook the system up to real developer tools using adapters (Process control, FlaUI, screenshots).

## Decisions

### Adapter Framework Design (ADAPT-01)
- **Interface + Registry pattern**: Define an `IAdapter` interface with a `Supports(Capability)` method. A central factory inside the Bridge dynamically resolves the best adapter for the target application.

### Process Control (ADAPT-02)
- **Buffered Output**: When capturing async stdout/stderr, buffer the output in the Desktop Bridge and send it in chunks over IPC to avoid flooding the SQLite database with thousands of tiny events.

### FlaUI Integration (ADAPT-03)
- **UIA3 with UIA2 Fallback**: Default to the UIA3 backend for modern apps, but provide a graceful fallback to UIA2 if the element isn't found. Target apps primarily by Process Name + Main Window Title.

### Screenshot Fallback (ADAPT-04)
- **GDI+**: Use `System.Drawing.Common` (`Graphics.CopyFromScreen`) to capture the screen or specific window rect. Compress to JPEG and encode to Base64 for transport over IPC.

## Code Context
- Target Project: `LocalLoop.Bridge`
- Related Core Models: `LocalLoop.Core.AppEvent`, `LocalLoop.Core.IpcMessage`
