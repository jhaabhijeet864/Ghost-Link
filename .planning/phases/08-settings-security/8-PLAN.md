# Phase 8 Plan: Settings & Security Management

## Requirements Covered
- **UI-10**: Device Identity Inspector displaying Ed25519 public key fingerprint and cryptographic curve info.
- **UI-11**: Security Policy Viewer displaying real-time risk level enforcement rules.
- **UI-12**: Pairing Revocation with safe key purging and session reset.

---

## Tasks

### Wave 1: Verification Test Suite
- [ ] Task 1.1: Create `mobile/test/phase8_widget_test.dart` verifying device identity card, policy rows, and revocation dialog flow.
- [ ] Task 1.2: Execute `flutter test test/phase8_widget_test.dart` to verify all pass.

### Wave 2: Validation Audit
- [ ] Task 2.1: Create `.planning/phases/08-settings-security/8-VALIDATION.md` documenting Nyquist compliance.
