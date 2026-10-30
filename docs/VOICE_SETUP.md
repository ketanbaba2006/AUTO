# AUTO Voice Interaction & Push-to-Talk Guide

## 1. Overview

AUTO provides a live, low-latency conversational voice experience inspired by HeyClicky. Unlike chat assistants that require manual clicking to record, AUTO uses a native **Global Hold-Control Push-to-Talk** mechanism.

---

## 2. Interaction Lifecycle

```
[ User Holds Control (⌃) ]
         │
         ▼
[ Capture & Real-Time Waveform ] ──> AudioCaptureManager taps AVAudioEngine
         │
[ User Speaks Naturally ]       ──> VoiceActivityDetector calculates RMS
         │
[ User Releases Control (⌃) ]   ──> Recording stops immediately
         │
         ▼
[ Speech Recognition Engine ]   ──> Apple Speech Framework (On-device / Cloud)
         │
         ▼
[ Gemini AI Streamed Answer ]   ──> Streamed chunks arrive in Companion Panel
         │
         ▼
[ Natural Speech Synthesis ]    ──> AVSpeechSynthesizer speaks response aloud
```

---

## 3. Keyboard Shortcut & Push-to-Talk

### Default Shortcut: Left or Right `Control` (⌃)
- **Hold `Control`**: The companion mascot transitions to the listening state with an animated waveform and cyan glow.
- **Speak Naturally**: Audio is streamed into the recognition pipeline in real time.
- **Release `Control`**: Audio ingestion cuts off instantly, and AUTO begins reasoning.

### Custom Hotkey Configuration
In **Settings -> Voice**, you can customize:
- Trigger Key: `Left Control`, `Right Control`, `Option`, or `Fn`.
- Double-Tap mode: Tap twice to lock listening on/off (hands-free).

---

## 4. Instant Speech Interruption

When AUTO is speaking aloud through text-to-speech, you can interrupt at any millisecond:
1. **Hold `Control` again**: Immediately silences speech output and begins listening for your next request.
2. **Say *"Stop"* or *"Quiet"***: Halts the active speech synthesizer.
3. **Click the red Stop button** in the Companion Panel header.

---

## 5. Audio Settings & Device Selection

In **Settings -> Voice**:
- **Input Device**: Select from all connected physical and virtual microphones (e.g., MacBook Built-in, AirPods, Studio USB).
- **Speech Rate**: Adjust companion voice playback speed (0.5x to 2.0x).
- **Auto-Speak Responses**: Toggle whether textual AI responses are read aloud or kept text-only.
- **Audio Chimes**: Subtle, non-intrusive sound cues on listening start and finish.

