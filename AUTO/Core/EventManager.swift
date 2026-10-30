//
//  EventManager.swift
//  AUTO
//
//  Decoupled Combine event bus for system-wide notifications, hotkey triggers,
//  voice events, and UI interactions.
//

import Foundation
import Combine

public enum AUTOEvent: Sendable {
    case hotkeyTriggered(isPressed: Bool)
    case voiceStateChanged(VoiceState)
    case speechAudioPower(level: Float)
    case transcriptionReceived(text: String, isFinal: Bool)
    case targetPointDetected(SpatialPoint)
    case aiResponseChunk(String)
    case aiResponseCompleted(String)
    case requestOpenSettings
    case requestOpenOnboarding
    case requestToggleCompanionPanel
    case requestToggleOverlay
}

public final class EventManager: @unchecked Sendable {
    public static let shared = EventManager()
    
    public let eventSubject = PassthroughSubject<AUTOEvent, Never>()
    
    public init() {}
    
    public func publish(_ event: AUTOEvent) {
        eventSubject.send(event)
    }
}
