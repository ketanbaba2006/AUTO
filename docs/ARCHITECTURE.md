# AUTO System Architecture

## 1. High-Level System Architecture

AUTO is built entirely in native Swift, leveraging SwiftUI for reactive UI rendering and AppKit for window management, status bar menus, event monitoring, ScreenCaptureKit, Accessibility APIs (`AXUIElement`), and CoreGraphics input simulation.

```
┌────────────────────────────────────────────────────────┐
│                        macOS                           │
└────────────────────────────────────────────────────────┘
          ▲                                    ▲
          │ Status Item                        │ Global CGEvent Tap
┌────────────────────────┐           ┌────────────────────────┐
│    MenuBarManager      │           │   PushToTalkManager    │
└────────────────────────┘           └────────────────────────┘
          │                                    │
          ▼                                    ▼
┌────────────────────────┐           ┌────────────────────────┐
│ CompanionWindowManager │           │  VoiceSessionManager   │
│   (Floating NSPanel)   │           └────────────────────────┘
└────────────────────────┘                     │
          │                                    ▼
          │                            ┌───────────────────────┐
          │                            │  AudioCaptureManager  │
          │                            └───────────────────────┘
          ▼                                    │
┌──────────────────────────────────────────────┴──────────┐
│                    ApplicationState                     │
│               (@MainActor ObservableObject)             │
└─────────────────────────────────────────────────────────┘
          │                     │                     │
          ▼                     ▼                     ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  AIProvider      │  │  ScreenCapture   │  │  Automation &    │  │  Autonomous      │
│  Manager         │  │  & Visual Intel  │  │  Cursor Control  │  │  Agent Engine    │
│  (Gemini/Omni)   │  │  (SCKit, Vision) │  │  (Fragment 5)    │  │  (Fragment 6)    │
└──────────────────┘  └──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 2. Directory Structure

```
AUTO/
├── App/
│   ├── AUTOApp.swift                     // SwiftUI App entry point with CLI test runner
│   ├── AppDelegate.swift                 // NSApplicationDelegate, accessory mode
│   └── AppLifecycleManager.swift         // Power/sleep/wake lifecycle orchestration
├── Core/
│   ├── ApplicationState.swift            // Central observable state
│   ├── CompanionManager.swift            // Central coordinator
│   ├── DependencyContainer.swift         // Dependency injection container
│   ├── EventManager.swift                // Publisher-subscriber event bus
│   └── PermissionManager.swift           // Mic, Screen, Accessibility, Input Monitoring
├── Views/
│   ├── CompanionPanelView.swift          // Companion view with live indicators & emergency stop
│   ├── ConversationView.swift            // Dialogue exchanges and message composer
│   ├── SettingsView.swift                // Multi-tab native settings interface (AI, Voice, Screen, Automation, Memory)
│   ├── OnboardingView.swift              // Multi-step user onboarding flow
│   └── Components/
│       ├── AudioWaveformView.swift       // Live audio metering waveform
│       ├── PermissionRow.swift           // Permission status and deep-link button
│       └── StatusBadge.swift             // Pulsing status indicators
├── Windows/
│   ├── MenuBarManager.swift              // NSStatusItem and custom vector icon
│   ├── CompanionWindowManager.swift      // Borderless floating NSPanel
│   └── OverlayWindowManager.swift        // Multi-monitor pass-through overlay windows
├── AI/
│   ├── AIProvider.swift                  // AI provider protocol
│   ├── AIProviderManager.swift           // Central AI manager with Zero-Screenshot privacy gating
│   ├── GeminiProvider.swift              // Production Google Gemini API client
│   ├── ModelDiscoveryManager.swift       // Dynamic model querying and caching
│   ├── PromptManager.swift               // Structured system prompts, injection defenses, action tags
│   └── ImageProcessor.swift              // Image payload downsampling & base64 encoding
├── LocalEngine/
│   ├── AutoExecutionEngine.swift         // Central local execution coordinator
│   ├── AutoToolRegistry.swift            // Modular catalog of 16+ built-in local tools
│   ├── AutoActionValidator.swift         // Coordinate bounds clamping and injection firewall
│   ├── AutoTaskManager.swift             // Multi-step task planner and dependency tracker
│   ├── AutoMemoryManager.swift           // Native SQLite local storage with regex sensitive firewall
│   ├── AutoConversationManager.swift     // Local turn storage and history compaction
│   ├── AutoScreenManager.swift           // ScreenCaptureKit capture and Apple Vision on-device OCR
│   ├── AutoCursorManager.swift           // Cubic Bezier cursor trajectories and clicks
│   ├── AutoKeyboardManager.swift         // CGEvent keyboard typing and hotkeys
│   ├── AutoVoiceManager.swift            // AVFoundation, Apple Speech, and offline voice parser
│   ├── AutoFileManager.swift             // Sandboxed safe directory file operations
│   ├── AutoSafetyManager.swift           // 3-tier risk gating and instant Emergency Stop (<10ms)
│   └── AutoResultVerifier.swift          // Native post-execution outcome verification
├── Agent/
│   ├── AgentManager.swift                // Autonomous companion agent coordinator
│   ├── AgentOrchestrator.swift           // Multi-step task execution coordinator & lifecycle
│   ├── TaskPlanner.swift                 // Natural language task decomposition & dependency resolution
│   ├── TaskExecutor.swift                // Safe step execution pipeline with verification
│   ├── ToolRegistry.swift                // Modular catalog of 16+ built-in tools across 6 categories
│   ├── ToolDispatcher.swift              // Tool execution router with permissions & timeouts
│   ├── MemoryManager.swift               // Thread-safe local JSON persistent memory with sensitive data guard
│   ├── MemoryRetrievalManager.swift      // Relevance ranking and prompt injection context grounding
│   ├── ConversationSummarizer.swift      // Multi-turn conversation compaction and history compression
│   ├── AgentSafetyManager.swift          // Risk classification, consequences explanation, prompt injection sanitizer
│   ├── AgentPermissionManager.swift      // Pre-execution permission verification
│   ├── TaskVerificationManager.swift     // Post-action state verification (app activation, files, visual)
│   ├── LocalFileManager.swift            // Sandboxed file operations (Desktop, Downloads, Documents)
│   ├── ConversationManager.swift         // Dialogue turns, streaming, spatial targeting & action dispatch
│   ├── ConversationMemory.swift          // Thread-safe turn history with context limits
│   └── ToolExecutionManager.swift        // Tool invocation bridge
├── Voice/
│   ├── PushToTalkManager.swift           // Global CGEvent tap for modifier shortcuts
│   ├── AudioCaptureManager.swift         // AVAudioEngine input tap and metering
│   ├── SpeechRecognitionManager.swift    // SFSpeechRecognizer & Apple Whisper engine
│   ├── SpeechOutputManager.swift         // AVSpeechSynthesizer natural speech
│   └── VoiceSessionManager.swift         // Push-to-talk voice session coordinator & "Stop" voice trigger
├── Screen/
│   ├── ScreenCaptureManager.swift        // Native ScreenCaptureKit display & window capture
│   ├── ScreenCapturePermissionManager.swift // TCC preflight & permission deep-linking
│   ├── DisplayManager.swift              // Multi-monitor virtual coordinate coordinator
│   ├── WindowCaptureManager.swift        // Shareable window discovery and capture
│   ├── ScreenshotProcessor.swift         // Retina downsampling & legibility JPEG encoding
│   ├── AccessibilityVisualInspector.swift// Frontmost app/window hierarchy grounding
│   ├── ScreenCoordinateManager.swift     // Normalized <-> Global coordinate translation
│   └── ScreenContextManager.swift        // Central visual context coordinator
├── Cursor/
│   ├── CursorManager.swift               // Spatial target coordinate coordinator
│   ├── CursorOverlayView.swift           // Custom cursor drawing, targeting reticle & click ripple
│   ├── CursorOverlayManager.swift        // State manager for overlay badges, ripples, and reticles
│   ├── CursorAnimationManager.swift      // Bezier spring curve animator
│   └── ElementLocationDetector.swift     // Spatial point parser
├── Automation/
│   ├── CoordinateMapper.swift            // Multi-monitor, Retina, and negative desktop coordinate mapping
│   ├── ActionPermissionManager.swift     // AXIsProcessTrusted preflight and System Settings links
│   ├── AccessibilityElementManager.swift // AXUIElement hierarchy discovery & traversal
│   ├── ElementLocator.swift              // Natural language control matching, scoring & ambiguity detection
│   ├── MouseActionManager.swift          // CGEvent mouse movement, clicking, dragging, scrolling & release
│   ├── KeyboardActionManager.swift       // CGEvent Unicode keystrokes, shortcuts & command safety
│   ├── ActionProposalParser.swift        // Extracts & sanitizes [ACTION:{...}] proposals from AI
│   ├── ActionVerificationManager.swift   // Verifies application activation and element state changes
│   ├── EmergencyStopManager.swift        // Instant local failsafe and hardware latch reset
│   └── ActionExecutionManager.swift      // Risk classification, confirmation gating & execution state machine
├── Security/
│   ├── KeychainManager.swift             // Native Apple Keychain wrapper
│   └── PrivacyManager.swift              // Zero telemetry and ephemeral data manager
├── Models/
│   ├── AIModels.swift                    // Provider configs, tokens, routing rules
│   ├── ApplicationModels.swift           // Preferences, display info, permissions
│   ├── ConversationModels.swift          // Turns, sessions, messages
│   ├── VoiceModels.swift                 // Voice states, triggers, audio levels
│   ├── ScreenModels.swift                // Modes, WindowInfo, VisualScreenContext
│   ├── AutomationModels.swift            // Action types, risk levels, AccessibleUIElement, records
│   └── AgentModels.swift                 // AgentTaskPlan, AgentTaskStep, AgentMemoryItem, ToolDefinition
└── Utilities/
    ├── Logger.swift                      // Structured unified os.log wrapper
    ├── ErrorHandler.swift                // Typed AUTOError enum
    └── AUTOTestSuite.swift               // Comprehensive offline automated test runner (84 tests)
```

---

## 3. Seven Fragments Development Roadmap

- **Fragment 1**: Foundation, Architecture and Native macOS Application (*Complete*)
- **Fragment 2**: Complete AI Engine, Google Gemini API & Hybrid Architecture (*Complete*)
- **Fragment 3**: Live Voice Conversations, Push-to-Talk and Natural AI Speech (*Complete*)
- **Fragment 4**: Screen Capture, Screen Sharing and Visual Intelligence (*Complete*)
- **Fragment 5**: Cursor Intelligence, Mouse Control and Visual Interaction (*Complete*)
- **Fragment 6**: Intelligent AI Agent, Memory and Autonomous Task Planning (*Complete*)
- **Fragment 7**: Integration, Security, Testing, Packaging and Release (*Complete*)
