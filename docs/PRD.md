# Product Requirements Document

## Project: LocalLoop

**Working product name:** LocalLoop  
**Previous working names:** Antigravity Link, Antigravity Ghost-Link  
**Product category:** Local-first remote control plane for AI coding agents and development environments  
**Primary client:** Flutter mobile application  
**Primary host:** Windows workstation  
**Document status:** Foundational PRD  
**Date:** September 19, 2026  

---

## 1. Executive Summary

LocalLoop enables developers to supervise and control autonomous coding sessions from a mobile device while the actual code, agents, tools, and execution remain on their own Windows workstation.

The product is not a remote-desktop or laptop-screen-streaming application. It is an application-aware control plane that translates development activity into a mobile-native experience: session status, agent plans, logs, diffs, tests, approvals, commands, notifications, failures, and recovery actions.

LocalLoop should support Antigravity and other AI coding environments through a layered integration strategy:

1. Native application or agent integrations.
2. CLI and terminal process control.
3. MCP, plugin, IPC, or local API integrations.
4. Windows UI Automation.
5. Guarded input injection.
6. On-demand visual evidence as a final fallback.

The product’s central promise is:

> Leave the desk without losing control of your coding agent.

---

## 2. Problem Statement

Modern AI-first development tools can run long, multi-step coding tasks, but developers are often forced to remain physically near the workstation to monitor progress, respond to prompts, approve actions, inspect failures, and provide follow-up instructions.

This creates several problems:

- Long-running agent tasks require desk-bound supervision.
- Developers miss opportunities to continue work while away from the workstation.
- Agent failures, approvals, and interactive prompts may block progress.
- Mobile users cannot easily understand code-generation progress from raw desktop pixels.
- Existing remote-desktop tools expose too much irrelevant UI and provide poor mobile interaction.
- Generic remote terminals do not understand workspaces, agent sessions, diffs, plans, tests, or approvals.
- Remote execution creates substantial security risk if commands are sent without identity, policy, confirmation, and audit controls.

LocalLoop addresses this by exposing structured development context and safe controls through a mobile application while keeping execution local to the developer’s workstation.

---

## 3. Product Vision

Create the trusted mobile command center for local AI-assisted software development.

A developer should be able to:

- Start or monitor a coding-agent session.
- Understand what the agent is doing without viewing the entire desktop.
- Receive alerts when the agent is blocked or needs approval.
- Send context-aware text or voice instructions.
- Review files, diffs, logs, tests, and agent plans.
- Approve, reject, pause, resume, retry, or cancel actions.
- Recover from connection, automation, and process failures.
- Keep source code and execution on their own machine.

---

## 4. Product Principles

### 4.1 Structured development context over pixels

The primary user experience must be semantic and application-aware. Screenshots are evidence and fallback, not the main transport or interface.

### 4.2 Local-first execution

Code, commands, agent processes, and workspace data remain on the user’s Windows machine unless the user explicitly enables a cloud or relay feature.

### 4.3 Native integration before automation

The integration hierarchy is:

1. Native APIs, plugins, MCP, IPC, or local APIs.
2. CLI and process control.
3. Windows UI Automation.
4. Win32 control APIs.
5. Guarded input injection.
6. Visual automation with verification.

### 4.4 Explicit trust

Every action must have a known target, permission scope, risk classification, and observable result.

### 4.5 No false certainty

The system must distinguish confirmed, failed, pending, and uncertain actions. It must never silently retry potentially destructive actions.

### 4.6 Capability-aware interfaces

The mobile UI must show only actions supported by the active adapter, machine state, workspace, and user permissions.

### 4.7 Recoverability

Network interruptions, process crashes, locked screens, application changes, adapter failures, and stale commands are expected operating conditions.

---

## 5. Goals

### 5.1 Primary goals

- Provide a Flutter mobile control center for local coding-agent sessions.
- Provide a secure Windows orchestration agent.
- Provide an interactive Windows desktop bridge for UI-aware integrations.
- Support machine, workspace, session, task, approval, and audit concepts.
- Stream structured events rather than relying on screen streaming.
- Support text and voice follow-up instructions.
- Provide policy-based approvals for risky operations.
- Support multiple adapter types.
- Provide reliable reconnect and offline behavior.
- Make the complete lifecycle understandable from install through recovery.
- Preserve local ownership of source code and execution.

### 5.2 Secondary goals

- Enable optional encrypted relay connectivity.
- Support third-party adapter development.
- Provide diagnostics for pairing, networking, adapters, and UI automation.
- Support notifications for failures, approvals, completion, and security events.
- Provide a trustworthy audit trail.
- Enable future support for additional IDEs, agents, terminals, CI systems, and platforms.

---

## 6. Non-Goals

The following are not the primary product purpose:

