//
//  AIProvider.swift
//  AUTO
//
//  Protocol definition for AI providers supporting multimodal reasoning,
//  connection verification, model discovery, and streaming.
//

import Foundation

public protocol AIProvider: AnyObject, Sendable {
    var providerType: AIProviderType { get }
    var isConfigured: Bool { get }
    func testConnection() async throws -> Bool
    func fetchAvailableModels() async throws -> [AIModelInfo]
    func generateResponse(messages: [AIMessage], context: AIRequestContext) async throws -> AICompletionResponse
    func streamResponse(messages: [AIMessage], context: AIRequestContext) -> AsyncThrowingStream<String, Error>
}
