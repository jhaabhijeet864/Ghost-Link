# MOBILE_UI_UX_SPEC.md

## LocalLoop Mobile Application UI/UX Specification

**Product:** LocalLoop  
**Platform:** Flutter mobile application  
**Purpose:** Define the complete mobile UI, UX, interaction model, visual system, screen behavior, component system, accessibility standards, and implementation contract for the LocalLoop remote coding-agent control plane.  
**Audience:** AI coding agents, designers, Flutter developers, reviewers, and maintainers.  
**Status:** Implementation-ready product UI specification  

---

## 1. Product UI Thesis

LocalLoop is not a remote desktop and must not look like one.

The mobile application is a calm, trustworthy command center for development activity running on a Windows workstation. It should help users answer three questions immediately:

1. **What is happening?**
2. **Where is it happening?**
3. **What can I safely do next?**

The UI must convert complex technical state into focused, readable, actionable information. Raw logs, screenshots, terminal output, and automation evidence are secondary views. The primary experience is structured development context.

### Core product promise

> Leave the desk without losing control of your coding agent.

### UX personality

- Calm.
- Precise.
- Technical without being intimidating.
- Trustworthy.
- Focused.
- Honest about uncertainty.
- Dense when useful, never cluttered.
- Fast to understand with one hand.

### UX anti-goals

Do not make the app feel like:

- A generic admin dashboard.
- A remote desktop.
- A terminal emulator with a mobile skin.
- A noisy observability platform.
- A chatbot that hides execution details.
- A consumer social app.
- A collection of disconnected screens.

---

## 2. Non-Negotiable UI Rules

1. Every control action must show the target machine and workspace.
2. Every dangerous action must show exact effects before confirmation.
3. The user must never mistake cached data for live data.
4. The user must never mistake a screenshot for verified state.
5. The user must never mistake an agent plan for a guaranteed prediction.
6. The interface must distinguish running, waiting, blocked, failed, completed, cancelled, offline, degraded, stale, and uncertain states.
7. Primary actions must be reachable with one hand.
8. The application must remain understandable without screenshots.
9. Do not display raw logs as the default session experience.
10. Do not use color as the only state indicator.
11. Do not hide connection, permission, or policy limitations.
12. Do not show controls unsupported by the active adapter.
13. Do not use fake progress percentages.
14. Do not make destructive actions visually equivalent to harmless actions.
15. Do not show sensitive source code or commands in push notifications by default.
16. Do not create a screen until its loading, empty, offline, error, stale, and permission states are defined.
17. Every new user-visible behavior requires a widget test and a state test.
18. Every interaction must have a clear success, failure, and uncertain outcome.
19. No screen may silently change the selected machine, workspace, branch, or session.
20. The mobile UI must remain useful when the Windows machine is unavailable.

---

## 3. Information Architecture

Use a five-destination bottom navigation structure:

```text
Home       Active overview, alerts, machines, current work
Sessions   All active and recent coding sessions
Approvals  Pending and historical approvals
Workspaces Projects, repositories, branches, history
Settings   Devices, security, connectivity, preferences
```

### Bottom navigation rules

- Use five destinations maximum.
- Each destination has a clear icon and text label.
- Show badges only for meaningful counts.
- Approval badge displays pending approval count.
- Session badge displays active session count only when useful.
- Do not use a badge for ordinary unread logs.
- Preserve the selected destination across app restarts.
- Deep links may open a detail screen but must retain the correct destination context.

### Global navigation

Every detail screen must provide:

- Back navigation.
- Machine/workspace/session context.
- Connection indicator.
- Overflow menu for secondary actions.
- A predictable title.

### Global command access

Provide a global command action from Home and Session screens, but do not use a permanently dominant floating action button on every screen.

The global command entry point should be:

- A bottom-sheet composer on Home.
- A context-attached composer on Session detail.
- A workspace-aware composer on Workspace detail.

---

## 4. Visual Design System

## 4.1 Design direction

Use a dark-first visual system because developers commonly monitor sessions at night and because dark surfaces help logs and diffs remain legible. Also support a light theme and system theme.

The visual style should be:

- Dark graphite surfaces.
- Restrained blue or violet accent.
- Green for confirmed success.
- Amber for waiting or approval.
- Red for failure or blocked state.
- Gray for unavailable or stale state.
- No neon gradients as primary UI.
- No excessive glassmorphism.
- No decorative illustrations in operational screens.

## 4.2 Color tokens

Define semantic tokens, not raw colors in widgets.

```dart
class AppColors {
  static const background = Color(0xFF0B0F14);
  static const surface = Color(0xFF121821);
  static const surfaceElevated = Color(0xFF19222D);
  static const surfacePressed = Color(0xFF222E3B);
  static const border = Color(0xFF2A3745);
  static const textPrimary = Color(0xFFF2F5F7);
  static const textSecondary = Color(0xFFAAB6C2);
  static const textMuted = Color(0xFF72808D);
  static const accent = Color(0xFF7C9CFF);
  static const success = Color(0xFF42C98A);
  static const warning = Color(0xFFF2B84B);
  static const danger = Color(0xFFF06C73);
  static const info = Color(0xFF61B7E8);
  static const neutral = Color(0xFF8794A1);
}
```

These are starting tokens. Validate contrast before release.

### State color semantics

