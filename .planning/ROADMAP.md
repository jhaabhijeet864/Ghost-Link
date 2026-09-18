# LocalLoop Roadmap

## Proposed Roadmap

**4 phases** | **17 requirements mapped** | All v1 requirements covered ✓

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 1 | Infrastructure & Event Model | Establish Windows dual-process (Service & Bridge) and SQLite event store | WIN-01, WIN-02, WIN-03 | 3 |
| 2 | Connectivity & Mobile Observe | Implement local networking, pairing, and Flutter read-only monitoring | MOB-01, MOB-02, MOB-05, NET-01, SEC-01 | 3 |
| 3 | Command & Control Mode | Implement command interpretation and policy engine for safe execution | MOB-03, MOB-04, SEC-02, SEC-03 | 3 |
| 4 | Native & UI Automation Adapters | Implement process control and FlaUI adapters for live agent interaction | ADAPT-01, ADAPT-02, ADAPT-03, ADAPT-04 | 3 |

### Phase Details

### Phase 1: Infrastructure & Event Model
**Goal:** Build the dual-process Windows architecture and local event storage.
**Mode:** mvp
**Requirements:** WIN-01, WIN-02, WIN-03
**Success Criteria:**
1. Background service initializes an SQLite append-only event store.
2. Desktop bridge launches in user session and connects via named pipe.
3. System can read and write standard events (e.g., `session_created`).

### Phase 2: Connectivity & Mobile Observe
**Goal:** Establish secure connection and build the Flutter mobile read-only views.
**Mode:** mvp
**Requirements:** MOB-01, MOB-02, MOB-05, NET-01, SEC-01
**Success Criteria:**
1. Secure pairing sequence successfully pairs Flutter app with Windows agent over LAN.
2. App reconstructs state from event store efficiently upon connection.
3. User can view live logs, active workspace, and agent status on phone.

### Phase 3: Command & Control Mode
**Goal:** Build the command composer on mobile and the approval engine on Windows.
**Mode:** mvp
**Requirements:** MOB-03, MOB-04, SEC-02, SEC-03
**Success Criteria:**
1. Command composer translates a complex text request into a structured JSON intent.
2. Windows agent blocks high-risk requests based on predefined policy and prompts mobile app for approval.
3. Audit log successfully records the command, the policy evaluation, and the user's approval.

### Phase 4: Native & UI Automation Adapters
**Goal:** Hook the system up to real developer tools using adapters.
**Mode:** mvp
**Requirements:** ADAPT-01, ADAPT-02, ADAPT-03, ADAPT-04
**Success Criteria:**
1. Process control adapter correctly captures output from a running CLI tool.
2. FlaUI-based UI Automation adapter identifies and interacts with a target application window.
3. System gracefully degrades and requests an on-demand screenshot if an automation target cannot be found.
