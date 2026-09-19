# AGENTS.md

Welcome to **LocalLoop** (Ghost-Link). This document provides architectural context, conventions, repository map, build/test commands, and security guidelines for AI coding agents collaborating on this codebase.

---

## 1. Project Overview & Core Value

**LocalLoop** is a local-first, application-aware remote control plane for autonomous AI coding agents running on a developer's Windows workstation. It frees developers from being tethered to their desks while maintaining strict security boundaries.

### Core Value Proposition
- **Observe Mode**: Supervise live agent logs, terminal outputs, syntax-colored file diffs, active window status, and on-demand screenshots directly from a mobile device.
- **Control Mode**: Send structured text or voice follow-up instructions, pause/cancel execution, and approve high-risk actions.
- **Security-First**: Ed25519 challenge-response handshake, signed request/approval envelopes, and zero raw remote shell execution.

---

## 2. Architecture & Process Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          LOCAL NETWORK (LAN / mDNS)                         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ WebSocket (Encrypted / Ed25519)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                 HOST BACKEND (Windows Dual-Process Architecture)            │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ 1. LocalLoop.Service (Background Service / Session 0)                 │  │
│  │    • WebSocket Server (Port 8080, Multi-frame MemoryStream)           │  │
│  │    • mDNS Zeroconf Advertiser (_localloop._tcp)                       │  │
│  │    • SQLite Append-Only Event Store (WAL Mode)                        │  │
│  │    • Policy Engine & Risk Classification                              │  │
│  │    • PairingManager (Ed25519 Challenge/Response, DPAPI Secret Store)  │  │
│  └───────────────────────────────────┬───────────────────────────────────┘  │
│                                      │ Named Pipe IPC                       │
│                                      │ (LocalLoop_ControlPipe)              │
│  ┌───────────────────────────────────▼───────────────────────────────────┐  │
│  │ 2. LocalLoop.Bridge (Foreground Interactive Systray / User Session)   │  │
│  │    • Windows Forms Systray & Desktop Pairing Window (QR Code)         │  │
│  │    • Adapters: Process Control, FlaUI (UI Automation), Screenshot    │  │
│  │    • Interactive User Prompts & Native OS Integration                 │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                       ▲
                                       │ WebSocket (Port 8080)
┌──────────────────────────────────────┴──────────────────────────────────────┐
│                  MOBILE COMPANION APPLICATION (Flutter / Dart)               │
│  • 5-Destination Shell: Workspaces, Observe, Command, Approvals, Settings    │
│  • Workspaces Dashboard: Active workstation card with live ping latency (ms)│
│  • Observe Surface: Filter chips (All/Logs/Diffs/Terminal/Errors), DiffView │
│  • Command Composer: Voice dictation waveform & parameter constraints        │
│  • Approval Inbox: Rich detail sheet, 2-minute countdown timer & auto-reject│
│  • Offline-First SQLite (WAL Mode) & Background Telemetry Ingest Queue       │
│  • Cryptography: Ed25519 keypair in Secure Keystore & Signed Action Envelope│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Technology Stack & Dependencies

### Windows Backend (.NET 8)
- **Framework**: .NET 8 (`net8.0`, `net8.0-windows`)
- **Cryptography**: `NSec.Cryptography` (libsignal/libsodium Ed25519 bindings)
- **Discovery**: `Makaretu.Dns.Multicast` (Zeroconf / mDNS)
- **Storage**: `Microsoft.Data.Sqlite` + `Dapper` (WAL Mode enabled)
- **UI Automation**: `FlaUI.Core`, `FlaUI.UIA3`
- **IPC**: `System.IO.Pipes.NamedPipeServerStream` (Asynchronous, multi-instance)

### Mobile Client (Flutter / Dart)
- **SDK**: Flutter `>=3.0.0 <4.0.0`
- **State Management & Routing**: `flutter_riverpod`, `go_router`
- **Cryptography**: `cryptography` (Ed25519, SHA-256)
- **Storage**: `flutter_secure_storage`, `sqflite` (WAL Mode), `shared_preferences`
- **Networking**: `web_socket_channel`, `multicast_dns`
- **Scanner & Hardware**: `mobile_scanner`, `permission_handler`

