# Changelog

All notable changes to **AUTO** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-31

### Added
- **Native Foundation & Architecture (Fragment 1)**:
  - Menu bar accessory with custom vector mascot icon and native context menu.
  - Floating borderless Companion Panel with live indicators and audio waveforms.
  - Transparent non-activating multi-display overlays (`OverlayWindowManager`).
  - Hardware power and sleep/wake lifecycle management (`AppLifecycleManager`).
- **Complete AI Infrastructure (Fragment 2)**:
  - Google Gemini API primary integration with streaming responses and model discovery.
  - OmniRoute Gateway optional provider for local models (Ollama, LM Studio) and custom endpoints.
  - Dynamic AI routing rules with automatic fallback from OmniRoute to Gemini.
  - Hardware-backed Apple Keychain storage (`KeychainManager`).
- **Live Push-to-Talk Voice Conversations (Fragment 3)**:
  - Global Hold-Control push-to-talk shortcut using low-level `CGEvent` taps.
  - Real-time `AVAudioEngine` capture with Voice Activity Detection (RMS energy).
  - Apple Speech transcription (`SFSpeechRecognizer`).
  - Natural speech output via `AVSpeechSynthesizer` with instant speech interruption.
- **Official Mascot Branding**:
  - Integrated friendly futuristic white robot mascot with glowing cyan eyes.
  - Vector menu bar template rendering and high-resolution icons across Dock and panel.
- **Screen Intelligence & Visual Understanding (Fragment 4)**:
  - Native ScreenCaptureKit capture across multi-monitor virtual coordinate spaces.
  - Window inspection and display selection.
  - Ephemeral in-memory image processing with Retina downsampling and JPEG encoding.
- **Cursor Intelligence & Desktop Automation (Fragment 5)**:
  - Accessibility element hierarchy discovery (`AXUIElement`).
  - Natural language control matching with fuzzy scoring and ambiguity detection.
  - Smooth Bezier cursor guidance and hardware mouse/keyboard simulation.
  - Three-tier action risk gating with modal user confirmation for destructive actions.
  - Instant triple-channel Emergency Stop (<10ms latency).
- **Autonomous Agent, Memory & Task Planning (Fragment 6)**:
  - Multi-step task planner with step dependencies (`dependencies: [UUID]`).
  - Modular tool registry with 16+ built-in tools across 6 functional domains.
  - Sandboxed local file operations (`~/Desktop`, `~/Downloads`, `~/Documents`) with restricted path guards.
  - Private persistent local JSON memory (`agent_memory.json`) with sensitive data scanner.
  - Conversation summarization for infinite context without token bloat.
- **Production Integration, Security & Packaging (Fragment 7)**:
  - Concurrency hardening across all managers (Swift 6 `@MainActor` safety).
  - Unified Permissions Hub in Settings and 5-step interactive onboarding wizard.
  - Dedicated Privacy section with local vs. remote processing disclosures and granular purging.
  - Automated release packaging script producing signed `AUTO.app` (16 MB) and mountable `AUTO-1.0.0.dmg` (11 MB).
  - 84 automated unit and integration tests passing with 100% success.

