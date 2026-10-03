# Phase 1.5: UI Redesign Spec

## Objective
Radically simplify the mobile app UI to match the "Agent Trust & Approval Layer" positioning, following the guidelines set in `ui_redesign_spec.md`.

## Steps

1. **Purge Simulated Features**
   - Delete `mobile/lib/features/command/widgets/voice_dictation_modal.dart`.
   - Remove the Voice Dictation FAB and related waveform animations from the UI.

2. **Global Navigation Refactor**
   - Refactor `core/router/app_router.dart` and `app_bottom_navigation.dart` to trim the nav shell down to a 3-tab layout:
     - Tab 1: Inbox (Default Home - replaces "Control Room")
     - Tab 2: Workstations
     - Tab 3: Settings

3. **Inbox Screen Implementation**
   - Design the `InboxScreen` as a chronological `ListView` of pending and recently resolved `SignedEnvelope` requests.
   - Implement the new Header displaying the active Workstation pill.
   - Implement the Empty State using a circular well with an inbox icon and text: "No pending agent requests."

4. **Approval Detail Sheet Implementation**
   - Refactor `approval_detail_sheet.dart` to slide up when a request is tapped.
   - Implement the **Header Row** with a Risk Chip (`[🚨 HIGH RISK]`) and a Monospace Countdown Timer (turning `dangerSoft` at 00:30).
   - Implement the **Payload / Diff Well** with `obsidian` background and git-diff styling (`okBg` for additions, `errBg` for deletions).
   - Implement the **Action Row** with an Outlined Reject Button and a Hold-to-Approve Button (requires 1.5-second long-press before triggering auth).

5. **Component Rules & Corrections**
   - Remove all "Encrypted" status badges across the app and replace them with "Ed25519 Signed".
   - Update connection state indicators so that the dot (`🟢` / `🔴`) is always accompanied by the text "Connected" or "Disconnected".
   - Replace all full-screen blocking loading modals with inline stroke-width 2 spinners.

## Verification
- Run Flutter widget tests (`flutter test`) ensuring `sqfliteFfiInit()` is properly configured for Windows, all tests must pass.
- Run `flutter analyze` ensuring 0 errors remain.
