# Building and Running AUTO

AUTO is a native macOS desktop companion written in Swift. It requires **macOS 14.0 (Sonoma) or later**.

---

## 1. Quick Start via Swift Command Line

Ensure you have Swift installed (part of Xcode or Apple Command Line Tools):
```bash
swift --version
```

### 1.1 Compile the Application
From the project root:
```bash
swift build
```
This produces the native binary at `.build/debug/AUTO`.

### 1.2 Run the Automated Test Suite
To run all 84 automated unit and integration tests offline:
```bash
swift run AUTO --test
# or
./.build/debug/AUTO --test
```
Output:
```
=======================================================
    AUTO AUTOMATED TEST SUITE (FRAGMENT 7: RELEASE)   
=======================================================

  [PASS] Gemini Connection Testing (Mocked)
  [PASS] Gemini Model Discovery (Parsing)
  [PASS] Gemini Generate & Spatial Points & Tokens
  [PASS] Gemini 403 Auth Error Mapping
  [PASS] Gemini 429 Rate Limit Error Mapping
  [PASS] OmniRoute Model Discovery (OpenAI Format)
  [PASS] OmniRoute Chat Completions & Spatial Tagging
  [PASS] OmniRoute 502 Bad Gateway Error Mapping
  [PASS] SpatialPoint Regex Point Parsing
  [PASS] PromptManager Template Generation
  [PASS] ConversationMemory History Limits & Pruning
  [PASS] Task-Based AI Routing Resolution
  [PASS] OmniRoute Fallback to Gemini
  [PASS] ImageProcessor Screenshot Compression
  [PASS] Mock Keychain Storage & Deletion
  [PASS] Push-to-Talk Press and Release Detection
  [PASS] Push-to-Talk Duplicate Event Suppression
  [PASS] Voice State Machine Transitions
  [PASS] Assistant Speech Interruption Handling
  [PASS] Voice Activity Detector RMS Calculation
  [PASS] Microphone Device Discovery
  [PASS] Speech Output Text Sanitization
  [PASS] Empty Speech Recognition Graceful Handling
  [PASS] Official Brand Theme & Identity Constants
  [PASS] Brand Asset Resolution & Image Caching
  [PASS] Menu Bar Mascot Vector Icon Template Rendering
  [PASS] Screen Capture Permission State Handling
  [PASS] ScreenshotProcessor 4K Downsampling & JPEG Legibility
  [PASS] Multi-Display Negative Virtual Coordinates Mapping
  [PASS] WindowInfo Metadata Filtering and Ordering
  [PASS] ScreenContextManager Lifecycle & Memory Purge
  [PASS] Accessibility Visual Context Hierarchy Summary
  [PASS] Screen Awareness Mode and Capture State Transitions
  [PASS] Gemini Multimodal Vision Payload Request Construction
  [PASS] Coordinate Mapper Bounds and Clamping
  [PASS] Multi-Display Negative Coordinate Mapping V2
  [PASS] Screenshot Pixel to Desktop Coordinate Mapping
  [PASS] Window-Relative to Global Coordinate Mapping
  [PASS] Element Locator Exact & Fuzzy Scoring
  [PASS] Element Locator Ambiguity Detection
  [PASS] Structured Action Proposal Parser from AI
  [PASS] High-Risk Action Confirmation Gating
  [PASS] High-Risk Action Cancellation/Rejection
  [PASS] MouseActionManager Mock Event Pipeline
  [PASS] MouseActionManager Safe Button State Release
  [PASS] KeyboardActionManager Mock Keystroke Pipeline
  [PASS] KeyboardActionManager Destructive Command Interception
  [PASS] Emergency Stop Instant Failsafe & Latch Reset
  [PASS] Action Verification Manager Outcome Evaluation
  [PASS] Action History Recording & Memory Clearing
  [PASS] Prompt Injection Defense in System Templates
  [PASS] Task Planner Multi-Step Plan Generation
  [PASS] Task Plan Step Dependencies and Progress
  [PASS] Tool Registry Built-in Tool Catalog
  [PASS] Tool Dispatcher Synchronous/Async Execution
  [PASS] Tool Dispatcher Missing Tool & Error Handling
  [PASS] Agent Permission Manager Validation
  [PASS] Agent Task Status Lifecycle Transitions
  [PASS] Agent Orchestrator Task Initiation & Pause
  [PASS] Agent Orchestrator Task Cancellation
  [PASS] Task Executor Step Execution Pipeline
  [PASS] Agent Safety Manager Approval Gating
  [PASS] Agent Safety Manager Approval Request Details
  [PASS] Prompt Injection External Content Sanitizer
  [PASS] Local Memory Storage and Key Updates
  [PASS] Local Memory Category Partitioning and Querying
  [PASS] Local Memory Search and Relevance Ranking
  [PASS] Local Memory Sensitive Data Rejection
  [PASS] Local Memory Disabled Storage Policy
  [PASS] Memory Retrieval Manager Task Grounding
  [PASS] Conversation Summarizer Multi-Turn Compaction
  [PASS] Local File Manager Directory Listing and Path Guard
  [PASS] Unified Permission Hub Refresh and Query
  [PASS] Speech Recognition Permission Configuration
  [PASS] Notification Permission Configuration
  [PASS] Privacy Data Purge Granular Isolation
  [PASS] Privacy Master Purge Keychain and State
  [PASS] Onboarding Steps and State Transitions
  [PASS] App Lifecycle Power State Handling
  [PASS] Concurrent AI Request Cancellation
  [PASS] End-to-End Voice to Agent Task Pipeline
  [PASS] System Information & Brand Bundle Integrity
  [PASS] Keychain Key Replacement and Revocation
  [PASS] Hardware Release Failsafe on Emergency Stop

-------------------------------------------------------
TOTAL: 84 | PASSED: 84 | FAILED: 0
=======================================================
```

