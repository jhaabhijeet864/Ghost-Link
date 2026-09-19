# DESIGN.md

LocalLoop mobile design system. Source of truth for UI in `mobile/lib/`. Tokens live in `mobile/lib/main.dart`; reuse before inventing.

## Principles

1. **Terminal-grade, not decorative.** Dark, high-contrast, dense, legible. No gradients except voice-mic accent.
2. **State is never color-only.** Pair every status color with an icon and/or text label.
3. **Always show context.** Target machine + connection state visible on every control/approval surface.
4. **Security UI is sacred.** Approval/confirm/revoke surfaces do not get restyled without explicit approval.
5. **Honest UI.** No fake progress, no simulated success. Simulated features (voice) are labeled as such.

## Color Tokens

| Token | Hex | Use |
| --- | --- | --- |
| `obsidian` | `#090A0C` | Scaffold bg, code well |
| `gunmetal` | `#121418` | Cards, surfaces, dialogs |
| `panel` | `#13161C` | Elevated cards (workstation, settings, sheets) |
| `panelAlt` | `#1E222B` | Icon chips, nested wells |
| `border` | `#2A2E39` | Default borders, dividers |
| `borderSoft` | `#222733` | Panel borders |
| `steel` | `#8A94A6` | Secondary text, hints, inactive icons |
| `text` | `#FFFFFF` | Primary text |
| `textSoft` | `#C3C7D0` / `#CBD5E1` | Body/log text |
| `accent` | `#00E676` | Success, connected, primary affirm, live |
| `warn` | `#FFB300` | Medium risk, connecting, pending |
| `danger` | `#FF3D00` | High risk, errors, destructive |
| `dangerSoft` | `#FF5252` / `#FF8A80` | Destructive text/border on dark |
| `info` | `#90CAF9` | Policy/secondary links, informational |
| `okBg` | `#0D2117` | Success/added-line background |
| `errBg` | `#2A0D0D` | Error banner/removed-line background |

Rules:

- Tint backgrounds via `color.withValues(alpha: 0.10–0.15)`; borders at `0.3–0.4`. (Prefer `withValues` over deprecated `withOpacity` in new code.)
- Primary button: white bg / obsidian fg. Accent green is for status and affirm-in-place, not default CTAs.
- No new hex values without adding them here.

## Semantic State Map

| State | Color | Icon | Label |
| --- | --- | --- | --- |
| Connected | accent | `wifi` / pulsing dot | Online • Encrypted |
| Connecting / Authenticating | warn | `sync` / dot | Connecting… / Authenticating… |
| Disconnected | danger | `wifi_off` | Disconnected |
| Risk Low | accent | `check_circle` | Low |
| Risk Medium | warn | `warning` | Medium |
| Risk High | danger | `dangerous` | High |
| Expired | dangerSoft | `timer_outlined` | EXPIRED |
| Uncertain | warn | `help_outline` | Uncertain (never shown as success) |

Command statuses to surface: Accepted, Rejected, Running, Completed, Failed, Cancelled, TimedOut, Uncertain, Expired.

## Typography

| Role | Size | Weight | Notes |
| --- | --- | --- | --- |
| AppBar title | 20 | 700 | letterSpacing 0.5 |
| Section header (overline) | 11 | 700 | UPPERCASE, letterSpacing 1.2, white @ 50% |
| Title | 17–18 | 700 | Cards, sheets |
| Body | 13–14 | 400/600 | |
| Caption / meta | 11–12 | 400 | steel |
| Mono (code, IP, targets, timers, diffs) | 11–13 | 400/700 | `fontFamily: 'monospace'` |

Never below 11sp. Respect system text scaling; no fixed-height text containers.

## Spacing & Shape

- Scale (4-multiple): 4, 8, 12, 16, 24, 32.
- Screen padding: 16. Card padding: 14–20. Section gap: 24.
- Radius: chips 4–6 · buttons/inputs 8–10 · cards 12–16 · bottom sheets 24 (top) · pills 20.
- Borders 1px (`1.5` for active/connected cards). Elevation 0; separation via border, not shadow (exception: connected-card 5% accent glow).

## Components (reuse; do not duplicate)

