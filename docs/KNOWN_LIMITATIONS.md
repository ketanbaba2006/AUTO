# AUTO Known Limitations & Platform Constraints

In commitment to transparency and engineering integrity, this document details all known platform limitations, macOS security boundaries, and edge cases.

---

## 1. Operating System Compatibility
- **macOS 14.0 (Sonoma) or Later Required**: AUTO relies heavily on modern `ScreenCaptureKit` APIs, Swift 6 Concurrency (`@MainActor`), and AppKit panel accessories introduced in macOS 14. macOS 13 (Ventura) and earlier are not supported.

---

## 2. Secure Input Mode & Password Fields
- **Platform Behavior**: When any macOS application enters Secure Event Input mode (e.g., when the user focuses a password field in Terminal, 1Password, or a system authorization prompt), macOS disables global `CGEvent` taps to protect against keyloggers.
- **Companion Impact**: The global `Control` push-to-talk shortcut cannot be detected during active password entry.
- **Workaround**: Click the companion mascot directly in the Floating Panel to initiate voice conversation, or wait until password entry is complete.

---

## 3. DRM-Protected Content & Full-Screen Video
- **Platform Behavior**: Apple's `ScreenCaptureKit` intentionally renders protected media (e.g., Apple TV+, Netflix, protected iTunes video) as solid black rectangles in screen capture streams.
- **Companion Impact**: AUTO cannot visually inspect or assist with protected streaming video content.

---

## 4. Non-Standard UI Frameworks
- **Platform Behavior**: AUTO's `AccessibilityElementManager` traverses standard macOS accessibility trees (`AXUIElement`).
- **Companion Impact**: Applications that render custom pixel canvases without accessibility wrappers (such as WebGL games, non-accessible Flutter web apps, or raw Java Swing applications) do not expose child UI elements.
- **Graceful Fallback**: AUTO detects when an element cannot be targeted natively and provides spatial visual reticle pointing instead of attempting synthetic clicks.

---

## 5. Cloud AI Network & Quota Constraints
- **Platform Behavior**: While AUTO is 100% free software, Google Gemini is an external cloud service operated by Google DeepMind.
- **Companion Impact**: An active internet connection is required when using Gemini. Gemini API keys are subject to Google AI Studio's pricing, quotas, and requests-per-minute limits.
- **Offline Alternative**: For 100% offline and free local AI reasoning, users can connect local open-source models (e.g. Llama 3 via Ollama) through the optional OmniRoute Gateway.

---

## 6. Ad-Hoc Code Signing Notice
- **Platform Behavior**: AUTO is packaged with ad-hoc signatures by default so anyone can build and distribute it without paying Apple's \$99/year developer fee.
- **Companion Impact**: Gatekeeper will display a one-time *"unidentified developer"* prompt on first launch.
- **Resolution**: Right-click `AUTO.app` -> Select **Open** -> Click **Open**.

