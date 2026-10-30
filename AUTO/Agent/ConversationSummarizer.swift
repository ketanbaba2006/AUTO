//
//  ConversationSummarizer.swift
//  AUTO
//
//  Manages conversation context window limits by producing concise summaries of older dialogue turns,
//  preserving active goals, user preferences, and task decisions without consuming excessive tokens.
//

import Foundation

public final class ConversationSummarizer: @unchecked Sendable {
    public static let shared = ConversationSummarizer()
    
    public init() {}
    
    /// Summarizes an array of older conversation turns into a compact context string.
    public func summarizeTurns(_ turns: [ConversationTurn]) -> String {
        guard !turns.isEmpty else { return "" }
        
        var summaryBullets: [String] = []
        for (index, turn) in turns.enumerated() {
            let userGoal = turn.userTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            let assistantKey = extractKeyPoints(from: turn.assistantResponse)
            summaryBullets.append("Turn \(index + 1): User asked '\(userGoal)' -> AUTO responded: \(assistantKey)")
        }
        
        return """
        [Previous Conversation Summary]:
        \(summaryBullets.joined(separator: "\n"))
        """
    }
    
    private func extractKeyPoints(from text: String) -> String {
        let clean = text.replacingOccurrences(of: "\n", with: " ")
        if clean.count > 100 {
            return String(clean.prefix(100)) + "..."
        }
        return clean
    }
}

