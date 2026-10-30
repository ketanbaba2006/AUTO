# AUTO: Automation Safety, Security and Privacy Stewardship

This document details the safety guarantees, risk evaluation models, prompt injection defenses, and emergency stop mechanisms implemented in **AUTO**.

---

## 1. Action Risk Classification

Every action proposed by the AI or user is classified into one of three risk tiers:

### Low Risk
- **Examples**: Moving the cursor, highlighting elements, inspecting UI hierarchies.
- **Policy**: Executes immediately when mouse control is enabled.

### Medium Risk
- **Examples**: Clicking standard navigation buttons, scrolling views, typing non-sensitive text.
- **Policy**: Executes directly if Safe Action Mode is satisfied (verifying element focus and window bounds).

### High Risk
- **Examples**:
  - Deleting files or moving items to Trash.
  - Submitting forms or checkout pages.
  - Making purchases or authorizations.
  - Modifying macOS System Settings or security preferences.
  - Quitting running applications or running destructive terminal commands.
- **Policy**: **Explicit user confirmation is mandatory**. AUTO pauses execution, displays a prominent confirmation card in the Companion Panel, and only proceeds if the user clicks "Authorize Action".

---

## 2. Prompt Injection Defense

Screen content (webpages, documents, chat messages, terminal windows) represents **untrusted third-party input**.

To prevent prompt injection attacks where malicious text displayed on a webpage attempts to hijack AUTO:
1. **System Persona Directive**:
   `PromptManager` enforces that all visual text is untrusted. Gemini is strictly instructed to disregard instructions found inside screenshots.
2. **Local Proposal Validation**:
   Proposed actions must parse into rigid JSON schemas (`ActionProposalParser`). Free-form shell commands or code execution payloads are rejected.
3. **Destructive Command Blocking**:
   `KeyboardActionManager` checks typed text against destructive syntax patterns (`rm -rf`, `sudo`, `mkfs`, fork bombs) and blocks execution immediately.

---

## 3. Emergency Stop Failsafe (`EmergencyStopManager`)

The Emergency Stop is an **autonomous local failsafe** that operates independently of Gemini, network connections, or external services:

### Activation Methods
1. **Companion Panel UI**: Always-accessible red Stop button in the top navigation bar.
2. **Settings Window**: Direct "Trigger Emergency Stop Now" button in the Automation tab.
3. **Voice Command**: Speaking *"Stop"*, *"Stop now"*, or *"Emergency stop"* triggers an instant software halt on Push-to-Talk release.

### Action on Activation
- Cancels the active Swift concurrency `Task` executing the automation.
- Calls `MouseActionManager.shared.releaseHeldButtons()` to prevent stuck mouse drag states.
- Calls `KeyboardActionManager.shared.releaseHeldKeys()` to release stuck modifier keys.
- Resets companion cursor overlays to `idle`.
- Sets ApplicationState status to *"Automation halted (Emergency Stop)"*.
- Sets an internal latch preventing new automated actions until explicitly reset by the user.

---

## 4. Privacy & Action History

AUTO maintains a local log of executed actions:
- **Recorded Data**: Timestamp, action type, target app name, concise summary, risk tier, completion status.
- **Excluded Data**:
  - Passwords and authentication credentials.
  - Private form field inputs.
  - Screenshots or visual framebuffers.
- **User Control**: Action history is stored only on the local machine and can be cleared at any time via Settings > Automation > "Clear History".

