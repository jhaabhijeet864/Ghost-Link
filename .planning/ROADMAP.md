# LocalLoop Roadmap

## Milestone v1.0: Foundation & Core Control Plane (Complete)

| # | Phase | Goal | Requirements | Status |
|---|-------|------|--------------|--------|
| 1 | Infrastructure & Event Model | Establish Windows dual-process (Service & Bridge) and SQLite event store | WIN-01, WIN-02, WIN-03 | Completed ✓ |
| 2 | Connectivity & Mobile Observe | Implement local networking, pairing, and Flutter read-only monitoring | MOB-01, MOB-02, MOB-05, NET-01, SEC-01 | Completed ✓ |
| 3 | Command & Control Mode | Implement command interpretation and policy engine for safe execution | MOB-03, MOB-04, SEC-02, SEC-03 | Completed ✓ |
| 4 | Native & UI Automation Adapters | Implement process control and FlaUI adapters for live agent interaction | ADAPT-01, ADAPT-02, ADAPT-03, ADAPT-04 | Completed ✓ |

---

## Milestone v1.1: Mobile Companion Experience & UI Architecture (Active)

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 5 | Navigation Shell & Workspaces Dashboard | 5-tab navigation bar, active workstation card, status badge, multi-device switcher | UI-01, UI-02, UI-03, UI-04 | 4 |
| 6 | Advanced Observe Surface | Filter chips, code diff viewer widget, on-demand screenshot modal | UI-05, UI-06, UI-07 | 3 |
| 7 | Command & Approval Hardening | Voice visualizer, rich approval detail sheet with 2m timer & signed approval | UI-08, UI-09 | 2 |
| 8 | Settings & Security Management | Device identity card, policy inspector, cryptographic key revocation | UI-10, UI-11, UI-12 | 3 |

---

### Phase 5: Navigation Shell & Workspaces Dashboard
**Goal:** Establish a 5-tab application shell and full workspaces dashboard with real-time status and device switching.
**Mode:** standard
**Requirements:** UI-01, UI-02, UI-03, UI-04
**Success Criteria:**
1. Persistent bottom navigation bar allows switching between Workspaces, Observe, Command, Approvals, and Settings tabs without losing state.
2. Active Workstation Card displays live connection state (online/reconnecting/offline badge), hostname, active project, and ping latency.
3. Users can switch between multiple paired workstations or pair a new device from the Workspaces tab.
4. Manual connection dialog allows entering host IP, port, and pairing secret with real-time validation.

### Phase 6: Advanced Observe Surface
**Goal:** Deliver deep observation tools including telemetry filter chips, diff viewing, and screenshot inspection.
**Mode:** standard
**Requirements:** UI-05, UI-06, UI-07
**Success Criteria:**
1. Event filter chips (`All`, `Agent Logs`, `Diffs`, `Terminal Output`, `Errors`) instantly narrow down live stream telemetry.
2. Code Diff Viewer renders additions and deletions with syntax coloring and file metadata headers.
3. On-demand screenshot trigger captures a fresh host display and presents it in an interactive zoomable modal.

### Phase 7: Command & Approval Hardening
**Goal:** Upgrade command formulation and high-stakes action approvals with visual countdowns and signature signing.
**Mode:** standard
**Requirements:** UI-08, UI-09
**Success Criteria:**
1. Command Composer features a voice dictation animation visualizer and structured parameter constraint inputs.
2. Approval Inbox provides an expanded detail sheet showing full command arguments, affected files, policy classification, and a 2-minute countdown timer before expiration.
3. One-tap approval generates an Ed25519 canonical signature envelope verified by the host service.

### Phase 8: Settings & Security Management
**Goal:** Provide end-to-end security transparency and device pairing control.
**Mode:** standard
**Requirements:** UI-10, UI-11, UI-12
**Success Criteria:**
1. Settings screen displays Mobile Ed25519 public key fingerprint, unique device ID, and paired token info.
2. Security policy inspector lists all permission rules (safe auto-allowed operations vs. approval-required commands).
3. Revocation action securely purges stored cryptographic keys and pairings, resetting the app to a clean state.
