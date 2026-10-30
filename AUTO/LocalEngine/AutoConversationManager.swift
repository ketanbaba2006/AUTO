//
//  AutoConversationManager.swift
//  AUTO
//
//  Native Local Conversation Manager:
//  Manages conversational turn history locally, executes multi-turn compaction,
//  and provides granular privacy purging controls.
//

import Foundation

public struct AutoConversationTurn: Identifiable, Codable, Sendable {
    public let id: UUID
    public let userTranscript: String
    public let assistantResponse: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), userTranscript: String, assistantResponse: String, timestamp: Date = Date()) {
        self.id = id
        self.userTranscript = userTranscript
        self.assistantResponse = assistantResponse
        self.timestamp = timestamp
    }
}

public final class AutoConversationManager: @unchecked Sendable {
    public static let shared = AutoConversationManager()
    
    private var turns: [AutoConversationTurn] = []
    private let lock = NSLock()
    
    private init() {}
    
    public func addTurn(userTranscript: String, assistantResponse: String, maxLimit: Int = 20) {
        lock.lock()
        defer { lock.unlock() }
        
        let turn = AutoConversationTurn(userTranscript: userTranscript, assistantResponse: assistantResponse)
        turns.append(turn)
        
        // Compact history if exceeding max limit
        if turns.count > maxLimit {
            turns.removeFirst(turns.count - maxLimit)
        }
    }
    
    public func recentTurns(limit: Int = 10) -> [AutoConversationTurn] {
        lock.lock()
        defer { lock.unlock() }
        return Array(turns.suffix(limit))
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        turns.removeAll()
    }
}
