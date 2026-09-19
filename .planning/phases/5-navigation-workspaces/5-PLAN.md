# Phase 5 Plan: Navigation Shell & Workspaces Dashboard

## Requirements Covered
- **UI-01**: 5-Destination persistent Navigation Shell (`Workspaces`, `Observe`, `Command`, `Approvals`, `Settings`).
- **UI-02**: Active Workstation Dashboard Card with real-time connectivity badges (online/reconnecting/offline) and ping latency.
- **UI-03**: Multi-Device Switcher & management interface.
- **UI-04**: Validated manual connection modal with IP, Port, and Token inputs.

---

## Plan Waves & Tasks

### Wave 1: Telemetry & Measurement Foundation
- [ ] Task 1.1: In `mobile/lib/core/network/websocket_client.dart`, expose `latencyNotifier` calculating round-trip ping/pong duration in ms, and expose `activeMachineName`.

### Wave 2: Dashboard UI Components
- [ ] Task 2.1: Create `mobile/lib/features/workspaces/presentation/widgets/active_workstation_card.dart` with pulsing green/amber/red status badges, latency display, and action buttons.
- [ ] Task 2.2: Create `mobile/lib/features/workspaces/presentation/widgets/manual_connect_dialog.dart` with input validation, clipboard paste, and quick connect.
- [ ] Task 2.3: Create `mobile/lib/features/workspaces/presentation/workspaces_dashboard_screen.dart` with active workstation card, saved devices list, and empty-state pairing prompt.

### Wave 3: App Navigation Shell & Routing
- [ ] Task 3.1: Create `mobile/lib/features/settings/presentation/settings_screen.dart` displaying device identity and security options.
- [ ] Task 3.2: Update `mobile/lib/core/router/app_router.dart` to mount `MainNavigationShell` with 5 persistent tabs at `/`.

### Wave 4: Validation
- [ ] Task 4.1: Run `flutter analyze` in `mobile/` and verify 0 errors.
- [ ] Task 4.2: Validate tab transitions and connection flow in running Flutter app.
