//
//  AutomationModels.swift
//  AUTO
//
//  Data models for cursor intelligence, mouse/keyboard automation,
//  accessibility element discovery, safety gating, and action execution.
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - Action Type
public enum AutomationActionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case moveCursor = "Move Cursor"
    case click = "Left Click"
    case doubleClick = "Double Click"
    case rightClick = "Right Click"
    case mouseDown = "Mouse Down"
    case mouseUp = "Mouse Up"
    case scroll = "Scroll"
    case drag = "Drag"
    case typeText = "Type Text"
    case pressKey = "Press Key"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .moveCursor: return "cursorarrow.motionlines"
        case .click: return "cursorarrow.click.2"
        case .doubleClick: return "cursorarrow.rays"
        case .rightClick: return "cursorarrow.click.badge.clock"
        case .mouseDown, .mouseUp: return "hand.tap"
        case .scroll: return "arrow.up.and.down"
        case .drag: return "hand.draw"
        case .typeText: return "keyboard"
        case .pressKey: return "command"
        }
    }
}

// MARK: - Risk Level
public enum ActionRiskLevel: String, Codable, CaseIterable, Sendable {
    case low = "Low Risk"
    case medium = "Medium Risk"
    case high = "High Risk"
    
    public var description: String {
        switch self {
        case .low:
            return "Read-only navigation, cursor movements, and visual element inspection."
        case .medium:
            return "Standard UI clicks, non-sensitive typing, and scrolling."
        case .high:
            return "Destructive actions, submitting forms, purchases, deletions, or security settings."
        }
    }
    
    public var displayColor: NSColor {
        switch self {
        case .low: return .systemGreen
        case .medium: return .systemOrange
        case .high: return .systemRed
        }
    }
}

// MARK: - Action Execution Status
public enum ActionStatus: Equatable, Sendable {
    case pending
    case validating
    case awaitingConfirmation
    case executing
    case verifying
    case completed
    case cancelled(reason: String)
    case failed(reason: String)
    
    public var isFinal: Bool {
        switch self {
        case .completed, .cancelled, .failed:
            return true
        default:
            return false
        }
    }
    
    public var isExecuting: Bool {
        switch self {
        case .validating, .awaitingConfirmation, .executing, .verifying:
            return true
        default:
            return false
        }
    }
}

// MARK: - Accessible UI Element
public struct AccessibleUIElement: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let role: String
    public let title: String?
    public let elementDescription: String?
    public let label: String?
    public let value: String?
    public let frame: CGRect
    public let isEnabled: Bool
    public let isFocused: Bool
    public let supportedActions: [String]
    public let windowTitle: String?
    public let appName: String?
    
    public init(
        id: UUID = UUID(),
        role: String,
        title: String? = nil,
        elementDescription: String? = nil,
        label: String? = nil,
        value: String? = nil,
        frame: CGRect = .zero,
        isEnabled: Bool = true,
        isFocused: Bool = false,
        supportedActions: [String] = [],
        windowTitle: String? = nil,
        appName: String? = nil
    ) {
        self.id = id
        self.role = role
        self.title = title
        self.elementDescription = elementDescription
        self.label = label
        self.value = value
        self.frame = frame
        self.isEnabled = isEnabled
        self.isFocused = isFocused
        self.supportedActions = supportedActions
        self.windowTitle = windowTitle
        self.appName = appName
    }
    
    public var displayName: String {
        if let t = title, !t.isEmpty { return t }
        if let l = label, !l.isEmpty { return l }
        if let d = elementDescription, !d.isEmpty { return d }
        return role
    }
    
    public var centerPoint: CGPoint {
        CGPoint(x: frame.midX, y: frame.midY)
    }
}

