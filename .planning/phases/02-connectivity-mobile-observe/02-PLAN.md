---
version: 1.0
phase: 02
slug: connectivity-mobile-observe
status: planned
autonomous: false
depends_on:
  - 01-infrastructure-event-model
files_modified:
  - mobile/pubspec.yaml
  - mobile/lib/main.dart
  - mobile/lib/core/router/app_router.dart
  - mobile/lib/core/security/crypto_manager.dart
  - mobile/lib/core/network/websocket_client.dart
  - mobile/lib/data/database/app_database.dart
  - mobile/lib/features/observe/presentation/observe_screen.dart
  - src/LocalLoop.Service/PairingManager.cs
  - src/LocalLoop.Service/WebSocketServer.cs
  - src/LocalLoop.Bridge/PairingWindow.cs
  - src/LocalLoop.Tests/WebSocketIntegrationTests.cs
requirements:
  - MOB-01
  - MOB-02
  - MOB-05
  - NET-01
  - SEC-01
must_haves:
  
  - "D-01:"
  - "D-02:"
  - "D-03:"
  - "D-04:"
  - "D-05:"
  - "D-06:"
  - "D-07:"
  - "D-08:"
  - "D-09:"
  - "D-10:"
  - "D-11:"
  - "D-12:"
  - "D-13:"
  - "D-14:"
  - "D-15:"
  - "D-16:"
  - "D-17:"
  - "D-18:"- "Secure pairing sequence successfully pairs Flutter app with Windows agent over LAN."
  - "App reconstructs state from event store efficiently upon connection."
  - "User can view live logs, active workspace, and agent status on phone."
---

# Phase 2: Connectivity & Mobile Observe

<verification_criteria>
- End-to-end pairing succeeds using deep links and WebSocket signature validation.
- Mobile UI accurately rebuilds state from SQLite event store upon connection.
- Global offline banner accurately displays when connection drops.
- Event offset syncing fetches missed events upon reconnect.
</verification_criteria>

