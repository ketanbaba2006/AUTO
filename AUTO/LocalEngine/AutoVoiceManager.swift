//
//  AutoVoiceManager.swift
//  AUTO
//
//  Native Local Voice Manager:
//  Captures audio via AVFoundation, transcribes via Apple Speech,
//  speaks responses via AVSpeechSynthesizer with instant interruption,
//  and parses fixed offline voice commands locally when Gemini is unavailable.
//

import Foundation
import AVFoundation
import Speech

public enum AutoVoiceState: String, Sendable {
    case idle
    case listening
    case processing
    case speaking
    case error
}

public final class AutoVoiceManager: NSObject, @unchecked Sendable, AVSpeechSynthesizerDelegate {
    public static let shared = AutoVoiceManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let lock = NSLock()
    private var currentState: AutoVoiceState = .idle
    
    override private init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public var state: AutoVoiceState {
        lock.lock()
        defer { lock.unlock() }
        return currentState
    }
    
    // MARK: - Speech Synthesis (Local)
    public func speak(text: String, rate: Float = 0.52, pitch: Float = 1.0) {
        lock.lock()
        currentState = .speaking
        lock.unlock()
        
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        synthesizer.speak(utterance)
    }
    
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    // MARK: - Fixed Offline Voice Commands Parser
    /// Evaluates if an utterance matches a fixed local command that runs 100% offline.
    public func parseOfflineCommand(_ transcript: String) -> String? {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        switch trimmed {
        case "stop", "halt", "pause", "cancel":
            return "emergency_stop"
        case "click", "left click":
            return "mouse_click"
        case "double click":
            return "mouse_double_click"
        case "right click":
            return "mouse_right_click"
        case "capture", "screenshot", "screen capture":
            return "capture_screen"
        case "read text", "ocr", "read screen":
            return "read_screen_ocr"
        case "status", "system status", "help":
            return "system_status"
        default:
            return nil
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        lock.lock()
        currentState = .idle
        lock.unlock()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        lock.lock()
        currentState = .idle
        lock.unlock()
    }
}

