//
//  AIProviderManager.swift
//  AUTO
//
//  Central manager and task router for AI providers.
//  Coordinates primary Gemini and optional OmniRoute engines, task-based routing,
//  dynamic model discovery, graceful fallback, and streaming.
//

import Foundation

@MainActor
public protocol AIProviderService: AnyObject {
    var activeProviderType: AIProviderType { get }
    func getProvider(for type: AIProviderType) -> AIProvider
    func testConnection(for type: AIProviderType) async throws -> Bool
    func discoverModels(for type: AIProviderType) async throws -> [AIModelInfo]
    func resolveProvider(for task: AITaskType?) -> AIProvider
    func generateResponse(messages: [AIMessage], context: AIRequestContext) async throws -> AICompletionResponse
    func streamResponse(messages: [AIMessage], context: AIRequestContext) -> AsyncThrowingStream<String, Error>
    func processScreenUnderstanding(request: ScreenUnderstandingRequest) async throws -> AICompletionResponse
}

@MainActor
public final class AIProviderManager: ObservableObject, AIProviderService {
    public static let shared = AIProviderManager()
    
    public let geminiProvider: GeminiProvider
    public let omniRouteProvider: OmniRouteProvider
    public let modelDiscoveryManager: ModelDiscoveryManager
    public let promptManager: PromptManager
    
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var activeProviderStatus: String = "Ready"
    @Published public private(set) var lastError: AUTOError?
    
    public init(
        geminiProvider: GeminiProvider = GeminiProvider(),
        omniRouteProvider: OmniRouteProvider = OmniRouteProvider(),
        modelDiscoveryManager: ModelDiscoveryManager = .shared,
        promptManager: PromptManager = .shared
    ) {
        self.geminiProvider = geminiProvider
        self.omniRouteProvider = omniRouteProvider
        self.modelDiscoveryManager = modelDiscoveryManager
        self.promptManager = promptManager
    }
    
    public var activeProviderType: AIProviderType {
        return ApplicationState.shared.activeAIProvider
    }
    
    public func getProvider(for type: AIProviderType) -> AIProvider {
        switch type {
        case .gemini:
            return geminiProvider
        case .omniRoute:
            return omniRouteProvider
        }
    }
    
    public var currentProvider: AIProvider {
        return getProvider(for: activeProviderType)
    }
    
    // MARK: - Task-Based Routing
    public func resolveProvider(for task: AITaskType?) -> AIProvider {
        guard let task = task else {
            return currentProvider
        }
        
        let rules = ApplicationState.shared.aiRoutingRules
        if let matched = rules.first(where: { $0.task == task }) {
            // Check if OmniRoute is requested but disabled or not configured
            if matched.provider == .omniRoute {
                let omniConfig = ApplicationState.shared.omniRouteConfig
                if !omniConfig.isEnabled {
                    AppLogger.shared.notice("Routing rule requested OmniRoute for \(task.rawValue), but OmniRoute is disabled. Falling back to Gemini.", category: .ai)
                    return geminiProvider
                }
            }
            return getProvider(for: matched.provider)
        }
        
        return currentProvider
    }
    
    // MARK: - Verification & Discovery
    public func testConnection(for type: AIProviderType) async throws -> Bool {
        let provider = getProvider(for: type)
        return try await provider.testConnection()
    }
    
    public func discoverModels(for type: AIProviderType) async throws -> [AIModelInfo] {
        let provider = getProvider(for: type)
        return try await modelDiscoveryManager.discoverModels(for: provider)
    }
    
    // MARK: - Response Generation with Intelligent Fallback
    public func generateResponse(messages: [AIMessage], context: AIRequestContext) async throws -> AICompletionResponse {
        isProcessing = true
        activeProviderStatus = "Generating..."
        defer { isProcessing = false }
        
        let targetProvider = resolveProvider(for: context.targetTask)
        AppLogger.shared.info("Dispatching AI request to \(targetProvider.providerType.rawValue)...", category: .ai)
        
        do {
            let response = try await targetProvider.generateResponse(messages: messages, context: context)
            activeProviderStatus = "Ready"
            lastError = nil
            return response
        } catch let error as AUTOError {
            // Fallback: If OmniRoute failed due to network / unavailable server, fall back to Gemini
            if targetProvider.providerType == .omniRoute {
                AppLogger.shared.warning("OmniRoute failed with error: \(error.localizedDescription). Attempting fallback to primary Gemini provider...", category: .ai)
                ApplicationState.shared.statusMessage = "OmniRoute unavailable. Using Gemini..."
                
                do {
                    let fallbackResponse = try await geminiProvider.generateResponse(messages: messages, context: context)
                    activeProviderStatus = "Ready (via Gemini fallback)"
                    return fallbackResponse
                } catch let fallbackErr as AUTOError {
                    self.lastError = fallbackErr
                    activeProviderStatus = "Error"
                    throw fallbackErr
                } catch {
                    let wrapped = AUTOError.aiProviderError(provider: "Gemini", message: error.localizedDescription, statusCode: nil)
                    self.lastError = wrapped
                    activeProviderStatus = "Error"
                    throw wrapped
                }
            }
            self.lastError = error
            activeProviderStatus = "Error"
            throw error
        } catch {
            let wrapped = AUTOError.aiProviderError(provider: targetProvider.providerType.rawValue, message: error.localizedDescription, statusCode: nil)
            self.lastError = wrapped
            activeProviderStatus = "Error"
            throw wrapped
        }
    }
    
    // MARK: - Streaming
    public func streamResponse(messages: [AIMessage], context: AIRequestContext) -> AsyncThrowingStream<String, Error> {
        let targetProvider = resolveProvider(for: context.targetTask)
        return targetProvider.streamResponse(messages: messages, context: context)
    }
    
    // MARK: - Multimodal Screen Understanding
    public func processScreenUnderstanding(request: ScreenUnderstandingRequest) async throws -> AICompletionResponse {
        var base64Screenshots: [String] = []
        for screenshot in request.screenshotData {
            do {
                let processed = try ImageProcessor.shared.processScreenshot(data: screenshot)
                base64Screenshots.append(processed)
            } catch {
                AppLogger.shared.error("Failed to process screenshot: \(error)", category: .screen)
            }
        }
        
        var messages = request.conversationHistory
        let userMessage = AIMessage(
            role: .user,
            content: request.userPrompt,
            attachedImageBase64: base64Screenshots
        )
        messages.append(userMessage)
        
        let systemPrompt = promptManager.systemPrompt(
            for: .screenUnderstanding,
            contextNote: request.applicationContext
        )
        
        let context = AIRequestContext(
            systemInstruction: systemPrompt,
            stream: false,
            targetTask: .screenUnderstanding
        )
        
        return try await generateResponse(messages: messages, context: context)
    }
}