<wave>
  <id>wave-1</id>
  <name>Secure Pairing Slices</name>
  <description>Initial scaffolding and cryptographic handshake</description>

  <task>
    <id>task-1</id>
    <title>Pairing Discovery and Mobile App Skeleton</title>
    <description><![CDATA[Set up the initial Flutter app and Windows QR code generation to establish the pairing handshake entry point.
Covers: 
- D-01: Discovery happens via QR code.
- D-02: Deep link format (localloop://pair?...).
- D-03: QR code embeds an ephemeral pairing token + IP address.
- D-07: Windows Desktop Bridge renders the QR code natively.]]></description>
    <read_first><![CDATA[
- .planning/phases/02-connectivity-mobile-observe/02-RESEARCH.md
- .planning/phases/02-connectivity-mobile-observe/02-PATTERNS.md
- src/LocalLoop.Bridge/Program.cs
- src/LocalLoop.Service/Worker.cs
    ]]></read_first>
    <action><![CDATA[
1. Create a new Flutter app in the `mobile/` directory. 
2. Add `go_router` and `app_links` to `pubspec.yaml`.
3. In `mobile/lib/main.dart` and `mobile/lib/core/router/app_router.dart`, configure routing to handle `localloop://pair` deep links and extract the `token`, `ip`, and `port` query parameters (D-02).
4. Create a default screen displaying the empty state heading "No Desktop Paired" and body "Scan the QR code on your Windows desktop bridge to connect LocalLoop." with a CTA button "Pair with Desktop" (D-01).
5. In Windows backend, create `src/LocalLoop.Service/PairingManager.cs` with a method `GeneratePairingToken()` that returns a string GUID.
6. Create `src/LocalLoop.Bridge/PairingWindow.cs` to fetch this token via IPC and use `QRCoder` to render a QR code containing the URI format: `localloop://pair?token=[TOKEN]&ip=[LOCAL_IP]&port=[PORT]` (D-03, D-07).
    ]]></action>
    <acceptance_criteria><![CDATA[
- Running `dotnet run --project src/LocalLoop.Bridge` displays a window with a QR code.
- Flutter app compiles successfully (`flutter build apk` or equivalent).
- Triggering the deep link on the Flutter app navigates to a screen that displays the extracted token, IP, and port on the UI (verifiable via Flutter widget tests searching for the text).
- `grep -q "No Desktop Paired" mobile/lib/core/router/app_router.dart` (or wherever the empty screen is defined) succeeds.
    ]]></acceptance_criteria>
    <dependencies>
      <dependency>none</dependency>
    </dependencies>
  </task>

  <task>
    <id>task-2</id>
    <title>Secure Ed25519 WebSocket Handshake</title>
    <description><![CDATA[Implement cryptographic key generation and WebSocket signature validation.
Covers: 
- D-04: Pairing uses Ed25519, stored in Flutter Secure Storage.
- D-06: Strictly 1:1 pairing.
- D-14: WebSockets authenticated via Ed25519 signature.
- D-07: Display "Allow pairing?" prompt.
- D-05: mDNS fallback for automatic IP rediscovery.]]></description>
    <read_first><![CDATA[
- src/LocalLoop.Bridge/PairingWindow.cs
- src/LocalLoop.Service/PairingManager.cs
    ]]></read_first>
    <action><![CDATA[
1. On Mobile, add `cryptography`, `flutter_secure_storage`, and `web_socket_channel` to `pubspec.yaml`.
2. Create `mobile/lib/core/security/crypto_manager.dart` that generates an Ed25519 keypair and saves the private key via `flutter_secure_storage` (D-04).
3. Create `mobile/lib/core/network/websocket_client.dart` that connects to the IP/port and sends an HTTP header `X-LocalLoop-Signature` containing the signed ephemeral token (D-14). Also, set up mDNS discovery fallback in case the initial IP changes (D-05).
4. On Windows, create `src/LocalLoop.Service/WebSocketServer.cs` using `System.Net.WebSockets` to accept connections.
5. Update `PairingManager.cs` to validate the `X-LocalLoop-Signature` against the provided token. Enforce 1:1 pairing (D-06). Upon success, trigger an IPC call to `PairingWindow.cs` to display the prompt text "Allow pairing?" (D-07).
6. On Mobile, transition to a "Connected" placeholder screen when the WebSocket connects successfully.
    ]]></action>
    <acceptance_criteria><![CDATA[
- C# test in `src/LocalLoop.Tests/WebSocketIntegrationTests.cs` (or manual test script) asserts that connections with invalid `X-LocalLoop-Signature` headers receive a 401 Unauthorized WebSocket closure.
- C# backend successfully verifies an Ed25519 signature generated by the Dart `cryptography` package.
- `grep -q "X-LocalLoop-Signature" mobile/lib/core/network/websocket_client.dart` succeeds.
- `grep -q "Allow pairing?" src/LocalLoop.Bridge/PairingWindow.cs` succeeds.
    ]]></acceptance_criteria>
    <dependencies>
      <dependency>task-1</dependency>
    </dependencies>
  </task>
</wave>

<wave>
  <id>wave-2</id>
  <name>Observe Mode Slices</name>
  <description>Event streaming, UI, and edge cases</description>

  <task>
    <id>task-3</id>
    <title>Observe Mode Event Streaming & UI (Happy Path)</title>
    <description><![CDATA[Complete vertical slice: stream JSON events from the service, save them in SQLite, and render them immediately on the screen.
Covers:
- D-11: WebSockets push events from Windows Service to Flutter.
- D-12: Event payload structured as JSON strings.
- D-15: Riverpod is the state management library.
- D-16: SQLite persists the append-only event stream locally.
- D-17: WebSocket pushes to SQLite first, triggering Riverpod provider update.]]></description>
    <read_first><![CDATA[
- src/LocalLoop.Service/WebSocketServer.cs
- mobile/lib/core/network/websocket_client.dart
- .planning/phases/02-connectivity-mobile-observe/02-UI-SPEC.md
    ]]></read_first>
    <action><![CDATA[
1. On Mobile, add `sqflite`, `path_provider`, and `flutter_riverpod` to `pubspec.yaml` (D-15, D-16).
2. Create `mobile/lib/data/database/app_database.dart` with an `events` table schema: `(id INTEGER PRIMARY KEY, session_id TEXT, type TEXT, timestamp TEXT, payload TEXT)` (D-16).
3. Update `websocket_client.dart` to receive events from Windows (D-11) and insert incoming JSON events (D-12) into `app_database.dart`.
4. Update `src/LocalLoop.Service/WebSocketServer.cs` to push JSON events in the format `{"id": 1, "session_id": "...", "type": "session_created", "timestamp": "...", "payload": "{...}"}` to connected clients.
5. Create `mobile/lib/features/observe/presentation/observe_screen.dart`. Define a Riverpod provider that queries rows from `app_database.dart` and triggers UI rebuilds (D-17) to render a list of event logs.
    ]]></action>
    <acceptance_criteria><![CDATA[
- Flutter unit test or log output confirms that receiving the JSON payload results in a successful `INSERT` into the `events` SQLite table.
- When the Windows service fires a mock `session_created` event over the WebSocket, the Flutter UI logs view automatically updates to display it.
- `grep -q "INSERT INTO events" mobile/lib/data/database/app_database.dart` (or equivalent query) succeeds.
    ]]></acceptance_criteria>
    <dependencies>
      <dependency>task-2</dependency>
    </dependencies>
  </task>

  <task>
    <id>task-4</id>
    <title>Edge Cases, Validation & Unpairing</title>
    <description><![CDATA[Implement offline syncing, connection error states, and device revocation.
Covers:
- D-08: Active paired devices listed in Windows system tray/window with Revoke options.
- D-09: Mobile app includes "Disconnect & Forget Desktop" button.
- D-10: Network isolation failures show a clear error suggesting a mobile hotspot fallback.
- D-13: Offline missed events reconstructed using "Sync from Offset".
- D-18: Connection status managed by a global Riverpod StateNotifier presenting an offline banner/icon.]]></description>
    <read_first><![CDATA[
- src/LocalLoop.Service/WebSocketServer.cs
- mobile/lib/features/observe/presentation/observe_screen.dart
- src/LocalLoop.Bridge/PairingWindow.cs
    ]]></read_first>
    <action><![CDATA[
1. On Mobile, create a global `StateNotifier` for WebSocket connection status (D-18). If disconnected, display an offline banner on `observe_screen.dart` with the text: "Connection Lost. Please ensure your desktop is on and connected to the same network. If network isolation prevents connection, try using a mobile hotspot as a fallback." (D-10).
2. Implement "Sync from Offset" logic (D-13): upon WebSocket connection, Mobile sends a message `{"action": "sync", "last_id": [highest_id_in_sqlite]}`. The Windows server replies with all events where `Id > last_id`.
3. Add a "Disconnect & Forget Desktop" button in the mobile app (D-09), with a confirmation dialog: "Disconnect: Are you sure you want to forget this desktop? You will need to pair again using a QR code." This deletes the Ed25519 key and clears the DB upon confirmation.
4. On Windows, update `PairingWindow.cs` to display a list of active devices with a "Revoke" button that deletes the paired public key (D-08).
    ]]></action>
    <acceptance_criteria><![CDATA[
- `grep -q "Connection Lost. Please ensure your desktop is on" mobile/lib/features/observe/presentation/observe_screen.dart` succeeds.
- `grep -q "Disconnect: Are you sure you want to forget this desktop?" mobile/lib/features/observe/presentation/observe_screen.dart` succeeds.
- Flutter widget test verifies that when the connection state provider emits `offline`, the error banner is rendered.
- Stopping the Windows service automatically displays the global offline banner on the mobile app.
- Reconnecting the mobile app automatically triggers a sync request sending its `last_id`.
    ]]></acceptance_criteria>
    <dependencies>
      <dependency>task-3</dependency>
    </dependencies>
  </task>
</wave>

