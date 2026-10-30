//
//  AIProviderManager.swift
//  AUTO
//
//  Hybrid AI Manager for Natural Language Understanding & Reasoning.
//  Coordinates Google Gemini as the sole AI reasoning provider,
//  integrating with local Swift execution and providing offline state handling.
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
    public let modelDiscoveryManager: ModelDiscoveryManager
    public let promptManager: PromptManager
    
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var activeProviderStatus: String = "Ready"
    @Published public private(set) var lastError: AUTOError?
    
    public init(
        geminiProvider: GeminiProvider = GeminiProvider(),
        modelDiscoveryManager: ModelDiscoveryManager = .shared,
        promptManager: PromptManager = .shared
    ) {
        self.geminiProvider = geminiProvider
        self.modelDiscoveryManager = modelDiscoveryManager
        self.promptManager = promptManager
    }
    
    public var activeProviderType: AIProviderType {
        return .gemini
    }
    
    public func getProvider(for type: AIProviderType) -> AIProvider {
        return geminiProvider
    }
    
    public var currentProvider: AIProvider {
        return geminiProvider
    }
    
    // MARK: - Task-Based Routing (Gemini is sole Language Reasoning Provider)
    public func resolveProvider(for task: AITaskType?) -> AIProvider {
        return geminiProvider
    }
    
    // MARK: - Verification & Discovery
    public func testConnection(for type: AIProviderType = .gemini) async throws -> Bool {
        return try await geminiProvider.testConnection()
    }
    
    public func discoverModels(for type: AIProviderType = .gemini) async throws -> [AIModelInfo] {
        return try await modelDiscoveryManager.discoverModels(for: geminiProvider)
    }
    
    // MARK: - Response Generation with Offline Handling
    public func generateResponse(messages: [AIMessage], context: AIRequestContext) async throws -> AICompletionResponse {
        isProcessing = true
        activeProviderStatus = "Reasoning with Gemini..."
        defer { isProcessing = false }
        
        do {
            let response = try await geminiProvider.generateResponse(messages: messages, context: context)
            activeProviderStatus = "Ready"
            lastError = nil
            ApplicationState.shared.isOfflineMode = false
            return response
        } catch let error as AUTOError {
            self.lastError = error
            activeProviderStatus = "Offline / Unavailable"
            ApplicationState.shared.isOfflineMode = true
            throw error
        } catch {
            let wrapped = AUTOError.aiProviderError(provider: "Google Gemini", message: error.localizedDescription, statusCode: nil)
            self.lastError = wrapped
            activeProviderStatus = "Error"
            ApplicationState.shared.isOfflineMode = true
            throw wrapped
        }
    }
    
    // MARK: - Streaming
    public func streamResponse(messages: [AIMessage], context: AIRequestContext) -> AsyncThrowingStream<String, Error> {
        return geminiProvider.streamResponse(messages: messages, context: context)
    }
    
    // MARK: - Privacy-Preserving Screen Understanding
    public func processScreenUnderstanding(request: ScreenUnderstandingRequest) async throws -> AICompletionResponse {
        var base64Screenshots: [String] = []
        
        // Privacy Gate: Screenshots are only transmitted if user explicitly authorized visual reasoning
        let allowVisualTransmission = ApplicationState.shared.allowScreenshotTransmission
        
        if allowVisualTransmission {
            for screenshot in request.screenshotData {
                do {
                    let processed = try ImageProcessor.shared.processScreenshot(data: screenshot)
                    base64Screenshots.append(processed)
                } catch {
                    AppLogger.shared.error("Failed to process screenshot: \(error)", category: .screen)
                }
            }
        } else {
            AppLogger.shared.info("Zero-Screenshot Privacy: Screenshot images omitted from Gemini payload. Sending local text context only.", category: .screen)
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
