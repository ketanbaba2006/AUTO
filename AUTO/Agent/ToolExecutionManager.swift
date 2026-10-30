//
//  ToolExecutionManager.swift
//  AUTO
//
//  Interface for computer guidance actions, tool invocations, and dispatch routing.
//

import Foundation

public protocol ToolExecutionService: AnyObject, Sendable {
    func executeTool(name: String, parameters: [String: Any]) async throws -> [String: Any]
}

public final class ToolExecutionManager: ToolExecutionService, @unchecked Sendable {
    public static let shared = ToolExecutionManager()
    
    private let dispatcher: ToolDispatcher
    
    public init(dispatcher: ToolDispatcher = .shared) {
        self.dispatcher = dispatcher
    }
    
    public func executeTool(name: String, parameters: [String: Any]) async throws -> [String: Any] {
        AppLogger.shared.info("Tool execution requested: \(name)", category: .agent)
        
        var stringParams: [String: String] = [:]
        for (k, v) in parameters {
            stringParams[k] = "\(v)"
        }
        
        let result = await dispatcher.dispatch(toolId: name, parameters: stringParams)
        if result.isSuccess {
            var outputDict: [String: Any] = result.output
            outputDict["status"] = "success"
            return outputDict
        } else {
            throw AUTOError.internalError(result.errorMessage ?? "Tool execution failed")
        }
    }
}
