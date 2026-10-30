//
//  AIModels.swift
//  AUTO
//
//  Models for AI providers, request/response structures, connection profiles,
//  token metrics, task routing, and spatial element targeting.
//

import Foundation

public enum AIProviderType: String, Codable, CaseIterable, Identifiable, Sendable {
    case gemini = "Google Gemini"
    case omniRoute = "OmniRoute Gateway"
    
    public var id: String { rawValue }
    
    public var defaultModelId: String {
        switch self {
        case .gemini:
            return "gemini-2.5-flash"
        case .omniRoute:
            return "default"
        }
    }
}

public struct AIModelInfo: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let provider: AIProviderType
    public let contextWindow: Int
    public let supportsVision: Bool
    public let supportsAudio: Bool
    public let supportsStreaming: Bool
    public let isDefault: Bool
    public let isLocal: Bool
    
    public init(
        id: String,
        displayName: String,
        provider: AIProviderType,
        contextWindow: Int = 128000,
        supportsVision: Bool = true,
        supportsAudio: Bool = false,
        supportsStreaming: Bool = true,
        isDefault: Bool = false,
        isLocal: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.provider = provider
        self.contextWindow = contextWindow
        self.supportsVision = supportsVision
        self.supportsAudio = supportsAudio
        self.supportsStreaming = supportsStreaming
        self.isDefault = isDefault
        self.isLocal = isLocal
    }
}

public struct TokenUsage: Codable, Equatable, Sendable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    
    public init(promptTokens: Int = 0, completionTokens: Int = 0, totalTokens: Int = 0) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens > 0 ? totalTokens : (promptTokens + completionTokens)
    }
}

public struct AIProviderConfiguration: Codable, Equatable, Sendable {
    public var providerType: AIProviderType
    public var isEnabled: Bool
    public var endpointURL: String
    public var selectedModelId: String
    public var temperature: Double
    public var maxOutputTokens: Int
    public var timeoutInterval: TimeInterval
    public var maxRetries: Int
    
    public init(
        providerType: AIProviderType,
        isEnabled: Bool,
        endpointURL: String,
        selectedModelId: String,
        temperature: Double = 0.7,
        maxOutputTokens: Int = 2048,
        timeoutInterval: TimeInterval = 30.0,
        maxRetries: Int = 2
    ) {
        self.providerType = providerType
        self.isEnabled = isEnabled
        self.endpointURL = endpointURL
        self.selectedModelId = selectedModelId
        self.temperature = temperature
        self.maxOutputTokens = maxOutputTokens
        self.timeoutInterval = timeoutInterval
        self.maxRetries = maxRetries
    }
    
    public static func defaultGeminiConfig() -> AIProviderConfiguration {
        return AIProviderConfiguration(
            providerType: .gemini,
            isEnabled: true,
            endpointURL: "https://generativelanguage.googleapis.com/v1beta",
            selectedModelId: "gemini-2.5-flash",
            temperature: 0.7,
            maxOutputTokens: 2048,
            timeoutInterval: 30.0,
            maxRetries: 2
        )
    }
    
    public static func defaultOmniRouteConfig() -> AIProviderConfiguration {
        return AIProviderConfiguration(
            providerType: .omniRoute,
            isEnabled: false,
            endpointURL: "http://localhost:20128/v1",
            selectedModelId: "default",
            temperature: 0.7,
            maxOutputTokens: 2048,
            timeoutInterval: 20.0,
            maxRetries: 1
        )
    }
}

public struct OmniRouteProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var baseURL: String
    public var apiKeyAccount: String
    public var connectionType: ConnectionType
    public var isEnabled: Bool
    public var defaultModel: String
    public var lastConnectionStatus: String?
    public var lastConnectionDate: Date?
    
    public enum ConnectionType: String, Codable, CaseIterable, Identifiable, Sendable {
        case local = "Local"
        case remote = "Remote"
        
        public var id: String { rawValue }
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        baseURL: String,
        apiKeyAccount: String,
        connectionType: ConnectionType = .local,
        isEnabled: Bool = true,
        defaultModel: String = "default",
        lastConnectionStatus: String? = nil,
        lastConnectionDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.baseURL = baseURL
        self.apiKeyAccount = apiKeyAccount
        self.connectionType = connectionType
        self.isEnabled = isEnabled
        self.defaultModel = defaultModel
        self.lastConnectionStatus = lastConnectionStatus
        self.lastConnectionDate = lastConnectionDate
    }
    
    public static func defaultLocalProfile() -> OmniRouteProfile {
        return OmniRouteProfile(
            name: "Local OmniRoute Gateway",
            baseURL: "http://localhost:20128/v1",
            apiKeyAccount: "omniroute_local_key",
            connectionType: .local,
            isEnabled: true,
            defaultModel: "default"
        )
    }
}

public enum AITaskType: String, Codable, CaseIterable, Identifiable, Sendable {
    case naturalLanguageProcessing = "Natural Language Processing"
    case screenUnderstanding = "Screen Understanding"
    case mainConversation = "Main Conversation"
    case contextualReasoning = "Contextual Reasoning"
    case alternativeModelRequest = "Alternative Model Request"
    case userSelectedModel = "User Selected Model"
    
