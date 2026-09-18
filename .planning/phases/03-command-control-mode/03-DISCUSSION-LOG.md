# Phase 3: Command & Control Mode - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-19
**Phase:** 3-Command & Control Mode
**Areas discussed:** Mobile command input, Policy definitions, Approval notification flow, Audit log structure

---

## Mobile command input

| Option | Description | Selected |
|--------|-------------|----------|
| Text field plus a row of quick-action chips (e.g., "Pause", "Resume", "Cancel") | | ✓ |
| Text field with a '/' command menu for structured inputs | | |
| Just a simple text field for free-form instructions | | |
| Other (I will type my own answer in the chat) | | |

**User's choice:** Text field plus a row of quick-action chips (e.g., "Pause", "Resume", "Cancel")
**Notes:** Decided for quick interactions without needing full typing.

---

## Policy definitions

| Option | Description | Selected |
|--------|-------------|----------|
| A local JSON configuration file (easy to edit manually) | | |
| Hardcoded rules in the Service layer (simplest for MVP) | | ✓ |
| Stored in the SQLite database alongside events | | |
| Other (I will type my own answer in the chat) | | |

**User's choice:** Hardcoded rules in the Service layer (simplest for MVP)
**Notes:** MVP constraint.

---

## Approval notification flow

| Option | Description | Selected |
|--------|-------------|----------|
| A dedicated "Approval Inbox" list view in the app | | ✓ |
| An urgent in-app modal/dialog that pops up over the current view | | |
| Inline within the event timeline as an actionable item | | |
| Other (I will type my own answer in the chat) | | |

**User's choice:** A dedicated "Approval Inbox" list view in the app, placed in a badge/icon that opens a side drawer or modal list.
**Notes:** Keeps the main views clear while still being accessible.

---

## Audit log structure

| Option | Description | Selected |
|--------|-------------|----------|
| Full command context, device ID, timestamp, and active policy matched | | |
| Just timestamp and device ID (keep it minimal for MVP) | | ✓ |
| Device ID, timestamp, and user IP address | | |
| Other (I will type my own answer in the chat) | | |

**User's choice:** Just timestamp and device ID (keep it minimal for MVP)
**Notes:** Minimal audit trail for MVP.

---

## the agent's Discretion

None

## Deferred Ideas

None
