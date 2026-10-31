//
//  ConversationManager.swift
//  AUTO
//
//  Orchestrates dialogue turns, multi-turn AI history, streaming token updates,
//  cancellation, session management, and spatial cursor reactions.
//

import AppKit
import Foundation

@MainActor
public final class ConversationManager: ObservableObject {
    public static let shared = ConversationManager()
    
    @Published public private(set) var turns: [ConversationTurn] = []
    @Published public private(set) var isStreaming: Bool = false
    
    private let appState: ApplicationState
    private let aiProviderManager: AIProviderManager
    private let memory: ConversationMemory
    private let promptManager: PromptManager
    private var currentTask: Task<Void, Never>?
    
    public init(
        appState: ApplicationState,
        aiProviderManager: AIProviderManager,
        memory: ConversationMemory,
        promptManager: PromptManager
    ) {
        self.appState = appState
        self.aiProviderManager = aiProviderManager
        self.memory = memory
        self.promptManager = promptManager
        self.turns = memory.getRecentTurns()
    }
    
    public convenience init() {
        self.init(
            appState: .shared,
            aiProviderManager: .shared,
            memory: .shared,
            promptManager: .shared
        )
    }
    
    public func sendUserInput(_ text: String, screenshotBase64: [String] = [], stream: Bool = true) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Cancel any pending query
        cancelCurrentRequest()
        
