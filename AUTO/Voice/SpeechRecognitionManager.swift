//
//  SpeechRecognitionManager.swift
//  AUTO
//
//  Native speech-to-text recognition service using Apple's Speech framework (SFSpeechRecognizer).
//  Streams real-time audio buffers, emits partial live transcripts, and delivers
//  final validated utterances.
//

import AVFoundation
import Combine
import Foundation
import Speech

public protocol SpeechRecognitionService: AnyObject, Sendable {
    var isRecognizing: Bool { get }
    func startRecognition(
        locale: Locale,
        onPartialResult: @escaping @Sendable (String) -> Void
    ) throws
    func appendBuffer(_ buffer: AVAudioPCMBuffer)
    func finishRecognition() async throws -> String
    func cancelRecognition()
}

public final class SpeechRecognitionManager: SpeechRecognitionService, @unchecked Sendable {
    public static let shared = SpeechRecognitionManager()
    
    public private(set) var isRecognizing: Bool = false
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var currentTranscript: String = ""
    private var continuation: CheckedContinuation<String, Error>?
    private let lock = NSLock()
    
    public init() {}
    
    // MARK: - Speech Permission Verification
    public static func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    // MARK: - Recognition Lifecycle
    public func startRecognition(
        locale: Locale = Locale.current,
        onPartialResult: @escaping @Sendable (String) -> Void
    ) throws {
        lock.lock()
        defer { lock.unlock() }
        
        cancelRecognitionLocked()
        
        let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw AUTOError.speechRecognitionError(reason: "Native Speech Recognizer is not available for locale '\(locale.identifier)'.")
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        // Prefer on-device speech recognition for low latency, zero network dependence, and complete privacy
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        self.speechRecognizer = recognizer
        self.recognitionRequest = request
        self.currentTranscript = ""
        self.isRecognizing = true
        
        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                self.lock.lock()
                self.currentTranscript = transcription
                let isFinal = result.isFinal
                let cont = self.continuation
                if isFinal {
                    self.continuation = nil
                }
                self.lock.unlock()
                
                onPartialResult(transcription)
                
                if isFinal, let cont = cont {
                    cont.resume(returning: transcription)
                }
            }
            
            if let error = error {
                self.lock.lock()
                let cont = self.continuation
                self.continuation = nil
                self.isRecognizing = false
                self.lock.unlock()
                
                // An error occurs naturally if recognition was cancelled early
                if (error as NSError).code == 216 { // Cancelled
                    cont?.resume(returning: "")
                } else {
                    cont?.resume(throwing: AUTOError.speechRecognitionError(reason: error.localizedDescription))
                }
            }
        }
        
        AppLogger.shared.info("Speech recognition session started (locale: \(locale.identifier)).", category: .voice)
    }
    
    public func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        recognitionRequest?.append(buffer)
    }
    
    public func finishRecognition() async throws -> String {
        return try await withCheckedThrowingContinuation { cont in
            lock.lock()
            guard isRecognizing, let request = recognitionRequest else {
                lock.unlock()
                cont.resume(returning: currentTranscript)
                return
            }
            
            self.continuation = cont
            request.endAudio()
            lock.unlock()
            
            // Timeout safety: if SFSpeechRecognizer does not flag final within 2.5 seconds, return current transcript
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.5) { [weak self] in
                guard let self = self else { return }
                self.lock.lock()
                if let pendingCont = self.continuation {
                    let transcript = self.currentTranscript
                    self.continuation = nil
                    self.isRecognizing = false
                    self.lock.unlock()
                    AppLogger.shared.debug("Speech recognition timed out waiting for final flag; using partial: \"\(transcript)\"", category: .voice)
                    pendingCont.resume(returning: transcript)
                } else {
                    self.lock.unlock()
                }
            }
        }
    }
    
    public func cancelRecognition() {
        lock.lock()
        defer { lock.unlock() }
        cancelRecognitionLocked()
    }
    
    private func cancelRecognitionLocked() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        isRecognizing = false
        currentTranscript = ""
        continuation?.resume(returning: "")
        continuation = nil
    }
}
