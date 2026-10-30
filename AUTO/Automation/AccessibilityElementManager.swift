//
//  AccessibilityElementManager.swift
//  AUTO
//
//  Discovers, traverses, and queries accessible UI elements across running applications
//  using macOS Accessibility APIs (AXUIElement).
//

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

public protocol AccessibilityElementService: Sendable {
    func discoverElements(forApplicationPID pid: pid_t, maxDepth: Int, maxElements: Int) async -> [AccessibleUIElement]
    func discoverElementsInFrontmostApp(maxDepth: Int, maxElements: Int) async -> [AccessibleUIElement]
    func findElementAtPosition(_ point: CGPoint) -> AccessibleUIElement?
}

public final class AccessibilityElementManager: AccessibilityElementService, @unchecked Sendable {
    public static let shared = AccessibilityElementManager()
    
    public init() {}
    
    // MARK: - Discovery
    
    /// Discovers accessible UI elements in the frontmost application.
    public func discoverElementsInFrontmostApp(maxDepth: Int = 4, maxElements: Int = 150) async -> [AccessibleUIElement] {
        let frontApp = await MainActor.run { NSWorkspace.shared.frontmostApplication }
        guard let frontApp = frontApp else {
            return []
        }
        return await discoverElements(forApplicationPID: frontApp.processIdentifier, maxDepth: maxDepth, maxElements: maxElements)
    }
    
    /// Recursively discovers elements from an application's root element.
    public func discoverElements(
        forApplicationPID pid: pid_t,
        maxDepth: Int = 4,
        maxElements: Int = 150
    ) async -> [AccessibleUIElement] {
        guard AXIsProcessTrusted() else {
            AppLogger.shared.warning("Accessibility permission missing. Skipping AX element discovery.", category: .cursor)
            return []
        }
        
        let appElement = AXUIElementCreateApplication(pid)
        let runningApp = NSRunningApplication(processIdentifier: pid)
        let appName = runningApp?.localizedName ?? "Application"
        
        var results: [AccessibleUIElement] = []
        var windowTitle: String? = nil
        
        // Retrieve focused window title
        var focusedWindowValue: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowValue) == .success,
           let windowAX = focusedWindowValue {
            var titleValue: AnyObject?
            if AXUIElementCopyAttributeValue(windowAX as! AXUIElement, kAXTitleAttribute as CFString, &titleValue) == .success,
               let str = titleValue as? String {
                windowTitle = str
            }
        }
        
        // Traverse tree
        traverse(
            element: appElement,
            depth: 0,
            maxDepth: maxDepth,
            maxElements: maxElements,
            appName: appName,
            windowTitle: windowTitle,
            results: &results
        )
        
        return results
    }
    
    /// Finds the accessible element directly under the given CoreGraphics desktop coordinate.
    public func findElementAtPosition(_ point: CGPoint) -> AccessibleUIElement? {
        guard AXIsProcessTrusted() else { return nil }
        
        let systemWide = AXUIElementCreateSystemWide()
        var hitElement: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &hitElement)
        
        guard result == .success, let axElement = hitElement else {
            return nil
        }
        
        return parseAccessibleElement(axElement, appName: nil, windowTitle: nil)
    }
    
    // MARK: - Element Tree Traversal
    
    private func traverse(
        element: AXUIElement,
        depth: Int,
        maxDepth: Int,
        maxElements: Int,
        appName: String,
        windowTitle: String?,
        results: inout [AccessibleUIElement]
    ) {
        guard depth <= maxDepth, results.count < maxElements else { return }
        
        // Extract current element if relevant
        if let parsed = parseAccessibleElement(element, appName: appName, windowTitle: windowTitle), isInteractiveRole(parsed.role) {
            results.append(parsed)
        }
        
        // Retrieve children
        var childrenValue: AnyObject?
        let copyResult = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenValue)
        guard copyResult == .success, let children = childrenValue as? [AXUIElement] else {
            return
        }
        
        for child in children {
            if results.count >= maxElements { break }
            traverse(
                element: child,
                depth: depth + 1,
                maxDepth: maxDepth,
                maxElements: maxElements,
                appName: appName,
                windowTitle: windowTitle,
                results: &results
            )
        }
    }
    
    // MARK: - Parsing AXUIElement Attributes
    
    public func parseAccessibleElement(
        _ element: AXUIElement,
        appName: String?,
        windowTitle: String?
    ) -> AccessibleUIElement? {
        // Role
        var roleValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        let role = (roleValue as? String) ?? "AXUnknown"
        
        // Title
        var titleValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
        let title = titleValue as? String
        
        // Description
        var descValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descValue)
        let description = descValue as? String
        
        // Value
        var valValue: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valValue)
        let value = (valValue as? String)
        
        // Position & Size -> Frame
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        var frame = CGRect.zero
        
        if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
           let posVal = positionValue, CFGetTypeID(posVal) == AXValueGetTypeID() {
            var point = CGPoint.zero
            if AXValueGetValue(posVal as! AXValue, .cgPoint, &point) {
                frame.origin = point
            }
        }
        
        if AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
           let sVal = sizeValue, CFGetTypeID(sVal) == AXValueGetTypeID() {
            var size = CGSize.zero
            if AXValueGetValue(sVal as! AXValue, .cgSize, &size) {
                frame.size = size
            }
        }
        
        // Enabled state
        var enabledValue: AnyObject?
        var isEnabled = true
        if AXUIElementCopyAttributeValue(element, kAXEnabledAttribute as CFString, &enabledValue) == .success,
           let boolVal = enabledValue as? Bool {
            isEnabled = boolVal
        }
        
        // Focused state
        var focusedValue: AnyObject?
        var isFocused = false
        if AXUIElementCopyAttributeValue(element, kAXFocusedAttribute as CFString, &focusedValue) == .success,
           let boolVal = focusedValue as? Bool {
            isFocused = boolVal
        }
        
        // Supported Actions
        var actionsValue: CFArray?
        var supportedActions: [String] = []
        if AXUIElementCopyActionNames(element, &actionsValue) == .success,
           let actionsList = actionsValue as? [String] {
            supportedActions = actionsList
        }
        
        return AccessibleUIElement(
            role: role,
            title: title,
            elementDescription: description,
            label: nil,
            value: value,
            frame: frame,
            isEnabled: isEnabled,
            isFocused: isFocused,
            supportedActions: supportedActions,
            windowTitle: windowTitle,
            appName: appName
        )
    }
    
    private func isInteractiveRole(_ role: String) -> Bool {
        let interactiveRoles: Set<String> = [
            "AXButton", "AXTextField", "AXTextArea", "AXSearchField", "AXCheckBox",
            "AXRadioButton", "AXPopUpButton", "AXMenuButton", "AXMenuItem", "AXMenu",
            "AXTabGroup", "AXRadioButton", "AXLink", "AXSlider", "AXComboBox",
            "AXCell", "AXRow", "AXOutline", "AXTable", "AXScrollArea"
        ]
        return interactiveRoles.contains(role)
    }
}
