# AUTO Security Architecture & Threat Model

## 1. Security Overview

AUTO operates as an autonomous desktop companion with mouse, keyboard, and screen interaction capabilities. To protect the user's workstation, privacy, and sensitive credentials, AUTO implements a **strict multi-layered defense-in-depth security model**:

```
┌────────────────────────────────────────────────────────┐
│                   SECURITY BOUNDARIES                  │
└────────────────────────────────────────────────────────┘
  ├── 1. Hardware Keychain Storage   (Encrypted API Keys)
  ├── 2. TCC Permission Gating       (Mic, Screen, Accessibility)
  ├── 3. Risk-Based Action Gating    (Low / Med / High Confirmation)
  ├── 4. Filesystem Path Guard       (Restricted System Isolation)
  ├── 5. Prompt Injection Defense    (Tag Stripping & Schema Latching)
  ├── 6. Hardware Emergency Stop     (<10ms Interrupt & Failsafe Release)
  └── 7. Ephemeral Capture Policy    (RAM-Only Screenshots & Audio)
```

---

## 2. API Key Security & macOS Keychain

- **Hardware-Backed Encryption**: Provider API keys (Google Gemini, OmniRoute) are never written to plaintext files, `.env` files, or `UserDefaults`.
- Keys are saved directly to the macOS Keychain using Apple's `Security.framework` (`SecItemAdd`, `SecItemUpdate`, `SecItemCopyMatching`):
  - Service: `com.auto.desktop.companion`
  - Accounts: `gemini_api_key`, `omniroute_api_key_<profileId>`
- **No Log Leaks**: The logging subsystem (`AppLogger`) actively filters out API keys and token strings to prevent accidental leakage into system logs (`os.log`).

---

## 3. Automation Safety & Risk Gating

Every simulated cursor movement, click, keystroke, or tool call passes through [`AgentSafetyManager`](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Agent/AgentSafetyManager.swift) and [`ActionExecutionManager`](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Automation/ActionExecutionManager.swift):

| Risk Level | Gating Policy | Scope |
| :--- | :--- | :--- |
| **Low** | Executed automatically | Screen capture, OCR inspection, memory queries, UI reads |
| **Medium** | Configurable auto-execute | Safe UI navigation, window switching, application activation |
| **High** | **Mandatory Explicit Modal Confirmation** | File organization, deletions, payment buttons, form submission |

### High-Risk Confirmation Card
Before any High-Risk action runs, execution pauses and the Companion Panel displays:
- The exact action title and target element/folder.
- A plain-language explanation of real-world consequences.
- Explicit `[Approve]` and `[Reject]` controls.

---

## 4. Hardware-Level Release Failsafes

When an action is interrupted, cancelled, or fails:
- `MouseActionManager.releaseHeldButtons()` synthesizes immediate `.leftMouseUp` and `.rightMouseUp` events to guarantee the cursor is not left in a dragged or held state.
- `KeyboardActionManager.releaseHeldKeys()` releases any depressed modifier keys (`Command`, `Option`, `Control`, `Shift`).

---

## 5. Instant Local Emergency Stop

The user can halt AUTO at any millisecond through three independent channels:
1. **Push-to-Talk Voice Trigger**: Speaking *"Stop"*, *"Cancel"*, or *"Stop now"*.
2. **UI Stop Button**: Persistent bright red Stop button in the Companion Panel header.
3. **Hardware Key**: Pressing `Escape` or tapping `Control` twice rapidly.

The emergency stop mechanism:
- Operates locally without requiring network or AI response.
- Halts background tasks and sets status to `.cancelled` in <10ms.
- Releases all simulated input states.

---

## 6. Filesystem Sandboxing & Restricted Path Defense

[`LocalFileManager`](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Agent/LocalFileManager.swift) restricts all agent file operations to three standard user folders:
- `~/Desktop`
- `~/Downloads`
- `~/Documents`

Attempts to access system folders (`/System`, `/usr`, `/bin`, `/etc`), cloud configs (`~/.aws`, `~/.config`), SSH keys (`~/.ssh`), or Keychain databases (`~/Library/Keychains`) trigger an immediate hard rejection (`AgentExecutionError.unauthorizedPath`).

---

## 7. Prompt Injection Defense

Untrusted content encountered on websites, document previews, or image OCR text is sanitized:
- Marker injection tags (`<system>`, `[INSTRUCTION]`, `ADMIN_OVERRIDE`) are stripped.
- Hidden zero-width unicode characters are removed.
- **Deterministic Tool Schema**: The AI cannot fabricate or invoke unauthorized tools outside the strict `ToolRegistry` schema.

