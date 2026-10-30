//
//  SpeechOutputManager.swift
//  AUTO
//
//  Natural text-to-speech output service using AVFoundation's AVSpeechSynthesizer.
//  Coordinates utterance pacing, voice selection, spatial tag sanitization,
//  and immediate interruption handling.
//

import AVFoundation
import Combine
import Foundation

public protocol SpeechOutputService: AnyObject, Sendable {
    var isSpeaking: Bool { get }
    var speakingStatePublisher: AnyPublisher<Bool, Never> { get }
    func speak(text: String, onFinished: (@Sendable () -> Void)?)
    func stopSpeaking()
    func pauseSpeaking()
    func resumeSpeaking()
    func availableVoices() -> [VoiceVoiceInfo]
}

public final class SpeechOutputManager: NSObject, SpeechOutputService, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    public static let shared = SpeechOutputManager()
    
    private let synthesizer: AVSpeechSynthesizer
    private let speakingStateSubject = PassthroughSubject<Bool, Never>()
    public var speakingStatePublisher: AnyPublisher<Bool, Never> {
        return speakingStateSubject.eraseToAnyPublisher()
    }
    
    public var isSpeaking: Bool {
        lock.lock()
        defer { lock.unlock() }
        return synthesizer.isSpeaking
    }
    
    private var completionHandler: (@Sendable () -> Void)?
    private let lock = NSLock()
    
    public override init() {
        self.synthesizer = AVSpeechSynthesizer()
        super.init()
        self.synthesizer.delegate = self
    }
    
    // MARK: - Speech Synthesis
    public func speak(text: String, onFinished: (@Sendable () -> Void)? = nil) {
        // 1. Immediately halt any active utterance
        stopSpeaking()
        
        // 2. Strip spatial coordinate tags [POINT:x,y:label:screenN] so coordinates are not read aloud
        let cleanedText = sanitizeTextForSpeech(text)
        guard !cleanedText.isEmpty else {
            onFinished?()
            return
        }
        
        lock.lock()
        self.completionHandler = onFinished
        lock.unlock()
        
        let utterance = AVSpeechUtterance(string: cleanedText)
        
        // Voice configuration from ApplicationState
        let prefs = MainActor.assumeIsolated {
            ApplicationState.shared.voicePreferences
        }
        
        // Rate calibration: map user slider (0.5 to 1.5) relative to AVSpeechUtteranceDefaultSpeechRate (approx 0.5)
        let baseRate = AVSpeechUtteranceDefaultSpeechRate
        utterance.rate = min(max(baseRate * prefs.speechRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.pitchMultiplier = prefs.pitchMultiplier
        utterance.volume = prefs.volume
        
        // Resolve preferred natural voice
        if let voiceId = prefs.voiceIdentifier,
           let selectedVoice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = selectedVoice
        } else {
            // Default to high-quality system language voice
            utterance.voice = AVSpeechSynthesisVoice(language: prefs.speechRecognitionLocale) ?? AVSpeechSynthesisVoice(language: "en-US")
        }
        
        speakingStateSubject.send(true)
        synthesizer.speak(utterance)
        AppLogger.shared.info("SpeechOutputManager: Speaking \"\(cleanedText.prefix(40))...\"", category: .voice)
    }
    
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        speakingStateSubject.send(false)
        lock.lock()
        let handler = completionHandler
        self.completionHandler = nil
        lock.unlock()
        handler?()
    }
    
    public func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .immediate)
    }
    
    public func resumeSpeaking() {
        synthesizer.continueSpeaking()
    }
    
    public func availableVoices() -> [VoiceVoiceInfo] {
        return AVSpeechSynthesisVoice.speechVoices().map { voice in
            let qualityStr: String
            switch voice.quality {
            case .enhanced: qualityStr = "Enhanced"
            case .premium: qualityStr = "Premium"
            default: qualityStr = "Default"
            }
            return VoiceVoiceInfo(
                id: voice.identifier,
                name: voice.name,
                language: voice.language,
                quality: qualityStr
            )
        }
    }
    
    // MARK: - Sanitizer
    public func sanitizeTextForSpeech(_ rawText: String) -> String {
        var text = rawText
        // Remove [POINT:x,y:label:screenN] or [POINT:x,y:label]
        text = text.replacingOccurrences(
            of: #"\[POINT:\s*[0-9.]+\s*,\s*[0-9.]+\s*:[^\]]+\]"#,
            with: "",
            options: .regularExpression
        )
        // Remove markdown formatting characters (bold, headers, backticks)
        text = text.replacingOccurrences(of: #"[#*`_]"#, with: "", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speakingStateSubject.send(false)
        lock.lock()
        let handler = completionHandler
        self.completionHandler = nil
        lock.unlock()
        AppLogger.shared.debug("Speech synthesis finished.", category: .voice)
        handler?()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        speakingStateSubject.send(false)
        lock.lock()
        self.completionHandler = nil
        lock.unlock()
        AppLogger.shared.debug("Speech synthesis was cancelled.", category: .voice)
    }
}
