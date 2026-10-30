# AUTO Modular Tool Registry & Execution Dispatcher

## 1. Overview

AUTO equips its autonomous agent engine with a modular, extensible, and type-safe tool execution architecture. Tools provide the AI companion with safe, structured interfaces to inspect screens, interact with controls, manipulate files, manage memory, and communicate with the user.

All tools are centrally defined in [ToolRegistry.swift](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Agent/ToolRegistry.swift) and routed through [ToolDispatcher.swift](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Agent/ToolDispatcher.swift).

---

## 2. Tool Categories

Tools are organized into 6 functional domains:

```
┌────────────────────────────────────────────────────────┐
│                   Tool Categories                      │
└────────────────────────────────────────────────────────┘
  ├── 1. conversation      (Natural chat, questions, clarifications)
  ├── 2. screenIntelligence(Screen captures, OCR, element inspection)
  ├── 3. desktopAutomation (Mouse moves, clicks, typing, hotkeys)
  ├── 4. applicationContext(App listing, window inspection, activation)
  ├── 5. memory            (Memory store, query, update, clear)
  └── 6. localFiles        (Sandboxed directory listing, file moving)
```

---

## 3. Built-In Tool Catalog

| Tool Name | Category | Description | Risk Level |
| :--- | :--- | :--- | :--- |
| `speak_response` | `conversation` | Speaks or displays text to the user | `low` |
| `ask_clarification` | `conversation` | Prompts user with options or questions | `low` |
| `capture_screen` | `screenIntelligence` | Captures current display or window | `low` |
| `inspect_elements` | `screenIntelligence` | Traverses accessibility tree for visible controls | `low` |
| `click_element` | `desktopAutomation` | Moves cursor and clicks a designated UI element | `medium` |
| `type_text` | `desktopAutomation` | Types text into the currently focused field | `medium` |
| `press_key` | `desktopAutomation` | Simulates a keyboard shortcut (e.g. ⌘+S) | `medium` |
| `scroll` | `desktopAutomation` | Performs vertical or horizontal scroll | `low` |
| `list_applications` | `applicationContext` | Discovers running applications | `low` |
| `activate_application`| `applicationContext` | Brings an application to the foreground | `low` |
| `get_window_info` | `applicationContext` | Returns active window bounds and titles | `low` |
| `remember` | `memory` | Saves user preference or context to local memory | `low` |
| `recall_memory` | `memory` | Searches local memory store | `low` |
| `list_directory` | `localFiles` | Lists files in a sandboxed user folder | `low` |
| `read_file_preview` | `localFiles` | Reads text preview of a file (up to 4KB) | `low` |
| `organize_files` | `localFiles` | Moves files into categorised subfolders | `high` |

---

## 4. Execution Pipeline & Safety Gates

When the agent attempts to execute a tool:

```
┌────────────────────────────────────────────────────────┐
│               Tool Execution Request                   │
│   toolName: "organize_files", target: "Downloads"      │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│        1. Permission Validation (AgentPermission)      │
│   Checks Screen Recording, Accessibility, Files        │
└───────────────────────────┬────────────────────────────┘
                            │ (Granted)
                            ▼
┌────────────────────────────────────────────────────────┐
│        2. Risk Level Evaluation (AgentSafety)          │
│   Low/Medium -> Proceed                                │
│   High       -> Request User Gated Approval            │
└───────────────────────────┬────────────────────────────┘
                            │ (Approved)
                            ▼
┌────────────────────────────────────────────────────────┐
│        3. Dispatcher Routing (ToolDispatcher)          │
│   Routes to appropriate manager (LocalFileManager, etc)│
│   Enforces 30s timeout and handles cancellation        │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│        4. Result Encapsulation                         │
│   Returns ToolExecutionResult(success, output, error)  │
└────────────────────────────────────────────────────────┘
```

---

## 5. Extensibility

Adding a new tool requires two simple steps:
1. Register a `ToolDefinition` in `ToolRegistry.registerDefaultTools()`.
2. Implement the handling branch in `ToolDispatcher.dispatch()`.

