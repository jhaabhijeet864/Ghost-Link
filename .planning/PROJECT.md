# LocalLoop

## Core Value
A developer can leave the Windows workstation, continue supervising an autonomous coding session from a Flutter mobile app, understand what the agent is doing, intervene intelligently, provide voice or text instructions, approve risky actions, inspect results, and recover from failures without touching the laptop.

## What This Is
A secure, application-aware remote control plane for AI coding environments. The phone becomes a safe command, observation, approval, and orchestration surface for the workstation. 

### Architecture
1. **Flutter Mobile Application**: A domain-driven mobile app that offers multi-workspace views (Home, Session, Workspace, Approval inbox, Command composer, Timeline, Machine view, Settings/security).
2. **Connectivity and Relay Layer**: Supports Local network mode, Private-network mode, and Relay mode.
3. **LocalLoop Service (Windows Orchestration Agent)**: Background service handling networking, storage, process monitoring, and policy engine (append-only event store in SQLite).
4. **LocalLoop Desktop Bridge**: Foreground interactive session bridge that handles UI Automation, input, and visible prompts via Named Pipes IPC.

### Interaction Modes
- **Observe mode**: Read-oriented. Read logs, messages, diffs, plans, active window, screenshots on demand, and status summaries.
- **Control mode**: Action-oriented. Send instructions, pause/resume, cancel tasks, approve/reject commands, run workflows.

## Context
Modern AI-first development software lacks a native mobile remote. Simple remote terminal or screen streaming approaches are brittle and lack awareness of the development context. By building a native, 4-layer architecture with a robust capability-based protocol and policy engine, we establish a dependable engineering control plane without exposing the workstation to raw remote code execution.

## Requirements

### Validated
(None yet — ship to validate)

### Active
- [ ] Implement Flutter mobile app with domain-driven structure.
- [ ] Implement dual-process Windows architecture (Service + Desktop Bridge).
- [ ] Implement capability-based adapter framework (Level 1 Native down to Level 6 Visual Automation fallback).
- [ ] Implement intelligent command interpretation layer.
- [ ] Implement policy and approval engine with explicit risk levels.
- [ ] Implement append-only event stream data model.

### Out of Scope
- Full remote desktop streaming — Replaced by structured event/task streaming and on-demand screenshots.
- Cloud code storage or AI model hosting — Must remain local-first.
- Unconstrained shell access — Replaced by context-aware, approved actions.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Dual-process Windows Agent | Windows service cannot reliably perform interactive UI automation. Separate network/policy from UI interaction. | Pending |
| Event-driven Mobile App | Mobile apps face background restrictions and dropped connections. State must rebuild from events, not live open streams. | Pending |
| 6-level Automation Hierarchy | UI Automation is brittle; prioritize native APIs and process control, using SendInput/Visual strictly as fallbacks. | Pending |

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
*Last updated: 2026-09-19 after milestone update*
