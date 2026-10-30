# ORIGINAL PROJECT ANALYSIS: HeyClicky (clicky / leanring-buddy)

## 1. Executive Summary

This document provides a comprehensive technical analysis of the reference repository **HeyClicky** (`clicky`, internally named `leanring-buddy`), authored by Farza and team. The purpose of this analysis is to evaluate its architecture, Swift implementation, interaction models, dependencies, security profile, and shortcomings in order to build an independent, native macOS desktop companion named **AUTO**.

AUTO retains the interaction strengths of Clicky—specifically, menu-bar residency, floating companion panels, multi-monitor transparent overlays, global hold-to-talk shortcuts, and screen intelligence—while introducing a modular architecture, direct Google Gemini model integration, 13 native local execution services, local macOS Keychain credential storage, zero telemetry, and a full native settings and onboarding system.

---

## 2. Original Project Overview and Structure

### 2.1 Repository Layout
The original repository consists of:
- `leanring-buddy.xcodeproj`: Xcode project containing project settings, target configurations, and asset catalogs.
- `leanring-buddy/`: The main macOS application source directory (containing Swift files, asset catalogs, and entitlements).
- `worker/`: A Cloudflare Worker proxy written in TypeScript (`src/index.ts`) used to proxy API requests to Anthropic (Claude), AssemblyAI, and ElevenLabs.
- `scripts/`: Packaging and deployment automation scripts (e.g., DMG creation).

### 2.2 Key Source Files in the Original Project

| File Name | Approximate Line Count | Architectural Role |
| :--- | :--- | :--- |
| `leanring_buddyApp.swift` | ~90 lines | Menu bar application entry point (`@NSApplicationDelegateAdaptor(CompanionAppDelegate.self)`). |
| `MenuBarPanelManager.swift` | ~244 lines | Manages `NSStatusItem` in the system menu bar and a floating borderless `NSPanel` dropdown hosting `CompanionPanelView`. |
| `CompanionManager.swift` | ~1,027 lines | Monolithic central state machine handling voice state, onboarding media, email submission, permissions, and pipeline orchestration. |
| `OverlayWindow.swift` | ~882 lines | Full-screen transparent `NSWindow` (level `.screenSaver`) per display, rendering `BlueCursorView` with spring tracking and pointing animation. |
| `CompanionPanelView.swift` | ~761 lines | SwiftUI view for the menu bar dropdown panel, showing model selector, permissions status, and onboarding button. |
| `GlobalPushToTalkShortcutMonitor.swift` | ~133 lines | System-wide shortcut monitor using a listen-only `CGEvent` tap on `CFRunLoopGetMain()`. |
| `CompanionScreenCaptureUtility.swift` | ~133 lines | Multi-monitor screen capture using ScreenCaptureKit (`SCShareableContent`, `SCScreenshotManager`). |
| `BuddyDictationManager.swift` | ~866 lines | Push-to-talk voice recording using `AVAudioEngine`, audio level metering, and transcription orchestration. |
| `BuddyTranscriptionProvider.swift` | ~100 lines | Protocol abstraction for transcription providers (AssemblyAI, OpenAI, Apple Speech). |
| `AssemblyAIStreamingTranscriptionProvider.swift` | ~478 lines | WebSocket-based real-time transcription with temporary token authentication. |
| `ClaudeAPI.swift` | ~291 lines | Anthropic Messages API client with SSE streaming support. |
| `OpenAIAPI.swift` | ~142 lines | OpenAI Chat Completions API client with vision support. |
| `ElevenLabsTTSClient.swift` | ~81 lines | ElevenLabs Text-to-Speech client using `AVAudioPlayer` for playback. |
| `ElementLocationDetector.swift` | ~336 lines | UI element screen location detector using Anthropic Computer Use API resolution heuristics. |
| `WindowPositionManager.swift` | ~263 lines | System permission checking and settings redirection for Accessibility and Screen Recording. |
| `DesignSystem.swift` | ~880 lines | Design tokens, color constants, typography, and button styles. |
| `ClickyAnalytics.swift` | ~121 lines | PostHog telemetry tracking user behavior, app launches, and permission grants. |

