//
//  ToolDispatcher.swift
//  AUTO
//
//  Validates, dispatches, and executes tool invocations across Screen, Automation,
//  Memory, Application, and Local File domains with permission checking and cancellation.
//

import AppKit
import Foundation

public final class ToolDispatcher: @unchecked Sendable {
    public static let shared = ToolDispatcher()
    
    private let registry: ToolRegistry
    
    public init(registry: ToolRegistry = .shared) {
        self.registry = registry
    }
    
    /// Executes a registered tool by identifier with structured parameters.
    public func dispatch(toolId: String, parameters: [String: String]) async -> ToolExecutionResult {
        guard let tool = registry.getTool(toolId) else {
            return .failure(toolId: toolId, error: "Tool '\(toolId)' is not registered.")
        }
        
        guard tool.isAvailable else {
            return .failure(toolId: toolId, error: "Tool '\(toolId)' is currently unavailable.")
        }
        
        // 1. Permission Validation
        if let permission = tool.requiredPermission {
            let hasPerm = checkPermission(permission)
            guard hasPerm else {
                return .failure(toolId: toolId, error: "Required permission '\(permission)' is not granted.")
            }
        }
        
        // 2. Execution Routing
        do {
            try Task.checkCancellation()
            let output = try await execute(tool: tool, parameters: parameters)
            return .success(toolId: toolId, output: output)
        } catch is CancellationError {
            return .failure(toolId: toolId, error: "Tool execution was cancelled.")
        } catch {
            return .failure(toolId: toolId, error: error.localizedDescription)
        }
    }
    
    private func checkPermission(_ name: String) -> Bool {
        switch name {
        case "Screen Recording":
            return CGPreflightScreenCaptureAccess()
        case "Accessibility":
            return AXIsProcessTrusted()
        default:
            return true
        }
    }
    
    private func execute(tool: ToolDefinition, parameters: [String: String]) async throws -> [String: String] {
        switch tool.id {
        // Conversation
        case "conversation.send_message":
            let msg = parameters["message"] ?? ""
            await MainActor.run {
                ApplicationState.shared.currentResponseText = msg
            }
            return ["status": "sent", "message": msg]
            
        case "conversation.summarize":
            let turns = await MainActor.run { ConversationMemory.shared.getRecentTurns() }
            let summary = ConversationSummarizer.shared.summarizeTurns(turns)
            return ["summary": summary]
            
        // Screen Intelligence
        case "screen.capture":
            let visual = try await ScreenContextManager.shared.captureCurrentContext(mode: .onDemand)
            return ["status": "captured", "display": visual.displayInfo?.name ?? "Primary"]
            
        case "screen.inspect_elements":
            let elements = await AccessibilityElementManager.shared.discoverElementsInFrontmostApp()
            let countStr = "\(elements.count)"
            let sample = elements.prefix(5).map { $0.displayName }.joined(separator: ", ")
            return ["elementCount": countStr, "sampleElements": sample]
            
        case "screen.get_displays":
            let displays = await MainActor.run { DisplayManager.shared.displays }
            let desc = displays.map { "\($0.name) (\(Int($0.frame.width))x\(Int($0.frame.height)))" }.joined(separator: " | ")
            return ["displays": desc, "count": "\(displays.count)"]
            
        // Desktop Automation
        case "automation.move_cursor":
            guard let xStr = parameters["x"], let yStr = parameters["y"],
                  let x = Double(xStr), let y = Double(yStr) else {
                throw AUTOError.invalidOperation("Missing coordinates x, y")
            }
            let action = AutomationAction(actionType: .moveCursor, targetCoordinates: CGPoint(x: x, y: y), reason: "Agent task cursor move")
            let status = await ActionExecutionManager.shared.executeAction(action)
            return ["status": "\(status)"]
            
        case "automation.click":
            let target = parameters["target"] ?? "Element"
            let action = AutomationAction(actionType: .click, reason: "Click \(target)")
            let status = await ActionExecutionManager.shared.executeAction(action)
            return ["status": "\(status)"]
            
        case "automation.type_text":
            let text = parameters["text"] ?? ""
            let action = AutomationAction(actionType: .typeText, textToType: text, reason: "Type text")
            let status = await ActionExecutionManager.shared.executeAction(action)
            return ["status": "\(status)"]
            
        case "automation.press_key":
            let key = parameters["key"] ?? "Enter"
            let action = AutomationAction(actionType: .pressKey, keyToPress: key, reason: "Press \(key)")
            let status = await ActionExecutionManager.shared.executeAction(action)
            return ["status": "\(status)"]
            
        case "automation.scroll":
            let delta = Int(parameters["deltaY"] ?? "-5") ?? -5
            let action = AutomationAction(actionType: .scroll, scrollDelta: CGPoint(x: 0, y: delta), reason: "Scroll view")
            let status = await ActionExecutionManager.shared.executeAction(action)
            return ["status": "\(status)"]
            
        // Application Context
        case "app.get_frontmost":
            let app = await MainActor.run { NSWorkspace.shared.frontmostApplication?.localizedName ?? "Finder" }
            return ["appName": app]
            
        case "app.list_running":
            let apps = await MainActor.run {
                NSWorkspace.shared.runningApplications
                    .filter { $0.activationPolicy == .regular }
                    .compactMap { $0.localizedName }
                    .prefix(12)
                    .joined(separator: ", ")
            }
            return ["runningApps": apps]
            
        case "app.activate":
            let name = parameters["appName"] ?? ""
            let success = await MainActor.run { () -> Bool in
                if let targetApp = NSWorkspace.shared.runningApplications.first(where: {
                    $0.localizedName?.localizedCaseInsensitiveContains(name) == true
                }) {
                    return targetApp.activate()
                }
                return false
            }
            return ["activated": "\(success)"]
            
        // Memory
        case "memory.store":
            let catStr = parameters["category"] ?? "userPreferences"
            let key = parameters["key"] ?? "preference"
            let content = parameters["content"] ?? ""
            let category = MemoryCategory(rawValue: catStr) ?? .userPreferences
            let stored = MemoryManager.shared.store(category: category, key: key, content: content)
            return ["stored": stored != nil ? "true" : "false"]
            
        case "memory.retrieve":
            let query = parameters["query"] ?? ""
            let results = MemoryManager.shared.search(query: query, limit: 3)
            let desc = results.map { "\($0.key): \($0.content)" }.joined(separator: " | ")
            return ["results": desc]
            
        case "memory.delete":
            let idStr = parameters["id"] ?? ""
            if let uuid = UUID(uuidString: idStr) {
                MemoryManager.shared.delete(id: uuid)
                return ["deleted": "true"]
            }
            return ["deleted": "false"]
            
        // Local File Operations
        case "files.list":
            let path = parameters["path"] ?? "~/Desktop"
            let files = try LocalFileManager.shared.listFilesInDirectory(atPath: path, maxItems: 20)
            let fileList = files.map { $0.name }.joined(separator: ", ")
            return ["files": fileList, "count": "\(files.count)"]
            
        case "files.read_preview":
            let path = parameters["path"] ?? ""
            let preview = try LocalFileManager.shared.readFilePreview(atPath: path)
            return ["preview": preview]
            
        case "files.organize":
            let source = parameters["source"] ?? ""
            let dest = parameters["destinationFolder"] ?? ""
            try LocalFileManager.shared.moveFile(from: source, to: dest)
            return ["status": "moved", "source": source, "destination": dest]
            
        default:
            throw AUTOError.invalidOperation("Unhandled tool operation: \(tool.id)")
        }
    }
}