| State | Color | Icon style | Text treatment |
|---|---|---|---|
| Running | Accent or info | Animated activity icon | “Running” |
| Waiting | Warning | Clock or pause icon | “Waiting” |
| Approval required | Warning | Shield/check icon | “Needs approval” |
| Completed | Success | Check icon | “Completed” |
| Failed | Danger | Error icon | “Failed” |
| Blocked | Danger | Stop icon | “Blocked” |
| Offline | Neutral | Cloud-off icon | “Offline” |
| Stale | Neutral/warning | History icon | “Stale” |
| Uncertain | Warning | Question/alert icon | “Uncertain” |
| Revoked | Danger | Lock icon | “Revoked” |

Never communicate state with color alone. Always pair color with icon and text.

## 4.3 Typography

Use a readable sans-serif for interface content and a monospace font only for code, commands, hashes, and logs.

Suggested type scale:

```text
Display:       30 px / 36 px
Screen title:  24 px / 30 px
Section title: 18 px / 24 px
Card title:    16 px / 22 px
Body:          15 px / 22 px
Secondary:     13 px / 18 px
Caption:       12 px / 16 px
Code:          13 px / 20 px
```

Rules:

- Use sentence case.
- Avoid all-caps labels except compact status badges where necessary.
- Do not use more than two font weights in one component.
- Use monospace only for technical values.
- Preserve line height for accessibility.
- Support system text scaling without clipping.

## 4.4 Spacing

Use an 8-point spacing system:

```text
4   Micro spacing
8   Small spacing
12  Compact spacing
16  Standard spacing
20  Section spacing
24  Large spacing
32  Screen section spacing
40  Major separation
```

Do not use arbitrary values unless required by platform controls or visual assets.

## 4.5 Shapes and elevation

- Default card radius: 16 px.
- Compact control radius: 10–12 px.
- Bottom sheet radius: 24 px top corners.
- Buttons: 12–14 px radius.
- Avoid excessive shadows.
- Use elevation sparingly and consistently.
- Use borders to separate dark surfaces instead of heavy shadows.

## 4.6 Motion

Motion should communicate state, not decorate the interface.

Use:

- 150–200 ms for small state changes.
- 200–300 ms for navigation transitions.
- Subtle pulse for running connection indicators.
- No infinite animation for completed or failed states.
- Reduced-motion support.
- Skeleton loading only when loading is expected to last more than a brief moment.

Never animate log lines aggressively or make the user chase moving content.

---

## 5. Core Domain Objects in the UI

The UI must consistently represent these objects:

### Machine

A Windows workstation that runs the orchestration agent.

Display:

- Name.
- Online state.
- Windows session state.
- Agent state.
- Desktop bridge state.
- Last synchronization time.
- Active session count.

### Workspace

A project, repository, folder, or configured development environment.

Display:

- Name.
- Repository.
- Path, optionally abbreviated.
- Branch.
- Modified-file count.
- Health.
- Adapter.
- Active session count.

### Session

A bounded coding-agent activity instance.

Display:

- Session name or generated title.
- Status.
- Duration.
- Workspace.
- Branch.
- Adapter.
- Current activity.
- Last event.
- Pending approvals.

### Action

A concrete operation requested or performed by the agent or user.

Display:

- Action type.
- Exact command or instruction.
- Target.
- Risk.
- Approval state.
- Execution method.
- Result.

### Event

A timestamped development activity record.

Display:

- Time.
- Category.
- Summary.
- Details on expansion.
- Source.
- Result.

---

## 6. Application States

Every screen must support the following state model where applicable:

```text
initializing
loading
ready
empty
refreshing
offline
stale
degraded
permission_denied
error
recoverable_error
```

Every action must support:

```text
idle
submitting
accepted
running
completed
failed
cancelled
expired
uncertain
```

### State presentation rules

- `loading`: show a meaningful skeleton, not a blank screen.
- `empty`: explain why it is empty and provide the next action.
- `offline`: show cached content with an offline banner.
- `stale`: show last synchronization time and disable unsafe actions.
- `degraded`: show which capability is unavailable.
- `permission_denied`: explain the missing permission and provide a route to settings.
- `error`: show a human-readable explanation and recovery action.
- `uncertain`: stop automatic retries and explain why.

---

## 7. Screen Specifications

## 7.1 Welcome screen

### Purpose

Explain the product in one glance and begin setup.

### Layout

```text
[LocalLoop mark]

Your coding agent does not need you at the desk.

Monitor sessions, review changes, respond to failures,
and approve actions from your phone.

[Set up Windows machine]
[I already have a paired machine]
[Explore demo]

Local-first · Your code stays on your machine
```

### Rules

- Do not show technical architecture on the first screen.
- Do not require cloud account creation before local setup.
- Include a link to privacy and security overview.
- The primary action must be visually clear.

### Empty and error states

- If setup cannot continue, show an actionable diagnostic.
- Do not display a generic “Something went wrong.”

## 7.2 Permission education screen

### Purpose

Explain permissions before requesting them.

### Layout

```text
A few permissions make LocalLoop useful

Notifications
Know when sessions fail or need approval.

Microphone
Use voice instructions after reviewing the transcription.

Camera
Scan the secure pairing QR code.

[Continue]
[Not now]
```

### Rules

- Explain each permission in product language.
- Request permissions just in time.
- Never imply that refusing a permission breaks unrelated features.

## 7.3 Home screen

### Purpose

Provide an immediate operational overview.

### Layout

```text
Good evening, Rajesh

[Connection summary: 1 machine online]

Needs attention                         See all
[Approval card]

Active sessions                         See all
[Session card]
[Session card]

Machines                                See all
[Machine card]

Recent activity                         See all
[Activity rows]

[Command action]
```

### Home hierarchy

1. Critical attention.
2. Active sessions.
3. Machine connectivity.
4. Recent activity.
5. Secondary shortcuts.

### Home cards

