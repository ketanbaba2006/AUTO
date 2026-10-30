# Speech Recognition & Voice Synthesis

## 1. Speech Recognition Engine

AUTO uses Apple's native `Speech` framework (`SFSpeechRecognizer`).

### Key Features
- **Zero Third-Party Cloud Latency**: Recognizes speech on-device or via Apple's integrated speech infrastructure.
- **Streaming Partial Hypotheses**: As the user speaks while holding the PTT key, partial words stream into the companion panel and overlay window with sub-second feedback.
- **Zero Paid Subscriptions**: No AssemblyAI, Deepgram, or OpenAI Whisper API keys required. Works completely out of the box.

---

## 2. Multi-Language & Locale Support

Users can select their preferred speech recognition locale in **Settings > Voice > Recognition Language**:

- English (United States) — `en-US`
- English (United Kingdom) — `en-GB`
- Spanish (Spain) — `es-ES`
- French (France) — `fr-FR`
- German (Germany) — `de-DE`
- Japanese (Japan) — `ja-JP`

When changed, `SpeechRecognitionManager` recreates the recognizer instance targeting the selected locale.

---

## 3. Natural Speech Output (TTS)

AUTO uses `AVSpeechSynthesizer` from `AVFoundation` for natural, expressive voice output.

### Features
- **Dynamic Voice Discovery**: Inspects `AVSpeechSynthesisVoice.speechVoices()` and surfaces all installed voices (Default, Enhanced, and Premium neural voices like Samantha, Siri, Daniel, Alex).
- **Speech Rate & Pitch Customization**: Configurable rate slider (`0.5x` to `1.5x`) and pitch multiplier.
- **Coordinate Tag Sanitization**: AI models generate spatial tags like `[POINT:0.35,0.72:Button:screen1]` for mouse pointing. `SpeechOutputManager.sanitizeTextForSpeech` strips these tags along with markdown symbols (`*`, `#`, `` ` ``) before sending text to the audio synthesizer, ensuring only natural conversational language is spoken.
- **Instant Interruption**: When the user presses the PTT key again, `stopSpeaking(at: .immediate)` immediately cuts audio output at the hardware layer with 0ms buffering lag.

