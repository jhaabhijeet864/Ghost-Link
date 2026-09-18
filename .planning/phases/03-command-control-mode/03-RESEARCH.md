# Phase 3: Command & Control Mode - Research

## Overview
To effectively plan Phase 3, we must coordinate the development of the Flutter mobile interface with the Windows Service's AI and policy logic. The phase delivers the mobile command composer UI, the AI-driven intent parsing on Windows, the hardcoded policy/approval engine, and the mobile approval inbox.

## Key Requirements & Scope
- **Mobile Application (Flutter - Domain-Driven Architecture):**
  - **Command Composer UI (MOB-04):** Text field with a row of quick-action chips ("Pause", "Resume", "Cancel"). Primary CTA uses the Accent color (Primary Color) for submit actions.
  - **Approval Inbox UI (MOB-03):** Dedicated list view accessed via a badge/icon opening a side drawer or modal. Handles empty states ("No pending approvals") and error states.
  - **Interactivity:** Destructive confirmation dialogs for rejecting actions ("Are you sure you want to reject this request?"). 
- **Windows Service (.NET 8):**
  - **AI Command Composer (WIN-01):** Uses `Microsoft.SemanticKernel` (1.14.x) to parse raw natural language from mobile into a structured `CommandIntent` JSON (Action, Target, Parameters, RiskLevel, Explanation) using C# Records.
  - **Policy & Approval Engine (SEC-02):** Hardcoded rules in the Service layer mapping intents to execution or manual approval flows based on risk (e.g., `Read logs` = Allow, `Delete files` = Always ask).
  - **Audit Logging (SEC-03):** Minimal MVP structure recording only `timestamp` and `device ID` for all events and approval decisions.

## Architectural & Implementation Insights
- **Input to AI Parsing Flow:** The mobile app captures unstructured text and sends it to the Windows Service. The Windows Service handles the heavy lifting of AI parsing using Semantic Kernel, avoiding complex LLM logic on the mobile client.
- **Async & Resiliency:** All AI parsing (via Semantic Kernel) and policy evaluations must be strictly async and handle cancellation tokens gracefully, as they run in a background worker service.
- **Guardrails:** Online guardrails must be implemented on the Windows Service to validate schema (retrying once, then blocking) and enforce an Action Allowlist (blocking hallucinated action verbs) before reaching the policy engine.

## Validation Architecture

1. **AI Component Validation (C# xUnit):**
   - **Accuracy & Safety:** Custom xUnit tests over a golden dataset (size ≥ 10) asserting exact matches for explicit requests and lack of hallucinations. 
   - **Risk Rating:** Pass/fail assertions ensuring intents are correctly classified (e.g., high-risk actions are never classified as low-risk, prioritizing safety).
   - **Guardrails Testing:** Verify the service blocks inputs outside the allowlist and handles serialization failures safely.
2. **Policy Engine & Audit Validation (C# xUnit):**
   - Test hardcoded rules to confirm low-risk intents execute immediately and high-risk intents correctly transition to a "Pending Approval" state.
   - Verify that the Audit Log successfully records the `timestamp` and `device ID` for evaluated intents and approval/rejection outcomes.
3. **Mobile UI Validation (Flutter Widget Tests):**
   - **Command Composer:** Verify text input and quick-action chips trigger appropriate intent events.
   - **Approval Inbox:** Test the badge state, drawer/modal toggling, empty state rendering, and the destructive confirmation dialog.
4. **Integration Validation (End-to-End):**
   - Simulate a complete cycle: Mobile text command -> Windows Service AI parsing -> Risk evaluated as high -> Pending approval state synced to mobile -> User rejects via mobile UI -> Audit log securely updated on Windows.