### 1.3 Launch the Application
To run AUTO as a native menu bar accessory:
```bash
swift run AUTO
# or
./.build/debug/AUTO
```
Once launched:
- An AUTO mascot icon appears in the macOS menu bar.
- Left-clicking the icon toggles the floating Companion Panel.
- Right-clicking the icon opens the native context menu (Open, Settings, Push-to-Talk, Screen Sharing, Emergency Stop, About, Quit).
- Press and hold **Control (⌃)** anywhere on macOS to speak to AUTO; release to transmit and hear speech feedback.
- Saying *"Stop"* at any time instantly halts active automation via the hardware failsafe latch.
- In Settings, configure Gemini API keys, voice preferences, Screen Awareness, and Automation permissions.

---

## 2. Opening in Xcode

You can open the project directly in Xcode:
```bash
open Package.swift
```
Select the `AUTO` scheme and click **Run** (`Cmd + R`).

---

## 3. Required macOS Permissions

When using AUTO for voice, screen understanding, and automated desktop interaction, macOS will request:
1. **Accessibility**: For UI element hierarchy inspection (`AXUIElement`) and mouse/keyboard input simulation (`CGEvent`).
2. **Screen Recording**: For multi-monitor visual reasoning (`ScreenCaptureKit`).
3. **Microphone**: For Push-to-Talk voice capture (`AVAudioEngine`).
4. **Speech Recognition**: For on-device voice transcription (`SFSpeechRecognizer`).
5. **Input Monitoring**: For physical Control-key state observation (`CGEvent.tapCreate`).

---

## 4. Packaging Release Application Bundle (.app) & DMG Installer

To build the release distribution package:
```bash
./scripts/package_app.sh
```

This compiles AUTO with release optimizations, creates a valid `AUTO.app` bundle with `Info.plist`, `AppIcon.icns`, and hardened entitlements, applies ad-hoc code signing, and packages an `AUTO-1.0.0.dmg` installer disk image with an `/Applications` shortcut.

Generated artifacts:
- `dist/AUTO.app` (16 MB)
- `dist/AUTO-1.0.0.dmg` (11 MB)