---

## 3. Original Architecture Deep Dive

### 3.1 Application Lifecycle and Menu Bar Pattern
- **Agent/Background Mode**: Clicky sets `LSUIElement = true` in `Info.plist`, hiding the application from the macOS Dock and Cmd+Tab app switcher.
- **Menu Bar Residency**: It creates an `NSStatusItem` in `NSStatusBar.system` with a custom-drawn icon (`NSBezierPath`).
- **Floating Panel (`NSPanel`)**: When the menu bar item is clicked, an `NSPanel` with style mask `[.borderless, .nonactivatingPanel]` and level `.floating` is displayed directly below the status item.
- **Dismissal Mechanism**: A global `NSEvent` monitor (`.leftMouseDown`, `.rightMouseDown`) listens for outside clicks to hide the panel, behaving like an `NSPopover` but with custom window chrome.

### 3.2 Screen Overlay and Coordinate Transformation
- **Overlay Window Management**: Clicky instantiates one transparent borderless `OverlayWindow` per active `NSScreen`.
- **Window Level**: The overlay window level is set to `.screenSaver`, placing it above standard application windows, menus, and popovers.
- **Click-Through**: `ignoresMouseEvents = true` enables all mouse clicks to pass through to underlying applications.
- **Coordinate Systems**:
  - macOS AppKit coordinates use a bottom-left origin `(0, 0)`.
  - CoreGraphics (`CGEvent`, ScreenCaptureKit `SCDisplay`) uses a top-left origin.
  - Multi-monitor setups require normalization relative to `NSScreen.screens` frames to avoid cursor misplacement across displays.

### 3.3 Voice and Push-to-Talk Pipeline
- **Global Event Tap**: Background shortcut detection relies on `CGEvent.tapCreate` (`.cgSessionEventTap`, `.listenOnly`) capturing `.flagsChanged`, `.keyDown`, and `.keyUp`. This allows detecting modifier-only shortcuts (such as `Control` or `Control + Option`).
- **Audio Capture**: `AVAudioEngine` attaches a tap on `inputNode` to stream PCM audio buffers.
- **Transcription**: The audio buffer is converted into mono PCM16 and streamed via WebSocket to AssemblyAI or buffered for OpenAI/Apple Speech.

### 3.4 AI Interaction and Element Pointing
- **Cloudflare Worker Proxy**: Clicky avoids storing API keys in the app by proxying all requests (`/chat`, `/tts`, `/transcribe-token`) through a remote Cloudflare Worker.
- **Streaming Response**: Claude streams tokens via Server-Sent Events (SSE).
- **Element Pointing Syntax**: Claude includes spatial tags in the format:
  `[POINT:x,y:label:screenN]`
  The overlay parses these tags, maps the coordinates to the specified display, and animates a triangular cursor buddy along a bezier curve to point at the target element.

---

## 4. Reusable Implementation Patterns

The following patterns from Clicky are architecturally sound and will be adapted for AUTO:
1. **Menu Bar Non-Activating Panel**: Using a borderless `NSPanel` hosting SwiftUI via `NSHostingView` with `.canJoinAllSpaces` and `.fullScreenAuxiliary` ensures clean native macOS integration without stealing focus.
2. **Listen-Only `CGEvent` Tap**: Monitoring `flagsChanged` and `keyDown`/`keyUp` using a CoreGraphics session event tap attached to `CFRunLoopGetMain()` is the most reliable way on macOS to detect global push-to-talk modifier keys without third-party hotkey libraries.
3. **Multi-Display Overlay Windows**: Creating one transparent, pass-through `NSWindow` per display at `.screenSaver` level ensures continuous visual guidance across all monitors.
4. **ScreenCaptureKit Integration**: Leveraging `SCShareableContent` and `SCScreenshotManager` with app-window exclusions (`Bundle.main.bundleIdentifier`) ensures clean captures without self-occlusion.