- Full remote desktop replacement.
- Continuous laptop-screen streaming.
- General-purpose remote administration.
- Arbitrary unrestricted shell execution.
- Cloud-hosted code workspace.
- Mandatory cloud source-code storage.
- Replacing the user’s IDE.
- Building or hosting a new coding model.
- Autonomous execution without user-configurable controls.
- Universal compatibility with every Windows application.
- Team collaboration as an initial requirement.
- Automatic bypass of UAC, secure desktop, login, or privilege boundaries.

---

## 7. Target Users

### 7.1 Primary user: AI-assisted developer

A developer who uses Antigravity, terminal agents, IDE agents, scripts, or local automation and wants to supervise work away from the desk.

Needs:

- Reliable task visibility.
- Mobile-friendly status and logs.
- Safe follow-up instructions.
- Diff and test inspection.
- Approval control.
- Local privacy.

### 7.2 Secondary user: technical founder or solo builder

A person running long development tasks on a personal workstation who wants to stay productive while traveling, walking, or away from the desk.

Needs:

- Simple setup.
- Clear connection state.
- Notifications.
- Voice input.
- Minimal infrastructure.
- Low operational complexity.

### 7.3 Future user: engineering team

A small team that needs controlled remote supervision, shared policies, audit trails, and role-based access.

This is a future expansion and is not required for the first production release.

---

## 8. Core User Journey

```text
Install Windows companion
        ↓
Install Flutter mobile app
        ↓
Pair phone and workstation
        ↓
Discover machine and workspaces
        ↓
Select workspace and adapter
        ↓
Start or detect coding session
        ↓
Observe structured progress
        ↓
Receive alert or identify issue
        ↓
Compose text or voice instruction
        ↓
Review context and risk
        ↓
Send instruction
        ↓
Approve sensitive actions when requested
        ↓
Verify execution result
        ↓
Inspect files, tests, and diff
        ↓
Pause, retry, continue, commit, or stop
        ↓
Review final summary and audit timeline
```

---

## 9. Product Scope

## 9.1 Flutter mobile application

The mobile application is the primary user interface.

### Required mobile areas

- Home dashboard.
- Machines.
- Workspaces.
- Active sessions.
- Session detail.
- Approval inbox.
- Command composer.
- Voice interaction.
- File and diff inspection.
- Test and build results.
- Timeline and audit history.
- Notifications.
- Security settings.
- Connectivity diagnostics.

### Mobile modes

#### Observe mode

Observe mode allows read-oriented actions:

- View session status.
- Read agent messages.
- Read logs.
- View plans.
- Inspect files and diffs.
- View tests and build results.
- Receive notifications.
- Request a status summary.
- View evidence screenshots.

#### Control mode

Control mode allows approved actions:

- Send follow-up instructions.
- Start a session.
- Pause.
- Resume.
- Cancel.
- Retry.
- Approve.
- Reject.
- Run predefined workflows.
- Create commits where permitted.
- Push where explicitly permitted.

The current mode and permission scope must always be visible.

---

## 9.2 Windows orchestration agent

The Windows orchestration agent coordinates networking, local storage, process observation, workspace management, adapters, policies, and event generation.

### Responsibilities

- Generate and protect machine identity.
- Maintain authenticated connections.
- Discover workspaces.
- Manage sessions and tasks.
- Start and monitor supported processes.
- Collect structured events.
- Track logs and artifacts.
- Evaluate policies.
- Dispatch commands through adapters.
- Persist audit records.
- Handle reconnection and offline queues.
- Communicate with the desktop bridge through local IPC.
- Expose diagnostics.

---

## 9.3 Windows desktop bridge

The desktop bridge runs in the interactive Windows user session and performs operations that require access to the visible desktop.

### Responsibilities

- Discover windows and processes.
- Inspect UI Automation trees.
- Resolve target applications and controls.
- Read supported text.
- Set values and invoke controls.
- Subscribe to UI Automation events.
- Detect dialogs and interactive prompts.
- Verify foreground window and focus.
- Perform guarded input injection when authorized.
- Capture on-demand evidence.
- Detect locked or secure desktop states.
- Report automation confidence.
- Never accept remote connections directly.

The bridge communicates with the orchestration agent through a narrow authenticated local IPC interface.

---

## 9.4 Connectivity and relay layer

The product supports several connectivity modes:

- Local network.
- Private overlay network.
- Optional encrypted relay.

The relay should forward encrypted payloads and minimize access to source code, commands, and workspace content.

### Connection states

- Discovered.
- Pairing.
- Authenticated.
- Connected.
- Degraded.
- Reconnecting.
- Offline.
- Revoked.

---

## 10. Functional Requirements

## 10.1 Installation and onboarding

### FR-001: Windows installation

The system shall provide an installable Windows companion that installs the orchestration agent and desktop bridge.

