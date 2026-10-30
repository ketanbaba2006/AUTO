//
//  ConversationMemory.swift
//  AUTO
//
//  Thread-safe conversation memory manager.
//  Maintains turn-by-turn history, session tracking, configurable context limits,
//  and conversion to AI message representations.
//

import Foundation

public final class ConversationMemory: @unchecked Sendable {
    public static let shared = ConversationMemory()
    
    private var turns: [ConversationTurn] = []
    private var currentSessionId: UUID = UUID()
    private let lock = NSLock()
    
    public init() {}
    
    public var sessionId: UUID {
        lock.lock()
        defer { lock.unlock() }
        return currentSessionId
    }
    
    public func addTurn(_ turn: ConversationTurn, maxLimit: Int = 10) {
        lock.lock()
        defer { lock.unlock() }
        turns.append(turn)
        if turns.count > maxLimit {
            turns.removeFirst(turns.count - maxLimit)
        }
    }
    
    public func getRecentTurns() -> [ConversationTurn] {
        lock.lock()
        defer { lock.unlock() }
        return turns
    }
    
    public func getAIMessagesHistory(limit: Int = 10) -> [AIMessage] {
        lock.lock()
        defer { lock.unlock() }
        
        let slice = turns.suffix(limit)
        var messages: [AIMessage] = []
        for turn in slice {
            messages.append(AIMessage(role: .user, content: turn.userTranscript, timestamp: turn.timestamp))
            messages.append(AIMessage(role: .assistant, content: turn.assistantResponse, timestamp: turn.timestamp))
        }
        return messages
    }
    
    public func resetSession() {
        lock.lock()
        defer { lock.unlock() }
        turns.removeAll()
        currentSessionId = UUID()
        AppLogger.shared.info("Conversation session reset. New ID: \(currentSessionId.uuidString)", category: .agent)
    }
    
    public func clear() {
        resetSession()
    }
}
