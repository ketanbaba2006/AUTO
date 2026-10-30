//
//  AgentManager.swift
//  AUTO
//
//  Autonomous companion agent coordinator managing reasoning, memory, task planning, and actions.
//

import Foundation

@MainActor
public final class AgentManager: ObservableObject {
    public static let shared = AgentManager()
    
    public let conversationManager: ConversationManager
    public let toolExecutionManager: ToolExecutionManager
    public let orchestrator: AgentOrchestrator
    public let memoryManager: MemoryManager
    
    public init(
        conversationManager: ConversationManager,
        toolExecutionManager: ToolExecutionManager,
        orchestrator: AgentOrchestrator,
        memoryManager: MemoryManager
    ) {
        self.conversationManager = conversationManager
        self.toolExecutionManager = toolExecutionManager
        self.orchestrator = orchestrator
        self.memoryManager = memoryManager
    }
    
    public convenience init() {
        self.init(
            conversationManager: .shared,
            toolExecutionManager: .shared,
            orchestrator: .shared,
            memoryManager: .shared
        )
    }
    
    /// Starts an autonomous multi-step workflow.
    public func executeTask(instruction: String) {
        orchestrator.startTask(instruction: instruction)
    }
    
    /// Stops any running task.
    public func stopTask() {
        orchestrator.cancelCurrentTask(reason: "User requested task halt")
    }
}
