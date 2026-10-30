//
//  ElementLocator.swift
//  AUTO
//
//  Locates targeted user interface controls by matching natural language directives
//  against accessible UI element hierarchies and visual fallback locations.
//

import CoreGraphics
import Foundation

public struct ElementLocatorMatchResult: Sendable {
    public let bestMatch: ElementMatch?
    public let allCandidates: [ElementMatch]
    public let isAmbiguous: Bool
    public let clarificationMessage: String?
}

public struct ElementLocator: Sendable {
    
    public static let highConfidenceThreshold: Double = 0.85
    public static let mediumConfidenceThreshold: Double = 0.60
    public static let ambiguityDeltaThreshold: Double = 0.08
    
    /// Finds the best matching UI element for a target query.
    public static func locateElement(
        query: String,
        in elements: [AccessibleUIElement],
        preferredRole: String? = nil
    ) -> ElementLocatorMatchResult {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanedQuery.isEmpty else {
            return ElementLocatorMatchResult(bestMatch: nil, allCandidates: [], isAmbiguous: false, clarificationMessage: nil)
        }
        
        var scoredMatches: [ElementMatch] = []
        
        for element in elements {
            let score = calculateScore(for: element, query: cleanedQuery, preferredRole: preferredRole)
            if score >= 0.35 {
                let confidence: ElementMatchConfidence
                if score >= highConfidenceThreshold {
                    confidence = .high
                } else if score >= mediumConfidenceThreshold {
                    confidence = .medium
                } else {
                    confidence = .low
                }
                
                let match = ElementMatch(
                    element: element,
                    score: score,
                    confidence: confidence,
                    reason: "Matched query '\(query)' with score \(String(format: "%.2f", score))"
                )
                scoredMatches.append(match)
            }
        }
        
        // Sort descending by score
        scoredMatches.sort { $0.score > $1.score }
        
        guard let best = scoredMatches.first else {
            return ElementLocatorMatchResult(bestMatch: nil, allCandidates: [], isAmbiguous: false, clarificationMessage: nil)
        }
        
        // Check for ambiguity: multiple matches with very close scores
        if scoredMatches.count > 1 {
            let second = scoredMatches[1]
            if (best.score - second.score) < ambiguityDeltaThreshold && second.score >= mediumConfidenceThreshold {
                let candidatesDesc = scoredMatches.prefix(3).map {
                    "'\($0.element.displayName)' (\($0.element.role))"
                }.joined(separator: ", ")
                let clarification = "Multiple matching controls found: \(candidatesDesc). Which one would you like me to interact with?"
                return ElementLocatorMatchResult(
                    bestMatch: best,
                    allCandidates: scoredMatches,
                    isAmbiguous: true,
                    clarificationMessage: clarification
                )
            }
        }
        
        return ElementLocatorMatchResult(
            bestMatch: best,
            allCandidates: scoredMatches,
            isAmbiguous: false,
            clarificationMessage: nil
        )
    }
    
    // MARK: - Scoring Heuristics
    
    public static func calculateScore(
        for element: AccessibleUIElement,
        query: String,
        preferredRole: String? = nil
    ) -> Double {
        var baseScore: Double = 0.0
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanQuery.isEmpty else { return 0.0 }
        
        let title = element.title?.lowercased() ?? ""
        let label = element.label?.lowercased() ?? ""
        let desc = element.elementDescription?.lowercased() ?? ""
        let val = element.value?.lowercased() ?? ""
        
        // 1. Exact match on title or label
        if title == cleanQuery || label == cleanQuery {
            baseScore = 1.0
        }
        // 2. Starts with query
        else if title.hasPrefix(cleanQuery) || label.hasPrefix(cleanQuery) {
            baseScore = 0.90
        }
        // 3. Contains entire query string
        else if title.contains(cleanQuery) || label.contains(cleanQuery) {
            baseScore = 0.82
        }
        // 4. Description match
        else if desc.contains(cleanQuery) {
            baseScore = 0.72
        }
        // 5. Value match (for text fields / inputs)
        else if val.contains(cleanQuery) {
            baseScore = 0.65
        }
        // 6. Token overlap matching
        else {
            let queryTokens = Set(cleanQuery.split(separator: " ").map { String($0) })
            let elementText = "\(title) \(label) \(desc)".lowercased()
            let elementTokens = Set(elementText.split(separator: " ").map { String($0) })
            
            let intersection = queryTokens.intersection(elementTokens)
            if !queryTokens.isEmpty && !intersection.isEmpty {
                let ratio = Double(intersection.count) / Double(queryTokens.count)
                baseScore = 0.40 + (ratio * 0.35)
            }
        }
        
        // Role bonus or penalty
        if let role = preferredRole?.lowercased(), !role.isEmpty {
            if element.role.lowercased().contains(role) {
                baseScore = min(1.0, baseScore + 0.10)
            } else {
                baseScore = max(0.0, baseScore - 0.15)
            }
        }
        
        // Disabled penalty
        if !element.isEnabled {
            baseScore *= 0.5
        }
        
        return min(1.0, max(0.0, baseScore))
    }
}
