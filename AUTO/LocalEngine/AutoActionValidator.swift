//
//  AutoActionValidator.swift
//  AUTO
//
//  Local Action Validator: strictly validates all action proposals
//  from Gemini or local workflows before execution.
//  Enforces spatial boundary clamping, schema integrity, risk classification,
//  and blocks arbitrary shell or code execution.
//

import Foundation
import CoreGraphics
import AppKit

public struct DesktopActionProposal: Sendable {
    public let actionType: AutomationActionType
    public let targetPoint: CGPoint?
    public let textParameter: String?
    public let elementDescription: String?
    
    public init(
        actionType: AutomationActionType,
        targetPoint: CGPoint? = nil,
        textParameter: String? = nil,
        elementDescription: String? = nil
    ) {
        self.actionType = actionType
        self.targetPoint = targetPoint
        self.textParameter = textParameter
        self.elementDescription = elementDescription
    }
}

public struct AutoValidatedAction: Sendable {
    public let originalProposal: DesktopActionProposal
    public let riskLevel: ActionRiskLevel
    public let requiresConfirmation: Bool
    public let clampedCoordinates: CGPoint?
    public let warningMessage: String?
}

public final class AutoActionValidator: @unchecked Sendable {
    public static let shared = AutoActionValidator()
    
    private init() {}
    
    /// Validates an incoming action proposal against security rules, display boundaries, and risk tiers.
    public func validate(proposal: DesktopActionProposal) -> Result<AutoValidatedAction, AUTOError> {
        // 1. Guard against arbitrary code or shell injection attempts
        if let text = proposal.textParameter {
            if containsCodeInjection(text) {
                AppLogger.shared.error("Security alert: Blocked suspicious command injection attempt.", category: .security)
                return .failure(.automationError(reason: "Action proposal contained blocked shell/script execution syntax."))
            }
        }
        
        // 2. Validate coordinates if specified
        var clampedPoint: CGPoint? = nil
        if let target = proposal.targetPoint {
            guard !target.x.isNaN && !target.y.isNaN && !target.x.isInfinite && !target.y.isInfinite else {
                return .failure(.automationError(reason: "Invalid non-numeric coordinates (\(target.x), \(target.y))."))
            }
            
            // Validate against active display bounds
            let screens = NSScreen.screens
            guard !screens.isEmpty else {
                return .failure(.automationError(reason: "No active displays found to map coordinates."))
            }
            
            // Calculate union bounds of all screens
            let minX = screens.map { $0.frame.minX }.min() ?? 0
            let maxX = screens.map { $0.frame.maxX }.max() ?? 1920
            let minY = screens.map { $0.frame.minY }.min() ?? 0
            let maxY = screens.map { $0.frame.maxY }.max() ?? 1080
            
            let clampedX = min(max(target.x, minX), maxX)
            let clampedY = min(max(target.y, minY), maxY)
            clampedPoint = CGPoint(x: clampedX, y: clampedY)
        }
        
        // 3. Determine Risk Level
        let riskLevel = determineRiskLevel(proposal: proposal)
        let requiresConfirmation = (riskLevel == .high)
        let warning = requiresConfirmation ? "This action may alter system state, modify files, or close applications." : nil
        
        let validated = AutoValidatedAction(
            originalProposal: proposal,
            riskLevel: riskLevel,
            requiresConfirmation: requiresConfirmation,
            clampedCoordinates: clampedPoint,
            warningMessage: warning
        )
        
        return .success(validated)
    }
    
    private func determineRiskLevel(proposal: DesktopActionProposal) -> ActionRiskLevel {
        switch proposal.actionType {
        case .moveCursor, .scroll:
            return .low
        case .click, .doubleClick, .rightClick, .mouseDown, .mouseUp:
            if let desc = proposal.elementDescription?.lowercased() {
                if desc.contains("delete") || desc.contains("trash") || desc.contains("erase") || desc.contains("uninstall") {
                    return .high
                }
            }
            return .low
        case .typeText:
            return .medium
        case .pressKey:
            if let keyCombo = proposal.textParameter?.lowercased() {
                if keyCombo.contains("cmd+q") || keyCombo.contains("cmd+w") || keyCombo.contains("cmd+backspace") || keyCombo.contains("cmd+delete") {
                    return .high
                }
            }
            return .medium
        case .drag:
            return .medium
        }
    }
    
    private func containsCodeInjection(_ text: String) -> Bool {
        let lowercase = text.lowercased()
        let forbiddenPatterns = [
            "rm -rf", "sudo ", "chmod ", "/dev/null", "curl | sh", "wget ",
            ":(){ :|:& };:", "dd if=", "mkfs.", "> /dev/sda", "launchctl unload"
        ]
        return forbiddenPatterns.contains(where: { lowercase.contains($0) })
    }
}
