# Screen Capture Privacy & Security Architecture

## 1. Zero Secret Recording Principle

AUTO enforces strict transparency for all screen capture operations:

1. **Explicit User Authorization**: Screen capture cannot occur without explicit macOS Screen Recording permission granted in **System Settings > Privacy & Security > Screen Recording**.
2. **Visual Indicators**:
   - Whenever an active screen sharing session is enabled, the floating Companion Panel displays an illuminated cyan screen sharing badge.
   - During active capture and processing, the state machine explicitly transitions to `.capturing` and `.processing`.
   - macOS displays its system screen-recording indicator in the menu bar.
3. **Immediate Stop Control**: Users can immediately stop screen sharing via a dedicated button in Settings or Companion Panel.

---

## 2. Ephemeral In-Memory Storage

- **No Disk Retention**: Screen captures are held as transient `Data` and `CGImage` buffers in volatile RAM during AI reasoning.
- **Zero Disk Writes**: AUTO never writes `.png`, `.jpg`, `.mov`, or video files to disk (`/tmp`, `~/Library`, or elsewhere).
- **Immediate Memory Purge**: When an interaction turn concludes or when `ScreenContextManager.shared.clear()` is called, screenshot references are dereferenced and eligible for ARC deallocation immediately.
- **No Third-Party Analytics**: Visual captures are processed locally with Apple Vision OCR. If image transmission is enabled by the user, payloads are sent solely to Google Gemini over TLS. No third-party analytics or telemetry platforms ever receive screen data.

---

## 3. Exclusion of AUTO Windows

To prevent visual recursion and preserve interface privacy:
- `SCShareableContent` filters out all windows belonging to AUTO's own bundle identifier (`com.auto.desktop`).
- The companion panel, settings window, and cursor overlay windows are never included in screenshots sent to the AI.

