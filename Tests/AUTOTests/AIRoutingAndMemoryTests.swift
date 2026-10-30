//
//  AIRoutingAndMemoryTests.swift
//  AUTOTests
//
//  Unit tests for Task-based routing, fallback resolution, PromptManager,
//  SpatialPoint parser, and ConversationMemory.
//

import XCTest
@testable import AUTO

final class AIRoutingAndMemoryTests: XCTestCase {
    
    func testSpatialPointParsing() {
        let text = """
        I found the icon! Click here [POINT:0.12,0.88:Safari Icon:screen1] \
        or look at the other display [POINT:0.50,0.50:Center Window:screen2].
        """
        
        let points = SpatialPoint.parsePoints(from: text)
        XCTAssertEqual(points.count, 2)
        
        XCTAssertEqual(points[0].x, 0.12)
        XCTAssertEqual(points[0].y, 0.88)
        XCTAssertEqual(points[0].label, "Safari Icon")
        XCTAssertEqual(points[0].screenIndex, 1)
        
        XCTAssertEqual(points[1].x, 0.50)
        XCTAssertEqual(points[1].y, 0.50)
        XCTAssertEqual(points[1].label, "Center Window")
        XCTAssertEqual(points[1].screenIndex, 2)
    }
    
    func testPromptManagerTemplates() {
        let manager = PromptManager.shared
        let generalPrompt = manager.prompt(for: .generalConversation)
        XCTAssertTrue(generalPrompt.contains("AUTO"))
        XCTAssertTrue(generalPrompt.contains("General Desktop Assistance"))
        
        let screenPrompt = manager.prompt(for: .screenUnderstanding)
        XCTAssertTrue(screenPrompt.contains("Screen Understanding"))
        XCTAssertTrue(screenPrompt.contains("Carefully examine the attached screenshot"))
        
        let pointingPrompt = manager.prompt(for: .cursorPointing)
        XCTAssertTrue(pointingPrompt.contains("[POINT:x,y:Target Description:screenN]"))
    }
    
    func testConversationMemoryLimits() {
        let memory = ConversationMemory()
        memory.clear()
        
        for i in 1...15 {
            let turn = ConversationTurn(
                userTranscript: "Question \(i)",
                assistantResponse: "Answer \(i)"
            )
            memory.addTurn(turn, maxLimit: 5)
        }
        
        let recent = memory.getRecentTurns()
        XCTAssertEqual(recent.count, 5)
        XCTAssertEqual(recent.first?.userTranscript, "Question 11")
        XCTAssertEqual(recent.last?.userTranscript, "Question 15")
        
        let aiHistory = memory.getAIMessagesHistory(limit: 5)
        XCTAssertEqual(aiHistory.count, 10) // 5 user + 5 assistant
        XCTAssertEqual(aiHistory.first?.role, .user)
        XCTAssertEqual(aiHistory.first?.content, "Question 11")
    }
    
    @MainActor
    func testAIRoutingRules() {
        let appState = ApplicationState.shared
        appState.aiRoutingRules = AIRoutingRule.defaultRules()
        
        let providerManager = AIProviderManager.shared
        
        // Main conversation should default to Gemini
        let mainProvider = providerManager.resolveProvider(for: .mainConversation)
        XCTAssertEqual(mainProvider.providerType, .gemini)
        
        // Screen understanding should default to Gemini
        let screenProvider = providerManager.resolveProvider(for: .screenUnderstanding)
        XCTAssertEqual(screenProvider.providerType, .gemini)
    }
}

