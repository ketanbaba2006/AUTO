//
//  ActionExecutionManager.swift
//  AUTO
//
//  Central coordinator for proposing, validating, confirming, executing, and verifying
//  automated desktop interactions with risk classification and failsafe emergency stop.
//

import AppKit
import CoreGraphics
import Foundation

@MainActor
public final class ActionExecutionManager: ObservableObject {
    public static let shared = ActionExecutionManager()
    
    // MARK: - Published State
    @Published public private(set) var currentAction: AutomationAction? = nil
    @Published public private(set) var actionStatus: ActionStatus = .pending
    @Published public private(set) var pendingConfirmationAction: AutomationAction? = nil
    @Published public private(set) var actionHistory: [ActionRecord] = []
    @Published public var automationPreferences: AutomationPreferences {
        didSet {
            if let encoded = try? JSONEncoder().encode(automationPreferences) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.automationPreferences")
            }
        }
    }
    
    // Dependencies
    private let mouseManager: MouseActionService
    private let keyboardManager: KeyboardActionService
    private let verificationManager: ActionVerificationService
    private let permissionManager: ActionPermissionManager
    
    public init(
        mouseManager: MouseActionService,
        keyboardManager: KeyboardActionService,
        verificationManager: ActionVerificationService,
        permissionManager: ActionPermissionManager
    ) {
        self.mouseManager = mouseManager
        self.keyboardManager = keyboardManager
        self.verificationManager = verificationManager
        self.permissionManager = permissionManager
        
        if let data = UserDefaults.standard.data(forKey: "com.auto.automationPreferences"),
           let decoded = try? JSONDecoder().decode(AutomationPreferences.self, from: data) {
            self.automationPreferences = decoded
        } else {
            self.automationPreferences = .default
        }
        
        loadActionHistory()
    }
    
    public convenience init() {
        self.init(
            mouseManager: MouseActionManager.shared,
            keyboardManager: KeyboardActionManager.shared,
            verificationManager: ActionVerificationManager.shared,
            permissionManager: .shared
        )
    }
    
    // MARK: - Action Execution Entry Point
    
    /// Proposes and executes an automation action following safety gating.
    public func executeAction(_ action: AutomationAction) async -> ActionStatus {
        guard !EmergencyStopManager.shared.isEmergencyStopActive else {
            let status = ActionStatus.failed(reason: "Execution blocked by active Emergency Stop.")
            recordAction(action, finalStatus: status, wasSuccessful: false)
            return status
        }
        
        self.currentAction = action
        self.actionStatus = .validating
        
        // 1. Validate Permissions
        do {
            try permissionManager.canExecuteAutomation()
        } catch {
            let status = ActionStatus.failed(reason: error.localizedDescription)
            finishAction(action, status: status, wasSuccessful: false)
            return status
        }
        
        // 2. Risk Evaluation & Confirmation Gating
        if action.riskLevel == .high && automationPreferences.requireConfirmationForHighRisk {
            self.actionStatus = .awaitingConfirmation
            self.pendingConfirmationAction = action
            AppLogger.shared.warning("High-risk action awaiting user confirmation: \(action.reason)", category: .cursor)
            return .awaitingConfirmation
        }
        
        return await performExecution(action)
    }
    
    /// Confirms a pending high-risk action.
    public func confirmPendingAction() async -> ActionStatus {
        guard let action = pendingConfirmationAction else {
            return .pending
        }
        self.pendingConfirmationAction = nil
        return await performExecution(action)
    }
    
    /// Rejects or cancels a pending high-risk action.
    public func rejectPendingAction(reason: String = "User declined confirmation") {
        guard let action = pendingConfirmationAction else { return }
        self.pendingConfirmationAction = nil
        let status = ActionStatus.cancelled(reason: reason)
        finishAction(action, status: status, wasSuccessful: false)
    }
    
    // MARK: - Core Execution Routine
    
    private func performExecution(_ action: AutomationAction) async -> ActionStatus {
        self.actionStatus = .executing
        CursorOverlayManager.shared.updateVisualState(.executing(label: action.actionType.rawValue))
        
        let executionTask = Task { @MainActor () -> ActionStatus in
            do {
                try Task.checkCancellation()
                
                switch action.actionType {
                case .moveCursor:
                    if let target = action.targetCoordinates {
                        CursorOverlayManager.shared.updateVisualState(.targeting(target, label: action.targetElement?.displayName))
                        try await mouseManager.moveCursor(to: target, animated: true)
                    }
                    
                case .click:
                    if let target = action.targetCoordinates {
                        CursorOverlayManager.shared.updateVisualState(.clicking(target))
                        try await mouseManager.moveCursor(to: target, animated: true)
                        try await mouseManager.click(at: target)
                    } else {
                        try await mouseManager.click(at: nil)
                    }
                    
                case .doubleClick:
                    if let target = action.targetCoordinates {
                        CursorOverlayManager.shared.updateVisualState(.clicking(target))
                        try await mouseManager.moveCursor(to: target, animated: true)
                        try await mouseManager.doubleClick(at: target)
                    } else {
                        try await mouseManager.doubleClick(at: nil)
                    }
                    
                case .rightClick:
                    if let target = action.targetCoordinates {
                        try await mouseManager.moveCursor(to: target, animated: true)
                        try await mouseManager.rightClick(at: target)
                    } else {
                        try await mouseManager.rightClick(at: nil)
                    }
                    
                case .mouseDown:
                    try await mouseManager.mouseDown(button: .left, at: action.targetCoordinates)
                    
                case .mouseUp:
                    try await mouseManager.mouseUp(button: .left, at: action.targetCoordinates)
                    
                case .scroll:
                    if let delta = action.scrollDelta {
                        try await mouseManager.scroll(deltaY: Int32(delta.y), deltaX: Int32(delta.x))
                    } else {
                        try await mouseManager.scroll(deltaY: -5, deltaX: 0)
                    }
                    
                case .drag:
                    if let target = action.targetCoordinates {
                        let start = NSEvent.mouseLocation
                        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080.0
                        let cgStart = CoordinateMapper.appKitToCoreGraphicsGlobal(appKitPoint: start, primaryScreenHeight: primaryHeight)
                        try await mouseManager.drag(from: cgStart, to: target)
                    }
                    
                case .typeText:
                    if let text = action.textToType {
                        try await keyboardManager.typeText(text, obfuscatedInLogs: false)
                    }
                    
                case .pressKey:
                    if let key = action.keyToPress {
                        try await keyboardManager.pressNamedKey(key)
                    }
                }
                
                // 3. Action Verification
                self.actionStatus = .verifying
                let verification = await verificationManager.verifyAction(action)
                
                var finishedAction = action
                finishedAction.verificationNote = verification.details
                
                if verification.isVerified {
                    let status = ActionStatus.completed
                    finishAction(finishedAction, status: status, wasSuccessful: true)
                    return status
                } else {
                    let status = ActionStatus.failed(reason: "Verification failed: \(verification.details)")
                    finishAction(finishedAction, status: status, wasSuccessful: false)
                    return status
                }
                
            } catch is CancellationError {
                let status = ActionStatus.cancelled(reason: "Action cancelled by user or emergency stop.")
                finishAction(action, status: status, wasSuccessful: false)
                return status
            } catch {
                let status = ActionStatus.failed(reason: error.localizedDescription)
                finishAction(action, status: status, wasSuccessful: false)
                return status
            }
        }
        
        EmergencyStopManager.shared.registerActiveTask(Task {
            _ = await executionTask.value
        })
        
        return await executionTask.value
    }
    
    // MARK: - Completion & History Logging
    
    private func finishAction(_ action: AutomationAction, status: ActionStatus, wasSuccessful: Bool) {
        self.actionStatus = status
        self.currentAction = nil
        
        if wasSuccessful {
            CursorOverlayManager.shared.updateVisualState(.idle)
        } else {
            CursorOverlayManager.shared.updateVisualState(.error(reason: "Action halted"))
        }
        
        recordAction(action, finalStatus: status, wasSuccessful: wasSuccessful)
    }
    
    private func recordAction(_ action: AutomationAction, finalStatus: ActionStatus, wasSuccessful: Bool) {
        let statusStr: String
        switch finalStatus {
        case .completed: statusStr = "Completed"
        case .cancelled(let r): statusStr = "Cancelled: \(r)"
        case .failed(let r): statusStr = "Failed: \(r)"
        case .awaitingConfirmation: statusStr = "Awaiting Confirmation"
        default: statusStr = "In Progress"
        }
        
        let record = ActionRecord(
            actionType: action.actionType,
            targetAppName: action.targetApp ?? action.targetElement?.appName,
            summary: action.reason,
            riskLevel: action.riskLevel,
            statusString: statusStr,
            wasSuccessful: wasSuccessful
        )
        
        self.actionHistory.insert(record, at: 0)
        // Keep max 50 records in memory/storage
        if self.actionHistory.count > 50 {
            self.actionHistory = Array(self.actionHistory.prefix(50))
        }
        saveActionHistory()
    }
    
    public func clearActionHistory() {
        self.actionHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "com.auto.actionHistory")
    }
    
    public func clearHistory() {
        clearActionHistory()
    }
    
    public func handleEmergencyStop() {
        if let current = currentAction {
            finishAction(current, status: .cancelled(reason: "Emergency Stop triggered"), wasSuccessful: false)
        }
        self.pendingConfirmationAction = nil
        self.actionStatus = .cancelled(reason: "Emergency Stop")
    }
    
    // MARK: - Persistence
    
    private func saveActionHistory() {
        if let data = try? JSONEncoder().encode(actionHistory) {
            UserDefaults.standard.set(data, forKey: "com.auto.actionHistory")
        }
    }
    
    private func loadActionHistory() {
        if let data = UserDefaults.standard.data(forKey: "com.auto.actionHistory"),
           let decoded = try? JSONDecoder().decode([ActionRecord].self, from: data) {
            self.actionHistory = decoded
        }
    }
}