---

## 4. Repository Structure

```
Ghost-Link/
├── src/
│   ├── LocalLoop.Core/          # Shared models (CommandIntent, Events, IPC DTOs)
│   ├── LocalLoop.Service/       # Background host service (WebSockets, mDNS, Policy, SQLite)
│   ├── LocalLoop.Bridge/        # Interactive desktop systray, QR pairing UI, adapters
│   └── LocalLoop.Tests/         # xUnit test suite (IPC, SQLite, Security, Multi-frame WS)
├── mobile/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── network/         # WebSocketClient, SignedEnvelope, connection supervisor
│   │   │   ├── router/          # app_router.dart (MainNavigationShell, 5 destinations)
│   │   │   └── security/        # CryptoManager (Ed25519), DeviceManager (SavedDevice)
│   │   ├── data/database/       # AppDatabase (sqflite WAL), IsolateWorker (batching queue)
│   │   └── features/
│   │       ├── workspaces/      # Dashboard, ActiveWorkstationCard, ManualConnectDialog
│   │       ├── observe/         # ObserveScreen, CodeDiffViewer, ScreenshotPreviewer
│   │       ├── command/         # CommandComposerScreen, VoiceDictationModal, ApprovalInbox
│   │       └── settings/        # SettingsScreen, device identity, policy inspector
│   ├── test/                    # Widget test suites (Phase 3, Phase 5, Phase 6, Phase 7)
│   ├── android/                 # Android platform host & permissions (AndroidManifest.xml)
│   ├── ios/                     # iOS platform host & permissions (Info.plist)
│   └── windows/                 # Windows desktop platform host
├── .planning/                   # GSD roadmap, requirements, phase plans, and validations
├── AGENTS.md                    # This document
└── GEMINI.md                    # Project rules & GSD workflow directives
```

---

## 5. Development & Testing Commands

### Host Backend (.NET)
```powershell
# Build entire solution
dotnet build

# Run unit and integration tests
dotnet test

# Run the Background Service
dotnet run --project src/LocalLoop.Service/LocalLoop.Service.csproj

# Run the Systray Desktop Bridge
dotnet run --project src/LocalLoop.Bridge/LocalLoop.Bridge.csproj
```

### Mobile App (Flutter)
```powershell
# In ./mobile directory:
cd mobile

# Install / update dependencies
flutter pub get

# Run static analysis (must remain at 0 errors)
flutter analyze

# Run widget and unit tests
flutter test

# Run on Windows Desktop
flutter run -d windows

# Run on connected Mobile Device / Emulator
flutter run
```

---

## 6. Security & Cryptographic Invariants

1. **Zero-Token Fallback Backdoor**: Initial pairing strictly requires an ephemeral, cryptographically random pairing token generated by the Desktop Bridge and exchanged via QR code. Hardcoded fallbacks are strictly prohibited.
2. **Ed25519 Handshake & Envelope Sealing**:
   - Host sends random `auth_challenge` string.
   - Client signs with private key; Host verifies with device public key.
   - All high-impact actions (`command_request`, `approval_response`) must be sealed in a `SignedEnvelope` containing canonical JSON digest, timestamp, and signature.
3. **Replay Attack Window**: Timestamps skewed by $>30$ seconds are rejected by `Worker.cs`.
4. **Session 0 Safety**: Windows Service runs in background; all interactive UI (screen capture, message boxes, FlaUI) must execute in `LocalLoop.Bridge` via Named Pipe IPC.
5. **Mobile Permissions**: Mobile camera permissions are declared in `AndroidManifest.xml` and `Info.plist`, and requested at runtime via `permission_handler`.

---

## 7. GSD Workflow & Planning Directives

All changes should follow GSD milestones and phase tracking:
- Discuss & plan phases: `/gsd-discuss-phase <N>`, `/gsd-plan-phase <N>`
- Execute plans: Follow atomic commits per phase.
- Validate phases: `/gsd-validate-phase <N>` to maintain 100% Nyquist test compliance.
