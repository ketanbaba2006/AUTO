# AUTO Privacy & Data Stewardship Policy

## 1. Executive Privacy Philosophy

AUTO is designed as a **private, local-first macOS desktop companion**. It operates without user accounts, mandatory logins, cloud databases, user tracking, or telemetry.

---

## 2. Local vs. Remote Processing Disclosure

In full transparency, here is the exact architectural boundary between operations that execute locally on your Mac and operations that communicate with remote AI services:

### 100% Local Operations (Zero Network Transmission)
The following operations execute strictly on your device and never transmit data over the network:
1. **Push-to-Talk Hotkey Monitoring**: Global `CGEvent` tap listening for the `Control` key.
2. **Audio Capture & Voice Activity Detection**: Local `AVAudioEngine` capture and RMS energy calculation.
3. **Local On-Device Speech Recognition**: Apple `Speech` framework transcription when on-device models are installed.
4. **Desktop Automation & Cursor Control**: `AXUIElement` accessibility hierarchy inspection, Bezier cursor guidance, and CoreGraphics mouse/keyboard simulation.
5. **Multi-Monitor Coordinate Translation**: Virtual-to-screen coordinate math across displays.
6. **Local Persistent Memory**: Long-term preferences and project notes stored on local disk at `~/Library/Application Support/AUTO/agent_memory.json`.
7. **Sandboxed File Operations**: Reading file previews and reorganizing user folders (`Desktop`, `Downloads`, `Documents`).
8. **Emergency Stop System**: Hardware-level button release and task cancellation halts locally in <10ms.
9. **Settings & Key Storage**: Preferences stored in macOS `UserDefaults`; API secrets stored in macOS Keychain.

### Remote AI Operations (Encrypted HTTPS)
When you actively ask AUTO a question or request task assistance:
1. **Google Gemini API**:
   - Spoken or typed prompt text is transmitted to Google Gemini servers over TLS 1.3 HTTPS.
   - Screen text extracted locally by on-device Apple Vision OCR is provided as structured context.
   - Raw screenshot images are only transmitted if the user explicitly turns on `Allow Screenshot Transmission` in Settings.
   - Streaming responses are received over HTTPS chunks.

---

## 3. Ephemeral Screen Capture Architecture

AUTO adheres to an **ephemeral capture policy**:
- **No Background Recording**: AUTO never captures or records screens in the background.
- **Explicit Triggers Only**: Screen captures are triggered exclusively when you ask a screen-related question or execute an action that requires visual grounding.
- **RAM-Only Processing**: Screen captures are held in volatile memory (`CVPixelBuffer` / `CGImage`), compressed to JPEG in RAM, sent to the AI API, and immediately released from memory.
- **No Disk Archival**: Screenshots are never saved to disk, never cached, and never retained.

---

## 4. Ephemeral Audio Architecture

- **No Always-Listening Snooping**: The microphone is tapped only while the `Control` key is actively held down.
- **Instant Microphone Teardown**: Releasing `Control` immediately stops microphone audio ingestion.
- **No Audio Disk Caching**: Raw audio buffers are processed in memory and released. No `.wav` or `.m4a` files are ever created.

---

## 5. Sensitive Credential Rejection

AUTO's memory system ([`MemoryManager.swift`](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Agent/MemoryManager.swift)) automatically scans all incoming memory items for credentials:
- Automatically rejects keys or values containing: `password`, `secret`, `bearer`, `api_key`, `token`, `cvv`, `credit_card`, `pin_number`, `private_key`.
- Prevents accidental storage of confidential authentication secrets in plaintext memory files.

---

## 6. User Privacy Controls

From **Settings -> Privacy**, you have complete granular control:
- **Conversation Retention**: Choose to retain conversation history for 7 days, 30 days, 90 days, or indefinitely.
- **Clear Chat History**: Instantly clears active session dialogue from RAM and storage.
- **Clear Local Memory**: Wipes `agent_memory.json`.
- **Clear Task History**: Wipes logged automation actions from storage.
- **Purge All Local Data**: Wipes all Keychain secrets, local memory, preferences, and cached session data in a single click.

