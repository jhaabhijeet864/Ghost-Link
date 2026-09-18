# LocalLoop Requirements

## v1 Requirements

### Windows Orchestration & Desktop Bridge
- [ ] **WIN-01**: LocalLoop Service (Background) handles networking, storage (SQLite event store), process monitoring, and policy checks.
- [ ] **WIN-02**: LocalLoop Desktop Bridge (Foreground) runs inside the interactive Windows user session and handles UI automation.
- [ ] **WIN-03**: Secure IPC via Named pipes connects the Service to the Desktop Bridge.

### Mobile App (Flutter)
- [ ] **MOB-01**: Domain-driven Flutter application architecture (core, domain, data, features).
- [ ] **MOB-02**: **Observe Mode**: Read logs, diffs, agent messages, plans, and active workspace state.
- [ ] **MOB-03**: **Control Mode**: Send follow-up instructions, approve/reject actions, pause/cancel tasks.
- [ ] **MOB-04**: **Command Composer**: Process text/voice input into structured intents with constraints and risk classification.
- [ ] **MOB-05**: Rebuild application state from an append-only event stream (offline-first state cache).

### Connectivity & Security
- [ ] **NET-01**: Support Local network mode and Private-network mode (overlay network).
- [ ] **SEC-01**: Secure pairing and device identity mechanism.
- [ ] **SEC-02**: Policy & Approval Engine: Enforce predefined rules (e.g. `Read logs` = Allow, `Delete files` = Always ask).
- [ ] **SEC-03**: Immutable audit record tracking all events and approvals.

### Adapters & Automation
- [ ] **ADAPT-01**: Capability-based adapter framework to discover what each target application supports.
- [ ] **ADAPT-02**: Level 2 integration: Process and terminal control (start process, capture stdout/stderr, send stdin).
- [ ] **ADAPT-03**: Level 3 integration: Microsoft UI Automation (via FlaUI wrapper in .NET) for semantic window control.
- [ ] **ADAPT-04**: Screenshots used strictly on-demand as evidence/fallback, not as primary visual transport.

## v2 Requirements (Deferred)
- External Relay connectivity mode.
- Push notifications via native mobile platform integration.
- Voice-only, hands-free workflows.
- Visual automation image matching (Level 6).

## Out of Scope
- Full remote desktop streaming (VNC-style).
- WinAppDriver integration.
- Broad "allow all commands" switches without policy enforcement.

## Traceability
(To be updated during roadmap generation)
