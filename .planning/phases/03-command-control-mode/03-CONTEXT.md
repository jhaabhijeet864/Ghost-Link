# Phase 3: Command & Control Mode - Context

**Gathered:** 2026-09-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the command composer on mobile and the approval engine on Windows.
</domain>

<decisions>
## Implementation Decisions

### Mobile command input
- **D-01:** Text field plus a row of quick-action chips (e.g., "Pause", "Resume", "Cancel").

### Policy definitions
- **D-02:** Hardcoded rules in the Service layer (simplest for MVP).

### Approval notification flow
- **D-03:** A dedicated "Approval Inbox" list view in the app, accessible via a badge/icon that opens a side drawer or modal list.

### Audit log structure
- **D-04:** Just timestamp and device ID (keep it minimal for MVP).

### the agent's Discretion
None

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope & Requirements
- `.planning/PROJECT.md` — Project definition, core value, architecture.
- `.planning/REQUIREMENTS.md` — Active and deferred requirements, V1 details.
- `.planning/ROADMAP.md` — Phase boundaries and success criteria.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None (Phase 3 is an early phase).

### Established Patterns
- Dual-process architecture pattern on Windows (Service vs. Bridge).
- Domain-driven structure on Flutter.

### Integration Points
- Windows Service policy engine hooks into the IPC pipeline.
- Mobile App Command Composer hooks into the Flutter UI and event layer.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 3-Command & Control Mode*
*Context gathered: 2026-09-19*
