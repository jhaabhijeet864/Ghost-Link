# Phase 1: Infrastructure & Event Model — Context

## Goal
Build the dual-process Windows architecture and local event storage.

## Decisions
- **Language/Framework**: C# with .NET 8 (Best ecosystem for Windows integration).
- **Database**: Dapper as a fast micro-ORM over SQLite for the append-only event store.
- **IPC Topology**: Service acts as the Named Pipe Server (controls ACLs), Desktop Bridge is the Client.
- **Development Workflow**: .NET Worker Service template (runs as a console app during dev, Windows Service in prod).

## Canonical References
- `.planning/PROJECT.md`
- `.planning/ROADMAP.md`

## Code Context
(Greenfield — no existing code yet)
