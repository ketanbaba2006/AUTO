# Audio Privacy & Security Architecture

## 1. Zero Background Listening

AUTO adheres to a strict zero-background-listening architecture:

1. **No Hotword Daemons**: Unlike conventional voice assistants (e.g. Siri, Alexa), AUTO **never** keeps the microphone open in the background listening for wake words like "Hey AUTO".
2. **Strict Hardware Activation**: The audio capture tap (`AVAudioEngine.inputNode`) is activated **only** when the user physically presses and holds the push-to-talk modifier key (or clicks the UI microphone button).
3. **Immediate Hardware Teardown**: The moment the key is released, `AudioCaptureManager.stopCapture()` tears down the buffer tap and halts the audio engine. The macOS orange microphone indicator in the menu bar immediately extinguishes.

---

## 2. Ephemeral Audio Processing

- **Zero Audio Storage**: Audio buffers captured in memory (`AVAudioPCMBuffer`) are streamed directly to Apple's recognition pipeline and discarded immediately after RMS calculation.
- **No Disk Caching**: No `.wav`, `.m4a`, or `.mp3` files are ever written to the macOS file system (`/tmp`, `~/Library`, or elsewhere).
- **No Third-Party Speech Telemetry**: Audio data is never forwarded to third-party transcription services or analytics endpoints.
- **Immediate Interruption Purge**: If an interaction is cancelled or interrupted mid-turn, pending recognition requests are aborted and audio buffers are dereferenced immediately.

---

## 3. Sandboxing & macOS Privacy Controls

- Microphone access is requested explicitly using `AVCaptureDevice.requestAccess(for: .audio)`.
- Users can revoke access at any time in **System Settings > Privacy & Security > Microphone**.
- If microphone permission is revoked, AUTO displays an explicit notice and guides the user to System Settings without crashing.

