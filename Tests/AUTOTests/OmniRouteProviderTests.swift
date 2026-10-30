//
//  OmniRouteProviderTests.swift
//  AUTOTests
//
//  Unit tests for OmniRouteProvider endpoint routing, authentication headers,
//  model discovery, and chat completions.
//

import XCTest
@testable import AUTO

final class OmniRouteProviderTests: XCTestCase {
    private var mockKeychain: MockKeychainService!
    private var mockSession: URLSession!
    private var provider: OmniRouteProvider!
    
    override func setUp() {
        super.setUp()
        mockKeychain = MockKeychainService()
        mockSession = MockURLProtocol.makeMockSession()
        try? mockKeychain.save(key: KeychainManager.omniRouteApiKeyAccount, value: "test-omniroute-key", service: KeychainManager.defaultService)
        provider = OmniRouteProvider(keychainService: mockKeychain, session: mockSession)
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.lastInterceptedRequest = nil
        mockKeychain = nil
        provider = nil
        super.tearDown()
    }
    
    func testOmniRouteModelDiscovery() async throws {
        let mockJSON = """
        {
            "object": "list",
            "data": [
                { "id": "llama-3-8b-instruct", "object": "model", "owned_by": "meta" },
                { "id": "qwen-2.5-vl-7b", "object": "model", "owned_by": "alibaba" }
            ]
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-omniroute-key")
            XCTAssertTrue(request.url?.absoluteString.hasSuffix("/models") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockJSON)
        }
        
        let models = try await provider.fetchAvailableModels()
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models[0].id, "llama-3-8b-instruct")
        XCTAssertEqual(models[1].id, "qwen-2.5-vl-7b")
        XCTAssertTrue(models[1].supportsVision)
    }
    
    func testOmniRouteChatCompletions() async throws {
        let mockResponseJSON = """
        {
            "id": "chatcmpl-12345",
            "object": "chat.completion",
            "created": 1700000000,
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "Check the panel at [POINT:0.20,0.30:Sidebar:screen2]."
                    },
                    "finish_reason": "stop"
                }
            ],
            "usage": {
                "prompt_tokens": 15,
                "completion_tokens": 12,
                "total_tokens": 27
            }
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.absoluteString.hasSuffix("/chat/completions") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, mockResponseJSON)
        }
        
        let messages = [AIMessage(role: .user, content: "Where is the sidebar?")]
        let context = AIRequestContext(systemInstruction: "You are AUTO.")
        
        let response = try await provider.generateResponse(messages: messages, context: context)
        
        XCTAssertTrue(response.text.contains("Sidebar"))
        XCTAssertEqual(response.spatialPoints.count, 1)
        XCTAssertEqual(response.spatialPoints.first?.label, "Sidebar")
        XCTAssertEqual(response.spatialPoints.first?.screenIndex, 2)
        XCTAssertEqual(response.tokenUsage?.totalTokens, 27)
    }
    
    func testOmniRouteServerUnavailableMapping() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 502, httpVersion: nil, headerFields: nil)!
            return (response, "Bad Gateway".data(using: .utf8)!)
        }
        
        do {
            _ = try await provider.testConnection()
            XCTFail("Expected serverUnavailable error")
        } catch let error as AUTOError {
            if case .serverUnavailable = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected .serverUnavailable, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

