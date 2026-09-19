# Ghost-Link (LocalLoop)

A cross-platform remote control and monitoring system consisting of a Windows background service, a desktop bridge, and a Flutter mobile app.

## Architecture Overview

```
┌─────────────────┐     Named Pipes      ┌──────────────────┐
│  Mobile App     │◄────────────────────►│  Windows Service │
│  (Flutter)      │   WebSocket + mDNS   │  (.NET 8 Worker) │
└─────────────────┘                      └────────┬─────────┘
                                                   │
                                           Named Pipes (IPC)
                                                   │
                                           ┌───────▼────────┐
                                           │ Desktop Bridge │
                                           │  (Console App) │
                                           └────────────────┘
```

### Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| **LocalLoop.Service** | .NET 8 Worker Service | Background service, SQLite event store, WebSocket server, Named Pipes IPC |
| **LocalLoop.Bridge** | .NET 8 Console App | Desktop bridge, WPF pairing UI, connects to service via Named Pipes |
| **LocalLoop.Core** | .NET 8 Class Library | Shared models (`AppEvent`, `IpcMessage`, `CommandIntent`) |
| **LocalLoop.Tests** | xUnit | Unit & integration tests (98 tests passing) |
| **Mobile App** | Flutter 3.x / Dart | Mobile client: pairing, observe mode, command & control |

---

## Current Status (v0.5.0 - Pre-Alpha)

### ✅ Phase 1: Infrastructure & Event Model (Complete & Validated)
- Windows background service with SQLite event store (Dapper)
- Named Pipes IPC between Service ↔ Bridge
- Event persistence (`session_created`, etc.)
- **12 unit/integration tests passing**

### ✅ Phase 2: Connectivity & Mobile Observe (Code Complete & Tested)
- **Mobile App**: Pairing screen (QR code + manual entry), Observe screen (event stream with filter chips), Ed25519 crypto, WebSocket client with mDNS fallback
- **Windows**: WebSocket server with signature auth, PairingManager (1:1 device pairing), WPF QR code window
- **Mobile tests**: 32 widget tests passing
- **Flutter analyze**: 0 errors

### ✅ Phase 3: Command & Control Mode (Code Complete)
- **Mobile**: Command Composer (text + voice dictation + quick-action chips), Approval Inbox (drawer with 2-min countdown timer)
- **Windows**: Semantic Kernel AI intent parser (mock + LLM-ready), Policy Engine (Allow/Ask/Block), Audit Logger (JSONL)
- **IPC**: CommandRequest/ApprovalRequest/Response message types
- **Tests**: 11 comprehensive Worker command handling tests + 11 Phase 3 model tests

### ✅ Phase 4: Native & UI Automation Adapters (Framework Complete)
- **ProcessAdapter**: Buffered stdout/stderr via `System.Diagnostics.Process`
- **FlaUiAdapter**: UIA3 primary, UIA2 fallback for semantic window control
- **ScreenshotAdapter**: GDI+ capture → JPEG Base64
- **AdapterFactory**: Registry pattern for capability discovery
- **Tests**: 14 adapter tests passing (supports, execution, factory)

---

## Test Results Summary

| Test Suite | Tests | Status |
|------------|-------|--------|
| .NET xUnit (Worker, Adapters, Models) | 98 | ✅ All passing |
| Flutter Widget Tests (Phases 3, 5, 6, 7, 8) | 32 | ✅ All passing |
| Flutter Analyze | — | ✅ 0 errors |

---

## How to Use This Application

### For End Users (Once Complete)
1. **Install Windows Service** on target PC (runs at startup)
2. **Install Mobile App** on phone (APK/iOS)
3. **Pair Devices**: Open mobile app → scan QR code shown on Windows PC
4. **Observe**: View real-time event stream from PC on phone
5. **Control**: Send commands from phone → approve on PC → execute via adapters

### For Developers (Current State)

#### Prerequisites
- **.NET 8 SDK** — for Windows service, bridge, tests
- **Flutter SDK 3.x** — for mobile app
- **Visual Studio 2022** or **VS Code** with C# extension
- **Windows 10/11** (service uses Named Pipes, WPF)

