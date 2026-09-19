# Phase 7 Plan: Command & Approval Hardening

## Requirements Covered
- **UI-08**: Voice Input Waveform Visualizer with pulsating radial sound rings and transcript editing.
- **UI-09**: Rich Approval Request Detail Sheet with 2-minute countdown timer, affected resource inspection, and Ed25519 cryptographic approval.

---

## Tasks

### Wave 1: Voice Dictation Visualizer
- [ ] Task 1.1: Create `mobile/lib/features/command/widgets/voice_dictation_modal.dart` with animated radial sound rings, speech animation controller, live transcript editing, and "Use Transcript" / "Cancel" actions.
- [ ] Task 1.2: Integrate voice button into `CommandComposerScreen` input bar.

### Wave 2: Rich Approval Request Detail Sheet
- [ ] Task 2.1: Create `mobile/lib/features/command/widgets/approval_detail_sheet.dart` with 2-minute circular timer, resource badges, risk analysis, and Ed25519 one-tap approval.
- [ ] Task 2.2: Update `ApprovalInboxScreen` to auto-open `ApprovalDetailSheet` for High-risk requests, support tap-to-expand, and trigger auto-rejection when timer expires.

### Wave 3: Automated Test Verification
- [ ] Task 3.1: Create `mobile/test/phase7_widget_test.dart` validating `VoiceDictationModal`, `ApprovalDetailSheet`, countdown timer, and sign-and-approve flow.
- [ ] Task 3.2: Run `flutter test` and `flutter analyze` ensuring 0 regressions.
