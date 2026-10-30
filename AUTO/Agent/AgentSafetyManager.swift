//
//  AgentSafetyManager.swift
//  AUTO
//
//  Enforces safety boundaries, action risk classifications, prompt injection defenses,
//  and user approval gating for multi-step agent execution.
//

import Foundation

public struct StepApprovalRequest: Identifiable, Sendable {
    public let id: UUID
    public let step: AgentTaskStep
    public let reason: String
    public let consequences: String
    public let targetApplication: String?
}

public final class AgentSafetyManager: @unchecked Sendable {
    public static let shared = AgentSafetyManager()
    
    public init() {}
    
    /// Determines whether a task step requires explicit user approval before execution.
    public func requiresApproval(step: AgentTaskStep, preferences: AgentPreferences) -> Bool {
        if step.riskLevel == .high && preferences.requireApprovalForHighRisk {
            return true
        }
        if step.riskLevel == .medium && preferences.requireApprovalForMediumRisk {
            return true
        }
        
        // Destructive tools always require approval
        if step.requiredTool == "files.organize" {
            return true
        }
        
        return false
    }
    
    /// Generates human-readable approval details explaining the action and consequences.
    public func createApprovalRequest(for step: AgentTaskStep) -> StepApprovalRequest {
        let reason = step.explanation
        let consequences: String
        
        switch step.requiredTool {
        case "files.organize":
            consequences = "Files will be moved to designated folders on disk. No files will be deleted."
        case "automation.click":
            consequences = "Mouse will click '\(step.parameters["target"] ?? "the interface element")' in the active application."
        case "automation.type_text":
            consequences = "Text will be typed into the currently focused window."
        default:
            consequences = "This action will perform modifications on your desktop."
        }
        
        return StepApprovalRequest(
            id: UUID(),
            step: step,
            reason: reason,
            consequences: consequences,
            targetApplication: step.parameters["appName"]
        )
    }
    
    /// Validates text against prompt injection attacks attempting to override safety rules.
    public func sanitizeExternalContent(_ content: String) -> String {
        let maliciousPatterns = [
            "ignore previous instructions",
            "system override",
            "disregard safety",
            "format hard drive",
            "execute shell"
        ]
        var sanitized = content
        for pattern in maliciousPatterns {
            if sanitized.localizedCaseInsensitiveContains(pattern) {
                sanitized = sanitized.replacingOccurrences(of: pattern, with: "[BLOCKED_INJECTION]", options: .caseInsensitive)
            }
        }
        return sanitized
    }
}

