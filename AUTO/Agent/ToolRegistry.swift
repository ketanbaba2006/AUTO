//
//  ToolRegistry.swift
//  AUTO
//
//  Central registry of all modular capabilities exposed to the autonomous agent.
//  Defines tool specifications, schemas, required permissions, and risk tiers.
//

import Foundation

public final class ToolRegistry: @unchecked Sendable {
    public static let shared = ToolRegistry()
    
    private var tools: [String: ToolDefinition] = [:]
    private let lock = NSLock()
    
    public init() {
        registerBuiltinTools()
    }
    
    public func register(_ tool: ToolDefinition) {
        lock.lock()
        defer { lock.unlock() }
        tools[tool.id] = tool
    }
    
    public func getTool(_ id: String) -> ToolDefinition? {
        lock.lock()
        defer { lock.unlock() }
        return tools[id]
    }
    
    public func allTools() -> [ToolDefinition] {
        lock.lock()
        defer { lock.unlock() }
        return Array(tools.values)
    }
    
    public func tools(inCategory category: ToolCategory) -> [ToolDefinition] {
        lock.lock()
        defer { lock.unlock() }
        return tools.values.filter { $0.category == category }
    }
    
    // MARK: - Built-in Tools Registration
    
    private func registerBuiltinTools() {
        // A. Conversation
        register(ToolDefinition(
            id: "conversation.send_message",
            category: .conversation,
            name: "Send Message",
            toolDescription: "Sends conversational dialogue or clarification to the user.",
            parametersSchema: ["message": "String"],
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "conversation.summarize",
            category: .conversation,
            name: "Summarize Conversation",
            toolDescription: "Summarizes earlier dialogue turns.",
            parametersSchema: ["limit": "Int"],
            riskLevel: .low
        ))
        
        // B. Screen Intelligence
        register(ToolDefinition(
            id: "screen.capture",
            category: .screenIntelligence,
            name: "Capture Screenshot",
            toolDescription: "Captures fresh visual context from the authorized display.",
            requiredPermission: "Screen Recording",
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "screen.inspect_elements",
            category: .screenIntelligence,
            name: "Inspect Accessible Elements",
            toolDescription: "Queries UI controls in the frontmost application.",
            requiredPermission: "Accessibility",
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "screen.get_displays",
            category: .screenIntelligence,
            name: "Get Displays",
            toolDescription: "Retrieves display geometries and resolution scaling.",
            riskLevel: .low
        ))
        
        // C. Desktop Automation
        register(ToolDefinition(
            id: "automation.move_cursor",
            category: .desktopAutomation,
            name: "Move Cursor",
            toolDescription: "Moves mouse cursor to coordinate x, y.",
            parametersSchema: ["x": "Double", "y": "Double"],
            requiredPermission: "Accessibility",
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "automation.click",
            category: .desktopAutomation,
            name: "Click Element",
            toolDescription: "Clicks an accessible element or screen coordinate.",
            parametersSchema: ["target": "String"],
            requiredPermission: "Accessibility",
            riskLevel: .medium
        ))
        register(ToolDefinition(
            id: "automation.type_text",
            category: .desktopAutomation,
            name: "Type Text",
            toolDescription: "Types text into the currently focused control.",
            parametersSchema: ["text": "String"],
            requiredPermission: "Accessibility",
            riskLevel: .medium
        ))
        register(ToolDefinition(
            id: "automation.press_key",
            category: .desktopAutomation,
            name: "Press Key",
            toolDescription: "Presses a named virtual key (Enter, Tab, Esc, Space).",
            parametersSchema: ["key": "String"],
            requiredPermission: "Accessibility",
            riskLevel: .medium
        ))
        register(ToolDefinition(
            id: "automation.scroll",
            category: .desktopAutomation,
            name: "Scroll View",
            toolDescription: "Scrolls the frontmost view vertically.",
            parametersSchema: ["deltaY": "Int"],
            requiredPermission: "Accessibility",
            riskLevel: .low
        ))
        
        // D. Application Context
        register(ToolDefinition(
            id: "app.get_frontmost",
            category: .applicationContext,
            name: "Get Frontmost App",
            toolDescription: "Identifies the currently active application and window.",
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "app.list_running",
            category: .applicationContext,
            name: "List Running Apps",
            toolDescription: "Returns list of active macOS application names.",
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "app.activate",
            category: .applicationContext,
            name: "Activate App",
            toolDescription: "Brings a named application to the foreground.",
            parametersSchema: ["appName": "String"],
            riskLevel: .medium
        ))
        
        // E. Memory
        register(ToolDefinition(
            id: "memory.store",
            category: .memory,
            name: "Store Memory",
            toolDescription: "Stores a user preference or project context permanently.",
            parametersSchema: ["category": "String", "key": "String", "content": "String"],
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "memory.retrieve",
            category: .memory,
            name: "Retrieve Memory",
            toolDescription: "Retrieves stored memories matching a query.",
            parametersSchema: ["query": "String"],
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "memory.delete",
            category: .memory,
            name: "Delete Memory",
            toolDescription: "Deletes a specific stored memory item.",
            parametersSchema: ["id": "String"],
            riskLevel: .low
        ))
        
        // F. Local File Operations
        register(ToolDefinition(
            id: "files.list",
            category: .localFileOperations,
            name: "List Files",
            toolDescription: "Lists files in an authorized directory (e.g., Desktop).",
            parametersSchema: ["path": "String"],
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "files.read_preview",
            category: .localFileOperations,
            name: "Read File Preview",
            toolDescription: "Reads preview content of a permitted text file.",
            parametersSchema: ["path": "String"],
            riskLevel: .low
        ))
        register(ToolDefinition(
            id: "files.organize",
            category: .localFileOperations,
            name: "Organize File",
            toolDescription: "Moves a file to a designated folder with approval.",
            parametersSchema: ["source": "String", "destinationFolder": "String"],
            riskLevel: .high
        ))
    }
}

