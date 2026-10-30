# AUTO Voice Architecture & Pipeline (Fragment 3)

## 1. Overview

AUTO provides a native, low-latency voice interaction pipeline for macOS (14.0+) designed around physical push-to-talk (PTT) with instant interruption support. The architecture strictly adheres to native Apple frameworks (`AVFoundation`, `Speech`, `AppKit`, `CoreGraphics`) with zero proprietary third-party voice SDKs, zero subscriptions, and zero cloud lock-in.

```
       [User Holds ⌃ Control]
                 │
                 ▼
     PushToTalkManager (CGEvent Tap)
                 │
                 ▼
        VoiceSessionManager
   ┌─────────────┴─────────────┐
   │                           │
   ▼                           ▼
AudioCaptureManager      SpeechRecognitionManager
(AVAudioEngine Tap)     (SFSpeechAudioBufferRecognitionRequest)
   │                           │
   ▼ (PCM Buffers)             ▼ (Streaming Partials)
VoiceActivityDetector    ApplicationState.currentTranscript
(RMS Calculation)              │
                               │ [User Releases ⌃ Control]
                               ▼
                     Finalized Transcript
                               │
                               ▼
                      ConversationManager
                               │
                               ▼ (AI Model Dispatch: Gemini/OmniRoute)
                     AI Response Text
                               │
                               ▼
                      SpeechOutputManager
                     (AVSpeechSynthesizer)
                               │
               [User Presses ⌃ Control to Interrupt]
                               │
                               ▼
                      Immediate Stop & Reset
```

---

## 2. Voice State Machine

The voice pipeline is driven by a 7-state finite state machine defined in `VoiceState`:

| State | Status Message | Color | Is Busy | Can Interrupt | Description |
|---|---|---|---|---|---|
| `.idle` | "Hold ⌃ Control to Talk" | Gray | No | No | Microphone is completely unpowered. System is awaiting hotkey trigger. |
| `.listening` | "Listening..." | Cyan | Yes | No | Audio engine active, streaming PCM buffers to Speech framework, RMS metering live. |
| `.transcribing` | "Transcribing..." | Blue | Yes | Yes | Microphone stopped, awaiting final recognized speech utterance from Apple Speech. |
| `.thinking` | "AUTO is thinking..." | Purple | Yes | Yes | Transcript dispatched to Gemini or OmniRoute, awaiting response text. |
| `.speaking` | "Speaking..." | Green | Yes | Yes | Response is actively being read aloud via `AVSpeechSynthesizer`. |
| `.interrupted` | "Interrupted" | Orange | Yes | No | User held ⌃ Control while assistant was speaking/thinking; synthesis instantly aborted. |
| `.failed` | "Voice session failed" | Red | No | No | Missing microphone permission or unrecoverable audio engine error. |

---

## 3. Core Voice Components

### 3.1 PushToTalkManager (`AUTO/Voice/PushToTalkManager.swift`)
- Installs a listen-only `CGEvent.tapCreate` on `kCGSessionEventTap`.
- Monitors `.flagsChanged` events specifically checking `flags.contains(.maskControl)`.
- Eliminates duplicate state events by latching `isCurrentlyPressed`.
- Automatically re-arms if disabled by macOS timeout (`.tapDisabledByTimeout`).
- Exposes `simulateTrigger(state:)` for programmatic UI controls and headless unit testing.

### 3.2 AudioCaptureManager (`AUTO/Voice/AudioCaptureManager.swift`)
- Operates native `AVAudioEngine` with tap installed on `inputNode`.
- Runs on standard audio format: 44.1 kHz or 48 kHz single channel PCM float.
- Streams live buffers to registered handlers via `setBufferHandler((AVAudioPCMBuffer) -> Void)`.
- Calculates real-time audio power (0.0 to 1.0) and publishes via `audioPowerPublisher` to update the companion UI.
- Properly tears down hardware access when idle to respect macOS privacy indicators (orange dot disappears when not held).

### 3.3 VoiceActivityDetector (`AUTO/Voice/VoiceActivityDetector.swift`)
- Computes root-mean-square (RMS) energy level on real PCM buffers.
- Normalizes and scales power between `0.0` and `1.0`.
- Emits voice detection status based on configurable speech threshold (default `0.04`).

### 3.4 SpeechRecognitionManager (`AUTO/Voice/SpeechRecognitionManager.swift`)
- Leverages Apple's native `SFSpeechRecognizer` and `SFSpeechAudioBufferRecognitionRequest`.
- Supports dynamic locales (e.g. `en-US`, `en-GB`, `fr-FR`, `de-DE`, `ja-JP`, `es-ES`).
- Streams partial recognition hypotheses in real time directly to `ApplicationState.currentTranscript`.
- Fallbacks gracefully with timeout protection if the final utterance is delayed.
- Gracefully handles empty or silent sessions without sending empty queries to AI models.

### 3.5 SpeechOutputManager (`AUTO/Voice/SpeechOutputManager.swift`)
- Built on modern `AVSpeechSynthesizer` (replacing deprecated `NSSpeechSynthesizer`).
- Strips coordinate tags (`[POINT:x,y:label:screenN]`) and Markdown syntax so screen coordinates and formatting are not read aloud.
- Dynamically configures rate, pitch multiplier, volume, and selected system voice.
- Implements immediate interruption via `synthesizer.stopSpeaking(at: .immediate)`.

### 3.6 VoiceSessionManager (`AUTO/Voice/VoiceSessionManager.swift`)
- Coordinates the lifecycle from push-to-talk down to text-to-speech completion.
- Coordinates cancellation of pending AI queries when an interruption occurs.
- Automatically handles permissions verification prior to session ignition.

---

## 4. Immediate Speech Interruption Workflow

1. User holds ⌃ Control while AUTO is speaking (`voiceState == .speaking`) or thinking (`voiceState == .thinking`).
2. `VoiceSessionManager.handlePushToTalk(transition: .pressed)` inspects `voiceState.canInterrupt`.
3. Calls `speechOutputManager.stopSpeaking()`, which immediately terminates audio output at the hardware layer (`.immediate`).
4. Cancels the active `Task` querying Gemini / OmniRoute.
5. Invokes `conversationManager.cancelCurrentRequest()`.
6. Transitions state to `.interrupted` and immediately launches a new `.listening` turn for the user's new question.

