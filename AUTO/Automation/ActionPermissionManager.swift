//
//  ActionPermissionManager.swift
//  AUTO
//
//  Verifies and preflights macOS Accessibility and Input Monitoring permissions
//  required for mouse control, keyboard actions, and UI element discovery.
//

import AppKit
import ApplicationServices
import Foundation

@MainActor
public final class ActionPermissionManager: ObservableObject {
    public static let shared = ActionPermissionManager()
    
    @Published public private(set) var isAccessibilityGranted: Bool = false
    @Published public private(set) var isInputMonitoringGranted: Bool = false
    @Published public private(set) var lastCheckDate: Date = Date()
    
    public init() {
        refreshPermissionStatus()
    }
    
    /// Checks current Accessibility and Input Monitoring trust states.
    public func refreshPermissionStatus() {
        let trusted = AXIsProcessTrusted()
        self.isAccessibilityGranted = trusted
        self.isInputMonitoringGranted = trusted // AX trust grants CGEvent synthesis
        self.lastCheckDate = Date()
        
        // Sync with central ApplicationState
        ApplicationState.shared.hasAccessibilityPermission = trusted
        ApplicationState.shared.hasInputMonitoringPermission = trusted
    }
    
    /// Preflights accessibility trust with an optional OS prompt dialog.
    public func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        refreshPermissionStatus()
        return trusted
    }
    
    /// Opens macOS System Settings directly to Privacy & Security -> Accessibility.
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Opens macOS System Settings directly to Privacy & Security -> Input Monitoring.
    public func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Static nonisolated check for automation trust.
    public nonisolated static func checkAutomationPermission() throws {
        guard AXIsProcessTrusted() else {
            throw AUTOError.permissionDenied(
                permission: "Accessibility",
                instructions: "macOS Accessibility permission is required for mouse and keyboard control. Please grant access in System Settings."
            )
        }
    }
    
    /// Validates whether automation actions (mouse/keyboard input) can be safely executed.
    public nonisolated func canExecuteAutomation() throws {
        try Self.checkAutomationPermission()
    }
}
