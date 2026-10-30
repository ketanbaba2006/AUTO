//
//  ActionProposalParser.swift
//  AUTO
//
//  Parses structured action proposals emitted by Gemini / AI models.
//  Extracts [ACTION:{...}] tags and JSON blocks, validates safety constraints,
//  and classifies action risk levels before local execution.
//

import CoreGraphics
import Foundation

public struct ProposedActionDTO: Codable, Sendable {
    public let action: String
    public let target: String?
    public let coordinates: [Double]? // [x, y] normalized
    public let text: String?
    public let key: String?
    public let risk: String?
    public let reason: String?
}

public struct ActionProposalParser: Sendable {
    
    /// Parses action proposals from assistant response text.
    public static func parseAction(from text: String) -> AutomationAction? {
        // 1. Try matching [ACTION:{...}] tag
        let actionTagPattern = #"(?s)\[ACTION:(\{.*?\})\]"#
        if let regex = try? NSRegularExpression(pattern: actionTagPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let jsonRange = Range(match.range(at: 1), in: text) {
            let jsonString = String(text[jsonRange])
            if let action = decodeAction(from: jsonString) {
                return action
            }
        }
        
        // 2. Try matching standalone JSON code block ```json { "action": ... } ```
        let codeBlockPattern = #"(?s)```(?:json)?\s*(\{\s*"action"\s*:.*?\})\s*```"#
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let jsonRange = Range(match.range(at: 1), in: text) {
            let jsonString = String(text[jsonRange])
            if let action = decodeAction(from: jsonString) {
                return action
            }
        }
        
        return nil
    }
    
    private static func decodeAction(from jsonString: String) -> AutomationAction? {
        guard let data = jsonString.data(using: .utf8),
              let dto = try? JSONDecoder().decode(ProposedActionDTO.self, from: data) else {
            return nil
        }
        
        // Map action string to AutomationActionType
        let actionType: AutomationActionType
        switch dto.action.lowercased() {
        case "click", "leftclick", "left_click":
            actionType = .click
        case "doubleclick", "double_click":
            actionType = .doubleClick
        case "rightclick", "right_click":
            actionType = .rightClick
        case "movecursor", "move_cursor", "move":
            actionType = .moveCursor
        case "scroll":
            actionType = .scroll
        case "drag":
            actionType = .drag
        case "typetext", "type_text", "type":
            actionType = .typeText
        case "presskey", "press_key", "key":
            actionType = .pressKey
        default:
            return nil
        }
        
        // Parse coordinates if provided
        var targetCoords: CGPoint? = nil
        if let coords = dto.coordinates, coords.count >= 2 {
            targetCoords = CGPoint(x: coords[0], y: coords[1])
        }
        
        // Determine risk level with safety defaults
        let riskLevel = determineRiskLevel(
            actionType: actionType,
            declaredRisk: dto.risk,
            target: dto.target,
            textToType: dto.text
        )
        
        return AutomationAction(
            actionType: actionType,
            targetApp: nil,
            targetElement: nil,
            targetCoordinates: targetCoords,
            textToType: dto.text,
            keyToPress: dto.key,
            keyModifiers: [],
            scrollDelta: actionType == .scroll ? CGPoint(x: 0, y: -5) : nil,
            riskLevel: riskLevel,
            reason: dto.reason ?? "Action proposed for '\(dto.target ?? actionType.rawValue)'"
        )
    }
    
    public static func determineRiskLevel(
        actionType: AutomationActionType,
        declaredRisk: String?,
        target: String?,
        textToType: String?
    ) -> ActionRiskLevel {
        let targetLower = (target ?? "").lowercased()
        let textLower = (textToType ?? "").lowercased()
        
        // Inherently high-risk actions
        let highRiskKeywords = ["delete", "remove", "trash", "purchase", "buy", "pay", "format", "quit", "close window", "kill", "security", "terminal"]
        for kw in highRiskKeywords {
            if targetLower.contains(kw) || textLower.contains(kw) {
                return .high
            }
        }
        
        if let declared = declaredRisk?.lowercased() {
            if declared == "high" { return .high }
            if declared == "medium" { return .medium }
            if declared == "low" { return .low }
        }
        
        switch actionType {
        case .moveCursor:
            return .low
        case .click, .doubleClick, .rightClick, .scroll:
            return .medium
        case .typeText, .pressKey, .drag:
            return .medium
        case .mouseDown, .mouseUp:
            return .medium
        }
    }
}

