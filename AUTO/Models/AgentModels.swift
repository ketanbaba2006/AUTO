//
//  AgentModels.swift
//  AUTO
//
//  Data models for autonomous task planning, multi-step workflows,
//  agent state management, local memory items, and tool specifications.
//

import AppKit
import Foundation

// MARK: - Task Execution Status
public enum AgentTaskStatus: Equatable, Sendable {
    case created
    case planning
    case awaitingClarification(question: String)
    case awaitingApproval(stepTitle: String, explanation: String, risk: ActionRiskLevel)
    case ready
    case executing(currentStep: Int, totalSteps: Int, stepTitle: String)
    case paused
    case verifying(stepTitle: String)
    case completed(summary: String)
    case failed(reason: String)
    case cancelled(reason: String)
    
    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled: return true
        default: return false
        }
    }
    
    public var isBusy: Bool {
        switch self {
        case .planning, .executing, .verifying: return true
        default: return false
        }
    }
    
    public var statusDescription: String {
        switch self {
        case .created: return "Task created"
        case .planning: return "Planning workflow steps..."
        case .awaitingClarification(let q): return "Clarification needed: \(q)"
        case .awaitingApproval(let title, _, _): return "Awaiting approval for: \(title)"
        case .ready: return "Plan approved and ready"
        case .executing(let cur, let total, let title): return "Step \(cur)/\(total): \(title)"
        case .paused: return "Task paused"
        case .verifying(let title): return "Verifying: \(title)"
        case .completed(let summary): return "Completed: \(summary)"
        case .failed(let reason): return "Failed: \(reason)"
        case .cancelled(let reason): return "Cancelled: \(reason)"
        }
    }
}

// MARK: - Step Status
public enum AgentStepStatus: Equatable, Sendable {
    case pending
    case validating
    case awaitingApproval
    case executing
    case verifying
    case completed
    case failed(reason: String)
    case skipped(reason: String)
    case cancelled
}

// MARK: - Task Step Model
public struct AgentTaskStep: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let stepNumber: Int
    public let title: String
    public let explanation: String
    public let requiredTool: String
    public let parameters: [String: String]
    public let dependencies: [UUID]
    public let requiredPermission: String?
    public let riskLevel: ActionRiskLevel
    public var status: AgentStepStatus
    public var outputResult: String?
    public var verificationMethod: String?
    
    public init(
        id: UUID = UUID(),
        stepNumber: Int,
        title: String,
        explanation: String,
        requiredTool: String,
        parameters: [String: String] = [:],
        dependencies: [UUID] = [],
        requiredPermission: String? = nil,
        riskLevel: ActionRiskLevel = .low,
        status: AgentStepStatus = .pending,
        outputResult: String? = nil,
        verificationMethod: String? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.title = title
        self.explanation = explanation
        self.requiredTool = requiredTool
        self.parameters = parameters
        self.dependencies = dependencies
        self.requiredPermission = requiredPermission
        self.riskLevel = riskLevel
        self.status = status
        self.outputResult = outputResult
        self.verificationMethod = verificationMethod
    }
}

// MARK: - Task Plan Model
public struct AgentTaskPlan: Identifiable, Sendable {
    public let id: UUID
    public let originalInstruction: String
    public let intendedOutcome: String
    public var steps: [AgentTaskStep]
    public var currentStepIndex: Int
    public let riskLevel: ActionRiskLevel
    public var status: AgentTaskStatus
    public let createdAt: Date
    public var completedAt: Date?
    public var summary: String?
    
    public init(
        id: UUID = UUID(),
        originalInstruction: String,
        intendedOutcome: String,
        steps: [AgentTaskStep],
        currentStepIndex: Int = 0,
        riskLevel: ActionRiskLevel = .low,
        status: AgentTaskStatus = .created,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        summary: String? = nil
    ) {
        self.id = id
        self.originalInstruction = originalInstruction
        self.intendedOutcome = intendedOutcome
        self.steps = steps
        self.currentStepIndex = currentStepIndex
        self.riskLevel = riskLevel
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.summary = summary
    }
    
