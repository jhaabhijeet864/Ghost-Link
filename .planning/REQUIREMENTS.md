# LocalLoop Requirements

## v1 Requirements

### Architecture & Setup
- [ ] **ARCH-01**: Windows companion agent registers a local device identity.
- [ ] **ARCH-02**: Secure pairing between phone and Windows agent via short-lived QR code or one-time code.
- [ ] **ARCH-03**: Maintain named workspaces on the host.

### Monitoring & Control
- [ ] **MON-01**: Mobile client displays one active task, current phase, and recent logs.
- [ ] **MON-02**: Mobile client displays git branch, changed files, and test results.
- [ ] **MON-03**: Mobile client can pause, cancel, and retry the active task.

### Communication & Execution
- [ ] **EXEC-01**: Mobile client can send text follow-up commands to the Windows agent.
- [ ] **EXEC-02**: Explicit approval mechanism for high-risk or destructive actions.
- [ ] **EXEC-03**: Immutable audit log of every action executed.

### Adapters
- [ ] **ADAPT-01**: Implement a mock or local CLI adapter to prove the event model.
- [ ] **ADAPT-02**: Implement one real adapter (e.g., local CLI process or terminal agent).

## v2 Requirements (Deferred)
- Voice transcription and risk classification.
- Support for multiple active tasks.
- Push notifications.
- Universal IDE adapters.
- Read-only mode.

## Out of Scope
- Full remote desktop streaming — Unreliable and brittle.
- Cloud code storage — Defeats the local-first security premise.
- Team collaboration & billing — Focus on single-user developer experience for MVP.

## Traceability
(To be updated during roadmap generation)