#### Attention card

Use only for:

- Pending approval.
- Agent blocked.
- Critical failure.
- Security warning.
- Machine unavailable during an active session.

Do not use attention cards for ordinary progress.

#### Active session card

Show:

- Session title.
- Workspace.
- Machine.
- Status.
- Current activity.
- Duration.
- Latest meaningful event.
- Primary next action.

Example:

```text
CRM API
Running · 8m 42s
Rajesh-Workstation · feature/timeouts
Running integration tests

[Open session]
```

#### Machine card

Show:

```text
Rajesh-Workstation
Online · Desktop bridge ready
2 active sessions
Last sync just now
```

### Home actions

- Tap card: open detail.
- Long press: secondary actions only if discoverable.
- Pull to refresh: reconnect and refresh events.
- Command action: open workspace/machine-aware composer.

### Home empty state

```text
No active coding sessions

Start a session from a detected workspace,
or continue work from your Windows machine.

[View workspaces]
[Pair a machine]
```

## 7.4 Machine list screen

### Purpose

Show all paired Windows machines.

### Layout

```text
Machines                                  [+]

[Online machine card]
[Offline machine card]
[Revoked or attention card]
```

### Machine card content

- Machine name.
- Status.
- Agent status.
- Desktop bridge status.
- Active sessions.
- Last seen.
- Connection type.
- Security indicator.

### Machine detail

Sections:

- Overview.
- Active sessions.
- Workspaces.
- Diagnostics.
- Devices and access.
- Connection settings.

### Machine actions

- Open workspace.
- Run diagnostics.
- Rename machine.
- Configure notifications.
- Manage access.
- Revoke device.
- Remove machine.

### Machine removal warning

Removing a machine from the phone must explain whether it revokes the phone, removes only local pairing data, or affects other devices. Never use ambiguous “Delete machine” language.

## 7.5 Pairing flow

### Step 1: Select pairing method

```text
Add a Windows machine

Scan a QR code from the LocalLoop companion,
or enter a short pairing code.

[Scan QR code]
[Enter pairing code]
```

### Step 2: Scan

Show camera view with:

- Corner guides.
- Instruction.
- Manual-code fallback.
- Permission route.

### Step 3: Verify identity

```text
Confirm this is your machine

Machine: Rajesh-Workstation
Connection: Local network
Verification phrase: BLUE RIVER 482

Confirm the same phrase is shown on Windows.

[Confirm and pair]
[Cancel]
```

### Step 4: Permission mode

```text
Choose initial access

Observe only
View sessions, logs, tests, and diffs.

Observe and control
Send instructions and manage sessions.

[Continue]
```

Default to observe-only when uncertain.

### Step 5: Completion

```text
Machine paired

Rajesh-Workstation is ready.

[Discover workspaces]
[Go to home]
```

## 7.6 Workspace list screen

### Purpose

Present projects as meaningful development contexts.

### Layout

```text
Workspaces                                [Search]

[All] [Healthy] [Needs attention] [Active]

[Workspace card]
[Workspace card]
```

### Workspace card

```text
CRM API
feature/timeouts · 7 modified files
2 failing tests · 1 active session
Rajesh-Workstation
```

### Workspace detail

Header:

```text
CRM API
D:\Projects\crm-api
feature/timeouts
```

Sections:

- Health summary.
- Active session.
- Recent sessions.
- Changed files.
- Tests.
- Branch and repository.
- Policies.
- Adapter.

### Workspace actions

- Start session.
- Open active session.
- Review diff.
- View tests.
- Configure policies.
- Change adapter.
- Rename workspace.
- Archive workspace.

### Workspace safety

Before sending a command, show:

```text
Target workspace
CRM API · feature/timeouts
```

If branch or path changes while the composer is open, invalidate the draft confirmation and require review again.

## 7.7 Session list screen

### Purpose

Show active and historical coding sessions.

### Filters

- All.
- Active.
- Waiting.
- Failed.
- Completed.
- Cancelled.
- Needs attention.

### Session card

```text
Fix timeout handling
Running · 8m 42s
CRM API · feature/timeouts
Running integration tests
Last update 12s ago
```

Use a compact status icon, text label, and timestamp.

### Session list empty state

```text
No sessions match this filter.

[Clear filters]
```

## 7.8 New session screen

### Purpose

Start a task with explicit context and policy.

### Layout

```text
New coding session

Machine
[Rajesh-Workstation      >]

Workspace
[CRM API · feature/timeouts >]

Agent or adapter
[Antigravity Desktop      >]

Instruction
[Describe what you want the agent to do...]

Context
[Current error] [Changed files] [Latest diff]

Execution policy
[Ask before risky actions >]

Notifications
[Failures] [Approvals] [Completion]

[Review and start]
```

### Instruction field

- Multiline.
- Character count only when useful.
- Voice button.
- Saved-template button.
- Clear button.
- Do not auto-send on transcription completion.

### Review screen

Before starting:

```text
Review session

Target
Rajesh-Workstation · CRM API
Branch
feature/timeouts
Adapter
Antigravity Desktop

Instruction
Fix the timeout handling and run the local test pipeline.

Constraints
Do not commit or push.

Potential operations
Modify files · Run tests
Risk
Medium

[Start session]
[Edit]
```

## 7.9 Session detail screen

### Purpose

Primary supervision interface.

### Header

```text
<  Fix timeout handling       ⋮
   Running · 8m 42s
   CRM API · feature/timeouts
```

The header must remain compact and stable while content scrolls.

### Header actions

- Pause.
- Cancel.
- More.
- Connection status.

Dangerous actions must not be one tap away without confirmation.

