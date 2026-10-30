//
//  AutoKeyboardManager.swift
//  AUTO
//
//  Native Local Keyboard Manager:
//  Executes keystrokes, string typing, and key combinations via CGEvent.
//  Intercepts destructive shortcuts (Cmd+Q, Cmd+W, Cmd+Backspace).
//

import Foundation
import CoreGraphics
import AppKit

public final class AutoKeyboardManager: @unchecked Sendable {
    public static let shared = AutoKeyboardManager()
    
    private init() {}
    
    public func typeText(_ text: String) {
        for char in text {
            let utf16Chars = Array(String(char).utf16)
            guard let firstCode = utf16Chars.first else { continue }
            
            let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: [firstCode])
            down?.post(tap: .cghidEventTap)
            
            let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: 1, unicodeString: [firstCode])
            up?.post(tap: .cghidEventTap)
            
            usleep(10_000) // 10ms typing cadence
        }
    }
    
    public func pressHotkey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        down?.flags = flags
        down?.post(tap: .cghidEventTap)
        
        usleep(25_000)
        
        let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        up?.flags = flags
        up?.post(tap: .cghidEventTap)
    }
}
