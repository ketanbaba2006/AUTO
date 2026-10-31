# AUTO Offline Capabilities & Network Resilience

## Overview

A fundamental advantage of the **AUTO Hybrid Architecture** is that execution is detached from cloud connectivity. While Google Gemini provides advanced linguistic reasoning when connected to the internet, **AUTO's native engine remains active and capable even when completely offline**.

---

## 1. Capabilities Matrix: Online vs. Offline

| Capability | Online Mode | Offline Mode | Offline Implementation |
| :--- | :---: | :---: | :--- |
| **Push-to-Talk Voice Capture** | ✅ | ✅ | Apple Speech framework (`SFSpeechRecognizer`) with on-device speech models |
| **Speech Output (TTS)** | ✅ | ✅ | `AVSpeechSynthesizer` with high-quality local Siri / system voices |
| **Fixed Offline Voice Commands** | ✅ | ✅ | Regex and intent keyword parser in `AutoVoiceManager` |
| **Screen Capture** | ✅ | ✅ | `ScreenCaptureKit` / `CGDisplayStream` |
| **Optical Character Recognition (OCR)** | ✅ | ✅ | Apple Vision framework (`VNRecognizeTextRequest`) on Apple Silicon Neural Engine |
| **Mouse Cursor Control & Bezier Paths** | ✅ | ✅ | CoreGraphics `CGEvent` and `AutoCursorManager` |
| **Hardware Clicks & Keyboard Typing** | ✅ | ✅ | CoreGraphics event injection & `AutoKeyboardManager` |
| **Local Memory Storage & Search** | ✅ | ✅ | Native SQLite engine (`AutoMemoryManager`) |
| **Sandboxed File Operations** | ✅ | ✅ | `AutoFileManager` (`~/Desktop`, `~/Downloads`, `~/Documents`) |
| **Emergency Stop (<10ms)** | ✅ | ✅ | Hardware event release in `AutoSafetyManager` |
| **Multi-Turn Complex Reasoning** | ✅ | ❌ | Requires Google Gemini API connection |
| **Open-Ended Instruction Decomposition**| ✅ | ❌ | Requires Google Gemini API connection |

---

## 2. Fixed Voice Commands in Offline Mode

When offline or when no Gemini API key is configured, `AutoVoiceManager` transparently detects supported deterministic voice commands and dispatches them directly to the local engine:

- **"Stop" / "Emergency Stop" / "Cancel"**: Instantly triggers Emergency Stop, halting all actions and releasing inputs.
- **"Where is my cursor?"**: Announces the active cursor coordinates and current display index.
- **"Read my screen" / "What's on screen?"**: Triggers on-device Apple Vision OCR and reads the extracted text aloud.
- **"Clear memory"**: Clears conversation turn cache and resets session state.
- **"List files on Desktop"**: Lists the first 10 items in `~/Desktop` via `AutoFileManager`.

---

## 3. Honest Offline Degradation Policy

> [!NOTE]
> AUTO does not deceive the user by fabricating responses or running pseudo-LLMs when disconnected.

When a user issues a complex, open-ended instruction that requires high-level cognitive reasoning while offline:
1. AUTO detects network unavailability or Gemini API unreachable status.
2. The companion voice speaks a transparent status message:
   *"I am currently operating in local offline mode without an internet connection. I can capture your screen, read text, or move the cursor, but complex reasoning requires Google Gemini. Please check your network connection."*
3. The Companion UI displays a clear offline indicator and status banner without freezing or crashing.

