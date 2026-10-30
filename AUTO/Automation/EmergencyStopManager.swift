//
//  EmergencyStopManager.swift
//  AUTO
//
//  Instant local failsafe for halting all automated cursor movements, mouse clicks,
//  and keyboard actions. Releases physical input locks and restores safe idle state.
//

import AppKit
import Foundation

@MainActor
public final class EmergencyStopManager: ObservableObject {
    public static let shared = EmergencyStopManager()
    
    @Published public private(set) var isEmergencyStopActive: Bool = false
    @Published public private(set) var stopTimestamp: Date? = nil
    
    private var activeActionTask: Task<Void, Error>? = nil
    
    public init() {}
    
    /// Registers the currently running automation task so it can be cancelled immediately.
    public func registerActiveTask(_ task: Task<Void, Error>) {
        self.activeActionTask = task
    }
    
    /// Triggers an immediate local emergency stop.
    /// Halts active tasks, resets mouse and keyboard states, and clears pending actions.
    public func triggerEmergencyStop(reason: String = "User initiated Emergency Stop") {
        AppLogger.shared.warning("EMERGENCY STOP TRIGGERED: \(reason)", category: .cursor)
        
        self.isEmergencyStopActive = true
        self.stopTimestamp = Date()
        
        // 1. Cancel the in-flight execution Task
        activeActionTask?.cancel()
        activeActionTask = nil
        
        // 2. Safely release any held mouse buttons or modifier keys
        MouseActionManager.shared.releaseHeldButtons()
        KeyboardActionManager.shared.releaseHeldKeys()
        
        // 3. Reset CursorManager & Overlay
        CursorManager.shared.resetToCursorFollowing()
        CursorOverlayManager.shared.updateVisualState(.idle)
        
        // 4. Update ApplicationState
        ApplicationState.shared.statusMessage = "Automation halted (Emergency Stop)"
        
        // 5. Notify ActionExecutionManager to cancel pending actions
        ActionExecutionManager.shared.handleEmergencyStop()
    }
    
    /// Resets the emergency stop latch to allow new safe operations.
    public func resetEmergencyStop() {
        self.isEmergencyStopActive = false
        self.stopTimestamp = nil
        ApplicationState.shared.statusMessage = "Ready"
        AppLogger.shared.info("Emergency Stop latch cleared.", category: .cursor)
    }
}

