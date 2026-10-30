# AUTO Troubleshooting Guide

This guide covers common issues, diagnostics, and recovery steps.

---

## 1. Push-to-Talk Does Not Respond to `Control`

### Cause
macOS requires **Accessibility** and **Input Monitoring** permissions to monitor global modifier key events when AUTO is in the background.

### Resolution
1. Open **macOS System Settings -> Privacy & Security -> Accessibility**.
2. Ensure **AUTO** is toggled **ON**.
3. Open **Privacy & Security -> Input Monitoring** and verify **AUTO** is toggled **ON**.
4. If already enabled, toggle it OFF and back ON to force macOS TCC daemon to reload the permission ticket.
5. In AUTO, go to **Settings -> Permissions** and click **Refresh All Permissions**.

---

## 2. Speech Recognition Reports No Audio or Empty Transcription

### Cause
The active microphone device is muted or permissions were withheld.

### Resolution
1. Open **Settings -> Voice** in AUTO.
2. Confirm your desired microphone (e.g. *MacBook Pro Microphone* or *AirPods*) is selected.
3. Check the **Audio Meter** while holding `Control` and speaking. You should see dynamic waveform movement.
4. If no movement is observed, open **System Settings -> Privacy & Security -> Microphone** and verify AUTO is permitted.

---

## 3. Screen Capture Is Blank or Black

### Cause
macOS ScreenCaptureKit requires **Screen Recording** permission. If granted while the app was running, macOS often requires an app relaunch.

### Resolution
1. Open **System Settings -> Privacy & Security -> Screen Recording**.
2. Verify **AUTO** is listed and enabled.
3. Completely quit AUTO (`Right-click menu bar mascot -> Quit AUTO`) and re-open.
4. In AUTO **Settings -> Screen**, click **Test Capture Now** to verify your displays render properly.

---

## 4. Google Gemini 403 (Forbidden) or 429 (Rate Limit) Errors

### Cause
- **403 Forbidden**: The API key is invalid, lacks Generative Language API enablement, or has expired.
- **429 Too Many Requests**: You have exceeded the free tier RPM (requests per minute) quota on your Google AI Studio account.

### Resolution
1. Verify your key in [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Open **Settings -> Gemini** in AUTO.
3. Click **Remove Key**, paste the fresh key, click **Save to Keychain**, and click **Test API Connection**.
4. If encountering 429 limits, wait 60 seconds or switch to a secondary key. Fixed voice commands and screen OCR continue to work locally offline.

---

## 5. Offline Mode & Local Engine Fallback

### Behavior
When no internet connection is available or the Gemini API is unreachable, AUTO automatically shifts into **Local Offline Mode**.

### What Works Locally Offline
1. **Push-to-Talk Fixed Commands**: "Where is my cursor?", "Read my screen", "Emergency stop", "List files on Desktop".
2. **Apple Vision OCR**: On-device text recognition continues without network access.
3. **Local SQLite Memory**: Querying previous context and preferences.
4. **Desktop Automation & Failsafes**: All CoreGraphics cursor movements, clicks, and Emergency Stop remain 100% active.

### Resolution for Full Reasoning
1. Check your network or Wi-Fi connection.
2. Verify that `generativelanguage.googleapis.com` is reachable from your network.

---

## 6. Cursor Does Not Move to UI Controls

### Cause
1. Target application is running with elevated privileges (e.g., `sudo` terminal).
2. Target application uses an unsupported canvas (e.g. legacy Java Swing or games that bypass standard AppKit accessibility trees).

### Resolution
- Verify Accessibility permission is active.
- For non-standard web or game canvases, AUTO will provide spatial coordinate guidance reticles rather than attempting hardware synthetic clicks.

---

## 7. App Won't Open Due to "Unidentified Developer"

### Cause
AUTO is an independent application signed with ad-hoc certificates.

### Resolution
1. Right-click `AUTO.app` in `/Applications`.
2. Select **Open**.
3. Click **Open** in the confirmation alert.