// MARK: - Confidence Level
public enum ElementMatchConfidence: String, Codable, Comparable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    public static func < (lhs: ElementMatchConfidence, rhs: ElementMatchConfidence) -> Bool {
        let order: [ElementMatchConfidence] = [.low, .medium, .high]
        guard let lIndex = order.firstIndex(of: lhs), let rIndex = order.firstIndex(of: rhs) else { return false }
        return lIndex < rIndex
    }
}

// MARK: - Element Match Result
public struct ElementMatch: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let element: AccessibleUIElement
    public let score: Double // 0.0 ... 1.0
    public let confidence: ElementMatchConfidence
    public let reason: String
    
    public init(
        id: UUID = UUID(),
        element: AccessibleUIElement,
        score: Double,
        confidence: ElementMatchConfidence,
        reason: String
    ) {
        self.id = id
        self.element = element
        self.score = score
        self.confidence = confidence
        self.reason = reason
    }
}

// MARK: - Automation Action Model
public struct AutomationAction: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let actionType: AutomationActionType
    public let targetApp: String?
    public let targetElement: AccessibleUIElement?
    public let targetCoordinates: CGPoint?
    public let textToType: String?
    public let keyToPress: String?
    public let keyModifiers: [String]
    public let scrollDelta: CGPoint?
    public let riskLevel: ActionRiskLevel
    public let reason: String
    public var status: ActionStatus
    public var verificationNote: String?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        actionType: AutomationActionType,
        targetApp: String? = nil,
        targetElement: AccessibleUIElement? = nil,
        targetCoordinates: CGPoint? = nil,
        textToType: String? = nil,
        keyToPress: String? = nil,
        keyModifiers: [String] = [],
        scrollDelta: CGPoint? = nil,
        riskLevel: ActionRiskLevel = .low,
        reason: String,
        status: ActionStatus = .pending,
        verificationNote: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.actionType = actionType
        self.targetApp = targetApp
        self.targetElement = targetElement
        self.targetCoordinates = targetCoordinates
        self.textToType = textToType
        self.keyToPress = keyToPress
        self.keyModifiers = keyModifiers
        self.scrollDelta = scrollDelta
        self.riskLevel = riskLevel
        self.reason = reason
        self.status = status
        self.verificationNote = verificationNote
    }
}

// MARK: - Automation Preferences
public struct AutomationPreferences: Codable, Equatable, Sendable {
    public var isMouseControlEnabled: Bool
    public var isKeyboardControlEnabled: Bool
    public var isCursorOverlayEnabled: Bool
    public var requireConfirmationForHighRisk: Bool
    public var safeActionMode: Bool
    public var showActionProgress: Bool
    public var cursorSpeed: Double // 0.1 to 1.0
    public var actionDelaySeconds: Double
    
    public static let `default` = AutomationPreferences(
        isMouseControlEnabled: true,
        isKeyboardControlEnabled: true,
        isCursorOverlayEnabled: true,
        requireConfirmationForHighRisk: true,
        safeActionMode: true,
        showActionProgress: true,
        cursorSpeed: 0.7,
        actionDelaySeconds: 0.15
    )
}

// MARK: - Action History Record
public struct ActionRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let actionType: AutomationActionType
    public let targetAppName: String?
    public let summary: String
    public let riskLevel: ActionRiskLevel
    public let statusString: String
    public let wasSuccessful: Bool
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        actionType: AutomationActionType,
        targetAppName: String?,
        summary: String,
        riskLevel: ActionRiskLevel,
        statusString: String,
        wasSuccessful: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.actionType = actionType
        self.targetAppName = targetAppName
        self.summary = summary
        self.riskLevel = riskLevel
        self.statusString = statusString
        self.wasSuccessful = wasSuccessful
    }
}

// MARK: - Cursor Overlay State
public enum CursorOverlayVisualState: Equatable, Sendable {
    case idle
    case targeting(CGPoint, label: String?)
    case moving(from: CGPoint, to: CGPoint)
    case clicking(CGPoint)
    case executing(label: String)
    case error(reason: String)
}

