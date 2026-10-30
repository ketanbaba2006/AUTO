//
//  OmniRouteProvider.swift
//  AUTO
//
//  Optional AI Provider: OmniRoute API Gateway.
//  Supports local or remote OpenAI-compatible endpoints, connection profiles,
//  dynamic model discovery, vision payloads, SSE streaming, and Keychain credentials.
//

import Foundation

public final class OmniRouteProvider: AIProvider, @unchecked Sendable {
    public let providerType: AIProviderType = .omniRoute
    
    private let keychainService: KeychainService
    private let session: URLSession
    
    public init(
        keychainService: KeychainService = KeychainManager.shared,
        session: URLSession = .shared
    ) {
        self.keychainService = keychainService
        self.session = session
    }
    
    public var isConfigured: Bool {
        let endpoint = getActiveEndpointURLSync()
        return !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func getActiveEndpointURLSync() -> String {
        // Read active profile or default configuration
        return "http://localhost:20128/v1"
    }
    
    public func getEndpointURL() async -> String {
        return await MainActor.run {
            if let activeId = ApplicationState.shared.activeOmniRouteProfileId,
               let profile = ApplicationState.shared.omniRouteProfiles.first(where: { $0.id == activeId }) {
                var url = profile.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                if url.hasSuffix("/") { url.removeLast() }
                return url
            }
            var endpoint = ApplicationState.shared.omniRouteConfig.endpointURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if endpoint.isEmpty {
                endpoint = "http://localhost:20128/v1"
            }
            if endpoint.hasSuffix("/") { endpoint.removeLast() }
            return endpoint
        }
    }
    
    public func getApiKey() async -> String? {
        return await MainActor.run {
            if let activeId = ApplicationState.shared.activeOmniRouteProfileId,
               let profile = ApplicationState.shared.omniRouteProfiles.first(where: { $0.id == activeId }) {
                if let key = try? keychainService.get(key: profile.apiKeyAccount, service: KeychainManager.defaultService), !key.isEmpty {
                    return key
                }
            }
            return try? keychainService.get(key: KeychainManager.omniRouteApiKeyAccount, service: KeychainManager.defaultService)
        }
    }
    
    public func getSelectedModel() async -> String {
        return await MainActor.run {
            if let activeId = ApplicationState.shared.activeOmniRouteProfileId,
               let profile = ApplicationState.shared.omniRouteProfiles.first(where: { $0.id == activeId }) {
                return profile.defaultModel
            }
            return ApplicationState.shared.omniRouteConfig.selectedModelId
        }
    }
    
    // MARK: - Connection Testing
    public func testConnection() async throws -> Bool {
        let endpoint = await getEndpointURL()
        guard let url = URL(string: "\(endpoint)/models") else {
            throw AUTOError.invalidConfiguration(detail: "Invalid OmniRoute endpoint URL: \(endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8.0
        
        if let key = await getApiKey(), !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AUTOError.networkError(underlying: "Non-HTTP response received.")
            }
            
            if httpResponse.statusCode == 200 {
                AppLogger.shared.info("OmniRoute connection test succeeded at \(endpoint).", category: .ai)
                await updateLastConnectionStatus(status: "Connected", success: true)
                return true
            } else {
                await updateLastConnectionStatus(status: "HTTP \(httpResponse.statusCode)", success: false)
                throw mapHTTPError(statusCode: httpResponse.statusCode, data: data)
            }
        } catch is CancellationError {
            throw AUTOError.cancelled
        } catch let autoError as AUTOError {
            await updateLastConnectionStatus(status: autoError.localizedDescription, success: false)
            throw autoError
        } catch {
            await updateLastConnectionStatus(status: error.localizedDescription, success: false)
            throw AUTOError.networkError(underlying: "Failed to connect to OmniRoute gateway at \(endpoint): \(error.localizedDescription)")
        }
    }
    
    private func updateLastConnectionStatus(status: String, success: Bool) async {
        await MainActor.run {
            if let activeId = ApplicationState.shared.activeOmniRouteProfileId,
               let index = ApplicationState.shared.omniRouteProfiles.firstIndex(where: { $0.id == activeId }) {
                ApplicationState.shared.omniRouteProfiles[index].lastConnectionStatus = status
                ApplicationState.shared.omniRouteProfiles[index].lastConnectionDate = Date()
            }
        }
    }
    
    // MARK: - Dynamic Model Discovery
    public func fetchAvailableModels() async throws -> [AIModelInfo] {
        let endpoint = await getEndpointURL()
        guard let url = URL(string: "\(endpoint)/models") else {
            throw AUTOError.invalidConfiguration(detail: "Invalid OmniRoute endpoint URL: \(endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        if let key = await getApiKey(), !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AUTOError.networkError(underlying: "Non-HTTP response received.")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw mapHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
        
        struct OpenAIModelsResponse: Codable {
            struct ModelEntry: Codable {
                let id: String
                let object: String?
                let ownedBy: String?
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case object
                    case ownedBy = "owned_by"
                }
            }
            let data: [ModelEntry]?
        }
        
        guard let decoded = try? JSONDecoder().decode(OpenAIModelsResponse.self, from: data),
              let modelEntries = decoded.data else {
            return [
                AIModelInfo(id: "default", displayName: "OmniRoute Default", provider: .omniRoute, isDefault: true)
            ]
        }
        
        let isLocalServer = endpoint.contains("localhost") || endpoint.contains("127.0.0.1")
        return modelEntries.map { entry in
            let hasVision = entry.id.lowercased().contains("vision") ||
                            entry.id.lowercased().contains("vl") ||
                            entry.id.lowercased().contains("omni") ||
                            entry.id.lowercased().contains("4o")
            return AIModelInfo(
                id: entry.id,
                displayName: entry.id,
                provider: .omniRoute,
                contextWindow: 128000,
                supportsVision: hasVision,
                supportsAudio: false,
                supportsStreaming: true,
                isDefault: entry.id == "default",
                isLocal: isLocalServer
            )
        }
    }
    
    // MARK: - Chat Completions
    public func generateResponse(messages: [AIMessage], context: AIRequestContext) async throws -> AICompletionResponse {
        try Task.checkCancellation()
        let endpoint = await getEndpointURL()
        let modelId = await getSelectedModel()
        
        guard let url = URL(string: "\(endpoint)/chat/completions") else {
            throw AUTOError.invalidConfiguration(detail: "Invalid OmniRoute chat completions URL.")
        }
        
        let requestBody = buildOpenAIBody(messages: messages, context: context, model: modelId, stream: false)
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = await getApiKey(), !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = jsonData
        request.timeoutInterval = context.timeoutInterval ?? 30.0
        
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AUTOError.networkError(underlying: "Non-HTTP response received.")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw mapHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return try parseOpenAIResponse(data: data, modelUsed: modelId)
    }
    
    // MARK: - Streaming Response
    public func streamResponse(messages: [AIMessage], context: AIRequestContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try Task.checkCancellation()
                    let endpoint = await self.getEndpointURL()
                    let modelId = await self.getSelectedModel()
                    
                    guard let url = URL(string: "\(endpoint)/chat/completions") else {
                        throw AUTOError.invalidConfiguration(detail: "Invalid OmniRoute stream URL.")
                    }
                    
                    let requestBody = self.buildOpenAIBody(messages: messages, context: context, model: modelId, stream: true)
                    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let key = await self.getApiKey(), !key.isEmpty {
                        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                    }
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
                        
                        let dataContent = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                        if dataContent == "[DONE]" {
                            break
                        }
                        
                        guard let payloadData = dataContent.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let first = choices.first,
                              let delta = first["delta"] as? [String: Any],
                              let textDelta = delta["content"] as? String else {
                            continue
                        }
                        
                        continuation.yield(textDelta)
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
    
    // MARK: - Helpers
    private func buildOpenAIBody(messages: [AIMessage], context: AIRequestContext, model: String, stream: Bool) -> [String: Any] {
        var openAIMessages: [[String: Any]] = []
        
        if let systemInstruction = context.systemInstruction, !systemInstruction.isEmpty {
            openAIMessages.append([
                "role": "system",
                "content": systemInstruction
            ])
        }
        
        for msg in messages {
            let roleString = (msg.role == .assistant) ? "assistant" : "user"
            if msg.attachedImageBase64.isEmpty {
                openAIMessages.append([
                    "role": roleString,
                    "content": msg.content
                ])
            } else {
                // OpenAI Vision multimodal format
                var contentParts: [[String: Any]] = []
                if !msg.content.isEmpty {
                    contentParts.append(["type": "text", "text": msg.content])
                }
                for imgBase64 in msg.attachedImageBase64 {
                    contentParts.append([
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(imgBase64)"
                        ]
                    ])
                }
                openAIMessages.append([
                    "role": roleString,
                    "content": contentParts
                ])
            }
        }
        
        var body: [String: Any] = [
            "model": model,
            "messages": openAIMessages,
            "stream": stream
        ]
        
        if let temp = context.temperature {
            body["temperature"] = temp
        }
        if let maxTokens = context.maxTokens {
            body["max_tokens"] = maxTokens
        }
        
        return body
    }
    
    private func parseOpenAIResponse(data: Data, modelUsed: String) throws -> AICompletionResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AUTOError.malformedJSON(detail: "Unable to decode OmniRoute response.")
        }
        
        var tokenUsage: TokenUsage?
        if let usage = json["usage"] as? [String: Any] {
            let prompt = usage["prompt_tokens"] as? Int ?? 0
            let completion = usage["completion_tokens"] as? Int ?? 0
            let total = usage["total_tokens"] as? Int ?? (prompt + completion)
            tokenUsage = TokenUsage(promptTokens: prompt, completionTokens: completion, totalTokens: total)
            Task { @MainActor in
                ApplicationState.shared.lastTokenUsage = tokenUsage
            }
        }
        
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AUTOError.emptyResponse
        }
        
        return AICompletionResponse(
            text: content,
            modelUsed: modelUsed,
            tokenUsage: tokenUsage,
            rawResponseData: data
        )
    }
    
    private func mapHTTPError(statusCode: Int, data: Data) -> AUTOError {
        var detailMessage = "HTTP \(statusCode)"
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorObj = json["error"] as? [String: Any],
           let msg = errorObj["message"] as? String {
            detailMessage = msg
        }
        
        switch statusCode {
        case 401, 403:
            return AUTOError.authenticationFailed(provider: "OmniRoute", detail: "Invalid OmniRoute API key or unauthorized gateway access.")
        case 404:
            return AUTOError.modelNotFound(modelId: "Model or endpoint not found on OmniRoute server.")
        case 429:
            return AUTOError.rateLimitExceeded(provider: "OmniRoute", retryAfter: 10.0)
        case 500, 502, 503, 504:
            return AUTOError.serverUnavailable(provider: "OmniRoute", statusCode: statusCode)
        default:
            return AUTOError.aiProviderError(provider: "OmniRoute", message: detailMessage, statusCode: statusCode)
        }
    }
}