| Component | File | Notes |
| --- | --- | --- |
| Nav shell | `core/router/app_router.dart` | `NavigationBar`, `IndexedStack` to preserve state; bg `#0F1216`, indicator `#1E2638` |
| ActiveWorkstationCard | `features/workspaces/presentation/widgets/` | Status pill + latency + Ed25519 badge + Reconnect/Switch |
| ManualConnectDialog | same | IP/port validation (1–65535), paste URI, quick-connect |
| CodeDiffViewer | `features/observe/presentation/widgets/` | `+` accent on `okBg`, `-` danger on `errBg`, `@@` steel, line numbers, collapsible |
| ScreenshotPreviewer | same | Placeholder → image; tap → `InteractiveViewer` 0.8–4.0x |
| Telemetry filter chips | `observe_screen.dart` | `ChoiceChip` + count badge; selected = white bg/obsidian fg |
| ApprovalDetailSheet | `features/command/widgets/` | **Security-critical.** 2:00 countdown, risk header, policy reason, mono target + copy, Reject/Sign & Approve |
| VoiceDictationModal | same | Radial rings, simulated transcript, editable field |
| Offline banner | per screen | `errBg` bar, `wifi_off`, actionable text |

## Screens

| Tab | Purpose | Must show |
| --- | --- | --- |
| Control Room | Live agent activity + prompt composer | Active agent chip, connection dot, latency, quick-action pills, inline approval cards |
| Observe | Telemetry stream | Filter chips w/ counts, screenshot card, diff/log cards, empty state |
| Workstations | Device management | Active card, saved list, Pair New, empty state |
| Settings | Security | Key fingerprint (copy), policy rows, Revoke All (confirm dialog) |

Open item: Command and Approvals screens exist but are not mounted in the shell (see `CLAUDE.md`). Do not mount or restructure without asking.

## Interaction Rules

- **Destructive actions** (revoke, reject, forget device): confirmation dialog, `dangerSoft` action, explicit consequence copy.
- **Approvals:** show exact action, target, risk, expiry; approve disabled at `00:00`; expiry auto-rejects and notifies. Never one-tap approve without displaying target.
- **Copy affordances** on keys, targets, IPs (snackbar confirm).
- **Loading:** inline spinner in the control that triggered it (`strokeWidth: 2`); no full-screen blockers for cached data.
- **Offline:** cached data stays visible; banner explains cause and next action (same network / hotspot fallback).
- **Empty states:** icon in circular `gunmetal` well + heading + one-line guidance + primary CTA.

## Motion

- Duration ≤250ms for transitions; ambient loops (status pulse, voice rings) are decorative only.
- Honor `MediaQuery.disableAnimations`: stop pulses/rings, show static state.
- Target 60fps on low-end Android; avoid `saveLayer`-heavy effects (blur, opacity stacks) in lists.

## Accessibility

- Min tap target 48×48dp (use `constraints` on `IconButton`s; avoid `Size.zero` on primary actions).
- Contrast ≥4.5:1 for body text; `steel` on `obsidian` is for secondary text only.
- `tooltip`/`Semantics` label on every icon-only button.
- Status conveyed by text + icon, never color alone.
- Support 200% text scale without clipping; use `Expanded`/`Flexible`, not fixed widths.

## Copy Style

- Sentence case for UI, UPPERCASE only for section overlines.
- Verb-first buttons: `Pair Desktop`, `Sign & Approve`, `Revoke All`.
- Errors: what happened + what to do. No raw exception strings to users.
- Canonical strings (tests depend on them; change with tests): `No Desktop Paired`, `Connection Lost…`, `Allow pairing?`, `Revoke All Pairings?`, `Sign & Approve`, `Capture Fresh`, `Use Transcript`, `Risk Level: <level>`.
- Never claim transport encryption (no TLS). "Ed25519 Signed" is accurate; "Encrypted" labels are a known inaccuracy: flag, don't spread.

## Platform Guards

- Preserve `kIsWeb` guards in storage/crypto/db/mDNS paths.
- Camera permission via `permission_handler`; handle denied/permanently denied with settings deep-link.
- Use `SafeArea` on all bottom sheets.

## Testing UI

- Every screen/widget: widget test in `mobile/test/` (`phaseN_widget_test.dart` convention).
- Init `sqfliteFfiInit()` + `FlutterSecureStorage.setMockInitialValues({})`; `WebSocketClient().disconnect()` in tearDown.
- Assert on canonical strings and icons; avoid golden tests until tokens are frozen.
- `flutter analyze` must be clean before UI work is done.

## Change Control

- New color/type/spacing value → add to this file first.
- Security surfaces (approval sheet/inbox, revoke dialogs, pairing) → ask before restyle.
- Update this file in the same change when a token or component contract changes.
