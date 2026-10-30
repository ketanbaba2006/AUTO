//
//  GeminiProviderTests.swift
//  AUTOTests
//
//  Unit tests for GeminiProvider request generation, response parsing,
//  token usage, retries, and error handling.
//

import XCTest
@testable import AUTO

final class GeminiProviderTests: XCTestCase {
    private var mockKeychain: MockKeychainService!
    private var mockSession: URLSession!
    private var provider: GeminiProvider!
    
    override func setUp() {
        super.setUp()
        mockKeychain = MockKeychainService()
        mockSession = MockURLProtocol.makeMockSession()
        try? mockKeychain.save(key: KeychainManager.geminiApiKeyAccount, value: "test-gemini-key", service: KeychainManager.defaultService)
        provider = GeminiProvider(keychainService: mockKeychain, session: mockSession)
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.lastInterceptedRequest = nil
        mockKeychain = nil
        provider = nil
        super.tearDown()
    }
    
    func testGeminiConnectionSuccess() async throws {
        let mockJSON = """
        {
            "models": [
                { "name": "models/gemini-2.5-flash", "displayName": "Gemini 2.5 Flash", "supportedGenerationMethods": ["generateContent"] }
            ]
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("key=test-gemini-key") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockJSON)
        }
        
        let success = try await provider.testConnection()
        XCTAssertTrue(success)
    }
    
    func testGeminiModelDiscovery() async throws {
        let mockJSON = """
        {
            "models": [
                { "name": "models/gemini-2.5-flash", "displayName": "Gemini 2.5 Flash", "inputTokenLimit": 1000000, "supportedGenerationMethods": ["generateContent"] },
                { "name": "models/gemini-2.5-pro", "displayName": "Gemini 2.5 Pro", "inputTokenLimit": 2000000, "supportedGenerationMethods": ["generateContent"] }
            ]
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockJSON)
        }
        
        let models = try await provider.fetchAvailableModels()
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models[0].id, "gemini-2.5-flash")
        XCTAssertEqual(models[1].id, "gemini-2.5-pro")
        XCTAssertTrue(models[0].supportsVision)
    }
    
    func testGeminiGenerateResponseWithSpatialPointsAndTokens() async throws {
        let mockResponseJSON = """
        {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            { "text": "Click the button at [POINT:0.45,0.72:Submit Button:screen1] to continue." }
                        ],
                        "role": "model"
                    },
                    "finishReason": "STOP"
                }
            ],
            "usageMetadata": {
                "promptTokenCount": 24,
                "candidatesTokenCount": 16,
                "totalTokenCount": 40
            }
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockResponseJSON)
        }
        
        let messages = [AIMessage(role: .user, content: "Where do I submit?")]
        let context = AIRequestContext(systemInstruction: "You are AUTO.")
        
        let response = try await provider.generateResponse(messages: messages, context: context)
        
        XCTAssertTrue(response.text.contains("Submit Button"))
        XCTAssertEqual(response.spatialPoints.count, 1)
        XCTAssertEqual(response.spatialPoints.first?.label, "Submit Button")
        XCTAssertEqual(response.spatialPoints.first?.x, 0.45)
        XCTAssertEqual(response.spatialPoints.first?.y, 0.72)
        XCTAssertEqual(response.spatialPoints.first?.screenIndex, 1)
        XCTAssertEqual(response.tokenUsage?.totalTokens, 40)
    }
    
    func testGeminiAuthErrorMapping() async {
        let errorJSON = """
        {
            "error": {
                "code": 403,
                "message": "The caller does not have permission",
                "status": "PERMISSION_DENIED"
            }
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        }
        
        do {
            _ = try await provider.testConnection()
            XCTFail("Expected authenticationFailed error")
        } catch let error as AUTOError {
            if case .authenticationFailed = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected .authenticationFailed, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testGeminiRateLimitErrorMapping() async {
        let errorJSON = """
        {
            "error": { "code": 429, "message": "Resource exhausted" }
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, errorJSON)
        }
        
        do {
            _ = try await provider.generateResponse(messages: [AIMessage(role: .user, content: "hi")], context: AIRequestContext())
            XCTFail("Expected rateLimitExceeded error")
        } catch let error as AUTOError {
            if case .rateLimitExceeded = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected .rateLimitExceeded, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

