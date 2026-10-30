//
//  AccessibilityVisualInspector.swift
//  AUTO
//
//  Inspects frontmost applications and accessible UI elements using macOS Accessibility APIs.
//  Supplements visual screenshot analysis with text and structural hierarchy where available.
//

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
public final class AccessibilityVisualInspector: @unchecked Sendable {
    public static let shared = AccessibilityVisualInspector()
    
    public init() {}
    
    /// Inspects the frontmost application, focused window, and element under cursor.
    public func captureVisualContext() -> AccessibilityVisualContext {
        guard AXIsProcessTrusted() else {
            return AccessibilityVisualContext()
        }
        
        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = frontApp?.localizedName
        let bundleID = frontApp?.bundleIdentifier
        _ = bundleID
        
        var windowTitle: String? = nil
        var focusedElementDesc: String? = nil
        var selectedText: String? = nil
        var hoverElementDesc: String? = nil
        
        // 1. Inspect Frontmost App via AX
        if let pid = frontApp?.processIdentifier {
            let appElement = AXUIElementCreateApplication(pid)
            
            // Focused window
            var windowValue: AnyObject?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue) == .success,
               let windowAX = windowValue {
                var titleValue: AnyObject?
                if AXUIElementCopyAttributeValue(windowAX as! AXUIElement, kAXTitleAttribute as CFString, &titleValue) == .success,
                   let titleStr = titleValue as? String {
                    windowTitle = titleStr
                }
            }
            
            // Focused element
            var focusedElementValue: AnyObject?
            if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementValue) == .success,
               let focusedAX = focusedElementValue {
                focusedElementDesc = describeElement(focusedAX as! AXUIElement)
                
                // Selected text
                var selectedTextValue: AnyObject?
                if AXUIElementCopyAttributeValue(focusedAX as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedTextValue) == .success,
                   let textStr = selectedTextValue as? String, !textStr.isEmpty {
                    selectedText = String(textStr.prefix(200))
                }
            }
        }
        
        // 2. Element under cursor
        let mouseLoc = NSEvent.mouseLocation
        let systemWide = AXUIElementCreateSystemWide()
        var elementUnderCursor: AXUIElement?
        
        // Convert bottom-left mouse point to top-left CoreGraphics point for AX
        if let mainScreen = NSScreen.screens.first {
            let flippedY = mainScreen.frame.height - mouseLoc.y
            let result = AXUIElementCopyElementAtPosition(systemWide, Float(mouseLoc.x), Float(flippedY), &elementUnderCursor)
            if result == .success, let axEl = elementUnderCursor {
                hoverElementDesc = describeElement(axEl)
            }
        }
        
        return AccessibilityVisualContext(
            frontmostAppName: appName,
            frontmostWindowTitle: windowTitle,
            focusedElementDescription: focusedElementDesc,
            selectedText: selectedText,
            mouseHoverElement: hoverElementDesc,
            displayIndex: nil
        )
    }
    
    private func describeElement(_ element: AXUIElement) -> String? {
        var roleValue: AnyObject?
        var descValue: AnyObject?
        var titleValue: AnyObject?
        
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descValue)
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        
        let role = (roleValue as? String) ?? "Element"
        let desc = (descValue as? String) ?? (titleValue as? String)
        
        if let d = desc, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(role) (\"\(d)\")"
        }
        return role
    }
}