### Session summary strip

```text
Current activity: Running integration tests
Changed: 7 files
Tests: 47 passed · 2 failed
Approvals: 0 pending
```

### Tabs

Use a horizontally scrollable tab bar or segmented navigation:

- Overview.
- Plan.
- Activity.
- Files.
- Tests.
- Diff.
- Terminal.
- Timeline.
- Evidence.

Do not place all tabs in a crowded bottom navigation.

### Overview tab

Sections:

1. Current activity.
2. Latest agent message.
3. Plan preview.
4. Test summary.
5. Changed-file summary.
6. Attention items.
7. Suggested next actions.

### Suggested next actions

Examples:

- Explain latest failure.
- Ask agent to fix failing tests.
- Review current diff.
- Pause after current step.
- Send follow-up instruction.

Suggestions must be contextual and must not execute automatically.

### Plan tab

Use a vertical step timeline:

```text
✓ Inspect timeout configuration
✓ Identify failing request path
● Modify retry handling
○ Run unit tests
○ Run integration tests
```

Show when the plan was last updated. Never show a fake percentage if the adapter does not provide one.

### Activity tab

Use event rows with category icons:

```text
[agent] 01:24:18 Updated client.ts
[test]  01:24:31 Test suite started
[warn]  01:25:02 Dependency missing
```

Tap an event to expand details.

Filters:

- All.
- Agent.
- Files.
- Tests.
- Commands.
- Approvals.
- Errors.
- System.

### Files tab

Group by:

- Modified.
- Added.
- Deleted.
- Renamed.

Each row shows:

- File name.
- Short path.
- Change summary.
- Additions/deletions.
- Last event.

Actions:

- Open diff.
- Ask agent about file.
- Copy path.
- Exclude from context.

### Tests tab

Show:

```text
Integration tests
Failed 2 · Passed 47 · Skipped 1
1m 12s

[Failure row]
[Failure row]

[Explain failures]
[Rerun failed tests]
```

Do not make rerun appear equivalent to explanation. Rerun may consume resources and require permission.

### Diff tab

Provide:

- Summary first.
- File list.
- Expandable file diff.
- Syntax highlighting.
- Horizontal scrolling for long lines.
- Copy action.
- Ask-agent action.
- Redaction where configured.

Use additions and deletions with text labels for accessibility, not color alone.

### Terminal tab

Default view:

- Current command.
- Working directory.
- State.
- Exit code.
- Collapsed output preview.

Expanded view:

- Monospace output.
- Search.
- Copy.
- Jump to end.
- Pause automatic scrolling.
- Clear local display only, without deleting audit data.

Do not provide arbitrary input controls unless the adapter explicitly supports interactive input and policy allows it.

### Timeline tab

Show a complete chronological history:

- User prompts.
- Transcribed voice input.
- Normalized commands.
- Agent actions.
- Approvals.
- Rejections.
- Files.
- Tests.
- Connection events.
- Automation evidence.

### Evidence tab

For UI Automation or visual fallback actions, show:

- Target application.
- Target window.
- Automation method.
- Preconditions.
- Action.
- Verification.
- Confidence.
- Timestamp.
- Optional cropped screenshot.

Use a warning banner when evidence is not proof of execution.

## 7.10 Command composer

### Purpose

Allow safe, context-aware intervention.

### Entry points

- Home.
- Workspace detail.
- Session detail.
- Error event.
- Failed test.
- Changed file.
- Approval rejection.

### Composer layout

```text
Send instruction

Target
CRM API · feature/timeouts

Attached context
[Latest error ×] [Changed files ×]

[Text input area........................]

[Mic] [Templates] [Attach context]

[Review instruction]
```

### Composer rules

- Target cannot be hidden.
- Context chips can be removed.
- Context changes invalidate a previous review.
- Voice transcription must appear in the text area.
- The send action is disabled for empty or unresolved targets.
- If disconnected, allow drafting but disable dispatch.
- Drafts may be saved locally but must be marked unsent.

### Command review screen

```text
Review instruction

Machine
Rajesh-Workstation
Workspace
CRM API · feature/timeouts
Session
Fix timeout handling

Instruction
Fix the two failing timeout tests.

Constraints
Do not change the retry limit.
Do not modify production configuration.

Detected operations
Modify files · Run tests
Risk
Medium

[Send instruction]
[Edit]
[Cancel]
```

### Dispatch result

Show a result sheet or inline state:

- Accepted.
- Rejected by policy.
- Waiting for approval.
- Failed to dispatch.
- Uncertain.

Never show “Sent” unless dispatch acknowledgement is confirmed.

## 7.11 Voice interaction

### Voice button states

```text
idle
listening
processing
transcribed
low_confidence
error
```

### Listening screen

```text
Listening

“Fix the timeout tests, but do not change the retry limit.”

[Stop]
```

### Transcription review

```text
Review transcription

Fix the timeout tests, but do not change the retry limit.

[Use this] [Record again] [Edit]
```

### Voice safety rules

- Never execute directly after speech ends.
- Show the original transcription.
- Show normalized interpretation.
- Show constraints extracted.
- Flag low-confidence words.
- Preserve the transcript in the audit trail when the command is sent.
- Allow deletion of local audio after transcription.

## 7.12 Approval inbox

### Purpose

Centralize actions that need user decisions.

### Layout

```text
Approvals                              2

[Urgent approval card]
[Approval card]

History
[Approved row]
[Rejected row]
```

### Approval card

```text
Install dependency
CRM API · Rajesh-Workstation
Requested 2m ago · Expires in 3m
Medium risk
```