### FR-002: Mobile installation

The system shall provide Flutter mobile builds for supported Android and iOS versions.

### FR-003: Local identity generation

The Windows companion shall generate a device identity during setup.

### FR-004: Pairing

The system shall support pairing through a short-lived QR code or one-time pairing code.

### FR-005: Pairing verification

The system shall display a verification phrase or equivalent confirmation on both devices before trust is established.

### FR-006: Initial permissions

The system shall begin with observe-only permissions unless the user explicitly enables control permissions.

### FR-007: Setup diagnostics

The system shall provide connection, bridge, firewall, workspace, and adapter diagnostics during onboarding.

---

## 10.2 Machine management

### FR-010: Machine list

The mobile app shall display all paired machines and their connection states.

### FR-011: Machine identity

The app shall display the selected machine name on all control and approval screens.

### FR-012: Machine health

The system shall report agent status, desktop bridge status, Windows session state, connectivity, and relevant health data.

### FR-013: Machine revocation

The user shall be able to revoke a paired phone or machine immediately.

### FR-014: Multiple devices

The system shall support multiple phones or clients per machine with independently configurable permissions.

### FR-015: No silent target switching

The system shall prevent commands from being sent to a different machine without explicit user selection.

---

## 10.3 Workspace management

### FR-020: Workspace discovery

The Windows agent shall discover configured or detected project workspaces.

### FR-021: Workspace selection

The user shall select a workspace before starting or sending a development command.

### FR-022: Workspace identity

The system shall display repository name, path, branch, and adapter before control actions.

### FR-023: Workspace policies

The user shall configure policies at workspace scope.

### FR-024: Workspace health

The system shall report branch, modified files, active sessions, recent errors, and detected conflicts where available.

### FR-025: Workspace isolation

Commands shall be bound to the selected workspace and shall not silently execute in another working directory.

---

## 10.4 Session management

### FR-030: Session discovery

The system shall detect supported active sessions on the Windows machine.

### FR-031: Session creation

The user shall be able to start a new session with an instruction, workspace, adapter, and policy.

### FR-032: Session states

The system shall support at least:

- Created.
- Queued.
- Running.
- Waiting.
- Awaiting approval.
- Paused.
- Blocked.
- Failed.
- Completed.
- Cancelled.
- Unknown.

### FR-033: Session controls

The system shall expose pause, resume, cancel, retry, and continue operations where supported by the adapter.

### FR-034: Session context

The system shall associate sessions with machine, workspace, repository, branch, adapter, user, policy, and event history.

### FR-035: Session summary

The system shall provide a structured summary of prompts, actions, files, tests, errors, approvals, and final outcome.

---

## 10.5 Agent adapters

### FR-040: Adapter discovery

The system shall detect installed or configured adapters.

### FR-041: Capability discovery

Each adapter shall declare supported capabilities.

### FR-042: Adapter lifecycle

The system shall support adapter detection, health checks, session discovery, command dispatch, event collection, and shutdown.

### FR-043: Adapter hierarchy

The system shall prefer native integrations, then process control, then UI Automation, then guarded input, then visual fallback.

### FR-044: Adapter isolation

Adapters shall declare permissions and shall not receive capabilities beyond their configured scope.

### FR-045: Adapter diagnostics

The user shall be able to test an adapter without sending a production or destructive command.

### FR-046: Adapter versioning

The system shall support adapter version and compatibility reporting.

---

## 10.6 Windows UI Automation

### FR-050: Window detection

The desktop bridge shall detect target windows by process, title, class, handle, and adapter criteria.

### FR-051: Semantic control discovery

The bridge shall locate controls by automation ID, name, role, hierarchy, and supported control patterns.

### FR-052: Text extraction

The bridge shall extract supported text and text ranges from target controls.

### FR-053: Control invocation

The bridge shall invoke supported buttons, menus, tabs, list items, and input controls.

### FR-054: UI event monitoring

The bridge shall subscribe to relevant property, window, structure, and state events.

### FR-055: Precondition checks

Before an automated action, the bridge shall verify target process, window, workspace, control availability, session state, and required interaction conditions.

### FR-056: Postcondition verification

After an automated action, the bridge shall verify that the expected result occurred.

### FR-057: Uncertain state

If the system cannot verify an action, it shall report the action as uncertain and shall not automatically retry potentially destructive operations.

### FR-058: Automation evidence

The bridge shall be able to capture structured evidence and an optional cropped screenshot for relevant actions.

### FR-059: Privilege awareness

The bridge shall detect elevated targets, locked sessions, secure desktops, and input restrictions.

### FR-060: UI automation limitations

The product shall communicate when an action is unavailable because of application, privilege, session, or UI limitations.

---

## 10.7 Process and terminal control

### FR-065: Process lifecycle

