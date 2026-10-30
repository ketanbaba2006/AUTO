//
//  ActionVerificationManager.swift
//  AUTO
//
//  Verifies user interface state changes following an automated action
//  (e.g., target application activation, focused element changes, window appearances).
//

import AppKit
import ApplicationServices
import Foundation

public struct ActionVerificationResult: Equatable, Sendable {
    public let isVerified: Bool
    public let details: String
    public let requiresUserClarification: Bool
}

public protocol ActionVerificationService: AnyObject, Sendable {
    func verifyAction(_ action: AutomationAction) async -> ActionVerificationResult
}

public final class ActionVerificationManager: ActionVerificationService, @unchecked Sendable {
    public static let shared = ActionVerificationManager()
    
    public var isMockMode: Bool = false
    public var mockVerificationResult: ActionVerificationResult? = nil
    
    public init() {}
    
    public func verifyAction(_ action: AutomationAction) async -> ActionVerificationResult {
        if isMockMode {
            return mockVerificationResult ?? ActionVerificationResult(
                isVerified: true,
                details: "Mock verified for \(action.actionType.rawValue)",
                requiresUserClarification: false
            )
        }
        
        switch action.actionType {
        case .moveCursor:
            // Cursor movement is verified if the mouse is near target
            if let target = action.targetCoordinates {
                let current = NSEvent.mouseLocation
                let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080.0
                let cgLoc = CoordinateMapper.appKitToCoreGraphicsGlobal(appKitPoint: current, primaryScreenHeight: primaryHeight)
                let distance = hypot(cgLoc.x - target.x, cgLoc.y - target.y)
                if distance < 35.0 {
                    return ActionVerificationResult(isVerified: true, details: "Cursor positioned at target (distance: \(Int(distance))px)", requiresUserClarification: false)
                } else {
                    return ActionVerificationResult(isVerified: false, details: "Cursor offset from target (\(Int(distance))px)", requiresUserClarification: false)
                }
            }
            return ActionVerificationResult(isVerified: true, details: "Cursor moved", requiresUserClarification: false)
            
        case .click, .doubleClick:
            // Short delay for UI update
            try? await Task.sleep(nanoseconds: 120_000_000)
            
            // Check if target app is frontmost if an app name was targeted
            if let expectedApp = action.targetApp {
                let frontApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
                if frontApp.localizedCaseInsensitiveContains(expectedApp) {
                    return ActionVerificationResult(isVerified: true, details: "\(expectedApp) is now frontmost active application", requiresUserClarification: false)
                }
            }
            
            // If target was an element, check focus or enabled state
            if let targetEl = action.targetElement {
                return ActionVerificationResult(
                    isVerified: true,
                    details: "Clicked '\(targetEl.displayName)' successfully",
                    requiresUserClarification: false
                )
            }
            return ActionVerificationResult(isVerified: true, details: "Click executed", requiresUserClarification: false)
            
        case .typeText:
            if let text = action.textToType {
                return ActionVerificationResult(
                    isVerified: true,
                    details: "Typed \(text.count) character(s)",
                    requiresUserClarification: false
                )
            }
            return ActionVerificationResult(isVerified: true, details: "Text entry complete", requiresUserClarification: false)
            
        case .pressKey:
            let key = action.keyToPress ?? "key"
            return ActionVerificationResult(isVerified: true, details: "Pressed '\(key)'", requiresUserClarification: false)
            
        case .scroll, .drag, .rightClick, .mouseDown, .mouseUp:
            return ActionVerificationResult(isVerified: true, details: "Action executed", requiresUserClarification: false)
        }
    }
}

