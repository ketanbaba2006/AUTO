//
//  MemoryRetrievalManager.swift
//  AUTO
//
//  Searches, filters, and formats pertinent user-approved memories
//  for task planning and conversational grounding without leaking unnecessary context.
//

import Foundation

public final class MemoryRetrievalManager: @unchecked Sendable {
    public static let shared = MemoryRetrievalManager()
    
    private let memoryManager: MemoryManager
    
    public init(memoryManager: MemoryManager = .shared) {
        self.memoryManager = memoryManager
    }
    
    /// Retrieves formatted context string containing top relevant memories for an instruction.
    public func retrieveRelevantContext(for instruction: String, maxItems: Int = 3) -> String? {
        let isEnabled = UserDefaults.standard.object(forKey: "com.auto.isMemoryEnabled") as? Bool ?? true
        guard isEnabled else { return nil }
        
        let matches = memoryManager.search(query: instruction, limit: maxItems)
        guard !matches.isEmpty else { return nil }
        
        var lines: [String] = ["Relevant User Memories & Preferences:"]
        for match in matches {
            lines.append("• [\(match.category.rawValue)] \(match.key): \(match.content)")
        }
        return lines.joined(separator: "\n")
    }
    
    /// Checks for a specific user preference by key.
    public func userPreference(forKey key: String) -> String? {
        return memoryManager.get(key: key, category: .userPreferences)?.content
    }
}