The Windows agent shall support starting, monitoring, cancelling, and collecting exit status from configured processes.

### FR-066: Output capture

The system shall capture stdout, stderr, exit codes, working directory, and relevant process metadata.

### FR-067: Process hierarchy

The system shall track child processes where possible.

### FR-068: Timeouts

The system shall support command and task timeouts.

### FR-069: Cancellation

The system shall support safe cancellation and report whether cancellation was confirmed.

### FR-070: Interactive prompts

The system shall detect supported terminal prompts and convert them into mobile approval or response requests.

### FR-071: Environment restrictions

The system shall apply workspace, command, network, and file-system restrictions according to policy.

---

## 10.8 Event streaming and state reconstruction

### FR-075: Structured events

The system shall represent development activity as versioned structured events.

### FR-076: Event persistence

Events shall be persisted locally on the Windows machine.

### FR-077: Reconnection

The mobile app shall resume from the last acknowledged event after reconnection.

### FR-078: Event ordering

The protocol shall include sequence numbers and correlation identifiers.

### FR-079: Event deduplication

The mobile app and Windows agent shall handle duplicate event delivery safely.

### FR-080: Event replay

The system shall rebuild session state from persisted events and snapshots.

### FR-081: Offline cache

The mobile app shall display cached state with a clear stale indicator when the machine is unreachable.

---

## 10.9 Command composer

### FR-085: Text commands

The user shall be able to send text instructions to a selected session or workspace.

### FR-086: Voice commands

The user shall be able to record voice instructions and review transcription before sending.

### FR-087: Context attachment

The composer shall support attaching current session, workspace, branch, errors, files, diffs, test failures, and recent agent messages.

### FR-088: Constraint extraction

The system shall detect and display constraints such as “do not commit,” “do not push,” or “do not modify configuration.”

### FR-089: Normalized command preview

The system shall display the interpreted instruction, target, operations, constraints, and risk before dispatch.

### FR-090: Duplicate detection

The system shall warn before sending a command that appears to duplicate a recent command.

### FR-091: Idempotency

Each command shall include an idempotency key.

### FR-092: Command history

The user shall be able to reuse or edit previous commands.

---

## 10.10 Voice interaction

### FR-095: Push-to-talk

The system shall support explicit push-to-talk voice input.

### FR-096: Transcription review

The system shall show the original transcription before execution.

### FR-097: Confidence handling

The system shall flag low-confidence transcription and request correction.

### FR-098: Voice privacy

The system shall provide configurable audio and transcript retention.

### FR-099: Spoken status

The system may provide optional text-to-speech status summaries.

---

## 10.11 Approvals and policies

### FR-105: Risk classification

The system shall classify actions based on command, target, workspace, effects, policy, and adapter metadata.

### FR-106: Approval request

The system shall create an approval request for actions requiring user confirmation.

### FR-107: Exact action display

An approval screen shall display the exact instruction or command, machine, workspace, agent, expected effects, and expiry.

### FR-108: Approval scopes

The system shall support one-time, session-scoped, workspace-scoped, and policy-based approvals.

### FR-109: Expiration

Pending approvals shall expire after a configurable period.

### FR-110: Biometric confirmation

The system shall support biometric confirmation for high-risk approvals where the platform permits.

### FR-111: Rejection

The user shall be able to reject an action and optionally provide an alternative instruction.

### FR-112: Policy simulation

The user shall be able to preview whether a proposed operation would be allowed, blocked, or require approval.

### FR-113: Default policy

The default policy shall be conservative and shall not allow unrestricted destructive or remote execution.

---

## 10.12 Files, diffs, tests, and artifacts

### FR-120: File change tracking

The system shall detect and display created, modified, deleted, and renamed files where supported.

### FR-121: Diff inspection

The user shall be able to inspect file diffs and request an agent explanation.

### FR-122: Test results

The system shall display test commands, status, duration, pass/fail counts, skipped tests, and failure output where available.

### FR-123: Build results

The system shall display build status, compiler errors, warnings, duration, and exit status where available.

### FR-124: Artifact access

The system shall support secure access to relevant logs, reports, patches, and evidence.

### FR-125: Sensitive-file handling

The system shall detect and redact or restrict access to configured sensitive files and secrets.

---

## 10.13 Notifications

### FR-130: Approval notifications

The system shall notify the user when an action requires approval.

### FR-131: Failure notifications

The system shall notify the user of task failures, agent blocks, and critical errors.

### FR-132: Completion notifications

The system shall notify the user when a session completes.

### FR-133: Connection notifications

The system shall notify the user when a configured machine becomes offline or reconnects.

### FR-134: Notification grouping

The system shall group ordinary progress events and avoid notifying on every log line.

### FR-135: Sensitive content