    public var currentStep: AgentTaskStep? {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    public var totalSteps: Int { steps.count }
    
    public var progressFraction: Double {
        guard !steps.isEmpty else { return 0.0 }
        let completed = steps.filter { $0.status == .completed }.count
        return Double(completed) / Double(steps.count)
    }
}

// MARK: - Memory Category
public enum MemoryCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case userPreferences = "User Preferences"
    case workflowPreferences = "Workflow Preferences"
    case projectContext = "Project Context"
    case conversationContext = "Conversation Context"
    case temporaryContext = "Temporary Context"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .userPreferences: return "person.crop.circle"
        case .workflowPreferences: return "arrow.triangle.turn.up.right.diamond"
        case .projectContext: return "folder.badge.gearshape"
        case .conversationContext: return "bubble.left.and.text.bubble.right"
        case .temporaryContext: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - Memory Item Model
public struct AgentMemoryItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let category: MemoryCategory
    public let key: String
    public var content: String
    public var importance: Double // 0.0 to 1.0
    public var confidence: Double // 0.0 to 1.0
    public let createdAt: Date
    public var updatedAt: Date
    public var expiresAt: Date?
    public let source: String
    
    public init(
        id: UUID = UUID(),
        category: MemoryCategory,
        key: String,
        content: String,
        importance: Double = 0.5,
        confidence: Double = 1.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        expiresAt: Date? = nil,
        source: String = "user_interaction"
    ) {
        self.id = id
        self.category = category
        self.key = key
        self.content = content
        self.importance = importance
        self.confidence = confidence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
        self.source = source
    }
    
    public var isExpired: Bool {
        if let exp = expiresAt {
            return exp < Date()
        }
        return false
    }
}

// MARK: - Tool Category
public enum ToolCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case conversation = "Conversation"
    case screenIntelligence = "Screen Intelligence"
    case desktopAutomation = "Desktop Automation"
    case applicationContext = "Application Context"
    case memory = "Memory"
    case localFileOperations = "Local File Operations"
    
    public var id: String { rawValue }
}

// MARK: - Tool Definition
public struct ToolDefinition: Identifiable, Sendable {
    public let id: String
    public let category: ToolCategory
    public let name: String
    public let toolDescription: String
    public let parametersSchema: [String: String]
    public let requiredPermission: String?
    public let riskLevel: ActionRiskLevel
    public var isAvailable: Bool
    
    public init(
        id: String,
        category: ToolCategory,
        name: String,
        toolDescription: String,
        parametersSchema: [String: String] = [:],
        requiredPermission: String? = nil,
        riskLevel: ActionRiskLevel = .low,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.toolDescription = toolDescription
        self.parametersSchema = parametersSchema
        self.requiredPermission = requiredPermission
        self.riskLevel = riskLevel
        self.isAvailable = isAvailable
    }
}

// MARK: - Tool Execution Result
public struct ToolExecutionResult: Sendable {
    public let toolId: String
    public let isSuccess: Bool
    public let output: [String: String]
    public let errorMessage: String?
    
    public init(
        toolId: String,
        isSuccess: Bool,
        output: [String: String] = [:],
        errorMessage: String? = nil
    ) {
        self.toolId = toolId
        self.isSuccess = isSuccess
        self.output = output
        self.errorMessage = errorMessage
    }
    
    public static func success(toolId: String, output: [String: String] = [:]) -> ToolExecutionResult {
        ToolExecutionResult(toolId: toolId, isSuccess: true, output: output, errorMessage: nil)
    }
    
    public static func failure(toolId: String, error: String) -> ToolExecutionResult {
        ToolExecutionResult(toolId: toolId, isSuccess: false, output: [:], errorMessage: error)
    }
}

// MARK: - Agent Preferences
public struct AgentPreferences: Codable, Equatable, Sendable {
    public var isMemoryEnabled: Bool
    public var retentionDays: Int
    public var maxStoredMemories: Int
    public var requireApprovalForMediumRisk: Bool
    public var requireApprovalForHighRisk: Bool
    public var maxPlanningSteps: Int
    public var allowParallelSafeOps: Bool
    
    public static let `default` = AgentPreferences(
        isMemoryEnabled: true,
        retentionDays: 30,
        maxStoredMemories: 200,
        requireApprovalForMediumRisk: false,
        requireApprovalForHighRisk: true,
        maxPlanningSteps: 10,
        allowParallelSafeOps: false
    )
}

