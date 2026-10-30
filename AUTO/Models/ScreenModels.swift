//
//  ScreenModels.swift
//  AUTO
//
//  Core data models for ScreenCaptureKit screen capture, window capture,
//  multi-monitor displays, and visual intelligence.
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - Screen Awareness Mode
public enum ScreenAwarenessMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case onDemand = "On-Demand (When Asked)"
    case activeVoice = "Active Voice Session"
    case continuousSharing = "Manual Screen Sharing"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .onDemand:
            return "Captures screen content only when explicitly asked or commanded."
        case .activeVoice:
            return "Captures fresh screen context when you speak to AUTO with push-to-talk."
        case .continuousSharing:
            return "Shares continuous visual desktop context for proactive guidance."
        }
    }
}

// MARK: - Screen Capture State Model
public enum ScreenCaptureState: Equatable, Sendable {
    case unavailable
    case permissionRequired
    case idle
    case selectingSource
    case capturing
    case processing
    case analyzing
    case sharing
    case completed
    case cancelled
    case failed(reason: String)
    
    public var isBusy: Bool {
        switch self {
        case .capturing, .processing, .analyzing, .selectingSource:
            return true
        default:
            return false
        }
    }
    
    public var isSharingActive: Bool {
        return self == .sharing
    }
    
    public var statusDescription: String {
        switch self {
        case .unavailable:
            return "Screen capture unavailable"
        case .permissionRequired:
            return "Screen Recording permission required"
        case .idle:
            return "Screen awareness ready"
        case .selectingSource:
            return "Selecting display or window..."
        case .capturing:
            return "Capturing screen content..."
        case .processing:
            return "Optimizing visual payload..."
        case .analyzing:
            return "AUTO is analyzing screen..."
        case .sharing:
            return "Screen sharing active with AUTO"
        case .completed:
            return "Screen capture complete"
        case .cancelled:
            return "Capture cancelled"
        case .failed(let reason):
            return "Capture error: \(reason)"
        }
    }
    
    public var displayColor: NSColor {
        switch self {
        case .unavailable, .cancelled:
            return .gray
        case .permissionRequired, .failed:
            return .systemRed
        case .idle:
            return .systemGreen
        case .selectingSource, .capturing:
            return .systemCyan
        case .processing:
            return .systemBlue
        case .analyzing:
            return .systemPurple
        case .sharing:
            return .systemTeal
        case .completed:
            return .systemGreen
        }
    }
}

// MARK: - Capture Source Target
public enum CaptureSourceType: String, Codable, CaseIterable, Identifiable, Sendable {
    case display = "Entire Display"
    case window = "Application Window"
    
    public var id: String { rawValue }
}

// MARK: - Application Window Info
public struct WindowInfo: Identifiable, Equatable, Hashable, Sendable {
    public let id: CGWindowID
    public let title: String
    public let appName: String
    public let bundleIdentifier: String?
    public let frame: CGRect
    public let isOnScreen: Bool
    
    public init(
        id: CGWindowID,
        title: String,
        appName: String,
        bundleIdentifier: String? = nil,
        frame: CGRect = .zero,
        isOnScreen: Bool = true
    ) {
        self.id = id
        self.title = title
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.frame = frame
        self.isOnScreen = isOnScreen
    }
    
    public var displayName: String {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(appName) (Window #\(id))"
        }
        return "\(appName) — \(title)"
    }
}

// MARK: - Screen Capture Preferences
public struct ScreenCapturePreferences: Codable, Equatable, Sendable {
    public var isScreenAwarenessEnabled: Bool
    public var mode: ScreenAwarenessMode
    public var sourceType: CaptureSourceType
    public var selectedDisplayID: CGDirectDisplayID?
    public var selectedWindowID: CGWindowID?
    public var maxDimension: Int
    public var compressionQuality: Double
    public var includeAccessibilityContext: Bool
    
    public static let `default` = ScreenCapturePreferences(
        isScreenAwarenessEnabled: true,
        mode: .onDemand,
        sourceType: .display,
        selectedDisplayID: nil,
        selectedWindowID: nil,
        maxDimension: 1920,
        compressionQuality: 0.80,
        includeAccessibilityContext: true
    )
}

// MARK: - Accessibility Visual Context
public struct AccessibilityVisualContext: Equatable, Sendable {
    public var frontmostAppName: String?
    public var frontmostWindowTitle: String?
    public var focusedElementDescription: String?
    public var selectedText: String?
    public var mouseHoverElement: String?
    public var displayIndex: Int?
    
    public init(
        frontmostAppName: String? = nil,
        frontmostWindowTitle: String? = nil,
        focusedElementDescription: String? = nil,
        selectedText: String? = nil,
        mouseHoverElement: String? = nil,
        displayIndex: Int? = nil
    ) {
        self.frontmostAppName = frontmostAppName
        self.frontmostWindowTitle = frontmostWindowTitle
        self.focusedElementDescription = focusedElementDescription
        self.selectedText = selectedText
        self.mouseHoverElement = mouseHoverElement
        self.displayIndex = displayIndex
    }
    
    public var promptSummary: String {
        var lines: [String] = []
        if let app = frontmostAppName, !app.isEmpty {
            lines.append("Frontmost App: \(app)")
        }
        if let win = frontmostWindowTitle, !win.isEmpty {
            lines.append("Frontmost Window: \(win)")
        }
        if let focused = focusedElementDescription, !focused.isEmpty {
            lines.append("Focused Element: \(focused)")
        }
        if let selected = selectedText, !selected.isEmpty {
            lines.append("Selected Text: \"\(selected)\"")
        }
        if let hover = mouseHoverElement, !hover.isEmpty {
            lines.append("Under Cursor: \(hover)")
        }
        return lines.joined(separator: " | ")
    }
}

// MARK: - Visual Screen Context
public struct VisualScreenContext: Sendable {
    public let timestamp: Date
    public let displayInfo: DisplayInfo?
    public let windowInfo: WindowInfo?
    public let screenshotJPEG: Data
    public let base64String: String
    public let accessibilityContext: AccessibilityVisualContext?
    public let mode: ScreenAwarenessMode
    
    public init(
        timestamp: Date = Date(),
        displayInfo: DisplayInfo? = nil,
        windowInfo: WindowInfo? = nil,
        screenshotJPEG: Data,
        base64String: String,
        accessibilityContext: AccessibilityVisualContext? = nil,
        mode: ScreenAwarenessMode = .onDemand
    ) {
        self.timestamp = timestamp
        self.displayInfo = displayInfo
        self.windowInfo = windowInfo
        self.screenshotJPEG = screenshotJPEG
        self.base64String = base64String
        self.accessibilityContext = accessibilityContext
        self.mode = mode
    }
}

