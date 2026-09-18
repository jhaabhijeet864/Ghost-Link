# Phase 4 Discussion Log

## Discussion Areas

### Area 1: Adapter Framework Design (Capability discovery and interface structure)
**Options Presented:**
- (Recommended) Interface + Registry pattern: Define `IAdapter` with a `Supports(Capability)` method. A central factory dynamically resolves the best adapter based on the target.
- Simple capability flags: Adapters just expose a `SupportedLevels` enum, and the orchestrator manually loops through them.
- Hardcoded routing: Don't overcomplicate. Hardcode the logic for "If it's a console app -> ProcessAdapter, if it's a GUI -> FlaUiAdapter".

**User Selection:** Interface + Registry pattern

---

### Area 2: Process Control (Capturing async stdout/stderr and linking to event store)
**Options Presented:**
- (Recommended) Buffer output in the Desktop Bridge and send it in chunks via IPC to avoid flooding the SQLite database with thousands of tiny events.
- Stream output as continuous events (`process_output`) directly to the event store via IPC in real-time as soon as data is available.
- Pipe output to a physical file on disk and just store the file reference in the event store (cheapest on DB size, harder to sync to mobile).

**User Selection:** Buffer output in the Desktop Bridge and send it in chunks via IPC

---

### Area 3: FlaUI Integration (UIA2 vs UIA3, window targeting strategies)
**Options Presented:**
- (Recommended) Default to UIA3 for modern apps, but provide a graceful fallback to UIA2 if the element isn't found. Target apps primarily by Process Name + Main Window Title.
- Force UIA3 only. Target apps by Process ID to ensure strict 1:1 mapping, even if it breaks across restarts.
- Force UIA2 only (best for legacy Win32, worst for modern apps). Target by Window Handle (HWND).

**User Selection:** Default to UIA3 for modern apps, but provide a graceful fallback to UIA2

---

### Area 4: Screenshot Fallback (Implementation strategy for capturing screen state on demand)
**Options Presented:**
- (Recommended) System.Drawing.Common (GDI+) - Capture the screen or specific window rect using standard Graphics.CopyFromScreen. It's simple, reliable, and easily encodes to Base64/JPEG for transport over IPC.
- Windows Graphics Capture API (WinRT) - Higher performance and captures hardware overlays, but adds significant interop complexity and OS version requirements.

**User Selection:** System.Drawing.Common (GDI+)
