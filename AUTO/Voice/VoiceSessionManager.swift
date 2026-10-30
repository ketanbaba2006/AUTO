//
//  VoiceSessionManager.swift
//  AUTO
//
//  Central state machine and coordinator for live voice sessions.
//  Orchestrates Push-to-Talk, live microphone capture, real-time speech recognition,
//  AI query dispatch, natural speech synthesis, and immediate user interruption.
//

import Combine
import Foundation

@MainActor
public final class VoiceSessionManager: ObservableObject {
    public static let shared = VoiceSessionManager()
    
    @Published public private(set) var voiceState: VoiceState = .idle
    @Published public private(set) var liveTranscript: String = ""
    @Published public private(set) var audioLevel: Float = 0.0
    
    private let appState: ApplicationState
    private let pushToTalkManager: PushToTalkManager
    private let audioCaptureManager: AudioCaptureManager
    private let speechRecognitionManager: SpeechRecognitionManager
    private let speechOutputManager: SpeechOutputManager
    private let conversationManager: ConversationManager
    
    private var cancellables = Set<AnyCancellable>()
    private var activeAITask: Task<Void, Never>?
    
    public init(
        appState: ApplicationState,
        pushToTalkManager: PushToTalkManager,
        audioCaptureManager: AudioCaptureManager,
        speechRecognitionManager: SpeechRecognitionManager,
        speechOutputManager: SpeechOutputManager,
        conversationManager: ConversationManager
    ) {
        self.appState = appState
        self.pushToTalkManager = pushToTalkManager
        self.audioCaptureManager = audioCaptureManager
        self.speechRecognitionManager = speechRecognitionManager
        self.speechOutputManager = speechOutputManager
        self.conversationManager = conversationManager
        
        bindEvents()
    }
    
    public convenience init() {
        self.init(
            appState: .shared,
            pushToTalkManager: .shared,
            audioCaptureManager: .shared,
            speechRecognitionManager: .shared,
            speechOutputManager: .shared,
            conversationManager: .shared
        )
    }
    
    public func start() {
        pushToTalkManager.start()
        AppLogger.shared.info("VoiceSessionManager started.", category: .voice)
    }
    
    public func stop() {
        pushToTalkManager.stop()
        stopActiveSession()
    }
    
