# Requirements

## Epic 1: The Claude Code Hook Prototype (Completed)
Prove the core wedge by allowing a mobile device to approve or deny a command issued by an autonomous AI agent (Claude Code).

## Epic 2: Mobile UI Redesign (Current)
Redesign the mobile app to transition from a passive observation terminal to an interrupt-driven, high-friction security inbox.

### Functional Requirements
1. **Inbox-First Navigation:** The home screen must be the Approval Inbox, sorting requests chronologically.
2. **Approval Card Detail:** 
   - Display the raw target command in a monospace well.
   - Show a diff preview if files are being modified.
   - Explicitly display the risk level (e.g., `High`) via semantic chips.
   - 2:00 minute expiry countdown timer.
3. **Biometric Face ID Flow:** Approving an action must require a deliberate "Hold-to-Approve" gesture tied to local biometric auth.
4. **Prune Fake Features:** Remove simulated voice dictation components and inaccurate "Encrypted" status badges.

### Non-Functional Requirements
- **Terminal-Grade Contrast:** Follow the color palette in `DESIGN.md` (e.g., obsidian, gunmetal, steel).
- **Legibility:** Minimum font size of 11sp.
- **Honest UI:** Do not display uncertain states as successful.

## Future Epics
- **MacOS/Linux Daemon (Phase 2):** Decouple from Windows-only .NET to a cross-platform (Rust/Go) native daemon.
- **E2EE NAT Traversal (Phase 3):** Drop the LAN-only restriction with an untrusted relay server.
