# AUTO: Cursor Intelligence and Visual Interaction Architecture

This document details the architecture, design, and mechanisms powering **AUTO's** visual companion cursor, spatial coordinate mapping, element discovery, and targeting overlays.

---

## 1. System Overview

AUTO transforms from a screen-aware observer into an intelligent desktop companion capable of identifying user interface controls, visually guiding the user, and executing authorized desktop interactions with explicit permission gating and emergency failsafes.

```
┌────────────────────────────────────────────────────────┐
│               Natural Language / Voice                │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│            PromptManager & Gemini Multimodal           │
│           (Emits [POINT:...] and [ACTION:...])         │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                ActionProposalParser                    │
│           (Sanitizes & Classifies Risk Level)          │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                   ElementLocator                       │
│    (Matches Target against Accessible UI Elements      │
│     via Title, Label, Description & Role Heuristics)   │
└────────────────────────────────────────────────────────┘
              │                              │
     (Ambiguous Match)               (Confident Match)
              ▼                              ▼
  Request User Clarification       ┌───────────────────┐
                                   │ CoordinateMapper  │
                                   └───────────────────┘
                                             │
                                             ▼
                               ┌───────────────────────────┐
                               │   ActionExecutionManager  │
                               │   (Safety & Risk Gating)  │
                               └───────────────────────────┘
                                             │
                       ┌─────────────────────┴─────────────────────┐
                       ▼                                           ▼
         ┌───────────────────────────┐               ┌───────────────────────────┐
         │   CursorOverlayManager    │               │    MouseActionManager     │
         │   (Reticle, Ripple, Glow) │               │   & KeyboardActionManager │
         └───────────────────────────┘               └───────────────────────────┘
```

---

## 2. Accessible UI Element Discovery

AUTO interacts with macOS interface elements using Apple's native **Accessibility APIs** (`AXUIElement`):

1. **Frontmost Application Inspection**:
   - Queries the active process identifier via `NSWorkspace.shared.frontmostApplication`.
   - Creates the root application accessibility node via `AXUIElementCreateApplication(pid)`.
2. **Recursive Element Traversal**:
   - Traverses application windows, toolbars, buttons, text fields, pop-ups, and menus.
   - Enforces depth limits (max depth: 4) and element caps (max elements: 150) to ensure zero UI stutter or latency.
3. **Attribute Extraction**:
   - `kAXRoleAttribute`: Identifies the control type (`AXButton`, `AXTextField`, `AXMenuItem`, `AXCheckBox`, etc.).
   - `kAXTitleAttribute` & `kAXDescriptionAttribute`: Human-readable labels.
   - `kAXPositionAttribute` & `kAXSizeAttribute`: Global screen frame.
   - `kAXEnabledAttribute` & `kAXFocusedAttribute`: Interactive state.
   - `AXUIElementCopyActionNames`: Native actions supported (e.g. `AXPress`, `AXConfirm`).

---

## 3. Natural Language Element Locator & Confidence Scoring

When the user gives a natural instruction (e.g., *"Click the Save button"* or *"Focus the search field"*), `ElementLocator` scores candidate controls:

### Scoring Heuristics
- **Exact Match (1.00)**: Element title or label exactly matches the query.
- **Prefix Match (0.90)**: Element title starts with the query text.
- **Substring Match (0.82)**: Element title contains the query text.
- **Description Match (0.72)**: Accessibility description contains the query text.
- **Value Match (0.65)**: Current input field value matches.
- **Token Overlap (0.40 - 0.75)**: Jaccard intersection of query words with element text tokens.
- **Role Match Bonus (+0.10)**: Element matches preferred role (e.g. `AXButton`).
- **Disabled Penalty (× 0.50)**: Inactive or dimmed controls are penalized.

### Ambiguity Detection
If multiple controls score within `0.08` of each other (e.g. *"Submit Order"* vs *"Submit Feedback"*), AUTO flags the match as **ambiguous** and prompts the user for clarification rather than clicking blindly.

---

## 4. Multi-Display Coordinate Mapping

The `CoordinateMapper` bridges different coordinate systems:

1. **AppKit Coordinates**: Bottom-left origin (`0, 0` at lower-left of the primary display).
2. **CoreGraphics / CGEvent Coordinates**: Top-left origin (`0, 0` at top-left of the primary display).
3. **Normalized AI Coordinates**: Range `0.0 ... 1.0` (top-left origin).
4. **Negative Virtual Coordinates**: Displays arranged to the left or above the primary monitor have negative origins (e.g. `x = -1920`).

`CoordinateMapper` verifies that all target points fall within the physical bounds of a connected monitor before any mouse event is posted.

---

## 5. Visual Cursor Overlay

Rendered across all active monitors via non-activating, click-through `NSPanel` overlay windows (`OverlayWindowManager`):

- **Targeting Reticle**: Subtle cyan ring with target label hovering over the intended control.
- **Click Ripple**: Expanding animated shockwave confirming click execution.
- **Companion Buddy**: Triangular glowing mascot tracking cursor movement and displaying conversational feedback bubbles.
- **Zero Input Interference**: Windows set `.ignoresMouseEvents = true` and `canBecomeKey = false` so standard user interactions are never blocked.