    // MARK: - Event Bindings
    private func bindEvents() {
        // Listen to push-to-talk press & release
        pushToTalkManager.transitionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] transition in
                self?.handlePushToTalk(transition: transition)
            }
            .store(in: &cancellables)
            
        // Forward live audio power to AppState
        audioCaptureManager.audioPowerPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] power in
                guard let self = self else { return }
                self.audioLevel = power
                self.appState.currentAudioLevel = power
            }
            .store(in: &cancellables)
        
        // Track speech synthesizer completion
        speechOutputManager.speakingStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isSpeaking in
                guard let self = self else { return }
                if !isSpeaking && self.voiceState == .speaking {
                    self.transition(to: .idle, status: "Ready")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Push-to-Talk Handling & Interruption
    private func handlePushToTalk(transition: PushToTalkState) {
        switch transition {
        case .pressed:
            // Interruption check: If assistant is currently speaking or thinking, immediately halt!
            if voiceState.canInterrupt {
                handleInterruption()
            }
            startListeningSession()
            
        case .released:
            if voiceState == .listening {
                finalizeListeningSession()
            }
        }
    }
    
    private func handleInterruption() {
        AppLogger.shared.info("VoiceSessionManager: User interrupted assistant speech/thinking.", category: .voice)
        transition(to: .interrupted, status: "Interrupted")
        speechOutputManager.stopSpeaking()
        activeAITask?.cancel()
        activeAITask = nil
        conversationManager.cancelCurrentRequest()
    }
    
    // MARK: - Listening Session
    private func startListeningSession() {
        guard appState.hasMicrophonePermission else {
            transition(to: .failed, status: "Microphone permission required.")
            Task {
                _ = await PermissionManager.shared.requestMicrophonePermission()
            }
            return
        }
        
        transition(to: .listening, status: "Listening...")
        liveTranscript = ""
        appState.currentTranscript = ""
        
        // Connect audio capture buffer streaming directly to speech recognition
        audioCaptureManager.setBufferHandler { [weak self] buffer in
            self?.speechRecognitionManager.appendBuffer(buffer)
        }
        
        do {
            let locale = Locale(identifier: appState.voicePreferences.speechRecognitionLocale)
            try speechRecognitionManager.startRecognition(locale: locale) { [weak self] partialText in
                Task { @MainActor [weak self] in
                    guard let self = self, self.voiceState == .listening else { return }
                    self.liveTranscript = partialText
                    self.appState.currentTranscript = partialText
                }
            }
            try audioCaptureManager.startCapture()
        } catch {
            AppLogger.shared.error("Failed to start voice listening session: \(error)", category: .voice)
            transition(to: .failed, status: "Mic error: \(error.localizedDescription)")
            _ = audioCaptureManager.stopCapture()
            speechRecognitionManager.cancelRecognition()
        }
    }
    
    // MARK: - Finalize Session & Transcribe
    private func finalizeListeningSession() {
        transition(to: .transcribing, status: "Transcribing...")
        _ = audioCaptureManager.stopCapture()
        
        Task {
            do {
                let finalTranscript = try await speechRecognitionManager.finishRecognition()
                let trimmed = finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !trimmed.isEmpty else {
                    AppLogger.shared.notice("Voice session ended with empty transcript.", category: .voice)
                    self.transition(to: .idle, status: "Ready (no speech detected)")
                    return
                }
                
                // Immediate Emergency Stop voice command check
                let lower = trimmed.lowercased()
                if lower == "stop" || lower == "stop now" || lower == "emergency stop" || lower == "halt" || lower == "stop the current task" || lower == "stop task" {
                    EmergencyStopManager.shared.triggerEmergencyStop(reason: "Voice 'Stop' command detected")
                    AgentOrchestrator.shared.cancelCurrentTask(reason: "Voice 'Stop' command detected")
                    self.transition(to: .idle, status: "Emergency Stop triggered")
                    return
                }
                
                // Voice explanation of active task progress
                if lower.contains("explain what you are doing") || lower.contains("what are you doing") {
                    if let plan = AgentOrchestrator.shared.activePlan, let step = plan.currentStep {
                        let explanation = "Currently on step \(step.stepNumber) of \(plan.totalSteps): \(step.title). \(step.explanation)"
                        self.transition(to: .speaking, status: "Explaining progress...")
                        self.speechOutputManager.speak(text: explanation) { [weak self] in
                            Task { @MainActor [weak self] in
                                self?.transition(to: .idle, status: "Ready")
                            }
                        }
                        return
                    }
                }
                
                self.liveTranscript = trimmed
                self.appState.currentTranscript = trimmed
                self.dispatchToAI(query: trimmed)
            } catch {
                AppLogger.shared.error("Speech transcription failed: \(error)", category: .voice)
                self.transition(to: .failed, status: "Transcription failed: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.transition(to: .idle, status: "Ready")
                }
            }
        }
    }
    
    // MARK: - AI Dispatch & Natural Speech Synthesis
    private func dispatchToAI(query: String) {
        transition(to: .thinking, status: "AUTO is thinking...")
        
        activeAITask = Task {
            var screenshots: [String] = []
            
            // If screen awareness is enabled and active
            if appState.screenPreferences.isScreenAwarenessEnabled &&
               (appState.screenPreferences.mode == .activeVoice || appState.isScreenSharingActive) &&
               appState.hasScreenRecordingPermission {
                do {
                    let visualContext = try await ScreenContextManager.shared.captureCurrentContext(mode: .activeVoice)
                    screenshots.append(visualContext.base64String)
                } catch {
                    AppLogger.shared.notice("Voice session screen capture skipped: \(error.localizedDescription)", category: .screen)
                }
            }
            
            // Forward user input to ConversationManager with visual screenshot context
            conversationManager.sendUserInput(query, screenshotBase64: screenshots, stream: true)
            
            // Wait for response text to appear in appState
            // Poll briefly for completed response or streaming tokens
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                if !conversationManager.isStreaming && !appState.currentResponseText.isEmpty {
                    break
                }
            }
            
            guard !Task.isCancelled else { return }
            
            let responseText = appState.currentResponseText
            if !responseText.isEmpty && appState.voicePreferences.autoSpeakResponse {
                self.transition(to: .speaking, status: "Speaking...")
                self.speechOutputManager.speak(text: responseText) { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self = self, self.voiceState == .speaking else { return }
                        self.transition(to: .idle, status: "Ready")
                    }
                }
            } else {
                self.transition(to: .idle, status: "Ready")
            }
        }
    }
    
    // MARK: - Manual Controls
    public func stopActiveSession() {
        handleInterruption()
        _ = audioCaptureManager.stopCapture()
        speechRecognitionManager.cancelRecognition()
        transition(to: .idle, status: "Ready")
    }
    
    private func transition(to state: VoiceState, status: String) {
        self.voiceState = state
        self.appState.voiceState = state
        self.appState.statusMessage = status
        AppLogger.shared.debug("VoiceSessionManager state: \(state.rawValue) - \"\(status)\"", category: .voice)
    }
}
