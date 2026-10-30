//
//  TaskExecutor.swift
//  AUTO
//
//  Orchestrates step-by-step workflow execution, dependency validation,
//  safety gating, tool dispatching, verification, and failure recovery.
//

import Foundation

public final class TaskExecutor: @unchecked Sendable {
    public static let shared = TaskExecutor()
    
    private let toolDispatcher: ToolDispatcher
    private let safetyManager: AgentSafetyManager
    private let permissionManager: AgentPermissionManager
    private let verificationManager: TaskVerificationManager
    
    public init(
        toolDispatcher: ToolDispatcher = .shared,
        safetyManager: AgentSafetyManager = .shared,
        permissionManager: AgentPermissionManager = .shared,
        verificationManager: TaskVerificationManager = .shared
    ) {
        self.toolDispatcher = toolDispatcher
        self.safetyManager = safetyManager
        self.permissionManager = permissionManager
        self.verificationManager = verificationManager
    }
    
    /// Executes a single step of a plan with verification.
    public func executeStep(
        _ step: AgentTaskStep,
        preferences: AgentPreferences = .default
    ) async -> (step: AgentTaskStep, status: AgentStepStatus) {
        var runningStep = step
        runningStep.status = .validating
        
        // 1. Permission check
        guard permissionManager.isPermissionGranted(for: runningStep) else {
            let reason = "Permission '\(runningStep.requiredPermission ?? "Unknown")' is not granted."
            runningStep.status = .failed(reason: reason)
            return (runningStep, runningStep.status)
        }
        
        // 2. Safety & Approval check
        if safetyManager.requiresApproval(step: runningStep, preferences: preferences) {
            runningStep.status = .awaitingApproval
            return (runningStep, .awaitingApproval)
        }
        
        // 3. Execution
        runningStep.status = .executing
        let toolResult = await toolDispatcher.dispatch(
            toolId: runningStep.requiredTool,
            parameters: runningStep.parameters
        )
        
        // 4. Verification
        runningStep.status = .verifying
        let verification = await verificationManager.verifyStep(runningStep, result: toolResult)
        
        if verification.isSuccess {
            runningStep.status = .completed
            runningStep.outputResult = verification.details
            return (runningStep, .completed)
        } else {
            runningStep.status = .failed(reason: verification.details)
            return (runningStep, runningStep.status)
        }
    }
}

