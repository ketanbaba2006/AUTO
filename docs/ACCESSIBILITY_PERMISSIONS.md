# AUTO: macOS Accessibility and Input Monitoring Permissions

This guide explains the macOS permission requirements for **AUTO**, how permissions are requested and verified, and how known application limitations are handled.

---

## 1. Required macOS Permissions

To locate UI controls, guide the cursor, and perform automated desktop interactions, AUTO requires:

| Permission | System Setting Category | Purpose in AUTO |
| :--- | :--- | :--- |
| **Accessibility** | Privacy & Security > Accessibility | Inspecting accessible UI trees via `AXUIElement`, simulating mouse and keyboard events via `CGEvent` |
| **Screen Recording** | Privacy & Security > Screen Recording | Visual screen understanding via `ScreenCaptureKit` |
| **Input Monitoring** | Privacy & Security > Input Monitoring | Detecting global Push-to-Talk ⌃ Control press/release |
| **Microphone** | Privacy & Security > Microphone | Hardware voice recording via `AVAudioEngine` |
| **Speech Recognition**| Privacy & Security > Speech Recognition | Local speech-to-text via `SFSpeechRecognizer` |

---

## 2. Permission Verification Pipeline (`ActionPermissionManager`)

1. **Preflight Checking**:
   - `AXIsProcessTrusted()` verifies whether the application process is trusted by macOS WindowServer.
   - Performed nonisolated and synchronously before every mouse movement or key event.
2. **User Authorization Flow**:
   - `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])` displays Apple's native authorization dialog if trust is missing.
   - Deep links redirect directly to:
     - Accessibility: `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
     - Input Monitoring: `x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent`
3. **Revocation & Graceful Degradation**:
   - If Accessibility permission is revoked while the app is running, actions fail with typed error `AUTOError.permissionDenied`.
   - AUTO degrades gracefully to visual guidance mode (pointing only, no clicking).

---

## 3. Known Application Compatibility Limitations

Not every application on macOS exposes a full, clean Accessibility tree:

1. **Electron and Chromium Applications**:
   - Some web-based apps disable accessibility tree generation by default for performance until requested by a screen reader.
   - *AUTO's Fallback*: When accessibility element matching returns low confidence, AUTO falls back to screenshot visual analysis via Gemini vision (`[POINT:x,y:Label:screenN]`).
2. **Games and OpenGL/Metal Custom Renderers**:
   - Fullscreen 3D games and custom Canvas applications do not implement standard macOS `NSView` accessibility hierarchies.
   - Visual coordinate pointing remains functional via Gemini multimodal spatial analysis.
3. **Password & Secure Input Fields**:
   - macOS security mechanisms deliberately obscure password fields (`kAXRole = "AXSecureTextField"`).
   - AUTO's safety engine enforces that secure fields are never read or logged.