Notifications shall not expose sensitive commands, source code, or secrets by default.

---

## 10.14 Recovery

### FR-140: Connection loss

The system shall distinguish between machine offline, agent unavailable, bridge unavailable, target application unavailable, and event-delivery delay.

### FR-141: Action uncertainty

The system shall preserve uncertain-action state and provide inspection or safe recovery options.

### FR-142: Process failure

The system shall report process crashes, exit codes, and restart availability.

### FR-143: Adapter failure

The system shall report adapter-specific failure and avoid silently switching to a less reliable automation mode.

### FR-144: Locked machine

The system shall preserve read-only monitoring where possible and clearly identify interactive actions that are unavailable.

### FR-145: Stale sessions

The system shall detect and label sessions that have not emitted expected heartbeats or events.

### FR-146: Safe retry

The system shall retry only operations classified as safe or explicitly approved for retry.

---

## 10.15 Audit and history

### FR-150: Audit trail

The system shall record prompts, normalized commands, approvals, actions, results, failures, policy decisions, and security events.

### FR-151: Immutable records

Audit records shall be append-only from the user’s perspective.

### FR-152: Session timeline

The user shall be able to view a chronological session timeline.

### FR-153: Audit export

The user shall be able to export a redacted audit report.

### FR-154: Retention

The user shall configure event, log, screenshot, and artifact retention.

### FR-155: Provenance

The system shall show how each action was executed: native adapter, process control, UI Automation, input fallback, or visual fallback.

---

## 11. Data Model

Core entities:

- Device.
- Machine.
- User session.
- Workspace.
- Repository.
- Branch.
- Adapter.
- Adapter capability.
- Session.
- Task.
- Instruction.
- Normalized command.
- Action.
- Approval.
- Policy.
- Event.
- File change.
- Diff.
- Test result.
- Build result.
- Artifact.
- Notification.
- Evidence record.
- Audit record.
- Connection.
- Diagnostic report.

### 11.1 Event envelope

```json
{
  "event_id": "evt_123",
  "event_type": "approval_requested",
  "schema_version": 1,
  "machine_id": "machine_123",
  "workspace_id": "workspace_123",
  "session_id": "session_123",
  "sequence": 482,
  "timestamp": "2026-09-19T01:29:00+05:30",
  "correlation_id": "corr_123",
  "causation_id": "action_123",
  "payload": {}
}
```

### 11.2 Command envelope

```json
{
  "command_id": "cmd_123",
  "idempotency_key": "idem_123",
  "machine_id": "machine_123",
  "workspace_id": "workspace_123",
  "session_id": "session_123",
  "command_type": "send_instruction",
  "instruction": "Fix the timeout tests and do not change the retry limit.",
  "constraints": [
    "do_not_change_retry_limit"
  ],
  "requested_by_device": "device_123",
  "risk": "medium",
  "requires_confirmation": true,
  "created_at": "2026-09-19T01:29:00+05:30"
}
```

---

## 12. Technical Architecture

```text
+-----------------------------------------------------------+
|                    Flutter Mobile App                    |
|                                                           |
|  Dashboard | Sessions | Approvals | Composer | Settings   |
|  Local cache | Notifications | Voice | Secure storage     |
+-----------------------------+-----------------------------+
                              |
                   Authenticated protocol
                              |
+-----------------------------v-----------------------------+
|              Connectivity and Relay Layer                |
|                                                           |
| Local network | Private network | Optional encrypted relay|
+-----------------------------+-----------------------------+
                              |
+-----------------------------v-----------------------------+
|              Windows Orchestration Agent                 |
|                                                           |
| Session manager | Workspace manager | Policy engine      |
| Adapter manager | Event store | Process controller        |
| Git observer | Test parser | Audit store | Diagnostics     |
+-----------------------------+-----------------------------+
                              |
                 Authenticated local IPC
                              |
+-----------------------------v-----------------------------+
|                Windows Desktop Bridge                   |
|                                                           |
| UI Automation | Win32 | SendInput | Screenshots          |
| Window resolver | Evidence | Interactive session state   |
+-----------------------------------------------------------+
                              |
+-----------------------------v-----------------------------+
|                Local Applications and Tools              |
|                                                           |
| Antigravity | IDEs | CLI agents | Terminals | Git | CI    |
+-----------------------------------------------------------+
```

---

## 13. Technology Requirements

### 13.1 Mobile

- Flutter.
- Dart.
- Riverpod.
- GoRouter.
- Freezed.
- Drift and SQLite.
- Secure storage.
- WebSocket or gRPC client.
- Push notifications.
- QR scanning.
- Voice input.
- Biometric authentication.

### 13.2 Windows

