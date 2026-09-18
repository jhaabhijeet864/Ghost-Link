# Phase 2: Connectivity & Mobile Observe - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-19
**Phase:** 2-Connectivity & Mobile Observe
**Areas discussed:** Discovery & Pairing, Event Streaming Protocol, Flutter State Management

---

## Discovery & Pairing

| Option | Description | Selected |
|--------|-------------|----------|
| QR Code | (Recommended) QR Code (Scan screen on Windows app — highly secure, ensures physical proximity) | ✓ |
| mDNS / ZeroConf | Tap to pair on local network — seamless but might need PIN for security | |
| Manual IP / PIN | Simplest to implement, good fallback | |

**User's choice:** QR Code
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Ephemeral token + IP | (Recommended) Ephemeral pairing token + IP Address (Token is exchanged for long-lived cert/keys upon connection) | ✓ |
| Static PSK + IP | Simpler, but key never rotates | |
| Just the IP address | Pairing happens via separate PIN prompt | |

**User's choice:** Ephemeral pairing token + IP Address
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| mDNS fallback | (Recommended) mDNS fallback just for IP discovery (App securely finds the known Windows agent again without re-pairing) | ✓ |
| Manual IP update | User enters the new IP in settings | |
| Re-pairing required | Scan QR code again for new IP | |

**User's choice:** mDNS fallback just for IP discovery
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Deep link format | (Recommended) Deep link format (e.g., localloop://pair?...) which redirects to install the app or opens it | ✓ |
| Plain text JSON | Will just show raw text on screen in a generic scanner | |
| Base64 encoded blob | Keeps the payload opaque | |

**User's choice:** Deep link format
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Flutter Secure Storage | (Recommended) Stored in Flutter Secure Storage (encrypted by device keychain/keystore) | ✓ |
| SharedPreferences | Stored in plain SharedPreferences (simpler, but less secure) | |
| Regenerated | Regenerated on every launch (requires pairing every session) | |

**User's choice:** Flutter Secure Storage
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, with Revoke | (Recommended) Yes, a simple list in the system tray / window with 'Revoke' options | ✓ |
| No | No, pairing is handled silently in the background Service | |
| Yes, read-only | Yes, but read-only (revocation happens by restarting the service) | |

**User's choice:** Yes, with Revoke
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Multiple devices | (Recommended) Allow multiple devices to be paired and connected simultaneously | |
| Multiple, one active | Allow multiple paired devices, but only one active connection at a time | |
| Strictly 1:1 | Strictly 1:1 pairing (pairing a new device revokes the old one) | ✓ |

**User's choice:** Strictly 1:1 pairing
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Yes | (Recommended) Yes, the desktop bridge shows an 'Allow pairing?' prompt for security against shoulder surfing | ✓ |
| No | No, scanning the QR code implicitly grants access | |

**User's choice:** Yes
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Clear error | (Recommended) Show a clear error explaining network isolation and suggest a mobile hotspot fallback | |
| Generic error | Show a generic 'Connection failed' message with a retry button | ✓ |

**User's choice:** Generic error
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| WPF/WinForms window | (Recommended) Rendered directly in a small WPF/WinForms window by the Desktop Bridge | ✓ |
| Image file | Saved as an image file on the Desktop for the user to open | |
| ASCII art | Printed to the console as ASCII art (if running as a console app during dev) | |

**User's choice:** WPF/WinForms window
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Ed25519 | (Recommended) Ed25519 (Modern, fast, highly secure, standard for new systems) | ✓ |
| RSA-2048 | Legacy standard, widely supported but slower/larger | |
| ECDSA P-256 | Standard NIST curve, good support | |

**User's choice:** Ed25519
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Disconnect button | (Recommended) 'Disconnect & Forget Desktop' button in app settings which deletes the local key | ✓ |
| Delete app | Just delete the app to un-pair (No explicit un-pair button) | |
| Windows side only | Requires un-pairing from the Windows desktop side only | |

**User's choice:** Disconnect button
**Notes:** N/A

---

## Event Streaming Protocol

| Option | Description | Selected |
|--------|-------------|----------|
| WebSockets | (Recommended) WebSockets (Bidirectional, well-supported in Dart/C#, good for both push events and control commands later) | ✓ |
| SSE | Server-Sent Events (SSE) (Simpler for unidirectional push, but less ideal when we add Control mode in Phase 3) | |
| gRPC | Strongly typed, efficient, but requires more setup and protobuf compilation | |

**User's choice:** WebSockets
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| JSON strings | (Recommended) JSON strings (Human-readable, easy to debug, native to C# and Dart) | ✓ |
| MessagePack | More compact binary format, slightly faster parsing | |
| Protobuf | Strictly typed binary, requires schema files, smallest payload | |

**User's choice:** JSON strings
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Sync from Offset | (Recommended) 'Sync from Offset' logic: App sends its last known Event ID upon reconnect, Windows sends all missed events since then | ✓ |
| Full state dump | Full state dump on reconnect (Windows just sends the current full state, bypassing individual missed events) | |
| No offline | No offline reconstruction (If disconnected, just start listening to new events; history is lost) | |

**User's choice:** Sync from Offset
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Ed25519 signature | (Recommended) Ed25519 signature in a connection header (Client signs a nonce to prove identity without sending the key) | ✓ |
| Bearer token | Static bearer token passed in WebSocket URL query string (Easier to implement, slightly less secure) | |
| Basic Auth | HTTP Basic Auth headers with the token | |

**User's choice:** Ed25519 signature
**Notes:** N/A

---

## Flutter State Management

| Option | Description | Selected |
|--------|-------------|----------|
| Riverpod | (Recommended) Riverpod (Modern, compile-time safe, widely adopted in the Flutter community) | ✓ |
| BLoC / Cubit | Strict separation of concerns, heavily event-driven, but more boilerplate | |
| Provider | Legacy standard, easier to learn, but less safe | |

**User's choice:** Riverpod
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| SQLite | (Recommended) SQLite via the `sqflite` or `drift` package (Robust relational querying, matches Windows backend) | ✓ |
| Hive or Isar | NoSQL, fast local object storage | |
| SharedPreferences | Too simple for an event log, but requires no extra dependencies | |

**User's choice:** SQLite
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| SQLite first | (Recommended) WebSocket pushes to SQLite first -> SQLite triggers Riverpod provider update -> UI rebuilds (Single source of truth) | ✓ |
| Riverpod directly | WebSocket pushes directly to Riverpod state in memory (Faster UI updates, SQLite sync happens asynchronously in background) | |
| Polling | UI polls SQLite every second (Simplest, but inefficient and delayed) | |

**User's choice:** SQLite first
**Notes:** N/A

| Option | Description | Selected |
|--------|-------------|----------|
| Global StateNotifier | (Recommended) A global Riverpod `StateNotifier` that shows a persistent banner or icon when offline | ✓ |
| Local per screen | Handled locally per screen (Each screen checks if it has a connection) | |
| Blocking loading | Blocking loading screen (Users cannot view cached data while offline) | |

**User's choice:** Global StateNotifier
**Notes:** N/A

## the agent's Discretion

None

## Deferred Ideas

None
