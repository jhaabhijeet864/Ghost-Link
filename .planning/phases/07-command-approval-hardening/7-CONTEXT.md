# Phase 7: Command & Approval Hardening — Context

## Objective
Upgrade the command composer with an animated voice dictation interface and build a rich approval request detail sheet with a 2-minute expiration countdown timer and one-tap Ed25519 cryptographic approval.

---

## Locked Architectural & UI Decisions

### 1. Voice Dictation Waveform Visualizer
- **Visual Style**:
  - Pulsing radial sound rings expanding outward from a glowing cyan/green microphone circle.
  - Smooth animation controller simulating ambient audio level fluctuation.
- **Dictation Workflow**:
  - Tapping the microphone button opens an in-place voice recording overlay modal.
  - Displays real-time live transcribed text with an instant "Use Transcript" button that fills the Command Composer input field.
  - Includes a "Cancel" button to discard spoken input.

### 2. Rich Approval Request Detail Sheet
- **Presentation & Triggering**:
  - **High-risk requests**: Automatically open the expanded bottom modal sheet immediately upon receiving the `approval_request` WebSocket payload.
  - **Medium/Low-risk requests**: Render as cards in the inbox with a badge count, opening the detail sheet when tapped.
- **2-Minute Expiration Countdown**:
  - Live progress ring and countdown timer (`02:00` counting down to `00:00`).
  - **Auto-reject on expiration**: When `00:00` is reached, automatically mark the request as `expired`, notify the user with a subtle red alert, and transmit a signed rejection event to the Windows host agent.
- **Resource & Safety Inspection**:
  - Badges displaying affected target files, command lines to execute, and working directory.
  - Clear policy rationale explaining why the action was flagged (e.g. `destructor_rule: File deletion requires interactive human authorization`).
- **Cryptographic One-Tap Approval**:
  - "Sign & Approve" button signs the approval payload using the mobile device's Ed25519 private key via `SignedEnvelope`.
  - Transmits `{ "type": "approval_response", "decision": "approved", "signature": ... }` to the host.

---

## Deliverables
1. `mobile/lib/features/command/widgets/voice_dictation_modal.dart`: Animated radial sound rings and speech dictation modal.
2. `mobile/lib/features/command/widgets/approval_detail_sheet.dart`: 2-minute countdown timer, affected resource breakdown, and signed approval.
3. Update `command_composer_screen.dart` with mic trigger button and voice integration.
4. Update `approval_inbox_screen.dart` to auto-open high-risk sheets and manage the countdown lifecycle.