- C#.
- Current supported .NET LTS.
- Worker or generic host architecture.
- Windows UI Automation.
- FlaUI or equivalent .NET UIA wrapper.
- Win32 APIs and P/Invoke.
- Named pipes.
- SQLite.
- DPAPI.
- PowerShell integration.
- Git integration.
- Windows notifications.
- Signed installer and binaries.

### 13.3 Protocol

- WebSocket for event/control transport.
- Protobuf or MessagePack for structured messages.
- TLS 1.3.
- Device public-key authentication.
- Request IDs, event sequence numbers, idempotency keys, heartbeats, timeouts, and replay protection.

### 13.4 Optional backend

- Go relay and API services.
- PostgreSQL.
- Redis.
- NATS.
- Object storage.
- OpenTelemetry.
- Prometheus.
- Grafana.
- Sentry.

### 13.5 Security

- Ed25519 device identity.
- X25519 key exchange.
- ChaCha20-Poly1305 or AES-256-GCM.
- DPAPI on Windows.
- Android Keystore.
- iOS Keychain and Secure Enclave where available.
- Short-lived pairing codes.
- Token rotation.
- Device revocation.
- Biometric step-up authentication.
- Policy engine.
- Audit logging.

---

## 14. Security Requirements

### SEC-001: Device identity

Every paired device shall have a unique cryptographic identity.

### SEC-002: Secure pairing

Pairing codes shall expire and shall not be reusable.

### SEC-003: End-to-end protection

Commands and sensitive event payloads shall be encrypted in transit.

### SEC-004: Least privilege

The mobile client, orchestration agent, desktop bridge, and adapters shall receive only required permissions.

### SEC-005: No public inbound port by default

The Windows companion shall not require a public inbound port for normal operation.

### SEC-006: Workspace binding

Every action shall be bound to a machine, workspace, and session where applicable.

### SEC-007: Exact approval

Approvals shall be bound to the exact action payload, target, and expiration.

### SEC-008: Revocation

The user shall be able to revoke a device without physical access to the phone.

### SEC-009: Secret protection

The system shall not expose credentials, environment secrets, or private keys through logs, notifications, screenshots, or model prompts by default.

### SEC-010: Auditability

Security-sensitive actions shall be recorded with actor, target, time, decision, execution method, and result.

### SEC-011: Elevated-process warning

The system shall warn when the target process has a higher integrity level or requires elevated interaction.

### SEC-012: Secure desktop handling

The product shall not attempt to bypass the Windows secure desktop, UAC, login, or other operating-system security boundaries.

### SEC-013: Prompt-injection resistance

Instructions originating from source files, logs, agent output, or external content shall not automatically override user policies.

---

## 15. Reliability Requirements

### REL-001: Reconnection

The mobile app shall reconnect after temporary network interruptions and recover missed events.

### REL-002: Event ordering

Events shall be sequenced and processed consistently.

### REL-003: Duplicate safety

Duplicate commands and events shall be handled without unintended repeated execution.

### REL-004: Uncertain actions

The system shall preserve uncertainty rather than falsely reporting success or failure.

### REL-005: Crash recovery

The Windows agent shall recover persisted sessions and audit state after restart.

### REL-006: Machine sleep and wake

The app shall clearly report machine sleep, wake, and availability changes.

### REL-007: Bridge failure

The orchestration agent shall continue non-UI functions when the desktop bridge is unavailable.

### REL-008: Adapter failure

An adapter failure shall not corrupt session history or audit records.

### REL-009: Local durability

Critical events, approvals, and commands shall be persisted locally before acknowledgement where practical.

### REL-010: Safe shutdown

The system shall distinguish between graceful cancellation, process termination, crash, and lost connectivity.

---

## 16. Privacy Requirements

- Local execution shall be the default.
- Source code shall not be uploaded by default.
- Relay services shall minimize metadata and forward encrypted payloads where possible.
- Users shall control telemetry.
- Logs shall support redaction.
- Screenshots shall be on-demand and short-lived.
- Voice audio retention shall be configurable.
- Model requests shall be visible where external AI processing is used.
- Sensitive paths and files shall be configurable.
- Data retention shall be configurable.
- Users shall be able to export and delete stored data.

---

## 17. Non-Functional Requirements

### Performance

- Dashboard state should appear promptly after connection.
- Common control actions should provide immediate acknowledgement.
- Live events should be delivered with low practical latency.
- Large logs should be paginated or streamed incrementally.
- The mobile app should remain responsive while sessions are active.

### Availability

- Local operation should not depend on cloud availability.
- Optional relay services should support health checks and failover.
- The Windows agent should recover from network and application restarts.

### Accessibility

- Support large text.
- Support screen readers where practical.
- Use accessible labels for all controls.
- Provide sufficient contrast.
- Do not rely only on color for state.
- Provide text alternatives for visual evidence.

### Internationalization

