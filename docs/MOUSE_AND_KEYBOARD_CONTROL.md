# AUTO: Mouse and Keyboard Control Architecture

This document describes the native macOS input simulation engine in **AUTO**, implemented via CoreGraphics `CGEvent` and AppKit.

---

## 1. Mouse Action Simulation (`MouseActionManager`)

Mouse control is handled by `MouseActionManager` (`AUTO/Automation/MouseActionManager.swift`), using a shared `CGEventSource(stateID: .combinedSessionState)` to post hardware events into macOS's HID event tap (`.cghidEventTap`).

### Supported Operations
- **Cursor Movement (`moveCursor`)**:
  - Trajectory is smoothly interpolated along a quadratic Bezier arc using `CursorAnimationManager`.
  - 14 intermediate steps spaced at 12ms intervals generate a natural, human-like flight curve.
  - Final position is guaranteed with an exact terminal move event.
- **Left Click (`click`)**:
  - Emits `leftMouseDown`, holds for 40ms, then emits `leftMouseUp`.
- **Double Click (`doubleClick`)**:
  - Emits two consecutive click pairs with `.mouseEventClickState` set to 1 and 2, spaced by a 60ms gap.
- **Right Click (`rightClick`)**:
  - Emits `rightMouseDown` and `rightMouseUp` targeting contextual menus.
- **Scrolling (`scroll`)**:
  - Emits `CGEvent(scrollWheelEvent2Source:...)` with 2-axis precision for vertical and horizontal panning.
- **Dragging (`drag`)**:
  - Depresses left button at the start coordinate, interpolates mouse movement across 10 steps using `leftMouseDragged`, and releases the button at the destination.

### Interruption Safety & State Release
If an automated operation is interrupted, cancelled, or fails:
- `releaseHeldButtons()` executes immediately.
- Sends matching `leftMouseUp` or `rightMouseUp` events to ensure mouse buttons are never left depressed or locked on the user's desktop.

---

## 2. Keyboard Action Simulation (`KeyboardActionManager`)

Keyboard text input and control shortcuts are implemented in `KeyboardActionManager` (`AUTO/Automation/KeyboardActionManager.swift`).

### Text Entry
- Text is converted into UTF-16 code units and injected via `CGEvent.keyboardSetUnicodeString(stringLength:unicodeString:)`.
- Supports emojis, international characters, and accented glyphs without requiring physical keyboard layout remapping.
- Keystroke cadence: 15ms key hold duration, 10ms inter-key delay.

### Virtual Key Codes
Dedicated virtual key mappings for essential navigation:
- Return / Enter (`0x24`)
- Tab (`0x30`)
- Space (`0x31`)
- Delete / Backspace (`0x33`)
- Escape (`0x35`)
- Arrow Keys (Left `0x7B`, Right `0x7C`, Down `0x7D`, Up `0x7E`)
- Modifiers: Command (`0x37`), Shift (`0x38`), Option (`0x3A`), Control (`0x3B`)

### Modifier Release Failsafe
`releaseHeldKeys()` sends explicit `keyUp` events for all modifier keys (Cmd, Shift, Opt, Ctrl) whenever an action is cancelled or Emergency Stop is engaged.

---

## 3. Automated Test Mock Mode

To allow 100% automated test coverage without hijacking the host machine's mouse or physical keyboard during development builds:
- `MouseActionManager.isMockMode = true`
- `KeyboardActionManager.isMockMode = true`
- All events are captured in `executedEvents: [String]` for precise assertion verification.

