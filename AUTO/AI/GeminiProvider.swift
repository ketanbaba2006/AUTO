//
//  GeminiProvider.swift
//  AUTO
//
//  Primary AI Provider: Google Gemini API.
//  Implements production-quality multimodal text/image reasoning, SSE streaming,
//  connection verification, model discovery, retries, and token usage tracking.
//

import Foundation

public final class GeminiProvider: AIProvider, @unchecked Sendable {
    public let providerType: AIProviderType = .gemini
    
    private let keychainService: KeychainService
    private let session: URLSession
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
    public init(
        keychainService: KeychainService = KeychainManager.shared,
        session: URLSession = .shared
    ) {
        self.keychainService = keychainService
        self.session = session
    }
    
    public var isConfigured: Bool {
        return (try? keychainService.get(key: KeychainManager.geminiApiKeyAccount, service: KeychainManager.defaultService))?.isEmpty == false
    }
    
    public func getApiKey() throws -> String {
        guard let key = try keychainService.get(key: KeychainManager.geminiApiKeyAccount, service: KeychainManager.defaultService),
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AUTOError.invalidConfiguration(detail: "Gemini API key is not configured in macOS Keychain.")
        }
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Connection Testing
    public func testConnection() async throws -> Bool {
        let key = try getApiKey()
        guard let url = URL(string: "\(baseURL)/models?key=\(key)") else {
            throw AUTOError.invalidConfiguration(detail: "Invalid Gemini endpoint URL.")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        let (data, response) = try await performRequestWithRetry(request: request, maxRetries: 1)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AUTOError.networkError(underlying: "Non-HTTP response received.")
        }
        
        if httpResponse.statusCode == 200 {
            AppLogger.shared.info("Gemini connection test successful.", category: .ai)
            return true
        } else {
            throw mapHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    // MARK: - Dynamic Model Discovery
    public func fetchAvailableModels() async throws -> [AIModelInfo] {
        let key = try getApiKey()
        guard let url = URL(string: "\(baseURL)/models?key=\(key)") else {
            throw AUTOError.invalidConfiguration(detail: "Invalid Gemini endpoint URL.")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15.0
        
        let (data, response) = try await performRequestWithRetry(request: request, maxRetries: 2)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AUTOError.networkError(underlying: "Non-HTTP response received.")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw mapHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
        
        struct GeminiModelsResponse: Codable {
            struct ModelEntry: Codable {
                let name: String
                let displayName: String?
                let inputTokenLimit: Int?
                let supportedGenerationMethods: [String]?
            }
            let models: [ModelEntry]?
        }
        
        guard let decoded = try? JSONDecoder().decode(GeminiModelsResponse.self, from: data),
              let models = decoded.models else {
            // Provide sensible fallback models if parsing fails
            return defaultGeminiFallbackModels()
        }
        
        let filtered = models.filter { entry in
            entry.supportedGenerationMethods?.contains("generateContent") ?? true
        }
        
        return filtered.map { entry in
            let cleanId = entry.name.replacingOccurrences(of: "models/", with: "")
            let isDefault = cleanId == "gemini-3.8-flash"
            return AIModelInfo(
                id: cleanId,
                displayName: entry.displayName ?? cleanId,
                provider: .gemini,
                contextWindow: entry.inputTokenLimit ?? 128000,
                supportsVision: true,
                supportsAudio: true,
                supportsStreaming: true,
                isDefault: isDefault
            )
        }
    }
    
    public static let fallbackModels: [AIModelInfo] = [
        AIModelInfo(id: "gemini-3.8-flash", displayName: "Gemini 3.8 Flash", provider: .gemini, supportsVision: true, isDefault: true),
        AIModelInfo(id: "gemini-3.5-flash", displayName: "Gemini 3.5 Flash", provider: .gemini, supportsVision: true),
        AIModelInfo(id: "gemini-pro-latest", displayName: "Gemini Pro (Latest)", provider: .gemini, supportsVision: true)
    ]
    
    private func defaultGeminiFallbackModels() -> [AIModelInfo] {
        return Self.fallbackModels
    }
    
    // MARK: - Synchronous / Standard Generate Content
    public func generateResponse(messages: [AIMessage], context: AIRequestContext) async throws -> AICompletionResponse {
        try Task.checkCancellation()
        let key = try getApiKey()
        
        let modelId = await MainActor.run {
            ApplicationState.shared.geminiConfig.selectedModelId
        }
        
        guard let url = URL(string: "\(baseURL)/models/\(modelId):generateContent?key=\(key)") else {
            throw AUTOError.invalidConfiguration(detail: "Invalid Gemini request URL.")
        }
        
        let requestBody = buildGeminiRequestBody(messages: messages, context: context)
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = context.timeoutInterval ?? 30.0
        
        let (data, response) = try await performRequestWithRetry(request: request, maxRetries: 2)
        try Task.checkCancellation()
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AUTOError.networkError(underlying: "Non-HTTP response received.")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw mapHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return try parseGeminiResponse(data: data, modelUsed: modelId)
    }
    
    // MARK: - SSE Streaming Generate Content
    public func streamResponse(messages: [AIMessage], context: AIRequestContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try Task.checkCancellation()
                    let key = try self.getApiKey()
                    
                    let modelId = await MainActor.run {
                        ApplicationState.shared.geminiConfig.selectedModelId
                    }
                    
                    guard let url = URL(string: "\(self.baseURL)/models/\(modelId):streamGenerateContent?alt=sse&key=\(key)") else {
                        throw AUTOError.invalidConfiguration(detail: "Invalid Gemini stream endpoint URL.")
                    }
                    
                    let requestBody = self.buildGeminiRequestBody(messages: messages, context: context)
                    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = jsonData
                    request.timeoutInterval = context.timeoutInterval ?? 45.0
                    
                    let (asyncBytes, response) = try await self.session.bytes(for: request)
                    try Task.checkCancellation()
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw AUTOError.networkError(underlying: "Non-HTTP response received during streaming.")
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        throw self.mapHTTPError(statusCode: httpResponse.statusCode, data: Data())
                    }
                    
                    for try await line in asyncBytes.lines {
                        try Task.checkCancellation()
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard trimmed.hasPrefix("data: ") else { continue }
                        
                        let jsonPayload = String(trimmed.dropFirst(6))
                        guard let payloadData = jsonPayload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
                            continue
                        }
                        
                        // Parse usage if provided in chunk
                        if let usage = json["usageMetadata"] as? [String: Any] {
                            let p = usage["promptTokenCount"] as? Int ?? 0
                            let c = usage["candidatesTokenCount"] as? Int ?? 0
                            let t = usage["totalTokenCount"] as? Int ?? (p + c)
                            let usageModel = TokenUsage(promptTokens: p, completionTokens: c, totalTokens: t)
                            await MainActor.run {
                                ApplicationState.shared.lastTokenUsage = usageModel
                            }
                        }
                        
                        if let candidates = json["candidates"] as? [[String: Any]],
                           let first = candidates.first,
                           let content = first["content"] as? [String: Any],
                           let parts = content["parts"] as? [[String: Any]],
                           let textPart = parts.first?["text"] as? String {
                            continuation.yield(textPart)
                        }
                    }
                    
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: AUTOError.cancelled)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Request Builder
    private func buildGeminiRequestBody(messages: [AIMessage], context: AIRequestContext) -> [String: Any] {
        var contents: [[String: Any]] = []
        for msg in messages {
            let role = (msg.role == .assistant) ? "model" : "user"
            var parts: [[String: Any]] = []
            if !msg.content.isEmpty {
                parts.append(["text": msg.content])
            }
            for imgBase64 in msg.attachedImageBase64 {
                parts.append([
                    "inline_data": [
                        "mime_type": "image/jpeg",
                        "data": imgBase64
                    ]
                ])
            }
            if !parts.isEmpty {
                contents.append(["role": role, "parts": parts])
            }
        }
        
        var body: [String: Any] = ["contents": contents]
        
        if let systemInstruction = context.systemInstruction, !systemInstruction.isEmpty {
            body["systemInstruction"] = [
                "parts": [
                    ["text": systemInstruction]
                ]
            ]
        }
        
        var genConfig: [String: Any] = [:]
        if let temp = context.temperature {
            genConfig["temperature"] = temp
        }
        if let maxTokens = context.maxTokens {
            genConfig["maxOutputTokens"] = maxTokens
        }
        if !genConfig.isEmpty {
            body["generationConfig"] = genConfig
        }
        
        return body
    }
    
    // MARK: - Response Parsing
    private func parseGeminiResponse(data: Data, modelUsed: String) throws -> AICompletionResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AUTOError.malformedJSON(detail: "Unable to parse response JSON from Gemini.")
        }
        
