# LocalLoop

## Core Value
A local-first mobile control panel for monitoring and safely interacting with long-running AI coding tasks on your own computer, freeing the developer from being tethered to a physical desk without compromising security.

## What This Is
A secure remote control plane for local coding agents consisting of a Windows companion agent and a mobile application. It acts as an invisible digital bridge establishing an encrypted local-to-mobile tunnel. It allows developers to monitor logs, status, diffs, failures from the phone, send structured follow-up instructions, and approve sensitive actions. It uses an adapter model (e.g., CLI, IDE workflows, MCP-compatible agents) rather than brittle UI automation.

## Context
Modern AI-first development software lacks a native mobile remote, restricting the development loop to the physical workstation. This creates prototyping friction and accessibility gaps. While a phone cannot securely or reliably execute arbitrary prompts via simulated typing (which is brittle and insecure), it can effectively serve as a control plane using a capability-based protocol and adapters.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Windows companion agent that registers a local device identity.
- [ ] Secure pairing between phone and Windows agent (e.g., QR code or one-time code).
- [ ] Maintain named workspaces on the host.
- [ ] Mobile client displays active tasks, status, recent logs, and git diffs.
- [ ] Mobile client can send text follow-up commands (pause, cancel, retry, text instructions).
- [ ] Audit log tracking every action.
- [ ] Explicit approval mechanism for high-risk or destructive actions.
- [ ] Mock or CLI adapter to prove the event model before IDE integrations.

### Out of Scope

- Full remote desktop streaming — Replaced by a structured event and task streaming protocol.
- Universal IDE compatibility on launch — Focus on a single CLI/mock adapter first.
- Voice transcription and execution on launch — Kept out of the MVP vertical slice to ensure reliable text-based operations first.
- Cloud code storage or AI model hosting — Must remain local-first with zero mandatory cloud workspace.
- Team collaboration and billing — Out of scope for MVP.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Local-first with explicit approvals | Fixes the remote execution security risk while maintaining absolute data privacy | Pending |
| Adapter architecture | UI automation is brittle; structured task/event protocol is robust and extensible | Pending |
| Text commands first | Voice transcription adds complexity and interpretation risk; text is unambiguous for the MVP | Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
---
*Last updated: 2026-09-19 after initialization*