### Approval detail

Show:

- Exact action.
- Exact command or instruction.
- Machine.
- Workspace.
- Branch.
- Agent.
- Why it was requested.
- Potential effects.
- Network access.
- Files affected.
- Policy that triggered approval.
- Expiration.
- Evidence.

Actions:

- Approve once.
- Approve for session.
- Reject.
- Ask for alternative.
- View policy.

### High-risk approval

For delete, push, force-push, production changes, secrets, or unknown scripts:

- Require explicit confirmation.
- Require biometric confirmation where available.
- Use a destructive color only for the final action.
- Display the exact target and command immediately above the action.
- Do not place approve and destructive reject controls too close together.

## 7.13 Workspace history

### Purpose

Let the user understand project activity over time.

### Layout

```text
CRM API

Health summary
7 modified files · 2 failing tests

Active session
[Session card]

Recent sessions
[Completed session]
[Failed session]
[Waiting session]

Repository
Branch · commits · remote state

[View diff]
[Start session]
```

### Session history card

Show final outcome, changed files, tests, duration, and whether a commit or push occurred.

## 7.14 Settings

Organize settings into sections rather than a long list.

### Settings sections

```text
Account and identity
Machines and devices
Permissions and policies
Connectivity
Notifications
Voice and AI
Privacy and data
Appearance
Diagnostics
About
```

### Device management

Show:

- Paired device name.
- Device type.
- Last activity.
- Permission scope.
- Revoke action.

### Permissions and policies

Use plain-language policy controls:

```text
Read status                         Allowed
Read diffs                         Allowed
Run tests                          Ask
Modify source files                Ask
Install dependencies               Ask
Delete files                       Always ask
Git push                           Always ask
Force-push                         Blocked
Production configuration           Blocked
```

Each policy row must explain its effect.

### Connectivity settings

Show:

- Current connection method.
- Encryption state.
- Relay status.
- Last successful handshake.
- Network diagnostics.
- Reconnect option.

### Privacy settings

Show:

- Source-code transmission policy.
- Screenshot retention.
- Voice-audio retention.
- Transcript retention.
- Telemetry status.
- Model-processing destination.
- Clear local cache.
- Export data.
- Delete local data.

## 7.15 Diagnostics screen

### Purpose

Turn failures into actionable information.

### Diagnostic categories

- Mobile app.
- Windows agent.
- Desktop bridge.
- Machine connection.
- Relay.
- Workspace.
- Adapter.
- Notifications.
- Voice.
- Permissions.

### Diagnostic result

```text
Desktop bridge
Status: Warning

The bridge is running, but the Windows session is locked.
Read-only session monitoring is available.
Interactive UI automation is unavailable.

[View details] [Refresh]
```

### Support bundle

Allow export of a redacted diagnostic bundle. Never include secrets or unredacted source code by default.

---

## 8. Reusable Component Library

Build the app from reusable components. Do not implement visually similar patterns separately on every screen.

### Required components

- `AppScaffold`.
- `AppBottomNavigation`.
- `AppTopBar`.
- `ConnectionBanner`.
- `MachineCard`.
- `WorkspaceCard`.
- `SessionCard`.
- `StatusBadge`.
- `StatusIcon`.
- `AttentionCard`.
- `EventRow`.
- `EventFilterBar`.
- `TimelineItem`.
- `MetricStrip`.
- `ContextChip`.
- `TargetContextHeader`.
- `RiskBadge`.
- `ApprovalCard`.
- `ApprovalEffectList`.
- `CommandComposer`.
- `VoiceButton`.
- `TranscriptionReviewCard`.
- `CommandReviewSheet`.
- `DiffViewer`.
- `LogViewer`.
- `TestSummaryCard`.
- `FileChangeRow`.
- `PlanStep`.
- `EvidenceCard`.
- `OfflineBanner`.
- `StaleDataLabel`.
- `EmptyState`.
- `ErrorState`.
- `SkeletonCard`.
- `ConfirmActionSheet`.
- `BiometricConfirmSheet`.
- `DiagnosticsRow`.
- `PermissionExplanation`.

### Component rules

Each component must define:

- Required properties.
- Optional properties.
- Loading state.
- Disabled state.
- Error state.
- Accessibility label.
- Tap behavior.
- Long-press behavior if supported.
- Analytics event if applicable.
- Widget tests.

---

## 9. Interaction Patterns

## 9.1 Bottom sheets

Use bottom sheets for:

- Quick filters.
- Context selection.
- Composer entry.
- Secondary actions.
- Short confirmation.

Do not put long policy explanations or complex diffs in a small bottom sheet.

## 9.2 Full-screen flows

Use full-screen routes for:

- Pairing.
- New session.
- Command review.
- Approval detail.
- Diagnostics.
- Diff inspection.
- Settings subsections.

## 9.3 Destructive confirmations

Use a confirmation page or large modal for high-risk actions. Include:

- Exact action.
- Target.
- Effects.
- Reversibility.
- Expiration if relevant.
- Final action button.

Do not confirm destructive actions with “Are you sure?” alone.

## 9.4 Swipe actions

Do not use swipe-to-delete or swipe-to-cancel for important operational actions. Users can trigger them accidentally.

## 9.5 Pull to refresh

Pull-to-refresh must:

- Request a current snapshot.
- Preserve visible scroll position where possible.
- Show refresh status.
- Not duplicate commands or sessions.

## 9.6 Search

Search should support:

- Machines.
- Workspaces.
- Sessions.
- Files.
- Timeline events.
- Commands.

Search results must retain target context.

---

## 10. Loading, Empty, Error, and Offline Designs