#### Build & Run (Windows Side)
```bash
# Restore & build solution
dotnet restore LocalLoop.sln
dotnet build LocalLoop.sln

# Run tests
dotnet test src/LocalLoop.Tests/LocalLoop.Tests.csproj

# Run Service (background worker)
dotnet run --project src/LocalLoop.Service/LocalLoop.Service.csproj

# Run Bridge (console + WPF pairing window)
dotnet run --project src/LocalLoop.Bridge/LocalLoop.Bridge.csproj
```

#### Build Mobile App (Requires Flutter SDK)
```bash
cd mobile
flutter pub get
flutter test                       # Run all widget tests
flutter analyze                    # Static analysis
flutter build apk --release        # Android APK
flutter build ios --release        # iOS (requires macOS + Xcode)
flutter build appbundle --release  # Android App Bundle (Play Store)
```

**Output**: `mobile/build/app/outputs/flutter-apk/app-release.apk`

---

## Database Management

### Windows Service (SQLite)
- **File**: `src/LocalLoop.Service/localloop.db` (auto-created on first run)
- **Schema**: Single `Events` table (id, session_id, type, payload, timestamp)
- **Access**: Via `EventRepository` (Dapper) — append-only, no migrations needed
- **Backup**: Copy `localloop.db` file

### Mobile App (SQLite via sqflite)
- **Location**: App documents directory (platform-specific)
- **Schema**: Mirrors Windows event store + `command_history` + `approval_history` for offline-first
- **Sync**: WebSocket stream from Windows service → local SQLite

### No External Database Required
- Zero-config: SQLite files created automatically
- No PostgreSQL, MySQL, or cloud DB needed
- All data stays local (privacy-first)

---

## Website / Landing Page?

**Not required for core functionality.** The application handles everything:

| Need | Handled By |
|------|------------|
| Device discovery | mDNS (Bonjour/zeroconf) — no central server |
| Pairing | QR code (Windows shows, mobile scans) |
| Communication | Direct WebSocket (LAN) + Named Pipes (local) |
| Authentication | Ed25519 keypairs — no accounts, no cloud |
| Updates | Manual APK install / Windows service update |

**Optional**: A landing page could provide:
- Download links (APK, Windows installer)
- Documentation / setup guide
- Privacy policy (required for app stores)
- FAQ / troubleshooting

But the **app works fully offline** without any web infrastructure.

---

## Project Structure

```
Ghost-Link/
├── .planning/                 # Project planning & requirements
│   ├── PROJECT.md             # Architecture & tech decisions
│   ├── REQUIREMENTS.md        # 17 v1 requirements
│   ├── ROADMAP.md             # 4-phase roadmap
│   ├── STATE.md               # Current state tracker
│   └── phases/                # Phase-specific docs
├── src/
│   ├── LocalLoop.Core/        # Shared models
│   ├── LocalLoop.Service/     # Windows background service
│   ├── LocalLoop.Bridge/      # Desktop bridge + WPF pairing
│   └── LocalLoop.Tests/       # xUnit tests (98 tests)
├── mobile/                    # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart          # App entry + routing
│   │   ├── core/              # Router, crypto, network
│   │   ├── data/              # SQLite database
│   │   └── features/          # Observe, Command, Approvals, Workspaces, Settings
│   └── pubspec.yaml
├── LocalLoop.sln              # .NET solution
└── README.md                  # This file
```

---

## Development Roadmap

| Phase | Focus | Status | Remaining |
|-------|-------|--------|-----------|
| 1 | Infrastructure & Events | ✅ Done | — |
| 2 | Connectivity & Mobile Observe | ✅ Done | — |
| 3 | Command & Control | ✅ Done | — |
| 4 | Native/UI Adapters | ✅ Framework | — |
| **5** | Navigation Shell & Workspaces Dashboard | ✅ Done | — |
| **6** | Advanced Observe Surface | ✅ Done | — |
| **7** | Command & Approval Hardening | ✅ Done | — |
| **8** | Settings & Security Management | ✅ Done | — |

**All Milestone v1.1 Phases (5-8) Complete & Nyquist-Compliant**

---

## Next Steps (Packaging & Distribution)

1. **Windows Installer**: Create MSIX/ClickOnce installer for Service + Bridge (auto-start, updates)
2. **Mobile Release**: Sign APK / App Bundle for Play Store; iOS build (requires macOS)
3. **Optional**: Landing page for distribution (download links, docs, privacy policy)

---

## License

MIT License — see `LICENSE` file (to be added).