//
//  AgentOrchestrator.swift
//  AUTO
//
//  Master coordinator for autonomous agent operations.
//  Coordinates task planning, step execution, safety approvals, memory grounding,
//  and UI/voice feedback across multi-step desktop workflows.
//

import AppKit
import Foundation

@MainActor
public final class AgentOrchestrator: ObservableObject {
    public static let shared = AgentOrchestrator()
    
    // MARK: - Published State
    @Published public private(set) var activePlan: AgentTaskPlan? = nil
    @Published public private(set) var taskStatus: AgentTaskStatus = .created
    @Published public private(set) var pendingApproval: StepApprovalRequest? = nil
    @Published public private(set) var taskHistory: [AgentTaskPlan] = []
    @Published public var agentPreferences: AgentPreferences {
        didSet {
            if let encoded = try? JSONEncoder().encode(agentPreferences) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.agentPreferences")
                UserDefaults.standard.set(agentPreferences.isMemoryEnabled, forKey: "com.auto.isMemoryEnabled")
            }
        }
    }
    
    private let planner: TaskPlanner
    private let executor: TaskExecutor
    private let safetyManager: AgentSafetyManager
    private let memoryRetrieval: MemoryRetrievalManager
    
    private var executionTask: Task<Void, Never>? = nil
    
    public init(
        planner: TaskPlanner = .shared,
        executor: TaskExecutor = .shared,
        safetyManager: AgentSafetyManager = .shared,
        memoryRetrieval: MemoryRetrievalManager = .shared
    ) {
        self.planner = planner
        self.executor = executor
        self.safetyManager = safetyManager
        self.memoryRetrieval = memoryRetrieval
        
        if let data = UserDefaults.standard.data(forKey: "com.auto.agentPreferences"),
           let decoded = try? JSONDecoder().decode(AgentPreferences.self, from: data) {
            self.agentPreferences = decoded
        } else {
            self.agentPreferences = .default
        }
    }
    
    // MARK: - Start Workflow
    
    /// Plans and initiates a multi-step task workflow from a natural language instruction.
    public func startTask(instruction: String) {
        cancelCurrentTask(reason: "Superseded by new task")
        
        // 1. Retrieve relevant memory for task grounding
        let memorySnippet = memoryRetrieval.retrieveRelevantContext(for: instruction)
        if let snippet = memorySnippet {
            AppLogger.shared.info("Task grounded with retrieved memory: \(snippet)", category: .agent)
        }
        
        // 2. Plan Task
        let plan = planner.planTask(instruction: instruction)
        self.activePlan = plan
        self.taskStatus = .planning
        ApplicationState.shared.statusMessage = "AUTO is planning your task..."
        
        // 3. Begin Sequential Execution
        executionTask = Task { @MainActor in
            await runExecutionLoop()
        }
    }
    
    // MARK: - Execution Loop
    
    private func runExecutionLoop() async {
        guard var plan = activePlan else { return }
        
        while plan.currentStepIndex < plan.steps.count {
            if Task.isCancelled { break }
            
            let currentIndex = plan.currentStepIndex
            let currentStep = plan.steps[currentIndex]
            
            // Update UI status
            self.taskStatus = .executing(
                currentStep: currentIndex + 1,
                totalSteps: plan.steps.count,
                stepTitle: currentStep.title
            )
            ApplicationState.shared.statusMessage = "Step \(currentIndex + 1)/\(plan.steps.count): \(currentStep.title)"
            
            // Speak brief progress update if configured
            if ApplicationState.shared.voicePreferences.autoSpeakResponse && currentIndex == 0 {
                SpeechOutputManager.shared.speak(text: "Starting task: \(currentStep.title)")
            }
            
            // Check Approval Gating
            if safetyManager.requiresApproval(step: currentStep, preferences: agentPreferences) {
                let approvalReq = safetyManager.createApprovalRequest(for: currentStep)
                self.pendingApproval = approvalReq
                self.taskStatus = .awaitingApproval(
                    stepTitle: currentStep.title,
                    explanation: currentStep.explanation,
                    risk: currentStep.riskLevel
                )
                ApplicationState.shared.statusMessage = "Awaiting approval for: \(currentStep.title)"
                return // Pause execution until user authorizes
            }
            
            // Execute Step
            let (updatedStep, stepStatus) = await executor.executeStep(currentStep, preferences: agentPreferences)
            plan.steps[currentIndex] = updatedStep
            self.activePlan = plan
            
            switch stepStatus {
            case .completed:
                plan.currentStepIndex += 1
                self.activePlan = plan
                
            case .awaitingApproval:
                let approvalReq = safetyManager.createApprovalRequest(for: updatedStep)
                self.pendingApproval = approvalReq
                self.taskStatus = .awaitingApproval(
                    stepTitle: updatedStep.title,
                    explanation: updatedStep.explanation,
                    risk: updatedStep.riskLevel
                )
                return
                
            case .failed(let reason):
                self.taskStatus = .failed(reason: reason)
                ApplicationState.shared.statusMessage = "Step failed: \(reason)"
                finishPlan(plan, status: .failed(reason: reason))
                return
                
            default:
                break
            }
        }
        
        // All steps completed!
        let summary = "Successfully completed \(plan.steps.count) steps."
        plan.summary = summary
        plan.completedAt = Date()
        self.taskStatus = .completed(summary: summary)
        ApplicationState.shared.statusMessage = "Task completed!"
        
        if ApplicationState.shared.voicePreferences.autoSpeakResponse {
            SpeechOutputManager.shared.speak(text: "Task completed: \(plan.intendedOutcome)")
        }
        
        finishPlan(plan, status: .completed(summary: summary))
    }
    
    // MARK: - Approval Actions
    
    /// User authorizes the currently pending step.
    public func approvePendingStep() {
        guard pendingApproval != nil, var plan = activePlan else { return }
        self.pendingApproval = nil
        
        let index = plan.currentStepIndex
        plan.steps[index].status = .executing
        self.activePlan = plan
        
        executionTask = Task { @MainActor in
            let (updatedStep, stepStatus) = await executor.executeStep(plan.steps[index], preferences: AgentPreferences(
                isMemoryEnabled: agentPreferences.isMemoryEnabled,
                retentionDays: agentPreferences.retentionDays,
                maxStoredMemories: agentPreferences.maxStoredMemories,
                requireApprovalForMediumRisk: false, // bypassed for this approved step
                requireApprovalForHighRisk: false,
                maxPlanningSteps: agentPreferences.maxPlanningSteps,
                allowParallelSafeOps: agentPreferences.allowParallelSafeOps
            ))
            
            plan.steps[index] = updatedStep
            if stepStatus == .completed {
                plan.currentStepIndex += 1
            }
            self.activePlan = plan
            await runExecutionLoop()
        }
    }
    
    /// User rejects the pending step.
    public func rejectPendingStep(reason: String = "User declined step approval") {
        guard pendingApproval != nil, var plan = activePlan else { return }
        self.pendingApproval = nil
        let index = plan.currentStepIndex
        plan.steps[index].status = .cancelled
        self.taskStatus = .cancelled(reason: reason)
        ApplicationState.shared.statusMessage = "Task cancelled by user."
        finishPlan(plan, status: .cancelled(reason: reason))
    }
    
    // MARK: - Cancellation & Pause
    
    public func pauseTask() {
        executionTask?.cancel()
        executionTask = nil
        self.taskStatus = .paused
        ApplicationState.shared.statusMessage = "Task paused."
    }
    
    public func resumeTask() {
        guard taskStatus == .paused, activePlan != nil else { return }
        executionTask = Task { @MainActor in
            await runExecutionLoop()
        }
    }
    
    public func cancelCurrentTask(reason: String = "User cancelled task") {
        executionTask?.cancel()
        executionTask = nil
        self.pendingApproval = nil
        
        if var plan = activePlan {
            plan.status = .cancelled(reason: reason)
            finishPlan(plan, status: .cancelled(reason: reason))
        }
        
        self.taskStatus = .cancelled(reason: reason)
        ApplicationState.shared.statusMessage = "Task cancelled."
    }
    
    private func finishPlan(_ plan: AgentTaskPlan, status: AgentTaskStatus) {
        var finished = plan
        finished.status = status
        self.taskHistory.insert(finished, at: 0)
        if self.taskHistory.count > 25 {
            self.taskHistory = Array(self.taskHistory.prefix(25))
        }
        self.activePlan = nil
    }
}
