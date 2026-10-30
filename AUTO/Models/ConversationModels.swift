//
//  ConversationModels.swift
//  AUTO
//
//  Data models representing user conversations, turns, and context memory.
//

import Foundation

public struct ConversationTurn: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let userTranscript: String
    public let assistantResponse: String
    public let targetPoint: SpatialPoint?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        userTranscript: String,
        assistantResponse: String,
        targetPoint: SpatialPoint? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userTranscript = userTranscript
        self.assistantResponse = assistantResponse
        self.targetPoint = targetPoint
    }
}

public struct ConversationSession: Identifiable, Codable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public var turns: [ConversationTurn]
    
    public init(id: UUID = UUID(), createdAt: Date = Date(), turns: [ConversationTurn] = []) {
        self.id = id
        self.createdAt = createdAt
        self.turns = turns
    }
}
