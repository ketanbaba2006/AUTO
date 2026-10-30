# AUTO Screen Intelligence & Visual Understanding (Fragment 4)

## 1. Overview

AUTO integrates Apple's native **ScreenCaptureKit** framework and multimodal **Google Gemini API** to provide context-aware desktop guidance. Through ScreenCaptureKit, AUTO can capture entire displays, individual application windows, or multi-monitor arrangements without capturing its own companion windows, convert screenshots into high-legibility JPEG payloads, and deliver them to Gemini to answer questions about errors, buttons, menus, and on-screen workflows.

```
       [User Action / Voice Turn]
                   │
                   ▼
       ScreenContextManager
   ┌───────────────┴───────────────┐
   ▼                               ▼
ScreenCaptureManager       WindowCaptureManager
(SCShareableContent)     (Desktop-Independent Windows)
   │                               │
   ▼                               ▼
       ScreenshotProcessor
   (4K Downsampling & JPEG Compression)
                   │
                   ▼
   AccessibilityVisualInspector
  (AX Focused App, Window, Selected Text)
                   │
                   ▼
          VisualScreenContext
                   │
                   ▼
          ConversationManager
                   │
                   ▼
           Gemini Multimodal
    (Text Prompt + Inlined Screen Data)
```

---

## 2. ScreenCaptureKit Architecture

### 2.1 ScreenCaptureManager (`AUTO/Screen/ScreenCaptureManager.swift`)
- Interfaces directly with `SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)`.
- Excludes AUTO companion panel, overlays, and settings windows so the AI never sees recursive companion UI.
- Implements:
  - `captureActiveDisplay()`: Captures display containing the mouse cursor or selected display.
  - `captureDisplay(displayID:maxDimension:compressionQuality:)`: Captures a specific display.
  - `captureAllScreens()`: Simultaneously captures all active monitors.
  - `startContinuousSharing(interval:)`: Mode C periodic sampling.
  - `stopContinuousSharing()`: Instant termination of screen sampling.

### 2.2 WindowCaptureManager (`AUTO/Screen/WindowCaptureManager.swift`)
- Discovers on-screen windows via `SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)`.
- Filters out Dock, Window Server, and AUTO application windows.
- Captures individual application windows via `SCContentFilter(desktopIndependentWindow: scWindow)`.
- Exposes `availableWindows: [WindowInfo]` to SwiftUI Settings and Companion picker.

### 2.3 ScreenshotProcessor (`AUTO/Screen/ScreenshotProcessor.swift`)
- Converts high-resolution Retina screenshots into optimized vision payloads:
  - Preserves exact aspect ratio (e.g. 16:9, 16:10, ultrawide).
  - Downsamples 4K / 5K displays exceeding `maxDimension` (1920px, 1536px, 1280px).
  - Encodes to JPEG with optimal legibility factor (default `0.80`) ensuring small code, terminal text, and button labels remain sharp.
  - Computes SHA-256 hash for memory caching.
  - Produces `ProcessedScreenshot` containing both raw JPEG `Data` and `base64String`.

### 2.4 ScreenContextManager (`AUTO/Screen/ScreenContextManager.swift`)
- Central coordinator bundling `DisplayInfo`, `WindowInfo`, `screenshotJPEG`, `base64String`, and `AccessibilityVisualContext`.
- Directly interfaces with `ConversationManager.sendUserInput(query, screenshotBase64: [base64], stream: true)`.
- Provides `clear()` to purge visual snapshots from RAM immediately after reasoning.

---

## 3. Screen Awareness Modes

### Mode A: On-Demand Screen Capture
- Activated when the user clicks the "Capture Now" button in Settings or Companion Panel.
- Captures current display or window, presents brief feedback, and keeps context ready for the next question.

### Mode B: Active Voice Session
- When enabled in Settings, push-to-talk voice conversations automatically capture screen context upon releasing the `⌃ Control` key.
- Example: User holds Control, asks "What does this compiler error mean?", and releases Control. AUTO captures the authorized screen, sends both the question and screenshot to Gemini, and speaks the answer aloud.

### Mode C: Manual Screen Sharing
- User toggles "Start Screen Sharing" in Settings.
- Shows a glowing cyan screen indicator in the companion panel.
- Periodically refreshes visual context in RAM.
- Includes an immediate "Stop Screen Sharing" button that halts all timers and cleans up resources.

---

## 4. Accessibility Metadata Supplementation

When macOS Accessibility permission is granted, `AccessibilityVisualInspector` inspects:
- Frontmost application name (`NSWorkspace.shared.frontmostApplication`)
- Frontmost window title (`kAXFocusedWindowAttribute`)
- Focused UI element description (`kAXFocusedUIElementAttribute`)
- Currently selected text (`kAXSelectedTextAttribute`)
- Element under mouse cursor (`AXUIElementCopyElementAtPosition`)

This metadata is formatted into a concise string (`promptSummary`) and passed as `contextNote` to Gemini's system prompt to ground visual analysis in exact window and element names.

