# TASKS.md

## Current Project Status

- **Version:** v0.5.0 (Pre-Alpha) / Milestone v1.1 Complete
- **Status:** All core infrastructure, observation, and command phases (1-8) are code complete and tested.

## Completed Phases

- [x] **Phase 1:** Infrastructure & Event Model (Windows service, SQLite, IPC)
- [x] **Phase 2:** Connectivity & Mobile Observe (Pairing, WebSockets, mDNS, Observe UI)
- [x] **Phase 3:** Command & Control (Composer, Approvals, Policy Engine)
- [x] **Phase 4:** Native & UI Automation Adapters (ProcessAdapter, FlaUiAdapter, ScreenshotAdapter)
- [x] **Phase 5:** Navigation Shell & Workspaces Dashboard
- [x] **Phase 6:** Advanced Observe Surface
- [x] **Phase 7:** Command & Approval Hardening
- [x] **Phase 8:** Settings & Security Management

## Recent Work

- [x] **Dual-Strategy IDE Integration:** Implemented `TranscriptWatcher` in `LocalLoop.Service` to read `transcript.jsonl` logs, alongside the `IdePromptInjector` in `LocalLoop.Bridge` using FlaUI for sending prompts.
- [x] **Web Build:** Fixed Riverpod/Singleton issues to allow the Flutter web build to run smoothly (`flutter build web`).

## Pending / Next Steps

### Packaging & Distribution

- [ ] Create a Windows Installer (MSIX/ClickOnce) for Service + Bridge with auto-start and update capabilities.
- [ ] Build and sign the Android APK / App Bundle for distribution.
- [ ] Build for iOS (requires macOS + Xcode).

### Verification

- [ ] Verify the complete End-to-End Dual-Strategy integration (Mobile Command -> Bridge FlaUI -> IDE -> TranscriptWatcher -> Mobile Log View).

### Documentation & Onboarding

- [ ] Finalize `PRD.md`, `RULES.md`, `ARCHITECTURE.md`, `MEMORY.md`, `DESIGN.md`.
- [ ] Create an optional landing page for download links, setup guides, and privacy policies.
