# AUTO Task Planning Architecture

## 1. Overview

In **Fragment 6**, AUTO evolves from an immediate-action assistant into an autonomous desktop companion agent capable of understanding complex, multi-stage user instructions and breaking them down into ordered, verifiable, and safe execution plans.

The task planning subsystem is responsible for:
1. Parsing natural language user prompts and intent.
2. Formulating structured, multi-step execution plans (`AgentTaskPlan`).
3. Establishing step dependencies (`dependencies: [UUID]`) to enforce logical ordering.
4. Classifying risk levels (`low`, `medium`, `high`) for every individual step.
5. Associating verification criteria with each step to confirm success.
6. Adapting plans dynamically when step execution fails or interface state diverges.

---

## 2. Data Models

The core task planning models are defined in [AgentModels.swift](file:///Users/ketanbaba/Desktop/Extra/AUTO/AUTO/Models/AgentModels.swift):

### `AgentTaskPlan`
Represents an entire multi-step workflow.
```swift
public struct AgentTaskPlan: Identifiable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let goal: String
    public var steps: [AgentTaskStep]
    public var status: AgentTaskStatus
    public var createdAt: Date
    public var startedAt: Date?
    public var completedAt: Date?
    public var failureReason: String?
}
```

### `AgentTaskStep`
Represents an individual unit of work within a plan.
```swift
public struct AgentTaskStep: Identifiable, Codable, Sendable {
    public let id: UUID
    public let stepNumber: Int
    public let title: String
    public let description: String
    public let toolName: String
    public let parameters: [String: String]
    public let dependencies: [UUID]
    public let riskLevel: ActionRiskLevel
    public var status: AgentStepStatus
    public let verificationCriteria: String?
    public var result: ToolExecutionResult?
    public var startedAt: Date?
    public var completedAt: Date?
}
```

### `AgentTaskStatus` & `AgentStepStatus`
Lifecycle states:
- **Task Statuses**: `.planning`, `.ready`, `.executing`, `.paused`, `.waitingForApproval`, `.completed`, `.failed`, `.cancelled`.
- **Step Statuses**: `.pending`, `.blocked`, `.waitingForApproval`, `.executing`, `.completed`, `.failed`, `.skipped`.

---

## 3. Plan Generation Workflow

The planning process is orchestrated by `TaskPlanner`:

```
┌────────────────────────────────────────────────────────┐
│             User Natural Language Instruction          │
│   e.g. "Organize my Downloads folder by file type"     │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│             TaskPlanner Intent Decomposition           │
│   - Identify primary objective and target domain       │
│   - Query relevant memories for user preferences       │
│   - Inspect current desktop context (apps & windows)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│            Structured Step Plan Assembly               │
│   Step 1: list_directory (Downloads)                   │
│   Step 2: organize_files (Downloads, byExtension)      │
│   Step 3: capture_screen (Verify visual state)         │
│   Step 4: speak_response (Report completion)           │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│             Dependency & Risk Tagging                  │
│   - Step 2 depends on Step 1 [UUID]                    │
│   - Step 2 classified as Medium/High Risk              │
│   - Gated by User Approval if High Risk                │
└────────────────────────────────────────────────────────┘
```

---

## 4. Step Dependencies & Sequencing

Steps can declare zero or more dependent step IDs via `dependencies: [UUID]`.
- A step cannot begin execution (`.pending` -> `.executing`) until all dependencies have reached `.completed`.
- If an earlier dependent step fails:
  - If the step is non-critical, the planner attempts alternative recovery steps.
  - If the failure is unrecoverable, subsequent dependent steps transition to `.skipped` or `.blocked`, and the task terminates gracefully with a descriptive explanation.

---

## 5. Verification & Plan Adaptation

Every action includes observable verification criteria:
- **Application Activation**: Verify that the application frontmost bundle matches expectations via `NSWorkspace`.
- **File Organization**: Verify that the destination directories exist and files are relocated.
- **Visual State**: Capture a post-action screenshot using `ScreenCaptureKit` and perform lightweight visual confirmation.

When an unexpected state is detected:
1. The `TaskVerificationManager` flags the step outcome as unverified.
2. The agent pauses execution before applying destructive actions.
3. The companion panel notifies the user and asks for guidance or offers a single-click retry.

