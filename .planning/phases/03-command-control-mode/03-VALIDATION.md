---
phase: 3
slug: command-control-mode
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-09-19
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | xUnit (C#) / flutter test |
| **Config file** | none — Wave 0 installs |
| **Quick run command** | `dotnet test` / `flutter test` |
| **Full suite command** | `dotnet test && flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test for the related domain
- **After every plan wave:** Run `dotnet test && flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (TBD) | | | | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/LocalLoop.Tests/` — xUnit project setup for Service
- [ ] `test/` — Flutter widget test setup for Mobile
- [ ] Golden dataset (size >= 10) for Semantic Kernel intent accuracy and risk rating tests

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| End-to-End Cycle | MOB-03, SEC-02 | Requires real Mobile <-> Windows IPC/Network sync | Start service, send command from mobile, approve on mobile, verify audit log |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