        currentTask = Task {
            await executeTurn(trimmed, screenshotBase64: screenshotBase64, stream: stream)
        }
    }
    
    public func cancelCurrentRequest() {
        if let task = currentTask {
            task.cancel()
            currentTask = nil
            isStreaming = false
            appState.voiceState = .idle
            appState.statusMessage = "Cancelled"
            AppLogger.shared.info("ConversationManager: Active AI request was cancelled.", category: .agent)
        }
    }
    
    private func executeTurn(_ text: String, screenshotBase64: [String], stream: Bool) async {
        appState.currentTranscript = text
        appState.voiceState = .processing
        appState.statusMessage = "Thinking..."
        appState.currentResponseText = ""
        appState.activeSpatialPoint = nil
        
        // Assemble conversation history up to user-configured limit
        var history = memory.getAIMessagesHistory(limit: appState.maxHistoryTurns)
        
        let userMessage = AIMessage(
            role: .user,
            content: text,
            attachedImageBase64: screenshotBase64
        )
        history.append(userMessage)
        
        let taskType: AITaskType = screenshotBase64.isEmpty ? .mainConversation : .screenUnderstanding
        
        var contextNotes: [String] = []
        if let accessNote = appState.activeScreenContext?.accessibilityContext?.promptSummary, !accessNote.isEmpty {
            contextNotes.append(accessNote)
        }
        
        // Retrieve relevant memory context for task grounding
        if let memoryNote = MemoryRetrievalManager.shared.retrieveRelevantContext(for: text) {
            contextNotes.append(memoryNote)
        }
        
        // Summarize older turns if history exceeds limits
        let allTurns = memory.getRecentTurns()
        if allTurns.count > appState.maxHistoryTurns {
            let olderTurns = Array(allTurns.prefix(allTurns.count - appState.maxHistoryTurns))
            let summary = ConversationSummarizer.shared.summarizeTurns(olderTurns)
            if !summary.isEmpty {
                contextNotes.append(summary)
            }
        }
        
        let combinedContext = contextNotes.joined(separator: "\n\n")
        let systemPrompt = promptManager.systemPrompt(for: taskType, contextNote: combinedContext)
        
        let context = AIRequestContext(
            systemInstruction: systemPrompt,
            stream: stream,
            targetTask: taskType
        )
        
        if stream {
            await handleStreamingTurn(history: history, promptText: text, context: context)
        } else {
            await handleNonStreamingTurn(history: history, promptText: text, context: context)
        }
    }
    
    private func handleStreamingTurn(history: [AIMessage], promptText: String, context: AIRequestContext) async {
        isStreaming = true
        var accumulatedText = ""
        
        do {
            let stream = aiProviderManager.streamResponse(messages: history, context: context)
            for try await token in stream {
                if Task.isCancelled { break }
                accumulatedText += token
                appState.currentResponseText = accumulatedText
            }
            
            finalizeTurn(userText: promptText, responseText: accumulatedText)
        } catch is CancellationError {
            appState.voiceState = .idle
            appState.statusMessage = "Cancelled"
        } catch {
            handleAIError(error, userText: promptText)
        }
        
        isStreaming = false
    }
    
    private func handleNonStreamingTurn(history: [AIMessage], promptText: String, context: AIRequestContext) async {
        do {
            let response = try await aiProviderManager.generateResponse(messages: history, context: context)
            finalizeTurn(userText: promptText, responseText: response.text, explicitPoints: response.spatialPoints)
        } catch is CancellationError {
            appState.voiceState = .idle
            appState.statusMessage = "Cancelled"
        } catch {
            handleAIError(error, userText: promptText)
        }
    }
    
    private func handleAIError(_ error: Error, userText: String) {
        appState.voiceState = .idle
        AppLogger.shared.error("AI Error occurred during turn: \(error)", category: .agent)
        
        let friendlyMessage: String
        let statusBadge: String
        
        if let autoError = error as? AUTOError {
            switch autoError {
            case .invalidConfiguration(let detail) where detail.contains("Gemini API key"):
                statusBadge = "API Key Required"
                friendlyMessage = "Google Gemini API key is missing. Please open Settings (⌘,) -> Gemini to paste your free API key from Google AI Studio."
            case .authenticationFailed:
                statusBadge = "Authentication Failed"
                friendlyMessage = "Gemini API key authentication failed. Please check your key in Settings -> Gemini."
            case .rateLimitExceeded(_, let retryAfter):
                statusBadge = "Rate Limit Exceeded"
                let waitSec = retryAfter != nil ? " Please wait \(Int(retryAfter!)) seconds." : ""
                friendlyMessage = "Gemini rate limit exceeded.\(waitSec)"
            case .networkError, .serverUnavailable, .requestTimeout:
                statusBadge = "Network Offline"
                friendlyMessage = "Cannot connect to Google Gemini. Please check your network connection or use offline voice commands."
            default:
                statusBadge = "AI Error"
                friendlyMessage = "AI Error: \(autoError.localizedDescription)"
            }
        } else {
            let desc = error.localizedDescription
            if desc.contains("Gemini API key") {
                statusBadge = "API Key Required"
                friendlyMessage = "Google Gemini API key is missing. Please open Settings (⌘,) -> Gemini to paste your free API key from Google AI Studio."
            } else {
                statusBadge = "AI Error"
                friendlyMessage = "AI Error: \(desc)"
            }
        }
        
        appState.statusMessage = statusBadge
        appState.currentResponseText = friendlyMessage
        
        let turn = ConversationTurn(
            userTranscript: userText,
            assistantResponse: friendlyMessage,
            targetPoint: nil
        )
        memory.addTurn(turn, maxLimit: appState.maxHistoryTurns)
        self.turns = memory.getRecentTurns()
        
        if appState.voicePreferences.autoSpeakResponse {
            SpeechOutputManager.shared.speak(text: friendlyMessage)
        }
    }
    
    private func finalizeTurn(userText: String, responseText: String, explicitPoints: [SpatialPoint] = []) {
        let points = explicitPoints.isEmpty ? SpatialPoint.parsePoints(from: responseText) : explicitPoints
        let firstPoint = points.first
        
        let turn = ConversationTurn(
            userTranscript: userText,
            assistantResponse: responseText,
            targetPoint: firstPoint
        )
        
        memory.addTurn(turn, maxLimit: appState.maxHistoryTurns)
        self.turns = memory.getRecentTurns()
        
        appState.currentResponseText = responseText
        appState.activeSpatialPoint = firstPoint
        appState.voiceState = .idle
        appState.statusMessage = "Ready"
        
        if let point = firstPoint {
            CursorManager.shared.pointAt(target: point)
        }
        
        // Handle proposed automation action
        if let proposedAction = ActionProposalParser.parseAction(from: responseText) {
            handleProposedAction(proposedAction, point: firstPoint)
        }
        
        // Handle natural language memory command
        let lower = userText.lowercased()
        if lower.contains("remember that") || lower.contains("remember my preference") {
            MemoryManager.shared.store(
                category: .userPreferences,
                key: "user_preference",
                content: userText
            )
        }
        
        // Trigger autonomous multi-step task if requested
        if isAutonomousTaskInstruction(userText) {
            AgentOrchestrator.shared.startTask(instruction: userText)
        }
        
        if appState.voicePreferences.autoSpeakResponse && !responseText.isEmpty {
            SpeechOutputManager.shared.speak(text: responseText)
        }
    }
    
    private func handleProposedAction(_ action: AutomationAction, point: SpatialPoint?) {
        guard appState.automationPreferences.isMouseControlEnabled || appState.automationPreferences.isKeyboardControlEnabled else {
            return
        }
        
        Task { @MainActor in
            var resolvedAction = action
            
            // Map spatial point to coordinates if needed
            if resolvedAction.targetCoordinates == nil, let pt = point {
                let displays = appState.connectedDisplays
                let display = displays.first ?? DisplayInfo(
                    id: 0,
                    name: "Main",
                    frame: NSScreen.screens.first?.frame ?? .zero,
                    isPrimary: true,
                    hasCursor: true,
                    scaleFactor: 2.0
                )
                let cgPoint = CoordinateMapper.normalizedToGlobalCoreGraphics(
                    normalizedPoint: CGPoint(x: pt.x, y: pt.y),
                    display: display
                )
                resolvedAction = AutomationAction(
                    id: action.id,
                    timestamp: action.timestamp,
                    actionType: action.actionType,
                    targetApp: action.targetApp,
                    targetElement: action.targetElement,
                    targetCoordinates: cgPoint,
                    textToType: action.textToType,
                    keyToPress: action.keyToPress,
                    keyModifiers: action.keyModifiers,
                    scrollDelta: action.scrollDelta,
                    riskLevel: action.riskLevel,
                    reason: action.reason
                )
            }
            
            _ = await ActionExecutionManager.shared.executeAction(resolvedAction)
        }
    }
    
    public func clearConversation() {
        cancelCurrentRequest()
        memory.clear()
        turns = []
        appState.currentTranscript = ""
        appState.currentResponseText = ""
        appState.activeSpatialPoint = nil
        appState.statusMessage = "Conversation cleared"
    }
    
    public func resetSession() {
        clearConversation()
        appState.resetSession()
    }
    
    private func isAutonomousTaskInstruction(_ text: String) -> Bool {
        let lower = text.lowercased()
        return (lower.contains("organize") && (lower.contains("desktop") || lower.contains("file"))) ||
               (lower.contains("search") && lower.contains("summarize")) ||
               lower.hasPrefix("plan task:") ||
               lower.hasPrefix("start task:")
    }
}
