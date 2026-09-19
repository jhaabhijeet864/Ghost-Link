# Phase 5: Navigation Shell & Workspaces Dashboard — Context

## Objective
Establish a unified 5-tab application shell (`Workspaces`, `Observe`, `Command`, `Approvals`, `Settings`) and build the Workspaces Dashboard with real-time workstation status, auto-reconnection, and multi-device switching.

---

## Locked Architectural Decisions

### 1. App Navigation Shell & Startup Flow
- **5-Tab Navigation Structure**:
  - Tab 0: **Workspaces** (Home dashboard, active workstation card, saved devices list, pair new desktop button)
  - Tab 1: **Observe** (Live agent logs, diffs, terminal outputs, screenshots)
  - Tab 2: **Command** (Intent composer, voice dictation, execution constraints)
  - Tab 3: **Approvals** (Pending sensitive approvals, risk assessment, 2m countdown, one-tap signed approval)
  - Tab 4: **Settings** (Device identity, Ed25519 fingerprint, security policy inspector, pair revocation)
- **Startup Behavior**:
  - The app launches directly into the 5-tab shell with `Workspaces` as the active home tab.
  - If no devices are saved, the `Workspaces` tab displays a sleek dark empty state card with a prominent "Pair New Desktop" CTA.
  - If a device is paired, the shell persists the active session context across tab transitions using `IndexedStack` so state (like ongoing logs or command drafts) is never lost.

### 2. Auto-Reconnection & Heartbeat
- **Automatic Reconnection**:
  - On app launch, if a previously paired workstation exists in `DeviceManager` / `SharedPreferences`, the app automatically attempts to re-establish the connection in the background.
  - Resolves via mDNS Zeroconf discovery (`_localloop._tcp`) or falls back to the last known IP/port.
- **Heartbeat & Latency Telemetry**:
  - WebSocket client tracks live ping/pong round-trip latency in milliseconds.
  - Status indicators:
    - **Pulsing Green**: Connected (`WebSocketState.Open`), latency $<100$ms.
    - **Amber Pulse**: Reconnecting / searching on LAN via mDNS.
    - **Red**: Disconnected / Offline.

### 3. Active Workstation Card & Multi-Device Switcher
- **Workstation Card Component**:
  - Displays host computer name (e.g. `PREADATOR-LocalLoop`), active project directory, and live connectivity badge with latency (ms).
  - Quick actions: Disconnect, Switch Device, Quick Ping.
- **Multi-Device List**:
  - Displays all saved workstations with last connected timestamps and IP addresses.
  - One-tap switching between workstations.
  - Swipe-to-delete or delete icon to remove obsolete workstations.

### 4. Pairing & Manual Connection Modal
- **Pairing Options Modal**:
  - Triggered via "Pair New Desktop" button.
  - Option 1: **Scan QR Code with Camera** (triggers native Android/iOS system camera permission request).
  - Option 2: **Manual Entry / Paste URL**:
    - Dark modal with inputs for IP Address, Port, and One-Time Pairing Secret.
    - "Paste from Clipboard" button that auto-parses `localloop://pair?token=...&ip=...&port=...`.
    - "Quick Connect to Localhost (8080)" button for local development and testing.

---

## Downstream Deliverables for Planning
1. `mobile/lib/core/router/app_router.dart`: Update `MainNavigationShell` to 5 tabs with icons and labels.
2. `mobile/lib/features/workspaces/presentation/workspaces_dashboard_screen.dart`: New primary home screen.
3. `mobile/lib/features/workspaces/presentation/widgets/active_workstation_card.dart`: Workstation telemetry card.
4. `mobile/lib/features/workspaces/presentation/widgets/manual_connect_dialog.dart`: Input modal for IP/Port/Token.
5. `mobile/lib/core/network/websocket_client.dart`: Expose latency stream and connection state.
