# Push-to-Talk (PTT) Setup & Configuration

## 1. Overview

AUTO uses physical key press and release detection to provide a walkie-talkie style AI companion experience. By default, pressing and holding the **Control (⌃)** key captures your voice; releasing the key finishes the utterance and triggers the assistant's response.

---

## 2. macOS Accessibility Requirements

Global key monitoring in macOS requires Accessibility permissions:

1. When AUTO is first launched, macOS will prompt to grant Accessibility permissions.
2. If skipped, open **System Settings > Privacy & Security > Accessibility**.
3. Enable the checkbox / toggle next to **AUTO** (or `Terminal` / `Xcode` if running from developer tools).
4. `PushToTalkManager` automatically detects when permission is granted and installs the event tap without requiring an application restart.

> [!NOTE]
> Even if Accessibility permission has not yet been granted, users can still click the microphone button in the AUTO companion panel to simulate push-to-talk.

---

## 3. Supported Trigger Hotkeys

Users can change the global push-to-talk key in **Settings > Voice > Push-to-Talk Trigger**:

| Trigger Option | Physical Key(s) | Description |
|---|---|---|
| **Hold Control Key** *(Default)* | `⌃ Control` | Standard HeyClicky interaction pattern. Minimal interference with typical desktop typing. |
| **Hold Option Key** | `⌥ Option` | Convenient for users with keyboards where Control is difficult to reach. |
| **Hold Control + Option** | `⌃ Control` + `⌥ Option` | Dual-key hold to prevent any accidental recording triggers. |
| **Hold Fn Key** | `fn` / `Globe` | Uses the macOS Globe/Fn key. |

---

## 4. Timeout & System Re-arming

macOS periodically pauses event taps if the main thread delays event handling (`kCGEventTapDisabledByTimeout`). AUTO guards against this failure mode:

- The event tap is registered with `options: .listenOnly`, ensuring AUTO never blocks or delays user keyboard input.
- In `PushToTalkManager.handleEventTap`, incoming events with types `.tapDisabledByTimeout` or `.tapDisabledByUserInput` automatically invoke `CGEvent.tapEnable(tap: tap, enable: true)`, recovering the event tap instantly.

