//
//  VoiceModels.swift
//  AUTO
//
//  Models for voice states, push-to-talk triggers, audio device representation,
//  and speech synthesis preferences.
//

import Foundation
import SwiftUI

public enum VoiceState: String, Codable, CaseIterable, Sendable {
    case idle = "Idle"
    case listening = "Listening"
    case transcribing = "Transcribing"
    case thinking = "Thinking"
    case speaking = "Speaking"
    case interrupted = "Interrupted"
    case failed = "Failed"
    
    public static let processing: VoiceState = .thinking
    
    public var indicatorColorName: String {
        switch self {
        case .idle: return "gray"
        case .listening: return "cyan"
        case .transcribing: return "blue"
        case .thinking: return "purple"
        case .speaking: return "green"
        case .interrupted: return "orange"
        case .failed: return "red"
        }
    }
    
    public var displayColor: Color {
        switch self {
        case .idle: return .gray
        case .listening: return .cyan
        case .transcribing: return .blue
        case .thinking: return .purple
        case .speaking: return .green
        case .interrupted: return .orange
        case .failed: return .red
        }
    }
    
    public var statusDescription: String {
        switch self {
        case .idle: return "Hold ⌃ Control to Talk"
        case .listening: return "Listening..."
        case .transcribing: return "Transcribing..."
        case .thinking: return "AUTO is thinking..."
        case .speaking: return "Speaking..."
        case .interrupted: return "Interrupted"
        case .failed: return "Voice session failed"
        }
    }
    
    public var isBusy: Bool {
        return self != .idle && self != .failed
    }
    
    public var canInterrupt: Bool {
        return self == .speaking || self == .thinking || self == .transcribing
    }
}

public enum PushToTalkTrigger: String, Codable, CaseIterable, Identifiable, Sendable {
    case controlKeyHold = "Hold Control Key"
    case optionKeyHold = "Hold Option Key"
    case controlOptionHold = "Hold Control + Option"
    case fnKeyHold = "Hold Fn Key"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .controlKeyHold: return "Press and hold ⌃ Control"
        case .optionKeyHold: return "Press and hold ⌥ Option"
        case .controlOptionHold: return "Press and hold ⌃ Control + ⌥ Option"
        case .fnKeyHold: return "Press and hold fn Function"
        }
    }
}

public struct AudioDevice: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let isDefault: Bool
    
    public init(id: String, name: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
    }
}

public struct VoiceVoiceInfo: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let language: String
    public let quality: String
    
    public init(id: String, name: String, language: String, quality: String = "Default") {
        self.id = id
        self.name = name
        self.language = language
        self.quality = quality
    }
}

public struct VoicePreferences: Codable, Equatable, Sendable {
    public var selectedMicId: String?
    public var pushToTalkTrigger: PushToTalkTrigger
    public var speechRate: Float
    public var pitchMultiplier: Float
    public var volume: Float
    public var voiceIdentifier: String?
    public var autoSpeakResponse: Bool
    public var speechRecognitionLocale: String
    
    public static let `default` = VoicePreferences(
        selectedMicId: nil,
        pushToTalkTrigger: .controlKeyHold,
        speechRate: 1.0,
        pitchMultiplier: 1.0,
        volume: 1.0,
        voiceIdentifier: nil,
        autoSpeakResponse: true,
        speechRecognitionLocale: "en-US"
    )
}
