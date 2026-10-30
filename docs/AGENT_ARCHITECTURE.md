# AUTO: Autonomous Agent Architecture

This document describes the high-level architecture, orchestration flow, and state machines governing **AUTO's** autonomous desktop companion agent.

---

## 1. System Overview

AUTO acts as an autonomous personal assistant capable of decomposing complex natural language requests, planning multi-step sequential workflows, dispatching validated tools, maintaining local memories, and executing approved desktop interactions.

```
┌────────────────────────────────────────────────────────┐
│             User Input (Voice Push-to-Talk / UI)       │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│               MemoryRetrievalManager                   │
│   (Injects relevant user preferences & project context)│
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                    TaskPlanner                         │
│  (Converts request into structured AgentTaskPlan)      │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│                 AgentOrchestrator                      │
│       (@MainActor Coordinator & Execution Loop)        │
└────────────────────────────────────────────────────────┘
              │                              │
     (Approval Required)             (Step Ready)
              ▼                              ▼
    StepApprovalRequest             ┌────────────────────┐
  (Companion Panel Modal)           │    TaskExecutor    │
                                    └────────────────────┘
                                             │
                                             ▼
                               ┌───────────────────────────┐
                               │       ToolDispatcher      │
                               │  (Validates Schema & Risk)│
                               └───────────────────────────┘
                                             │
      ┌──────────────────┬───────────────────┼──────────────────┬──────────────────┐
      ▼                  ▼                   ▼                  ▼                  ▼
┌────────────┐    ┌─────────────┐     ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Screen     │    │ Automation  │     │ App Context │    │ Local Files │    │ Memory      │
│ Manager    │    │ Manager     │     │ (Workspace) │    │ Manager     │    │ Manager     │
└────────────┘    └─────────────┘     └─────────────┘    └─────────────┘    └─────────────┘
                                             │
                                             ▼
                               ┌───────────────────────────┐
                               │  TaskVerificationManager  │
                               │  (Inspects Post-Action UI)│
                               └───────────────────────────┘
```

---

## 2. Component Responsibilities

1. **`AgentOrchestrator`** (`AUTO/Agent/AgentOrchestrator.swift`):
   - Coordinates the lifecycle of active multi-step task plans.
   - Manages approval gating, pause/resume, task history, and UI progress reporting.
2. **`TaskPlanner`** (`AUTO/Agent/TaskPlanner.swift`):
   - Analyzes user instructions and generates deterministic or AI-assisted multi-step plans with dependencies and risk ratings.
3. **`TaskExecutor`** (`AUTO/Agent/TaskExecutor.swift`):
   - Executes individual steps sequentially, checks permissions, invokes tools via `ToolDispatcher`, and calls `TaskVerificationManager`.
4. **`ToolRegistry`** (`AUTO/Agent/ToolRegistry.swift`):
   - Catalog of all registered tool definitions, input schemas, required permissions, and risk tiers across 6 domains.
5. **`ToolDispatcher`** (`AUTO/Agent/ToolDispatcher.swift`):
   - Validates parameters and permissions, routes calls to native subsystems, handles timeouts and cancellations.
6. **`MemoryManager`** (`AUTO/Agent/MemoryManager.swift`):
   - Thread-safe persistent JSON store for user preferences, workflow patterns, and project context with zero credential leakage.
7. **`MemoryRetrievalManager`** (`AUTO/Agent/MemoryRetrievalManager.swift`):
   - Ranks and extracts relevant memory snippets to ground prompt reasoning for new tasks.
8. **`ConversationSummarizer`** (`AUTO/Agent/ConversationSummarizer.swift`):
   - Compacts older dialogue turns to preserve active task goals without consuming context window tokens.
9. **`AgentSafetyManager`** (`AUTO/Agent/AgentSafetyManager.swift`):
   - Enforces approval requirements for medium/high risk actions, sanitizes external injection attempts, and formulates consequence disclosures.
10. **`LocalFileManager`** (`AUTO/Agent/LocalFileManager.swift`):
    - Safe filesystem abstraction for browsing authorized user directories and organizing files.

---

## 3. Task State Machine

An `AgentTaskPlan` transitions through the following states:
```
[created] ──► [planning] ──► [ready] ──► [executing] ──► [verifying] ──► [completed]
                                  │           │
                                  ▼           ▼
                      [awaitingApproval]   [paused]
                                  │           │
                                  ▼           ▼
                              [failed]   [cancelled]
```

- **`created`**: Task initialized from raw user instruction.
- **`planning`**: Decomposing instruction into step sequence.
- **`awaitingApproval`**: High-risk step requires explicit user authorization.
- **`executing`**: Active tool is running.
- **`verifying`**: Checking interface or filesystem state changes.
- **`completed`**: All steps verified; summary reported to user.
- **`failed`**: Unrecoverable error encountered.
- **`cancelled`**: Aborted by user via UI button, voice command, or Emergency Stop.