---

## 5. Components That Must Be Replaced

| Original Component | Problem in Clicky | AUTO Replacement |
| :--- | :--- | :--- |
| **Cloudflare Worker Proxy** | Hardcoded dependency requiring user deployment of Cloudflare Workers and remote secrets. | **Direct Local & Provider Clients**: Native direct client for Google Gemini API and 100% local native Swift execution engine. |
| **Monolithic `CompanionManager`** | Over 1,000 lines coupling onboarding, video, audio playback, email, networking, and UI state. | **Modular Service Architecture**: Segregated managers (`CompanionManager`, `AIProviderManager`, `AudioCaptureManager`, `PermissionManager`, etc.) orchestrated via a `DependencyContainer`. |
| **Hardcoded Models & Prompts** | Hardcoded to Claude Sonnet/Opus via Anthropic API proxy. | **Dynamic Model Discovery & Protocol**: Protocol-oriented `AIProvider` supporting Gemini with dynamic model discovery and native local tools. |
| **Plain Text / Hardcoded Configs** | Secrets stored in worker environment or plain configuration. | **macOS Keychain Services**: Secure, encrypted storage of API keys via `KeychainManager`. |
| **PostHog Analytics & FormSpark** | Telemetry tracking and email submission without clear opt-out. | **Completely Free & Privacy-First**: Zero analytics, zero user tracking, zero data exfiltration. |
| **Hardcoded Assets & Video** | Bundled proprietary game audio (`ff.mp3`, `eshop.mp3`) and video. | **Native SwiftUI Vector Animations**: Clean, native vector and procedural UI components without copyright encumbrance. |
| **Minimal Panel UI** | Lacked settings, key management, audio config, display metrics, or privacy controls. | **Full Native Settings Window**: Multi-tab settings (General, AI Providers, Voice, Screen, Privacy) with persistent state. |

---

## 6. Permissions and Entitlements Analysis

### 6.1 Required macOS Permissions
1. **Microphone (`NSMicrophoneUsageDescription`)**: Required for voice input via `AVAudioEngine`.
2. **Screen Recording (`NSScreenCaptureUsageDescription`)**: Required for `ScreenCaptureKit` and `CGPreflightScreenCaptureAccess`.
3. **Accessibility (`AXIsProcessTrusted`)**: Required to query window positions and detect system elements.
4. **Input Monitoring / Event Tap**: Required for `CGEvent.tapCreate` to listen for global hotkeys across applications.

### 6.2 Entitlements
- In Clicky, `com.apple.security.app-sandbox` was set to `false`.
- **Reason**: Sandboxed applications are strictly forbidden from creating global `CGEvent` taps across other processes and cannot use Accessibility APIs to control cursor position or read screen elements of third-party applications.
- AUTO adopts the same non-sandboxed developer configuration with appropriate hardened runtime settings.

---

## 7. Architectural Decisions for AUTO Fragment 1

1. **Protocol-Oriented Architecture**: Define formal Swift protocols (`AIProvider`, `AudioCaptureService`, `ScreenCaptureService`, `KeychainService`, `PermissionService`).
2. **Dependency Injection**: Utilize a `DependencyContainer` to decouple concrete services from views and controllers, facilitating unit testing.
3. **Swift Concurrency**: Use `async`/`await`, `Actor` isolation for thread-safe operations, and `@MainActor` for all UI state and AppKit bridges.
4. **Secure Credential Storage**: Native macOS Security framework (`SecItemCopyMatching`, `SecItemAdd`, `SecItemUpdate`, `SecItemDelete`) with zero plain-text storage.
5. **Native Multi-Tab Settings**: Comprehensive SwiftUI-based settings panel integrated with persistent `UserDefaults` and `KeychainManager`.
6. **Robust Error Handling & Central Logging**: Unified `Logger` and typed `AppError` framework instead of scattered `print()` statements.
