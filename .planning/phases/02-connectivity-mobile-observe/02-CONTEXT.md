# Phase 2: Connectivity & Mobile Observe - Context

**Gathered:** 2026-09-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish secure connection and build the Flutter mobile read-only views for monitoring the Windows agent.
</domain>

<decisions>
## Implementation Decisions

### Discovery & Pairing
- **D-01:** Discovery happens via QR code (Scan screen on Windows app).
- **D-02:** Deep link format (`localloop://pair?...`) redirecting to app installation or opening.
- **D-03:** QR code embeds an ephemeral pairing token + IP address.
- **D-04:** Pairing uses Ed25519 cryptography, and the mobile app stores the key in Flutter Secure Storage.
- **D-05:** mDNS fallback is used for automatic IP rediscovery if the network changes.
- **D-06:** Strictly 1:1 pairing (pairing a new device revokes the old one).
- **D-07:** Windows Desktop Bridge renders the QR code natively and displays an "Allow pairing?" prompt for confirmation.
- **D-08:** Active paired devices are listed in the Windows system tray/window with Revoke options.
- **D-09:** Mobile app includes a "Disconnect & Forget Desktop" button to handle un-pairing.
- **D-10:** Network isolation failures show a clear error suggesting a mobile hotspot fallback.

### Event Streaming Protocol
- **D-11:** WebSockets will push events from the Windows Service to the Flutter app.
- **D-12:** Event payload will be structured as JSON strings.
- **D-13:** Offline missed events are reconstructed using a "Sync from Offset" logic upon reconnection.
- **D-14:** WebSockets are authenticated via an Ed25519 signature in a connection header.

### Flutter State Management
- **D-15:** Riverpod is the state management library for offline-first caching and UI updates.
- **D-16:** SQLite (`sqflite` or `drift`) persists the append-only event stream locally on mobile.
- **D-17:** WebSocket pushes to SQLite first, which then triggers a Riverpod provider update to rebuild UI.
- **D-18:** Connection status is managed by a global Riverpod `StateNotifier` presenting an offline banner/icon when disconnected.

### the agent's Discretion
None — all decisions were explicitly captured.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Core
- `.planning/PROJECT.md` — Project definition, core value, architecture constraints
- `.planning/ROADMAP.md` — Roadmap and phase boundaries

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None (Greenfield mobile app initialization)

### Established Patterns
- Dual-process IPC topology on Windows backend
- C# / .NET 8 / SQLite for backend event storage (established in Phase 1)

### Integration Points
- WebSocket integration between Dart (client) and C# (server)
- Flutter Secure Storage and SQLite setup

</code_context>

<specifics>
## Specific Ideas

No specific UI aesthetic preferences captured yet — open to standard Flutter/Material 3 approaches that fit the domain.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 2-Connectivity & Mobile Observe*
*Context gathered: 2026-09-19*
