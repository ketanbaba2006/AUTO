//
//  AutoToolRegistry.swift
//  AUTO
//
//  Native Local Tool Registry: Catalog of 16+ built-in modular tools
//  across 6 categories that execute 100% locally on macOS without cloud dependency.
//

import Foundation

public struct AutoToolDefinition: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let category: ToolCategory
    public let description: String
    public let parametersSchema: [String: String]
    public let riskLevel: ActionRiskLevel
    
    public init(
        name: String,
        category: ToolCategory,
        description: String,
        parametersSchema: [String: String],
        riskLevel: ActionRiskLevel = .low
    ) {
        self.id = name
        self.name = name
        self.category = category
        self.description = description
        self.parametersSchema = parametersSchema
        self.riskLevel = riskLevel
    }
}

public final class AutoToolRegistry: @unchecked Sendable {
    public static let shared = AutoToolRegistry()
    
    private var tools: [String: AutoToolDefinition] = [:]
    private let lock = NSLock()
    
    private init() {
        registerBuiltInTools()
    }
    
    private func registerBuiltInTools() {
        // 1. Conversation Domain
        register(AutoToolDefinition(
            name: "speak_response",
            category: .conversation,
            description: "Speak text locally to the user using native macOS speech synthesis.",
            parametersSchema: ["text": "String"],
            riskLevel: .low
        ))
        register(AutoToolDefinition(
            name: "request_clarification",
            category: .conversation,
            description: "Ask the user to clarify an ambiguous request.",
            parametersSchema: ["question": "String"],
            riskLevel: .low
        ))
        register(AutoToolDefinition(
            name: "display_notification",
            category: .conversation,
            description: "Post a native notification to the macOS Notification Center.",
            parametersSchema: ["title": "String", "body": "String"],
            riskLevel: .low
        ))
        
        // 2. Screen Intelligence Domain (Local)
        register(AutoToolDefinition(
            name: "capture_screen",
            category: .screenIntelligence,
            description: "Capture the active monitor locally via ScreenCaptureKit.",
            parametersSchema: ["displayIndex": "Int?"],
            riskLevel: .low
        ))
        register(AutoToolDefinition(
            name: "perform_local_ocr",
            category: .screenIntelligence,
            description: "Extract visible text on screen using Apple Vision on-device OCR.",
            parametersSchema: ["roi": "CGRect?"],
            riskLevel: .low
        ))
        register(AutoToolDefinition(
            name: "inspect_active_window",
            category: .screenIntelligence,
            description: "Inspect accessibility hierarchy and metadata of frontmost window.",
            parametersSchema: [:],
            riskLevel: .low
        ))
        
        // 3. Desktop Automation Domain (Local)
        register(AutoToolDefinition(
            name: "move_cursor",
            category: .desktopAutomation,
            description: "Move mouse smoothly to specified desktop coordinates.",
            parametersSchema: ["x": "Double", "y": "Double"],
            riskLevel: .low
        ))
        register(AutoToolDefinition(
            name: "click_element",
            category: .desktopAutomation,
            description: "Click an on-screen element by coordinates or description.",
            parametersSchema: ["x": "Double", "y": "Double", "clickType": "String"],
            riskLevel: .medium
        ))
        register(AutoToolDefinition(
            name: "type_keyboard_text",
            category: .desktopAutomation,
            description: "Type text into currently focused application via CGEvent.",
            parametersSchema: ["text": "String"],
            riskLevel: .medium
        ))
        register(AutoToolDefinition(
            name: "press_hotkey",
            category: .desktopAutomation,
            description: "Execute a keyboard shortcut with modifiers.",
            parametersSchema: ["keyCombo": "String"],
            riskLevel: .medium
        ))
        register(AutoToolDefinition(
            name: "scroll_window",
            category: .desktopAutomation,
            description: "Scroll active view up or down.",
            parametersSchema: ["deltaY": "Double"],
            riskLevel: .low
        ))
        
        // 4. Application Context Domain (Local)
        register(AutoToolDefinition(
            name: "list_running_applications",
            category: .applicationContext,
            description: "List currently active and background apps via NSWorkspace.",
            parametersSchema: [:],
            riskLevel: .low
        ))
        register(AutoToolDefinition(
            name: "activate_application",
            category: .applicationContext,
            description: "Bring a specific application to the front.",
            parametersSchema: ["bundleIdentifier": "String"],
            riskLevel: .low
        ))
        
        // 5. Memory Domain (Local SQLite)
        register(AutoToolDefinition(
            name: "store_local_memory",
            category: .memory,
            description: "Store a preference or context item in local SQLite database.",
            parametersSchema: ["category": "String", "key": "String", "content": "String"],
            riskLevel: .low
        ))
        register(AutoToolDefinition(
            name: "search_local_memory",
            category: .memory,
            description: "Query local memory database for relevant contextual items.",
            parametersSchema: ["query": "String"],
            riskLevel: .low
        ))
        
        // 6. Local Files Domain (Sandboxed)
        register(AutoToolDefinition(
            name: "list_directory",
            category: .localFileOperations,
            description: "List files in ~/Desktop, ~/Downloads, or ~/Documents.",
            parametersSchema: ["path": "String"],
            riskLevel: .low
        ))
        register(AutoToolDefinition(
            name: "read_text_file",
            category: .localFileOperations,
            description: "Preview safe text file contents in authorized folders.",
            parametersSchema: ["path": "String", "maxBytes": "Int?"],
            riskLevel: .low
        ))
    }
    
    public func register(_ tool: AutoToolDefinition) {
        lock.lock()
        defer { lock.unlock() }
        tools[tool.name] = tool
    }
    
    public func getTool(named name: String) -> AutoToolDefinition? {
        lock.lock()
        defer { lock.unlock() }
        return tools[name]
    }
    
    public func allTools() -> [AutoToolDefinition] {
        lock.lock()
        defer { lock.unlock() }
        return Array(tools.values).sorted(by: { $0.name < $1.name })
    }
}
