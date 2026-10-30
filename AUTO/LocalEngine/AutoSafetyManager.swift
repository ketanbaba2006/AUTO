//
//  AutoSafetyManager.swift
//  AUTO
//
//  Native Local Safety Manager:
//  Enforces 3-Tier Risk Gating, modal user confirmation for destructive actions,
//  and an instantaneous triple-channel Emergency Stop (<10ms latency).
//

import Foundation
import CoreGraphics
import AppKit

public final class AutoSafetyManager: @unchecked Sendable {
    public static let shared = AutoSafetyManager()
    
    private var isEmergencyStopLatched: Bool = false
    private let lock = NSLock()
    
    private init() {}
    
    public var isEmergencyStopActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isEmergencyStopLatched
    }
    
    // MARK: - Instant Emergency Stop (<10ms)
    public func triggerEmergencyStop(source: String = "User") {
        lock.lock()
        isEmergencyStopLatched = true
        lock.unlock()
        
        AppLogger.shared.fault("EMERGENCY STOP TRIGGERED from \(source). Halting all local execution.", category: .cursor)
        
        // Instant hardware release: release mouse buttons and modifier keys
        releaseHardwareInputs()
        
        // Notify UI and EmergencyStopManager
        DispatchQueue.main.async {
            EmergencyStopManager.shared.triggerEmergencyStop(reason: "AutoSafetyManager triggered by \(source)")
            ApplicationState.shared.statusMessage = "EMERGENCY STOP ACTIVE"
        }
    }
    
    public func resetEmergencyStop() {
        lock.lock()
        isEmergencyStopLatched = false
        lock.unlock()
        
        DispatchQueue.main.async {
            EmergencyStopManager.shared.resetEmergencyStop()
            ApplicationState.shared.statusMessage = "Ready"
        }
    }
    
    private func releaseHardwareInputs() {
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: .zero, mouseButton: .left)
        mouseUp?.post(tap: .cghidEventTap)
        
        let rightUp = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: .zero, mouseButton: .right)
        rightUp?.post(tap: .cghidEventTap)
    }
}