## 10.1 Loading

Use skeletons shaped like the final content:

- Session cards.
- Machine cards.
- Event rows.
- Summary metrics.

Do not show a spinner for an indefinite connection problem. Transition to a clear error or degraded state.

## 10.2 Empty

Every empty state must include:

- What is empty.
- Why it may be empty.
- The next useful action.

## 10.3 Error

Every error state must include:

- What failed.
- Whether work may still be running.
- What the user can do.
- A diagnostic route.
- Retry only when safe.

## 10.4 Offline

Offline banner:

```text
Offline
Showing cached data from 2 minutes ago.
New control actions are paused.
```

Actions:

- Retry.
- View diagnostics.
- Continue reading cached content.

## 10.5 Stale data

Every stale detail view must show:

```text
Last updated 4m ago
```

If an action depends on fresh state, require refresh before dispatch.

## 10.6 Degraded mode

Example:

```text
Connected, but desktop bridge unavailable
Native session monitoring continues.
UI automation actions are unavailable.
```

Do not hide unavailable capabilities.

---

## 11. Accessibility Specification

### Required accessibility behavior

- Every icon-only control has a semantic label.
- Every status uses icon, color, and text.
- Tap targets are at least 44×44 logical pixels.
- Text scales without clipping or hiding critical content.
- Diff additions and deletions have non-color labels.
- Screen readers can identify machine, workspace, session, status, and action.
- Focus order follows visual and task order.
- Bottom sheets announce their title and purpose.
- Destructive actions are announced as destructive.
- Loading and completion states are announced.
- Error messages are associated with the affected control.
- Motion can be reduced.
- Contrast meets WCAG AA target where practical.

### Technical Flutter requirements

- Use `Semantics` for composite status components.
- Use `ExcludeSemantics` only when an accessible equivalent is provided.
- Avoid text embedded only in images or screenshots.
- Test with TalkBack and VoiceOver.
- Test with large system font sizes.
- Test with reduced motion.
- Test with color-blind simulation.

---

## 12. Responsive and Device Rules

The mobile UI must support:

- Small phones.
- Large phones.
- Foldables where practical.
- Portrait as primary orientation.
- Landscape for diff and terminal inspection where useful.
- Safe areas and notches.
- Keyboard appearance.
- One-handed operation.

### Layout behavior

- Use adaptive spacing rather than fixed screen positions.
- Avoid horizontally clipped cards.
- Use horizontal scrolling only for technical content where necessary.
- Preserve context when the keyboard opens.
- Keep the primary action above the keyboard where practical.
- Use split view only on sufficiently wide devices.

---

## 13. State Management and UI Architecture

Use a feature-first architecture with explicit domain state.

```text
lib/
  core/
    theme/
    routing/
    widgets/
    errors/
    accessibility/
  domain/
    machines/
    workspaces/
    sessions/
    approvals/
    commands/
    events/
    policies/
  data/
    repositories/
    local/
    remote/
    protocol/
  features/
    home/
    machines/
    workspaces/
    sessions/
    approvals/
    composer/
    settings/
  services/
    notifications/
    voice/
    connectivity/
    analytics/
```

### State requirements

Use explicit state classes or sealed states for:

- Loading.
- Ready.
- Empty.
- Offline.
- Stale.
- Degraded.
- Error.
- Submitting.
- Uncertain.

Do not represent all states with nullable fields and ambiguous booleans.

### State ownership

- Domain state belongs in repositories and state notifiers/controllers.
- Widgets render state and dispatch intents.
- Widgets must not directly call transport clients.
- Navigation must respond to domain state intentionally.
- Authentication and pairing state must be separate from session state.
- Connection state must be observable globally.

### Optimistic UI

Only use optimistic updates for reversible, low-risk local interactions such as:

- Selecting filters.
- Expanding cards.
- Saving a draft locally.
- Marking a notification read locally.

Do not optimistically show that a command was executed, a file was changed, a session was cancelled, or an approval was accepted.

---

## 14. Navigation and Deep Links

Support deep links for:

- Approval request.
- Session.
- Workspace.
- Machine diagnostics.
- Failed test.
- Diff.
- Device revocation.

### Deep-link rules

- Validate that the target still exists.
- Validate permissions before showing content.
- Show stale or expired state if applicable.
- Do not execute an action simply because a deep link was opened.
- Approval deep links open review; they do not approve.
- Preserve back navigation to the originating destination.

---

## 15. Notification UX

### Notification categories

- Approval required.
- Session failed.
- Agent blocked.
- Session completed.
- Machine offline.
- Security warning.
- Session summary.

### Notification content

Use:

```text
CRM API needs approval
Install a development dependency on Rajesh-Workstation.
```

Avoid:

```text
Run npm install axios on D:\Projects\crm-api immediately.
```

unless the user explicitly enables detailed notification content.

### Notification actions

Allowed actions:

- Open review.
- Open session.
- View diagnostics.
- Mark read.

Do not approve or execute from a notification action directly. Open the review screen first, except for an explicitly configured low-risk action that has a documented policy.

---

## 16. Data Presentation Rules

### Logs

- Summarize by default.
- Preserve raw output behind expansion.
- Support search and copy.
- Show command boundaries.
- Group repeated lines.
- Highlight errors without hiding surrounding context.

### Diffs

- Summary before raw diff.
- File navigation.
- Expand/collapse sections.
- Preserve line numbers.
- Redact configured secrets.
- Do not render untrusted content as executable UI.

### Commands

- Use monospace.
- Allow horizontal scrolling.
- Show working directory.
- Show effects.
- Show exit state.
- Display whether the command was policy-approved.