- Externalize user-visible strings.
- Support localization of dates, times, numbers, and commands.
- Do not rely on English window names in automation adapters.

### Maintainability

- Version protocol schemas.
- Isolate adapters.
- Keep Windows-native code separate from Flutter UI code.
- Maintain architecture decision records.
- Provide adapter conformance tests.
- Preserve backward compatibility where practical.

---

## 18. User Stories

### Pairing

- As a developer, I want to pair my phone with my Windows machine securely so that I can control only my own workstation.
- As a developer, I want to revoke a lost phone so that it cannot control my machine.

### Observation

- As a developer, I want to see all active sessions so that I know whether my agents are working.
- As a developer, I want a summary of what the agent is doing so that I do not need to read every log line.
- As a developer, I want to inspect changed files and diffs so that I can review progress remotely.
- As a developer, I want to see test and build results so that I can understand whether the task succeeded.

### Control

- As a developer, I want to send a follow-up instruction from my phone so that I can continue working while away from my desk.
- As a developer, I want to use voice input so that I can issue commands while walking.
- As a developer, I want to attach the current error and diff automatically so that the agent has relevant context.
- As a developer, I want to pause or cancel a session so that I can prevent unwanted work.

### Safety

- As a developer, I want to see the exact command before approving it so that I understand its effects.
- As a developer, I want risky actions to require confirmation so that a compromised or misunderstood command cannot silently damage my project.
- As a developer, I want actions to be bound to a workspace so that commands cannot run in the wrong repository.
- As a developer, I want uncertain actions clearly identified so that I do not accidentally duplicate them.

### Recovery

- As a developer, I want to know whether a machine is offline, locked, or merely delayed so that I can choose an appropriate response.
- As a developer, I want the system to reconnect and recover missed events so that temporary network loss does not destroy session context.
- As a developer, I want to inspect why automation failed so that I can recover manually.

---

## 19. Success Metrics

### Product metrics

- Pairing completion rate.
- Time from installation to first connected machine.
- Workspace discovery success rate.
- First-session completion rate.
- Percentage of sessions observed remotely.
- Percentage of sessions receiving remote intervention.
- Approval completion rate.
- Session recovery rate after connection loss.
- Adapter success rate.
- Automation confirmation rate.
- Uncertain-action rate.
- Crash-free mobile sessions.
- Crash-free Windows agent sessions.

### User-value metrics

- Number of hours users report working away from the desk.
- Number of completed sessions without direct laptop interaction.
- Percentage of users who return to the product after the first session.
- Percentage of users using diff and test views.
- Voice-command usage and correction rate.
- Percentage of users who enable observe-only mode.
- Time saved responding to agent prompts.

### Trust and safety metrics

- Unauthorized-action rate.
- Incorrect-target action rate.
- Policy false-allow rate.
- Policy false-block rate.
- Approval mismatch rate.
- Secret-redaction failures.
- Device-revocation success rate.
- Security incidents.

---

## 20. Definition of Done

The initial complete product release is considered functionally complete when a new user can:

1. Install the Windows companion.
2. Install the mobile application.
3. Pair the phone and workstation securely.
4. Discover a project workspace.
5. Detect or start a supported coding-agent session.
6. View structured status, logs, plans, files, tests, and errors.
7. Send a text instruction with attached context.
8. Send a reviewed voice instruction.
9. Receive and process an approval request.
10. Approve or reject an exact action.
11. Pause, resume, cancel, or retry supported tasks.
12. Inspect resulting diffs and test outcomes.
13. Receive notifications while away from the application.
14. Recover from a temporary connection interruption.
15. Understand when an action is uncertain.
16. Inspect UI automation evidence when a desktop integration is used.
17. Review a complete audit timeline.
18. Revoke a paired device.
19. Configure workspace and action policies.
20. Continue operating locally when optional cloud services are unavailable.

---

## 21. Acceptance Criteria

### Pairing acceptance

- A user can pair a phone and Windows machine in under five minutes.
- Expired pairing codes cannot be used.
- The user confirms the same verification phrase on both devices.
- Revoked devices cannot reconnect.

### Session acceptance

- A supported session appears on the mobile dashboard.
- Status changes are reflected without requiring full screen streaming.
- The user can distinguish running, waiting, blocked, failed, completed, and offline states.

### Command acceptance

- A command shows target machine and workspace before dispatch.
- Voice commands show transcription before execution.
- Commands receive an idempotency key.
- The user can cancel before dispatch.
- The system does not silently retry uncertain destructive actions.

### Approval acceptance

- The approval screen shows the exact action and effects.
- Approvals expire.
- Approval decisions are recorded.
- The target workspace cannot change after approval without invalidating it.

### Automation acceptance

- Native or process integrations are selected before UI automation.
- UI automation verifies preconditions and postconditions.
- Automation failures expose an actionable explanation.
- Elevated, locked, or secure-desktop limitations are clearly reported.

