# AUTO Local Persistent Memory System

## 1. Overview

AUTO features a native, private, local persistent memory system designed to preserve user preferences, project context, and multi-turn conversational relationships across sessions.

### Privacy Guarantees:
- **100% Local**: Stored strictly on the user's local disk in `~/Library/Application Support/AUTO/agent_memory.json`.
- **Zero Cloud Leakage**: Memory contents are never sent to external tracking services, telemetry backends, or third-party databases.
- **Sensitive Data Rejection**: Automatic heuristic scanning actively blocks attempts to store passwords, auth tokens, private keys, credit cards, or credentials.
- **Full User Control**: Memory can be toggled on/off, searched, pruned, or completely wiped at any time from the Companion Settings pane.

---

## 2. Memory Categories

Memories are partitioned into five discrete categories:

| Category | Storage Target | Typical Contents |
| :--- | :--- | :--- |
| `userPreferences` | Long-term | Preferred text editors, preferred browser, theme preferences, voice speed. |
| `workflowPreferences` | Long-term | Default download organizing directories, code formatting tools, screenshot locations. |
| `projectContext` | Project-scoped | Active workspace directories, repo branches, project-specific build commands. |
| `conversationContext` | Multi-turn | Topics discussed in recent interactions, user-clarified constraints. |
| `temporaryContext` | Session | Ephemeral clipboard context, current window titles, short-lived task hints. |

---

## 3. Storage Architecture

The memory subsystem is implemented in [MemoryManager.swift](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Agent/MemoryManager.swift) and [MemoryRetrievalManager.swift](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Agent/MemoryRetrievalManager.swift).

```
┌────────────────────────────────────────────────────────┐
│                   Memory Storage Flow                  │
└────────────────────────────────────────────────────────┘
                           │
       User Voice / Text: "Remember that my code         │
       projects are in ~/Desktop/Code"                   │
                           ▼
┌────────────────────────────────────────────────────────┐
│             Sensitive Data Guard Check                 │
│  Regex / keyword scans for:                            │
│  - password, secret, token, bearer, api_key, cvv...    │
│  -> REJECT if pattern detected                         │
└──────────────────────────┬─────────────────────────────┘
                           │ (Safe)
                           ▼
┌────────────────────────────────────────────────────────┐
│               Memory Categorization & Tagging          │
│  Category: workflowPreferences                         │
│  Key: "code_projects_directory"                        │
│  Confidence: 1.0, Expiration: nil                      │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│       Thread-Safe JSON Persistence to Disk             │
│   ~/Library/Application Support/AUTO/agent_memory.json │
└────────────────────────────────────────────────────────┘
```

---

## 4. Relevance Search & Task Grounding

When a user initiates an instruction or conversational request:
1. `MemoryRetrievalManager.retrieveRelevantContext(for:query)` queries all stored memories.
2. An exact, token-overlap, and tag-similarity algorithm calculates relevance scores (0.0 to 1.0).
3. Memories scoring above the relevance threshold (default `0.3`) are formatted into a concise, grounded prompt block:

```markdown
### Known User Context & Preferences:
- [workflowPreferences] code_projects_directory: ~/Desktop/Code (Relevance: 0.95)
- [userPreferences] preferred_editor: Cursor (Relevance: 0.80)
```

4. This context is injected into the AI system instructions, allowing AUTO to act with immediate familiarity without repeatedly asking repetitive questions.

---

## 5. Conversation Summarization & History Compaction

To maintain infinite conversation continuity within finite LLM context windows, `ConversationSummarizer`:
- Evaluates conversation turns. When message history exceeds configured token/turn limits (default 20 turns), older exchanges are distilled into a compact narrative summary.
- The summary is retained in `conversationContext` memory, while recent turns remain verbatim.
- This prevents token bloat and avoids context window overflow errors.

---

## 6. Security & Sensitive Data Guard

The `MemoryManager` runs all incoming key-value pairs through `isSensitiveData(content:key:)`:
```swift
private func isSensitiveData(content: String, key: String) -> Bool {
    let lowerContent = content.lowercased()
    let lowerKey = key.lowercased()
    
    let sensitiveKeywords = [
        "password", "secret", "bearer", "api_key", "apikey",
        "private_key", "token", "cvv", "credit_card", "pin_number"
    ]
    
    for word in sensitiveKeywords {
        if lowerKey.contains(word) || lowerContent.contains(word) {
            return true
        }
    }
    return false
}
```
If sensitive keywords or potential secrets are detected, the memory write is immediately rejected, safeguarding the user's confidential data.

