---
phase: 4
slug: native-ui-adapters
status: final
nyquist_compliant: true
wave_0_complete: true
created: 2026-09-19
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | xUnit |
| **Config file** | src/LocalLoop.Tests/LocalLoop.Tests.csproj |
| **Quick run command** | `dotnet test src/LocalLoop.Tests` |
| **Full suite command** | `dotnet test src/LocalLoop.Tests` |
| **Estimated runtime** | ~1 seconds |

---

## Sampling Rate

- **After every task commit:** Run `dotnet test src/LocalLoop.Tests`
- **After every plan wave:** Run `dotnet test src/LocalLoop.Tests`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | ADAPT-01 | — | N/A | unit | `dotnet test` | ✅ | ✅ green |
| 4-01-02 | 01 | 1 | ADAPT-02 | — | N/A | unit | `dotnet test` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `src/LocalLoop.Tests/AdapterFactoryTests.cs` — stubs for ADAPT-01
- [x] `src/LocalLoop.Tests/ProcessAdapterTests.cs` — stubs for ADAPT-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Execute semantic UI actions via FlaUI | ADAPT-03 | Requires active interactive desktop UI session to target running windows, prone to extreme flakiness in CI pipelines. | Run Bridge locally, connect mobile app, send focus/click intents to Notepad. |
| Fallback screenshots via GDI+ | ADAPT-04 | Requires active desktop and GDI+ rendering context. CI environments typically run headless and fail rendering. | Request a screenshot intent via mobile app, ensure valid base64 JPEG returned. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-09-19