### Timestamps

Use relative time for recent activity and absolute timestamps in detail views.

Example:

```text
12s ago
Sep 19, 2026, 11:36 PM IST
```

Respect the user’s local timezone.

---

## 17. Interaction Safety

### Safe action classification

#### Low-risk

- Read status.
- Read logs.
- Read diff.
- Request summary.
- Filter events.
- Open diagnostics.

#### Medium-risk

- Run tests.
- Restart a known development process.
- Modify source files.
- Install a development dependency.
- Pause or resume a session.

#### High-risk

- Delete files.
- Modify environment variables.
- Access secrets.
- Commit.
- Push.
- Force-push.
- Change production configuration.
- Run unknown scripts.
- Change firewall or system settings.

The UI must reflect risk through explanation and confirmation, not just color.

### Action preview template

```text
You are about to:

[Exact action]

On:
[Machine]

In:
[Workspace · branch]

Expected effects:
- [Effect]
- [Effect]

Reversible:
[Yes / No / Partially]

[Final action]
[Cancel]
```

---

## 18. Microcopy Standards

Use concise, direct language.

### Prefer

- “Waiting for approval.”
- “The machine is offline.”
- “The action could not be verified.”
- “No active sessions.”
- “Review before sending.”
- “Read-only monitoring is available.”
- “This command changes 3 files.”
- “The agent is waiting for input.”

### Avoid

- “Oops!”
- “Magic happened.”
- “Something went wrong.”
- “Trust us.”
- “Instantly control anything.”
- “The AI knows what to do.”
- “Done” when verification is incomplete.
- “Failed” when the session may still be running.

### Error message template

```text
[What happened]

[What it means for your work]

[What you can do next]

[Primary action] [Diagnostics]
```

Example:

```text
The desktop bridge could not find the expected prompt field.

The agent may still be running, but the follow-up instruction was not verified.

No automatic retry was performed.

[Inspect session] [View diagnostics]
```

---

## 19. UI Automation and Evidence Presentation

The mobile app must never imply that an automation click alone proves success.

### Evidence card

```text
Automation evidence

Target
Antigravity · conversation window

Method
Windows UI Automation

Action
Inserted follow-up instruction

Verification
Instruction appeared and session state changed

Confidence
Confirmed

Captured
11:36:14 PM

[View cropped evidence]
```

### Confidence values

- Confirmed.
- Probable.
- Uncertain.
- Failed.

### Evidence limitations

If the system captured only a screenshot, say:

```text
Visual evidence captured. Execution was not independently verified.
```

Do not label that result “Confirmed.”

---

## 20. Design Tokens and Flutter Implementation Contract

Create a central theme and token layer.

Required files:

```text
lib/core/theme/app_colors.dart
lib/core/theme/app_typography.dart
lib/core/theme/app_spacing.dart
lib/core/theme/app_radii.dart
lib/core/theme/app_theme.dart
lib/core/theme/app_icons.dart
lib/core/widgets/app_scaffold.dart
lib/core/widgets/status_badge.dart
lib/core/widgets/connection_banner.dart
lib/core/widgets/empty_state.dart
lib/core/widgets/error_state.dart
lib/core/widgets/skeleton_card.dart
```

### Widget contract

Every reusable widget must:

- Receive data through typed parameters.
- Avoid direct repository access.
- Support disabled state.
- Support accessibility labels.
- Avoid hard-coded machine or workspace text.
- Avoid hard-coded color values outside theme tokens.
- Avoid hard-coded spacing outside spacing tokens.
- Expose callbacks for user intents.
- Have widget tests for default, loading, error, and disabled states where applicable.

### Feature contract

Every feature must define:

```text
feature_state.dart
feature_controller.dart
feature_repository.dart
feature_screen.dart
feature_components.dart
feature_test.dart
```

Names may vary by project convention, but state, behavior, data access, and presentation must remain separable.

---

## 21. Required UI Test Matrix

Each major screen must be tested in these states:

| Screen | Ready | Loading | Empty | Offline | Error | Stale | Permission denied |
|---|---:|---:|---:|---:|---:|---:|---:|
| Home | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Machines | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Workspaces | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Sessions | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Session detail | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Approvals | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Composer | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Settings | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Diagnostics | Yes | Yes | Yes | Yes | Yes | Yes | Yes |

### Required interaction tests

- Pairing success.
- Pairing cancellation.
- Invalid pairing code.
- Expired pairing code.
- Machine selection.
- Workspace selection.
- Session creation review.
- Command transcription review.
- Command cancellation.
- Command dispatch success.
- Command dispatch rejection.
- Uncertain command result.
- Approval review.
- Approval expiration.
- Approval rejection.
- Biometric failure.
- Session pause confirmation.
- Session cancellation confirmation.
- Offline drafting.
- Reconnection.
- Deep-link approval opening.
- Diff expansion.
- Log search.
- Accessibility focus order.
- Large text layout.
- Reduced-motion behavior.

---

## 22. Visual QA Checklist

Before accepting any screen, verify:

### Structure

- Is the primary purpose obvious within three seconds?
- Is the primary action obvious?
- Is the target context visible?
- Is the information hierarchy correct?
- Is there unnecessary content above the important content?

### State

- Does the screen show connection state?
- Does it distinguish stale from live?
- Does it show loading, empty, error, and offline states?
- Does it avoid fake progress?
- Does it explain unavailable capabilities?

### Safety

- Are destructive actions clearly differentiated?
- Is exact command text visible before approval?
- Is the machine/workspace target visible?
- Is confirmation required when appropriate?
- Is uncertain execution represented honestly?

