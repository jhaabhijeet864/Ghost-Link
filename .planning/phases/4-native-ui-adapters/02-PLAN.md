# Phase 4, Wave 2: UI Automation & Fallback

## Goal
Introduce the visual/semantic adapters (FlaUI & Screenshot) to the Desktop Bridge.

## Implementation Steps

### 1. Add NuGet Dependencies
**Target:** `src/LocalLoop.Bridge/LocalLoop.Bridge.csproj`
**Action:** Add packages `FlaUI.UIA2`, `FlaUI.UIA3`, and `System.Drawing.Common`.

### 2. Implement FlaUI Adapter
**Target:** `src/LocalLoop.Bridge/Adapters/FlaUiAdapter.cs`
**Action:** Implement `IAdapter` for `Level3_UIAutomation`.
- Instantiate `UIA3Automation` (modern) and `UIA2Automation` (fallback).
- Expose methods to find windows by `ProcessName` and `MainWindowTitle`.
- Map incoming `CommandIntent` to FlaUI actions (e.g. click, focus, get tree).

### 3. Implement Screenshot Adapter
**Target:** `src/LocalLoop.Bridge/Adapters/ScreenshotAdapter.cs`
**Action:** Implement `IAdapter` for `Level6_Screenshot`.
- Use `System.Drawing.Common` to capture the screen or a specific window's bounding rect.
- Compress the image to JPEG, encode to Base64.
- Return the Base64 string via IPC for the mobile app to consume.
