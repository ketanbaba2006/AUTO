//
//  AgentPermissionManager.swift
//  AUTO
//
//  Validates and preflights macOS permissions required by autonomous agent workflows
//  (Screen Recording, Accessibility, Files, Microphone).
//

import AppKit
import ApplicationServices
import Foundation

public final class AgentPermissionManager: @unchecked Sendable {
    public static let shared = AgentPermissionManager()
    
    public init() {}
    
    /// Checks whether the required permission for an agent step is currently granted.
    public func isPermissionGranted(for step: AgentTaskStep) -> Bool {
        guard let permission = step.requiredPermission else { return true }
        
        switch permission {
        case "Screen Recording":
            return CGPreflightScreenCaptureAccess()
        case "Accessibility":
            return AXIsProcessTrusted()
        default:
            return true
        }
    }
}

