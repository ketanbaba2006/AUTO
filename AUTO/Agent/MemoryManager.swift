//
//  MemoryManager.swift
//  AUTO
//
//  Thread-safe local persistent memory manager for user preferences,
//  workflow patterns, project context, and temporary task references.
//  Enforces zero sensitive data storage and transparent user controls.
//

import Foundation

public final class MemoryManager: @unchecked Sendable {
    public static let shared = MemoryManager()
    
    private var memoryStore: [UUID: AgentMemoryItem] = [:]
    private let lock = NSLock()
    private let storageURL: URL
    
    public init(customStorageURL: URL? = nil) {
        if let custom = customStorageURL {
            self.storageURL = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let autoDir = appSupport.appendingPathComponent("AUTO", isDirectory: true)
            try? FileManager.default.createDirectory(at: autoDir, withIntermediateDirectories: true)
            self.storageURL = autoDir.appendingPathComponent("agent_memory.json")
        }
        loadFromDisk()
    }
    
    // MARK: - Storing Memory
    
    @discardableResult
    public func store(
        category: MemoryCategory,
        key: String,
        content: String,
        importance: Double = 0.5,
        confidence: Double = 1.0,
        expiresAt: Date? = nil,
        source: String = "user_interaction"
    ) -> AgentMemoryItem? {
        lock.lock()
        defer { lock.unlock() }
        
        // Check if memory is enabled globally
        let isEnabled = UserDefaults.standard.object(forKey: "com.auto.isMemoryEnabled") as? Bool ?? true
        guard isEnabled else {
            AppLogger.shared.notice("Memory storage skipped: Memory system is disabled by user.", category: .agent)
            return nil
        }
        
        // Security guard against storing sensitive credentials
        if containsSensitiveData(key) || containsSensitiveData(content) {
            AppLogger.shared.warning("Memory rejected: Content contains sensitive data patterns.", category: .agent)
            return nil
        }
        
        // Check if item with same key and category exists -> update it
        if let existing = memoryStore.values.first(where: { $0.category == category && $0.key.lowercased() == key.lowercased() }) {
            var updated = existing
            updated.content = content
            updated.importance = importance
            updated.confidence = confidence
            updated.updatedAt = Date()
            updated.expiresAt = expiresAt
            memoryStore[existing.id] = updated
            saveToDisk()
            return updated
        }
        
        let item = AgentMemoryItem(
            category: category,
            key: key,
            content: content,
            importance: importance,
            confidence: confidence,
            createdAt: Date(),
            updatedAt: Date(),
            expiresAt: expiresAt,
            source: source
        )
        
        memoryStore[item.id] = item
        
        // Prune if exceeds max limit (default 200)
        let maxLimit = UserDefaults.standard.integer(forKey: "com.auto.maxStoredMemories")
        let limit = maxLimit > 0 ? maxLimit : 200
        if memoryStore.count > limit {
            // Remove least important / oldest items
            let sorted = memoryStore.values.sorted {
                if $0.importance == $1.importance {
                    return $0.updatedAt < $1.updatedAt
                }
                return $0.importance < $1.importance
            }
            if let oldest = sorted.first {
                memoryStore.removeValue(forKey: oldest.id)
            }
        }
        
        saveToDisk()
        AppLogger.shared.info("Stored memory: [\(category.rawValue)] '\(key)'", category: .agent)
        return item
    }
    
    // MARK: - Retrieval
    
    public func get(key: String, category: MemoryCategory? = nil) -> AgentMemoryItem? {
        lock.lock()
        defer { lock.unlock() }
        
        purgeExpiredUnlocked()
        
        return memoryStore.values.first { item in
            let matchesCategory = category == nil || item.category == category
            return matchesCategory && item.key.lowercased() == key.lowercased()
        }
    }
    
    public func getAll(category: MemoryCategory? = nil) -> [AgentMemoryItem] {
        lock.lock()
        defer { lock.unlock() }
        
        purgeExpiredUnlocked()
        
        let items: [AgentMemoryItem]
        if let cat = category {
            items = memoryStore.values.filter { $0.category == cat }
        } else {
            items = Array(memoryStore.values)
        }
        
        return items.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - Local Search
    
    public func search(query: String, limit: Int = 5) -> [AgentMemoryItem] {
        lock.lock()
        defer { lock.unlock() }
        
        purgeExpiredUnlocked()
        
        let tokens = Set(query.lowercased().split(separator: " ").map { String($0) })
        guard !tokens.isEmpty else { return [] }
        
        var scored: [(item: AgentMemoryItem, score: Double)] = []
        for item in memoryStore.values {
            let itemText = "\(item.key) \(item.content)".lowercased()
            let itemTokens = Set(itemText.split(separator: " ").map { String($0) })
            
            let overlap = tokens.intersection(itemTokens).count
            if overlap > 0 || itemText.contains(query.lowercased()) {
                var score = Double(overlap) * 1.5 + item.importance
                if itemText.contains(query.lowercased()) {
                    score += 2.0
                }
                scored.append((item, score))
            }
        }
        
        scored.sort { $0.score > $1.score }
        return Array(scored.prefix(limit).map { $0.item })
    }
    
    // MARK: - Deletion & Clearing
    
    public func delete(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        memoryStore.removeValue(forKey: id)
        saveToDisk()
    }
    
    public func clearCategory(_ category: MemoryCategory) {
        lock.lock()
        defer { lock.unlock() }
        memoryStore = memoryStore.filter { $0.value.category != category }
        saveToDisk()
    }
    
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        memoryStore.removeAll()
        saveToDisk()
        AppLogger.shared.info("Cleared all local agent memories.", category: .agent)
    }
    
    public func purgeExpired() {
        lock.lock()
        defer { lock.unlock() }
        purgeExpiredUnlocked()
    }
    
    private func purgeExpiredUnlocked() {
        let beforeCount = memoryStore.count
        memoryStore = memoryStore.filter { !$0.value.isExpired }
        if memoryStore.count != beforeCount {
            saveToDisk()
        }
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        let items = Array(memoryStore.values)
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            AppLogger.shared.error("Failed to persist memory to disk: \(error)", category: .agent)
        }
    }
    
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path),
              let data = try? Data(contentsOf: storageURL),
              let items = try? JSONDecoder().decode([AgentMemoryItem].self, from: data) else {
            return
        }
        
        lock.lock()
        defer { lock.unlock() }
        self.memoryStore = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        purgeExpiredUnlocked()
    }
    
    // MARK: - Sensitive Data Defense
    
    private func containsSensitiveData(_ text: String) -> Bool {
        let lower = text.lowercased()
        let sensitiveKeywords = [
            "password", "secret", "private key", "api_key", "bearer ",
            "access_token", "credit_card", "cvv", "social security", "ssn",
            "pin code", "auth_token"
        ]
        return sensitiveKeywords.contains { lower.contains($0) }
    }
}

