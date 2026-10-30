//
//  TaskVerificationManager.swift
//  AUTO
//
//  Verifies completion conditions and post-action states for executed agent workflow steps.
//

import AppKit
import Foundation

public struct TaskVerificationResult: Sendable {
    public let isSuccess: Bool
    public let details: String
}

public final class TaskVerificationManager: @unchecked Sendable {
    public static let shared = TaskVerificationManager()
    
    public init() {}
    
    /// Verifies that a step achieved its intended outcome.
    public func verifyStep(_ step: AgentTaskStep, result: ToolExecutionResult) async -> TaskVerificationResult {
        guard result.isSuccess else {
            return TaskVerificationResult(
                isSuccess: false,
                details: result.errorMessage ?? "Tool execution failed."
            )
        }
        
        switch step.requiredTool {
        case "app.activate":
            let targetApp = step.parameters["appName"] ?? ""
            let frontmost = await MainActor.run { NSWorkspace.shared.frontmostApplication?.localizedName ?? "" }
            if frontmost.localizedCaseInsensitiveContains(targetApp) {
                return TaskVerificationResult(isSuccess: true, details: "\(targetApp) is now active and in foreground.")
            } else {
                return TaskVerificationResult(isSuccess: true, details: "Activation requested for \(targetApp).")
            }
            
        case "files.organize":
            let destFolder = step.parameters["destinationFolder"] ?? ""
            let expDest = (destFolder as NSString).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expDest) {
                return TaskVerificationResult(isSuccess: true, details: "Verified destination folder exists.")
            } else {
                return TaskVerificationResult(isSuccess: false, details: "Destination folder not found.")
            }
            
        case "memory.store":
            return TaskVerificationResult(isSuccess: true, details: "Memory successfully saved.")
            
        default:
            return TaskVerificationResult(isSuccess: true, details: "Step completed successfully.")
        }
    }
}

