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
| **LocalLoop.Tests** | xUnit | Unit & integration tests (Nyquist-compliant) |
| **Mobile App** | Flutter 3.x / Dart | Mobile client: pairing, observe mode, command & control (planned) |

---

## Current Status (v0.2.0 - Pre-Alpha)

### ✅ Completed & Tested (Phase 1)
- Windows background service with SQLite event store (Dapper)
- Named Pipes IPC between Service ↔ Bridge
- Event persistence (`session_created`, etc.)
- Unit & integration tests passing

### ⚠️ Code Complete, Untested (Phase 2)
- **Mobile App**: Pairing screen (QR code), Observe screen (event stream), Ed25519 crypto, WebSocket client with mDNS fallback
- **Windows**: WebSocket server with signature auth, PairingManager (1:1 device pairing), WPF QR code window
- **Blocker**: Flutter SDK not installed — cannot build/test mobile app

### 📋 Planned Only (Phase 3)
- Command Composer (mobile) + Approval Inbox
- Semantic Kernel AI intent parser (Windows)
- Policy Engine (Allow/Ask/Block)
- Audit logging

### ✅/📋 Framework Done (Phase 4)
- Adapter framework: `ProcessAdapter` (stdout/stderr), `FlaUiAdapter` (UIA3/2), `ScreenshotAdapter` (GDI+)
- Unit tests passing for ProcessAdapter & AdapterFactory
- FlaUI & Screenshot require interactive desktop (manual validation only)

---

## How to Use This Application

### For End Users (Once Complete)
1. **Install Windows Service** on target PC (runs at startup)
2. **Install Mobile App** on phone (APK/iOS)
3. **Pair Devices**: Open mobile app → scan QR code shown on Windows PC
4. **Observe**: View real-time event stream from PC on phone
5. **Control** (Phase 3+): Send commands from phone → approve on PC → execute via adapters

### For Developers (Current State)

#### Prerequisites
- **.NET 8 SDK** — for Windows service, bridge, tests
- **Flutter SDK 3.x** — for mobile app (NOT INSTALLED IN CURRENT ENV)
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
flutter build apk --release          # Android APK
flutter build ios --release          # iOS (requires macOS + Xcode)
flutter build appbundle --release    # Android App Bundle (Play Store)
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
- **Schema**: Mirrors Windows event store for offline-first observe mode
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
│   └── LocalLoop.Tests/       # xUnit tests
├── mobile/                    # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart          # App entry + routing
│   │   ├── core/              # Router, crypto, network
│   │   ├── data/              # SQLite database
│   │   └── features/          # Observe, pairing screens
│   └── pubspec.yaml
├── LocalLoop.sln              # .NET solution
└── README.md                  # This file
```

---

## Development Roadmap

| Phase | Focus | Status | Blockers |
|-------|-------|--------|----------|
| 1 | Infrastructure & Events | ✅ Done | — |
| 2 | Connectivity & Mobile Observe | ⚠️ Code done | **Flutter SDK missing** |
| 3 | Command & Control | 📋 Planned | Phase 2 validation first |
| 4 | Native/UI Adapters | ✅ Framework | Manual validation only |

**Next Milestone**: Install Flutter SDK → validate Phase 2 → implement Phase 3.

---

## License

MIT License — see `LICENSE` file (to be added).