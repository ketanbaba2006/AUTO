//
//  ApplicationModels.swift
//  AUTO
//
//  Core application-level models, preferences, and enum types.
//

import Foundation
import CoreGraphics

public enum AppAppearanceMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"
    
    public var id: String { rawValue }
}

public enum CompanionVisibilityMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case alwaysVisible = "Always Visible"
    case transientOnHotkey = "Show on Hotkey"
    case hidden = "Hidden"
    
    public var id: String { rawValue }
}

public struct GeneralPreferences: Codable, Equatable, Sendable {
    public var launchAtLogin: Bool
    public var startMinimized: Bool
    public var appearanceMode: AppAppearanceMode
    public var companionVisibility: CompanionVisibilityMode
    public var playChimes: Bool
    
    public static let `default` = GeneralPreferences(
        launchAtLogin: false,
        startMinimized: false,
        appearanceMode: .dark,
        companionVisibility: .alwaysVisible,
        playChimes: false
    )
}

public enum PermissionType: String, CaseIterable, Identifiable, Sendable {
    case microphone = "Microphone"
    case speechRecognition = "Speech Recognition"
    case screenRecording = "Screen Recording"
    case accessibility = "Accessibility"
    case inputMonitoring = "Input Monitoring"
    case notifications = "Notifications"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .microphone: return "mic.fill"
        case .speechRecognition: return "waveform.badge.mic"
        case .screenRecording: return "display"
        case .accessibility: return "hand.raised.fill"
        case .inputMonitoring: return "keyboard.fill"
        case .notifications: return "bell.badge.fill"
        }
    }
    
    public var requiredDescription: String {
        switch self {
        case .microphone:
            return "Used for push-to-talk voice conversations with AUTO."
        case .speechRecognition:
            return "Enables Apple Speech recognition to transcribe your spoken voice instructions."
        case .screenRecording:
            return "Allows AUTO to see your screen context and provide visual guidance."
        case .accessibility:
            return "Enables global push-to-talk shortcut detection and window awareness."
        case .inputMonitoring:
            return "Enables global keyboard event listening for push-to-talk."
        case .notifications:
            return "Allows AUTO to deliver background task alerts and approval requests."
        }
    }
}

public enum PermissionStatus: String, Codable, Sendable {
    case notDetermined = "Not Determined"
    case authorized = "Authorized"
    case denied = "Denied"
    case restricted = "Restricted"
    
    public var isGranted: Bool {
        return self == .authorized
    }
}

public struct DisplayInfo: Identifiable, Equatable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let frame: CGRect
    public let isPrimary: Bool
    public let hasCursor: Bool
    public let scaleFactor: CGFloat
    
    public init(
        id: CGDirectDisplayID,
        name: String,
        frame: CGRect,
        isPrimary: Bool,
        hasCursor: Bool,
        scaleFactor: CGFloat = 2.0
    ) {
        self.id = id
        self.name = name
        self.frame = frame
        self.isPrimary = isPrimary
        self.hasCursor = hasCursor
        self.scaleFactor = scaleFactor
    }
}
