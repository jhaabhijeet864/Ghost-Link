# Roadmap

## Phase 1: The Trust Wedge (Completed)
- **Goal:** Prove the core interaction (phone buzzes → agent wants to run a command → you Face ID deny).
- **Deliverables:** Claude Code `PreToolUse` prototype in .NET CLI.

## Phase 1.5: UI Redesign Spec (Current)
- **Goal:** Radically simplify the mobile app UI to match the "Agent Trust & Approval Layer" positioning.
- **Deliverables:**
  - Produce the Markdown `ui_redesign_spec.md`.
  - Wireframe the Inbox, Approval Card, and remove simulated features.

## Phase 2: Cross-Platform Expansion
- **Goal:** Reach the primary demographic of early AI dev-tool adopters (macOS/Linux).
- **Deliverables:**
  - Rewrite or cross-compile the daemon for macOS/Linux (removing Windows UI automation layers).
  - Standardize the MCP/hook interface format.

## Phase 3: Internet Routing & Relay
- **Goal:** True remote control without being tethered to the same LAN or VPN.
- **Deliverables:**
  - Minimal Go/Rust relay server.
  - E2EE payloads (Noise protocol/libsodium) so the relay never sees the commands or source code.
  - APNs/FCM for push notifications that wake up the app.

## Phase 4: Prosumer & Teams
- **Goal:** Monetization.
- **Deliverables:**
  - Audit logging exports.
  - Policy-as-Code definitions.
  - Shared workstation approvals (team leads approving Junior dev agent runs).
