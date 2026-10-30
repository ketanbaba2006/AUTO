//
//  ModelDiscoveryManager.swift
//  AUTO
//
//  Discovers, caches, and refreshes available models from active AI providers.
//

import Foundation

public final class ModelDiscoveryManager: @unchecked Sendable {
    public static let shared = ModelDiscoveryManager()
    
    private var cachedModels: [AIProviderType: [AIModelInfo]] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func getCachedModels(for provider: AIProviderType) -> [AIModelInfo] {
        lock.lock()
        defer { lock.unlock() }
        return cachedModels[provider] ?? []
    }
    
    public func updateCache(for provider: AIProviderType, models: [AIModelInfo]) {
        lock.lock()
        defer { lock.unlock() }
        cachedModels[provider] = models
        AppLogger.shared.info("Updated model cache for \(provider.rawValue): \(models.count) models found.", category: .ai)
    }
    
    public func discoverModels(for provider: AIProvider) async throws -> [AIModelInfo] {
        let models = try await provider.fetchAvailableModels()
        updateCache(for: provider.providerType, models: models)
        return models
    }
}
