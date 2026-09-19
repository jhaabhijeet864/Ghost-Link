# ARCHITECTURE.md

## System Overview

LocalLoop is a local-first remote control plane for autonomous AI coding agents running on a developer's Windows workstation. It consists of a Windows background service, an interactive desktop bridge, and a Flutter mobile application.

The architecture emphasizes security (Ed25519 challenge-response), local-first execution, and a layered integration strategy (Native API -> CLI -> UI Automation).

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          LOCAL NETWORK (LAN / mDNS)                         │
└──────────────────────┬───────────────────────────────────────────────┬──────┘
                       │ WebSocket (Encrypted / Ed25519)               │
                       ▼                                               ▼
┌──────────────────────────────────────────────────┐ ┌──────────────────────────────────┐
│                 HOST BACKEND                     │ │       MOBILE COMPANION           │
│         (Windows Dual-Process Architecture)      │ │       (Flutter / Dart)           │
│                                                  │ │                                  │
│  ┌────────────────────────────────────────────┐  │ │ • Destinations: Workspaces,      │
│  │ 1. LocalLoop.Service (Session 0)           │  │ │   Observe, Command, Approvals,   │
│  │    • WebSocket Server (Port 8080)          │  │ │   Settings                       │
│  │    • mDNS Zeroconf Advertiser              │  │ │ • SQLite (WAL Mode)              │
│  │    • SQLite Append-Only Event Store        │  │ │ • Ed25519 Secure Keystore        │
│  │    • Policy Engine & Risk Classification   │  │ │ • Signed Action Envelopes        │
│  │    • PairingManager (DPAPI)                │  │ │                                  │
│  └──────────────────┬─────────────────────────┘  │ └──────────────────────────────────┘
│                     │ Named Pipe IPC             │
│                     │ (LocalLoop_ControlPipe)    │
│  ┌──────────────────▼─────────────────────────┐  │
│  │ 2. LocalLoop.Bridge (User Session)         │  │
│  │    • Windows Forms Systray & QR UI         │  │
│  │    • Adapters: Process Control, FlaUI      │  │
│  │    • Interactive User Prompts              │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

## Core Components

### 1. LocalLoop.Service (.NET 8 Worker Service)

- Runs as a background service (Session 0).
- Hosts the WebSocket server (Port 8080) for mobile communication.
- Advertises the service on the local network via mDNS (`_localloop._tcp`).
- Manages an append-only SQLite Event Store (WAL Mode) via Dapper.
- Enforces policies, risk classification, and pairing authentication (Ed25519 challenge-response).
- Monitors AI agent logs (e.g., `TranscriptWatcher` for `transcript.jsonl`).

### 2. LocalLoop.Bridge (.NET 8 Console/WPF App)

- Runs in the interactive Windows user session.
- Provides a systray icon and a WPF-based desktop pairing window (QR code).
- Connects to `LocalLoop.Service` via asynchronous Named Pipes.
- Executes UI-dependent actions using adapters (e.g., `FlaUI.Core` / `FlaUI.UIA3` for Antigravity IDE prompt injection).
- Takes on-demand screenshots (GDI+ to Base64 JPEG).

### 3. Mobile Client (Flutter)

- Built with Flutter (>=3.0.0 <4.0.0) and Dart.
- Uses `flutter_riverpod` for state management and `go_router` for navigation.
- Maintains an offline-first SQLite database (WAL mode) and background telemetry queue.
- Handles cryptographic pairing and signature verification using the `cryptography` package.

## Integration Adapters Hierarchy

1. Native APIs, plugins, MCP, IPC, or local APIs.
2. CLI and process control (`System.Diagnostics.Process`).
3. Windows UI Automation (`FlaUI`).
4. Win32 control APIs.
5. Guarded input injection.
6. Visual automation with verification (screenshots).

## Security Invariants

- **Zero-Token Fallback Backdoor**: Initial pairing requires an ephemeral QR code exchange.
- **Ed25519 Handshake & Envelope Sealing**: All high-impact actions must be sealed in a `SignedEnvelope` containing canonical JSON digest, timestamp, and signature.
- **Replay Attack Window**: Timestamps skewed by >30 seconds are rejected.
- **Session 0 Safety**: Interactive UI actions must execute via `LocalLoop.Bridge` using Named Pipe IPC.