### Recovery acceptance

- The mobile app reconnects after temporary network loss.
- Missed events are recovered or clearly marked unavailable.
- Machine offline and bridge unavailable are distinct states.
- Session history remains available after agent restart.

### Privacy acceptance

- Source code remains local by default.
- Logs and screenshots can be redacted or disabled.
- Users can view and configure relay and model-processing behavior.

---

## 22. Release Strategy

### Internal development release

- Windows companion in signed development builds.
- Flutter mobile app through internal testing.
- Local-network connectivity.
- One supported adapter.
- Structured session events.
- Basic approvals.
- Diagnostics and audit logs.

### Private beta

- Multiple adapters.
- Optional relay.
- Push notifications.
- Voice input.
- Diff and test views.
- Recovery flows.
- UI automation evidence.
- Security review.
- Onboarding without developer assistance.

### Public release

- Signed Windows installer.
- Android and iOS distribution.
- Documented security model.
- Stable protocol.
- Adapter compatibility documentation.
- Privacy policy and terms.
- Support and diagnostics workflow.
- Product website.
- Public issue tracker or feedback channel.
- Launch assets and demo.

---

## 23. Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Antigravity lacks a stable public integration surface | High | Build an adapter abstraction and support CLI/process/UIA fallbacks |
| UI automation breaks after application updates | High | Native-first hierarchy, capability detection, postcondition verification, adapter tests |
| Remote command can compromise workstation | Critical | Least privilege, policy engine, exact approvals, device keys, audit trail |
| Phone sends command to wrong workspace | Critical | Explicit target binding, workspace display, approval invalidation on context change |
| Network loss causes duplicate execution | Critical | Idempotency keys, uncertain state, no blind retries |
| Windows locked or secure desktop blocks actions | High | Detect session state, preserve read-only mode, explain limitation |
| Relay increases privacy concerns | High | Optional relay, encrypted payload forwarding, metadata minimization |
| Voice transcription misinterprets instruction | High | Review before sending, confidence warnings, constraints preview |
| Model-generated command is unsafe | Critical | Policy evaluation, command classification, user confirmation, sandboxing |
| Large logs overwhelm mobile UX | Medium | Structured summaries, pagination, filters, event grouping |
| Multiple adapters create maintenance burden | High | Adapter SDK, capability negotiation, conformance tests |
| Windows antivirus flags automation agent | High | Code signing, transparent behavior, least privilege, security documentation |
| App becomes too broad | High | Maintain control-plane thesis and reject unrelated remote-desktop scope |

---

## 24. Open Questions

- What official or local integration surfaces are available for Antigravity at implementation time?
- Which adapter should be the reference integration?
- Should relay infrastructure be operated by the project or remain self-hosted initially?
- Which features work while Windows is locked?
- Which actions should be blocked rather than approval-gated?
- How should adapter plugins be installed and signed?
- Should third-party adapters run in isolated processes?
- What source-code and log redaction defaults are required?
- Which model should interpret commands, and can interpretation run locally?
- What is the minimum supported Windows version?
- Which Android and iOS versions are supported?
- How should multi-monitor and scaling behavior be represented in evidence?
- What user experience is used when native integrations and UI Automation disagree?
- How should users recover from an action that is confirmed locally but not received by the phone?
- What is the legal and trademark position of any Antigravity-specific adapter or branding?

---

## 25. Product Positioning

### Recommended positioning

> LocalLoop is a local-first mobile command center for monitoring and safely controlling AI coding sessions running on your own computer.

### Recommended headline

> Your coding agent does not need you at the desk.

### Recommended subheadline

> Monitor sessions, review changes, respond to failures, and approve actions from your phone while your code stays on your own machine.

### Avoid

- “Control any Windows app from anywhere.”
- “Zero-risk remote code execution.”
- “Zero infrastructure costs.”
- “Full Antigravity remote access.”
- “Universal IDE compatibility” before it is demonstrated.
- “Invisible” or “ghost” control language that weakens trust.

---

## 26. Final Product Thesis

LocalLoop is not a remote desktop, screen streamer, or generic terminal.

It is a secure, local-first, application-aware control plane that connects a Flutter mobile command center to development activity running on a Windows workstation.

Its long-term differentiation is the combination of:

- Structured agent and development context.
- Native-first adapter architecture.
- Windows UI Automation fallback.
- Mobile-native voice and command interaction.
- Policy-based approvals.
- Explicit verification and uncertainty handling.
- Local-first privacy.
- Resilient connectivity.
- Recovery-oriented design.
- Extensible support for Antigravity, IDEs, CLI agents, terminals, scripts, and CI systems.

The product succeeds when a developer can walk away from the workstation without walking away from the engineering process.
