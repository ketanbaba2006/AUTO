//
//  AutoTaskManager.swift
//  AUTO
//
//  Native Local Task Manager:
//  Manages step planning, dependency ordering (dependencies: [UUID]),
//  and task lifecycle states (pending, executing, completed, failed, cancelled).
//

import Foundation

public struct AutoTaskStep: Identifiable, Sendable {
    public let id: UUID
    public let order: Int
    public let title: String
    public let toolName: String
    public let parameters: [String: String]
    public let dependencies: [UUID]
    public var status: AgentStepStatus
    
    public init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        toolName: String,
        parameters: [String: String] = [:],
        dependencies: [UUID] = [],
        status: AgentStepStatus = .pending
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.toolName = toolName
        self.parameters = parameters
        self.dependencies = dependencies
        self.status = status
    }
}

public final class AutoTaskManager: @unchecked Sendable {
    public static let shared = AutoTaskManager()
    
    private var activeSteps: [AutoTaskStep] = []
    private let lock = NSLock()
    
    private init() {}
    
    public func createPlan(instruction: String, steps: [(title: String, tool: String, params: [String: String])]) -> [AutoTaskStep] {
        lock.lock()
        defer { lock.unlock() }
        
        var generated: [AutoTaskStep] = []
        var lastId: UUID? = nil
        
        for (index, stepInfo) in steps.enumerated() {
            let id = UUID()
            let deps = lastId != nil ? [lastId!] : []
            let step = AutoTaskStep(
                id: id,
                order: index + 1,
                title: stepInfo.title,
                toolName: stepInfo.tool,
                parameters: stepInfo.params,
                dependencies: deps,
                status: .pending
            )
            generated.append(step)
            lastId = id
        }
        
        self.activeSteps = generated
        return generated
    }
    
    public func updateStepStatus(id: UUID, status: AgentStepStatus) {
        lock.lock()
        defer { lock.unlock() }
        
        if let idx = activeSteps.firstIndex(where: { $0.id == id }) {
            activeSteps[idx].status = status
        }
    }
    
    public func currentSteps() -> [AutoTaskStep] {
        lock.lock()
        defer { lock.unlock() }
        return activeSteps
    }
}