    public var id: String { rawValue }
}

public struct AIRoutingRule: Codable, Equatable, Sendable {
    public var task: AITaskType
    public var provider: AIProviderType
    public var preferredModelId: String?
    
    public init(task: AITaskType, provider: AIProviderType, preferredModelId: String? = nil) {
        self.task = task
        self.provider = provider
        self.preferredModelId = preferredModelId
    }
    
    public static func defaultRules() -> [AIRoutingRule] {
        return [
            AIRoutingRule(task: .naturalLanguageProcessing, provider: .gemini),
            AIRoutingRule(task: .screenUnderstanding, provider: .gemini),
            AIRoutingRule(task: .mainConversation, provider: .gemini),
            AIRoutingRule(task: .contextualReasoning, provider: .gemini),
            AIRoutingRule(task: .alternativeModelRequest, provider: .omniRoute),
            AIRoutingRule(task: .userSelectedModel, provider: .omniRoute)
        ]
    }
}

public enum AIMessageRole: String, Codable, Sendable {
    case system
    case user
    case assistant
}

public struct AIMessage: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let role: AIMessageRole
    public let content: String
    public let timestamp: Date
    public let attachedImageBase64: [String]
    
    public init(
        id: UUID = UUID(),
        role: AIMessageRole,
        content: String,
        timestamp: Date = Date(),
        attachedImageBase64: [String] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.attachedImageBase64 = attachedImageBase64
    }
}

public struct AIRequestContext: Sendable {
    public let systemInstruction: String?
    public let temperature: Double?
    public let maxTokens: Int?
    public let stream: Bool
    public let timeoutInterval: TimeInterval?
    public let targetTask: AITaskType?
    
    public init(
        systemInstruction: String? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        stream: Bool = false,
        timeoutInterval: TimeInterval? = nil,
        targetTask: AITaskType? = nil
    ) {
        self.systemInstruction = systemInstruction
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.stream = stream
        self.timeoutInterval = timeoutInterval
        self.targetTask = targetTask
    }
}

public struct SpatialPoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let label: String
    public let screenIndex: Int
    
    public init(x: Double, y: Double, label: String, screenIndex: Int = 1) {
        self.x = x
        self.y = y
        self.label = label
        self.screenIndex = screenIndex
    }
    
    /// Parses any [POINT:x,y:label:screenN] or [POINT:x,y:label] tags in text
    public static func parsePoints(from text: String) -> [SpatialPoint] {
        var results: [SpatialPoint] = []
        let pattern = #"\[POINT:\s*([0-9.]+)\s*,\s*([0-9.]+)\s*:\s*([^:\]]+)(?::screen(\d+))?\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return results
        }
        
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)
        
        for match in matches {
            guard match.numberOfRanges >= 4,
                  let xRange = Range(match.range(at: 1), in: text),
                  let yRange = Range(match.range(at: 2), in: text),
                  let labelRange = Range(match.range(at: 3), in: text),
                  let x = Double(text[xRange]),
                  let y = Double(text[yRange]) else {
                continue
            }
            
            let label = String(text[labelRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            var screenIndex = 1
            if match.numberOfRanges > 4 && match.range(at: 4).location != NSNotFound,
               let screenRange = Range(match.range(at: 4), in: text),
               let parsedScreen = Int(text[screenRange]) {
                screenIndex = parsedScreen
            }
            
            results.append(SpatialPoint(x: x, y: y, label: label, screenIndex: screenIndex))
        }
        
        return results
    }
}

public struct AICompletionResponse: Sendable {
    public let text: String
    public let modelUsed: String
    public let spatialPoints: [SpatialPoint]
    public let tokenUsage: TokenUsage?
    public let rawResponseData: Data?
    
    public init(
        text: String,
        modelUsed: String,
        spatialPoints: [SpatialPoint] = [],
        tokenUsage: TokenUsage? = nil,
        rawResponseData: Data? = nil
    ) {
        self.text = text
        self.modelUsed = modelUsed
        self.spatialPoints = spatialPoints.isEmpty ? SpatialPoint.parsePoints(from: text) : spatialPoints
        self.tokenUsage = tokenUsage
        self.rawResponseData = rawResponseData
    }
}

public struct ScreenUnderstandingRequest: Sendable {
    public let userPrompt: String
    public let conversationHistory: [AIMessage]
    public let screenshotData: [Data]
    public let applicationContext: String?
    public let displayInfo: DisplayInfo?
    
    public init(
        userPrompt: String,
        conversationHistory: [AIMessage] = [],
        screenshotData: [Data] = [],
        applicationContext: String? = nil,
        displayInfo: DisplayInfo? = nil
    ) {
        self.userPrompt = userPrompt
        self.conversationHistory = conversationHistory
        self.screenshotData = screenshotData
        self.applicationContext = applicationContext
        self.displayInfo = displayInfo
    }
}