        // Extract token usage
        var tokenUsage: TokenUsage?
        if let usage = json["usageMetadata"] as? [String: Any] {
            let promptTokens = usage["promptTokenCount"] as? Int ?? 0
            let candidatesTokens = usage["candidatesTokenCount"] as? Int ?? 0
            let totalTokens = usage["totalTokenCount"] as? Int ?? (promptTokens + candidatesTokens)
            tokenUsage = TokenUsage(promptTokens: promptTokens, completionTokens: candidatesTokens, totalTokens: totalTokens)
            Task { @MainActor in
                ApplicationState.shared.lastTokenUsage = tokenUsage
            }
        }
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first else {
            throw AUTOError.emptyResponse
        }
        
        guard let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw AUTOError.emptyResponse
        }
        
        var fullText = ""
        for part in parts {
            if let text = part["text"] as? String {
                fullText += text
            }
        }
        
        guard !fullText.isEmpty else {
            throw AUTOError.emptyResponse
        }
        
        return AICompletionResponse(
            text: fullText,
            modelUsed: modelUsed,
            tokenUsage: tokenUsage,
            rawResponseData: data
        )
    }
    
    // MARK: - Retries & Error Mapping
    private func performRequestWithRetry(request: URLRequest, maxRetries: Int) async throws -> (Data, URLResponse) {
        var attempts = 0
        var currentDelay: UInt64 = 1_000_000_000 // 1 second
        
        while true {
            try Task.checkCancellation()
            do {
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    // Retry on rate limit (429) or temporary server error (503)
                    if (httpResponse.statusCode == 429 || httpResponse.statusCode == 503) && attempts < maxRetries {
                        attempts += 1
                        AppLogger.shared.notice("Gemini returned \(httpResponse.statusCode); retrying attempt \(attempts)/\(maxRetries)...", category: .ai)
                        try await Task.sleep(nanoseconds: currentDelay)
                        currentDelay *= 2
                        continue
                    }
                }
                return (data, response)
            } catch is CancellationError {
                throw AUTOError.cancelled
            } catch {
                if attempts < maxRetries {
                    attempts += 1
                    AppLogger.shared.notice("Network error during Gemini call; retrying attempt \(attempts)...", category: .ai)
                    try await Task.sleep(nanoseconds: currentDelay)
                    currentDelay *= 2
                    continue
                }
                throw AUTOError.networkError(underlying: error.localizedDescription)
            }
        }
    }
    
    private func mapHTTPError(statusCode: Int, data: Data) -> AUTOError {
        var detailMessage = "HTTP \(statusCode)"
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorObj = json["error"] as? [String: Any],
           let message = errorObj["message"] as? String {
            detailMessage = message
        } else if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            detailMessage = text
        }
        
        switch statusCode {
        case 400:
            return AUTOError.invalidConfiguration(detail: "Bad request to Gemini API: \(detailMessage)")
        case 401, 403:
            return AUTOError.authenticationFailed(provider: "Gemini", detail: "Invalid API key or insufficient permissions.")
        case 404:
            return AUTOError.modelNotFound(modelId: "The selected model is no longer available (\(detailMessage)). Open AUTO Settings and pick a different model.")
        case 429:
            return AUTOError.rateLimitExceeded(provider: "Gemini", retryAfter: 15.0)
        case 500, 503, 504:
            return AUTOError.serverUnavailable(provider: "Gemini", statusCode: statusCode)
        default:
            return AUTOError.aiProviderError(provider: "Gemini", message: detailMessage, statusCode: statusCode)
        }
    }
}
