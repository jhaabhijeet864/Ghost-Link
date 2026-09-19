# LocalLoop Requirements

## Milestone v1.0 Requirements (Complete)
- [x] **WIN-01**: LocalLoop Service (Background) handles networking, storage (SQLite event store), process monitoring, and policy checks.
- [x] **WIN-02**: LocalLoop Desktop Bridge (Foreground) runs inside the interactive Windows user session and handles UI automation.
- [x] **WIN-03**: Secure IPC via Named pipes connects the Service to the Desktop Bridge.
- [x] **MOB-01**: Domain-driven Flutter application architecture (core, domain, data, features).
- [x] **MOB-02**: **Observe Mode**: Read logs, diffs, agent messages, plans, and active workspace state.
- [x] **MOB-03**: **Control Mode**: Send follow-up instructions, approve/reject actions, pause/cancel tasks.
- [x] **MOB-04**: **Command Composer**: Process text/voice input into structured intents with constraints and risk classification.
- [x] **MOB-05**: Rebuild application state from an append-only event stream (offline-first state cache).
- [x] **NET-01**: Support Local network mode (LAN/mDNS auto-discovery and direct pairing).
- [x] **SEC-01**: Secure pairing and Ed25519 challenge-response identity mechanism.
- [x] **SEC-02**: Policy & Approval Engine: Enforce predefined rules (e.g. `Read logs` = Allow, `Delete files` = Always ask).
- [x] **SEC-03**: Immutable audit record tracking all events and approvals.
- [x] **ADAPT-01**: Capability-based adapter framework to discover what each target application supports.
- [x] **ADAPT-02**: Level 2 integration: Process and terminal control (start process, capture stdout/stderr, send stdin).
- [x] **ADAPT-03**: Level 3 integration: Microsoft UI Automation (via FlaUI wrapper in .NET) for semantic window control.
- [x] **ADAPT-04**: Screenshots used strictly on-demand as evidence/fallback, not as primary visual transport.

---

## Milestone v1.1 Requirements: Mobile Companion Experience & UI Architecture

### 1. Navigation Shell & Workspaces Dashboard
- [ ] **UI-01**: **5-Destination Navigation Shell**: Persistent bottom navigation bar containing `Workspaces`, `Observe`, `Command`, `Approvals`, and `Settings`.
- [ ] **UI-02**: **Active Workstation Dashboard**: Visual card displaying active workstation name, IDE/project status, connection status badge (Green online, Amber reconnecting, Red offline), and network latency.
- [ ] **UI-03**: **Multi-Device Switcher**: Interface to manage, rename, disconnect, and switch between multiple saved Windows desktop hosts.
- [ ] **UI-04**: **Manual Connection Modal**: Dark dialog with validated inputs for IP address, Port, and Pairing Secret, with quick localhost pre-fill.

### 2. Observe Mode Enhancements
- [ ] **UI-05**: **Telemetry Filter Chips**: Filter chips (`All`, `Agent Logs`, `Diffs`, `Terminal Output`, `Errors`) for instant narrowing of event stream items.
- [ ] **UI-06**: **Code Diff Viewer Widget**: Dedicated visual component displaying file changes with colored additions/deletions, line numbers, and file paths.
- [ ] **UI-07**: **On-Demand Screenshot Previewer**: Interactive card allowing the user to trigger a fresh workstation screenshot and view it in a full-screen zoomable modal.

### 3. Command & Approval Polish
- [ ] **UI-08**: **Voice Input Waveform Visualizer**: Visual feedback during voice dictation with simulated sound wave pulses and transcript editing.
- [ ] **UI-09**: **Rich Approval Request Detail Sheet**: Bottom modal showing full command parameters, affected file badges, security rationale, and a 2-minute countdown timer with signed Ed25519 one-tap approval.

### 4. Settings & Cryptographic Security
- [ ] **UI-10**: **Device Identity Inspector**: Displays Ed25519 public key fingerprint, device ID, connection security level, and active pairing token status.
- [ ] **UI-11**: **Security Policy Viewer**: Lists active risk policies (Auto-allowed vs. Confirmation Required vs. Blocked actions).
- [ ] **UI-12**: **Pairing Revocation**: Safe reset button to revoke host authorization, wipe stored cryptographic keys, and return to pairing screen.

---

## Out of Scope
- Full remote desktop streaming (VNC/RDP-style).
- Cloud relay servers (focus remains strictly local-first / LAN).
- Third-party analytics or telemetry tracking.
