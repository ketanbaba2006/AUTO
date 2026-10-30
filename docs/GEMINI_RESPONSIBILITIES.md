# Google Gemini Responsibilities & Boundaries in AUTO

## Overview

In the AUTO Hybrid Architecture, **Google Gemini** serves as the central high-level intelligence and reasoning layer. Gemini is strictly confined to cognitive tasks: understanding human instructions, decomposing ambiguous or complex workflows into discrete operational steps, and producing structured action proposals for the local engine.

Gemini has **no direct access to macOS system APIs**, no shell execution capabilities, and no autonomous access to private user files or hardware inputs.

---

## 1. What Gemini Does (Cognitive Scope)

1. **Natural Language Understanding (NLU)**:
   - Interprets spoken and typed natural language commands from the user.
   - Disambiguates user intent across multi-turn desktop conversations.

2. **Intent Classification**:
   - Classifies requests into operational categories:
     - Informational queries (e.g., "What does this error message mean?")
     - Screen inspection requests (e.g., "Where is the submit button?")
     - Desktop task automation (e.g., "Open Safari and search for WWDC 2026 dates")
     - Conversational dialog and assistance.

3. **Complex Task Planning**:
   - Decomposes high-level instructions into ordered, dependency-aware steps.
   - Selects appropriate tools from AUTO's local tool registry schema (`AutoToolRegistry`).

4. **Structured Action Proposals**:
   - Returns structured action proposals conforming strictly to AUTO's JSON schema:
     ```json
     {
       "action": "click",
       "coordinates": {"x": 540, "y": 320},
       "elementDescription": "Blue 'Submit' button",
       "confidence": 0.95,
       "riskLevel": "medium"
     }
     ```

5. **Clarification and Dialogue**:
   - Asks targeted clarification questions when instructions are ambiguous, destructive, or missing essential parameters.

---

## 2. What Gemini NEVER Does (Strict Boundaries)

> [!IMPORTANT]
> The following actions are strictly prohibited from being performed by Gemini:

- ❌ **No Shell Command Execution**: Gemini cannot issue raw terminal commands or execute arbitrary bash/zsh scripts.
- ❌ **No Direct Mouse/Keyboard Injection**: Gemini does not drive cursor hardware or simulate keystrokes directly.
- ❌ **No Unfiltered File System Access**: Gemini cannot traverse the local file system or access arbitrary directories outside the sandboxed file manager.
- ❌ **No Direct Access to Credentials**: API keys, Keychain items, and private credentials are never exposed in prompts to Gemini.
- ❌ **No Autonomous Risk Bypass**: Gemini cannot lower or override the risk classification of an action. All high-risk proposals must be approved by the human user through AUTO's local safety modal.

---

## 3. Communication Protocol

All communication between AUTO and Google Gemini occurs via HTTPS using the official Gemini REST endpoints (`generativelanguage.googleapis.com`):

- **Model Families Supported**:
  - `gemini-2.5-flash`: Fast, efficient, multimodal default for interactive tasks.
  - `gemini-2.5-pro`: Deep reasoning and complex multi-step dependency planning.
  - `gemini-2.0-flash`: Ultra-low latency conversational assistant.

- **Payload Sanitization**:
  Before any prompt payload is dispatched to Gemini:
  1. Local OCR text is extracted on-device via Apple Vision framework.
  2. The sensitive data firewall in `AutoMemoryManager` scrubs regex patterns matching API tokens, passwords, and private keys.
  3. Raw screenshot images are only included if the user has explicitly toggled `allowScreenshotTransmission` in Settings.

---

## 4. Prompt Safety & Injection Defense

System prompts provided to Gemini include strict delimitations and defense patterns:
- System instructions are strictly segregated from user input and screen-extracted text.
- External screen content is treated as untrusted data wrapped in `<untrusted_screen_content>` XML tags.
- Gemini is instructed to ignore any instructions found embedded within screen text that attempt to hijack the assistant's behavior.
