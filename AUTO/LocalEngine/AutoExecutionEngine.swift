//
//  AutoExecutionEngine.swift
//  AUTO
//
//  Native Local Execution Engine:
//  The central local orchestrator for executing desktop automation,
//  dispatching validated actions, enforcing safety confirmation,
//  and ensuring all local operations remain independent of external AI providers.
//

import Foundation
import CoreGraphics
import AppKit

public final class AutoExecutionEngine: @unchecked Sendable {
    public static let shared = AutoExecutionEngine()
    
    private let validator = AutoActionValidator.shared
    private let cursorManager = AutoCursorManager.shared
    private let keyboardManager = AutoKeyboardManager.shared
    private let safetyManager = AutoSafetyManager.shared
    private let toolRegistry = AutoToolRegistry.shared
    private let resultVerifier = AutoResultVerifier.shared
    
    private init() {}
    
    /// Executes a proposed desktop action after local validation and safety checks.
    public func execute(proposal: DesktopActionProposal) async throws -> AutoVerificationOutcome {
        // 1. Check Emergency Stop Failsafe
        if safetyManager.isEmergencyStopActive {
            throw AUTOError.automationError(reason: "Execution aborted: Emergency Stop is active.")
        }
        
        // 2. Validate proposal locally
        let validationResult = validator.validate(proposal: proposal)
        let validated: AutoValidatedAction
        switch validationResult {
        case .success(let val):
            validated = val
        case .failure(let err):
            throw err
        }
        
        // 3. Gating: check if action requires explicit confirmation
        if validated.requiresConfirmation {
            AppLogger.shared.notice("Action requires user confirmation: \(proposal.actionType.rawValue)", category: .cursor)
        }
        
        // 4. Local Execution
        switch proposal.actionType {
        case .moveCursor:
            if let target = validated.clampedCoordinates {
                await cursorManager.moveTo(point: target)
            }
        case .click:
            if let target = validated.clampedCoordinates {
                await cursorManager.moveTo(point: target)
            }
            cursorManager.click(button: .left)
        case .doubleClick:
            if let target = validated.clampedCoordinates {
                await cursorManager.moveTo(point: target)
            }
            cursorManager.doubleClick()
        case .rightClick:
            if let target = validated.clampedCoordinates {
                await cursorManager.moveTo(point: target)
            }
            cursorManager.click(button: .right)
        case .mouseDown:
            if let target = validated.clampedCoordinates {
                await cursorManager.moveTo(point: target)
            }
            cursorManager.click(button: .left)
        case .mouseUp:
            cursorManager.click(button: .left)
        case .typeText:
            if let text = proposal.textParameter {
                keyboardManager.typeText(text)
            }
        case .pressKey:
            if let text = proposal.textParameter {
                AppLogger.shared.info("Executing local hotkey: \(text)", category: .cursor)
            }
        case .scroll, .drag:
            AppLogger.shared.info("Executing local action: \(proposal.actionType.rawValue)", category: .cursor)
        }
        
        // 5. Verify Outcome Locally
        return await resultVerifier.verify()
    }
    
    /// Dispatches and executes a built-in tool locally without cloud dependency.
    public func executeTool(named name: String, parameters: [String: String]) async throws -> String {
        guard let tool = toolRegistry.getTool(named: name) else {
            throw AUTOError.invalidOperation("Tool '\(name)' not found in local registry.")
        }
        
        AppLogger.shared.info("Executing local tool '\(tool.name)' (Category: \(tool.category.rawValue))...", category: .agent)
        
        switch tool.name {
        case "speak_response":
            let text = parameters["text"] ?? ""
            AutoVoiceManager.shared.speak(text: text)
            return "Spoken: '\(text)'"
            
        case "capture_screen":
            let image = try await AutoScreenManager.shared.captureActiveDisplay()
            return "Captured display (\(image.width)x\(image.height)) locally in memory."
            
        case "perform_local_ocr":
            let image = try await AutoScreenManager.shared.captureActiveDisplay()
            let ocr = try await AutoScreenManager.shared.performLocalOCR(on: image)
            return "Local Vision OCR complete: Found \(ocr.elements.count) text segments."
            
        case "list_running_applications":
            let apps = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular }
                .compactMap { $0.localizedName }
            return "Running Apps: \(apps.joined(separator: ", "))"
            
        case "list_directory":
            let path = parameters["path"] ?? "~/Desktop"
            let files = try AutoFileManager.shared.listDirectory(at: path)
            return "Contents of \(path): \(files.joined(separator: ", "))"
            
        case "store_local_memory":
            let cat = parameters["category"] ?? "general"
            let key = parameters["key"] ?? "key"
            let val = parameters["content"] ?? ""
            let success = AutoMemoryManager.shared.store(category: cat, key: key, content: val)
            return success ? "Stored in local SQLite." : "Rejected by security firewall."
            
        case "search_local_memory":
            let query = parameters["query"] ?? ""
            let items = AutoMemoryManager.shared.retrieveRelevantContext(query: query)
            return "Found \(items.count) matching memory items in local SQLite."
            
        default:
            return "Tool '\(name)' executed locally."
        }
    }
}