### Visual quality

- Are spacing tokens used consistently?
- Are cards aligned?
- Are text sizes readable?
- Are icons semantically meaningful?
- Is contrast sufficient?
- Is long text handled gracefully?
- Does the UI work with large text?
- Does the keyboard obscure the primary action?

### Interaction

- Does every tap have feedback?
- Are disabled actions explained?
- Can the user recover from mistakes?
- Are actions reversible where possible?
- Are loading actions protected from duplicate taps?

---

## 23. AI Vibe-Coding Instructions

AI agents implementing the mobile UI must follow this order.

### Before coding

1. Read `PRD.md`.
2. Read `RULES.md`.
3. Read this document.
4. Inspect current Flutter structure.
5. Locate existing theme and routing.
6. Identify reusable components.
7. Confirm the target screen and states.
8. Write a short UI implementation plan.
9. Define tests before production widgets.

### During coding

1. Add or update state tests first.
2. Add widget tests for the intended behavior.
3. Run the tests and confirm the expected failure.
4. Implement using existing design tokens.
5. Reuse existing components.
6. Avoid introducing a new visual pattern without documenting it.
7. Implement loading, empty, offline, stale, and error states.
8. Test large text and accessibility labels.
9. Keep the diff limited to the feature.
10. Do not replace the entire app shell to fix one screen.

### After coding

1. Run focused tests.
2. Run `flutter analyze`.
3. Run formatter checks.
4. Run affected integration tests.
5. Inspect screenshots on at least one small and one large device.
6. Check dark and light themes.
7. Check offline and permission-denied states.
8. Inspect the diff for unrelated changes.
9. Report what was tested and what was not.

### Prohibited vibe-coding behavior

AI agents must not:

- Generate a complete app shell without reading the existing code.
- Replace the theme with arbitrary colors.
- Add random gradients, glass cards, or animations.
- Use placeholder text in a production screen.
- Hide missing backend data with fake data without labeling it.
- Use `Opacity` or color changes as the only disabled-state signal.
- Put all logic inside widgets.
- Use `setState` for cross-feature state where the app architecture requires a controller.
- Hard-code machine, workspace, session, or user data.
- Add an unverified “success” state after a button tap.
- Build only the happy path.
- Leave dead buttons or fake navigation.
- Add screen-specific colors outside the theme.
- Create duplicated cards instead of reusable components.
- Rewrite unrelated routes or features.

---

## 24. Screen Implementation Sequence

This is an implementation dependency order, not permission to skip TDD.

1. App theme and tokens.
2. App shell and navigation.
3. Global connection state and banners.
4. Shared status, card, empty, error, and skeleton components.
5. Home dashboard.
6. Machines and pairing.
7. Workspaces.
8. Sessions.
9. Session detail and tabs.
10. Command composer.
11. Command review.
12. Approval inbox and approval detail.
13. Voice transcription review.
14. Diffs, tests, logs, and evidence.
15. Settings, policies, and devices.
16. Diagnostics.
17. Notifications and deep links.
18. Accessibility and responsive QA.

At each step, implement all relevant states rather than only the ready state.

---

## 25. Required Demo Data

Use deterministic fixture data for UI development and screenshot testing.

Required fixtures:

- No machines.
- One online machine.
- One offline machine.
- One machine with bridge unavailable.
- Healthy workspace.
- Workspace with failing tests.
- Running session.
- Waiting session.
- Approval-required session.
- Failed session.
- Completed session.
- Uncertain action.
- Large log output.
- Large diff.
- Empty approval inbox.
- Multiple pending approvals.
- Expired approval.
- Locked Windows session.
- Stale event stream.

Fixtures must not contain real credentials, source code, personal information, or live machine identifiers.

---

## 26. Recommended First UI Build

Build a complete, polished vertical experience with fixture data before wiring every backend operation:

```text
Home
  ↓
Active session card
  ↓
Session overview
  ↓
Failed test event
  ↓
Command composer
  ↓
Voice/transcription review
  ↓
Command review
  ↓
Approval detail
  ↓
Updated session state
  ↓
Diff and test results
```

This path must feel complete and coherent. It should demonstrate the product’s main value without becoming a remote desktop.

The fixture mode must visibly identify itself as demo or local fixture mode. Do not make fixture data look like a real connected workstation.

---

## 27. Definition of UI Done

A screen is complete only when:

- Its purpose is clear.
- Its target context is visible.
- Its loading state exists.
- Its empty state exists.
- Its offline state exists.
- Its stale state exists where relevant.
- Its error state exists.
- Its permission-denied state exists where relevant.
- Its primary action works or is explicitly disabled with an explanation.
- Its destructive actions are protected.
- Its accessibility labels exist.
- Its large-text layout works.
- Its dark and light themes work.
- Its widget tests pass.
- Its state tests pass.
- Its integration path is defined.
- Its copy is final enough for testing.
- It uses shared design tokens.
- It does not introduce an unrelated visual pattern.
- It has been checked on a small and large device.

The application is UI-complete only when the main journey is coherent from pairing through session supervision, intervention, approval, result inspection, and recovery.

---

## 28. Final Design Standard

LocalLoop should make complex engineering activity feel understandable, not simplistic.

The UI must show enough detail for trust while preserving focus:

- Summary before raw detail.
- Context before action.
- Preview before execution.
- Approval before risk.
- Verification after execution.
- Recovery after failure.
- History after completion.

The goal is not to make the interface flashy. The goal is to make a developer comfortable leaving the desk because the application clearly communicates what is happening, what it knows, what it does not know, and what the user can safely do next.
