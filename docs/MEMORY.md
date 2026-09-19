# MEMORY.md

## Project Context

- **Name:** LocalLoop (Ghost-Link)
- **Goal:** Local-first, application-aware remote control plane for AI coding agents on Windows.

## Technology Stack

- **Host Backend:** .NET 8 (`net8.0-windows`), SQLite, Dapper, mDNS, Named Pipes, NSec (Ed25519), FlaUI (UI Automation).
- **Mobile Client:** Flutter (>=3.0.0), Dart, Riverpod, GoRouter, sqflite, Ed25519.
- **Communication:** WebSocket (port 8080) for Mobile <-> Service; Named Pipes for Service <-> Bridge.

## Key Technical Decisions

- **Dual-Process Windows Architecture:** `LocalLoop.Service` handles background networking and SQLite in Session 0. `LocalLoop.Bridge` handles interactive UI automation (FlaUI) in the user session. They communicate via Named Pipes.
- **Dual-Strategy Prompt Injection:**
  - To read logs: Monitor `transcript.jsonl` in `<appDataDir>\brain\<conversation-id>` via `TranscriptWatcher`.
  - To send prompts: Use `IdePromptInjector` with Windows UI Automation (FlaUI) to target the IDE window.
- **Web Build Fallback:** Due to UI overlaps in the web preview, Flutter Web can be served locally (e.g., Python HTTP server on port 5000) for rapid UI testing during development.
- **Java System.load Warning:** The warning (`A restricted method in java.lang.System has been called`) during `flutter build apk` is a harmless Gradle dependency issue on modern JDKs and can be safely ignored.

## Critical Rules to Remember

1. **TDD is Mandatory:** Tests must be written before implementation code. No production behavior changes without tests.
2. **Local-First:** Source code and commands remain on the user's Windows machine. No automatic cloud uploads.
3. **Approval Gates:** Destructive or high-risk actions MUST require explicit user authorization (SignedEnvelopes, 2-minute expiry).
4. **No UI Automation Blind Spots:** Do not rely solely on screen coordinates. Use automation IDs/roles and verify preconditions/postconditions.
5. **No GSD Bypassing:** Follow GSD workflow directives (`/gsd-quick`, `/gsd-plan-phase`) for tracking planning and validation.

## Known Constraints

- Cannot directly run `dotnet build` while `LocalLoop.Bridge` or `LocalLoop.Service` are actively running in the terminal due to locked `.dll` files. Must terminate the processes before rebuilding.
