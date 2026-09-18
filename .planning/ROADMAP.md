# LocalLoop Roadmap

## Proposed Roadmap

**3 phases** | **8 requirements mapped** | All v1 requirements covered ✓

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 1 | Define the Contract & Mock | Set up the basic local agent, pairing, and mock execution | ARCH-01, ARCH-02, ARCH-03, ADAPT-01 | 3 |
| 2 | Mobile Monitor & Control | Build the mobile UI to display status and send commands safely | MON-01, MON-02, MON-03, EXEC-01 | 3 |
| 3 | Execution & Audit | Implement real adapter execution, audit logging, and approvals | EXEC-02, EXEC-03, ADAPT-02 | 3 |

### Phase Details

### Phase 1: Define the Contract & Mock
**Goal:** Establish the Windows companion agent, secure pairing, and a mock adapter.
**Mode:** mvp
**Requirements:** ARCH-01, ARCH-02, ARCH-03, ADAPT-01
**Success Criteria:**
1. Windows agent starts and exposes an authenticated endpoint.
2. Phone app can pair with the agent using a QR code.
3. Phone can trigger a mock task and receive status updates.

### Phase 2: Mobile Monitor & Control
**Goal:** Build the mobile UI to view tasks and send follow-up text instructions.
**Mode:** mvp
**Requirements:** MON-01, MON-02, MON-03, EXEC-01
**Success Criteria:**
1. Phone displays active task status and simulated logs.
2. User can tap pause or cancel on the phone and the mock agent reflects the state change.
3. User can send a text follow-up command.

### Phase 3: Execution & Audit
**Goal:** Hook up a real CLI adapter, implement audit logs, and require explicit approvals.
**Mode:** mvp
**Requirements:** EXEC-02, EXEC-03, ADAPT-02
**Success Criteria:**
1. Follow-up command executes via a real local CLI process.
2. High-risk mock command prompts for explicit user approval on the phone.
3. Audit log file is generated capturing all actions.
