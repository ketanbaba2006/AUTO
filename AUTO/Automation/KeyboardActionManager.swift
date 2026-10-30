//
//  KeyboardActionManager.swift
//  AUTO
//
//  Simulates native keyboard strokes, key combinations, and text entry using CoreGraphics.
//  Enforces strict safety rules against password leakage and unverified field input.
//

import AppKit
import CoreGraphics
import Foundation

public protocol KeyboardActionService: AnyObject, Sendable {
    func typeText(_ text: String, obfuscatedInLogs: Bool) async throws
    func pressKey(virtualKey: CGKeyCode, flags: CGEventFlags) async throws
    func pressNamedKey(_ keyName: String) async throws
    func releaseHeldKeys()
}

public final class KeyboardActionManager: KeyboardActionService, @unchecked Sendable {
    public static let shared = KeyboardActionManager()
    
    public var isMockMode: Bool = false
    public private(set) var executedEvents: [String] = []
    
    private let eventSource = CGEventSource(stateID: .combinedSessionState)
    
    public init() {}
    
    // MARK: - Virtual Key Codes
    public enum KeyCode: CGKeyCode {
        case returnKey = 0x24
        case tab = 0x30
        case space = 0x31
        case delete = 0x33
        case escape = 0x35
        case command = 0x37
        case shift = 0x38
        case option = 0x3A
        case control = 0x3B
        case leftArrow = 0x7B
        case rightArrow = 0x7C
        case downArrow = 0x7D
        case upArrow = 0x7E
    }
    
    // MARK: - Text Typing
    
    /// Types text into the currently focused element.
    /// Obfuscates content in logging to protect user privacy.
    public func typeText(_ text: String, obfuscatedInLogs: Bool = false) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        guard !text.isEmpty else { return }
        
        // Safety guard against dangerous shell scripts or command injections
        if isPotentiallyDestructiveCommand(text) {
            throw AUTOError.invalidOperation("Execution blocked: text contains potentially destructive command syntax.")
        }
        
        let logText = obfuscatedInLogs ? "••••••••" : (text.count > 30 ? String(text.prefix(30)) + "..." : text)
        AppLogger.shared.info("Typing text (\(text.count) characters): \(logText)", category: .cursor)
        
        if isMockMode {
            executedEvents.append("typeText(\(logText))")
            return
        }
        
        // Type characters using CGEvent keyboard events with UTF-16 characters
        for char in text {
            try Task.checkCancellation()
            
            let utf16Chars = Array(String(char).utf16)
            
            guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false) else {
                continue
            }
            
            keyDown.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
            keyUp.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: utf16Chars)
            
            keyDown.post(tap: .cghidEventTap)
            try await Task.sleep(nanoseconds: 15_000_000) // 15ms key hold
            keyUp.post(tap: .cghidEventTap)
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms between keystrokes
        }
    }
    
    // MARK: - Key Pressing
    
    public func pressKey(virtualKey: CGKeyCode, flags: CGEventFlags = []) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        
        if isMockMode {
            executedEvents.append("pressKey(\(virtualKey), flags: \(flags.rawValue))")
            return
        }
        
        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: virtualKey, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: virtualKey, keyDown: false) else {
            throw AUTOError.internalError("Failed to create keyboard CGEvent for keyCode: \(virtualKey)")
        }
        
        keyDown.flags = flags
        keyUp.flags = flags
        
        keyDown.post(tap: .cghidEventTap)
        try await Task.sleep(nanoseconds: 30_000_000)
        keyUp.post(tap: .cghidEventTap)
    }
    
    public func pressNamedKey(_ keyName: String) async throws {
        let lower = keyName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch lower {
        case "enter", "return":
            try await pressKey(virtualKey: KeyCode.returnKey.rawValue)
        case "tab":
            try await pressKey(virtualKey: KeyCode.tab.rawValue)
        case "escape", "esc":
            try await pressKey(virtualKey: KeyCode.escape.rawValue)
        case "space":
            try await pressKey(virtualKey: KeyCode.space.rawValue)
        case "delete", "backspace":
            try await pressKey(virtualKey: KeyCode.delete.rawValue)
        case "left", "leftarrow":
            try await pressKey(virtualKey: KeyCode.leftArrow.rawValue)
        case "right", "rightarrow":
            try await pressKey(virtualKey: KeyCode.rightArrow.rawValue)
        case "up", "uparrow":
            try await pressKey(virtualKey: KeyCode.upArrow.rawValue)
        case "down", "downarrow":
            try await pressKey(virtualKey: KeyCode.downArrow.rawValue)
        default:
            throw AUTOError.invalidOperation("Unsupported named key: \(keyName)")
        }
    }
    
    // MARK: - Common Shortcuts
    
    public func triggerShortcut(key: CGKeyCode, modifiers: CGEventFlags) async throws {
        // Block dangerous global shortcuts
        if modifiers.contains(.maskCommand) && (key == 0x0C /* Q - Quit */ || key == 0x0D /* W - Close */) {
            throw AUTOError.invalidOperation("Destructive shortcut Cmd+Q/Cmd+W requires explicit high-risk confirmation.")
        }
        try await pressKey(virtualKey: key, flags: modifiers)
    }
    
    public func releaseHeldKeys() {
        if isMockMode {
            executedEvents.append("releaseHeldKeys()")
        }
        // Send keyUp for modifier keys
        let modifiers: [CGKeyCode] = [
            KeyCode.command.rawValue,
            KeyCode.shift.rawValue,
            KeyCode.option.rawValue,
            KeyCode.control.rawValue
        ]
        for key in modifiers {
            if let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: key, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
            }
        }
    }
    
    public func clearMockEvents() {
        executedEvents.removeAll()
    }
    
    private func isPotentiallyDestructiveCommand(_ text: String) -> Bool {
        let dangerousSubstrings = ["rm -rf", "sudo ", "mkfs", ":(){ :|:& };:", "> /dev/sda", "chmod -R 777 /"]
        return dangerousSubstrings.contains { text.contains($0) }
    }
}
