//
//  MouseActionManager.swift
//  AUTO
//
//  Native macOS mouse movement, clicking, dragging, and scrolling engine using CoreGraphics CGEvent.
//  Includes safety button release, smooth Bezier interpolation, and mock mode for unit tests.
//

import AppKit
import CoreGraphics
import Foundation

public protocol MouseActionService: AnyObject, Sendable {
    func moveCursor(to point: CGPoint, animated: Bool) async throws
    func click(at point: CGPoint?) async throws
    func doubleClick(at point: CGPoint?) async throws
    func rightClick(at point: CGPoint?) async throws
    func mouseDown(button: CGMouseButton, at point: CGPoint?) async throws
    func mouseUp(button: CGMouseButton, at point: CGPoint?) async throws
    func scroll(deltaY: Int32, deltaX: Int32) async throws
    func drag(from start: CGPoint, to end: CGPoint) async throws
    func releaseHeldButtons()
}

public final class MouseActionManager: MouseActionService, @unchecked Sendable {
    public static let shared = MouseActionManager()
    
    /// Test hook: When true, CGEvent posting is bypassed and events are recorded into executedEvents.
    public var isMockMode: Bool = false
    public private(set) var executedEvents: [String] = []
    public private(set) var heldMouseButton: CGMouseButton? = nil
    private let eventSource = CGEventSource(stateID: .combinedSessionState)
    
    public init() {}
    
    // MARK: - Cursor Movement
    
    public func moveCursor(to point: CGPoint, animated: Bool = true) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        
        let startPoint = NSEvent.mouseLocation
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080.0
        let cgStart = CoordinateMapper.appKitToCoreGraphicsGlobal(appKitPoint: startPoint, primaryScreenHeight: primaryHeight)
        
        if isMockMode {
            executedEvents.append("moveCursor(\(point.x), \(point.y))")
            return
        }
        
        if !animated {
            postMouseEvent(type: .mouseMoved, point: point, button: .left)
            return
        }
        
        // Smooth Bezier interpolation over 12-18 steps
        let steps = 14
        let controlPoint = CursorAnimationManager.calculateArcControlPoint(from: cgStart, to: point, arcHeight: 40.0)
        
        for i in 1...steps {
            try Task.checkCancellation()
            let t = CGFloat(i) / CGFloat(steps)
            let stepPoint = CursorAnimationManager.evaluateBezier(p0: cgStart, p1: controlPoint, p2: point, t: t)
            postMouseEvent(type: .mouseMoved, point: stepPoint, button: .left)
            try await Task.sleep(nanoseconds: 12_000_000) // 12ms per step (~168ms total)
        }
        
        // Final position assurance
        postMouseEvent(type: .mouseMoved, point: point, button: .left)
    }
    
    // MARK: - Clicking
    
    public func click(at point: CGPoint? = nil) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        let target = point ?? currentMouseCGLocation()
        
        if isMockMode {
            executedEvents.append("click(\(target.x), \(target.y))")
            return
        }
        
        // Mouse down
        postMouseEvent(type: .leftMouseDown, point: target, button: .left)
        try await Task.sleep(nanoseconds: 40_000_000) // 40ms click duration
        // Mouse up
        postMouseEvent(type: .leftMouseUp, point: target, button: .left)
    }
    
    public func doubleClick(at point: CGPoint? = nil) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        let target = point ?? currentMouseCGLocation()
        
        if isMockMode {
            executedEvents.append("doubleClick(\(target.x), \(target.y))")
            return
        }
        
        // First click
        postMouseEvent(type: .leftMouseDown, point: target, button: .left, clickCount: 1)
        postMouseEvent(type: .leftMouseUp, point: target, button: .left, clickCount: 1)
        try await Task.sleep(nanoseconds: 60_000_000) // 60ms gap
        // Second click
        postMouseEvent(type: .leftMouseDown, point: target, button: .left, clickCount: 2)
        postMouseEvent(type: .leftMouseUp, point: target, button: .left, clickCount: 2)
    }
    
    public func rightClick(at point: CGPoint? = nil) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        let target = point ?? currentMouseCGLocation()
        
        if isMockMode {
            executedEvents.append("rightClick(\(target.x), \(target.y))")
            return
        }
        
        postMouseEvent(type: .rightMouseDown, point: target, button: .right)
        try await Task.sleep(nanoseconds: 40_000_000)
        postMouseEvent(type: .rightMouseUp, point: target, button: .right)
    }
    
    // MARK: - State-Managed Mouse Down / Up
    
    public func mouseDown(button: CGMouseButton = .left, at point: CGPoint? = nil) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        let target = point ?? currentMouseCGLocation()
        
        if isMockMode {
            executedEvents.append("mouseDown(\(button.rawValue), \(target.x), \(target.y))")
            heldMouseButton = button
            return
        }
        
        let type: CGEventType = (button == .left) ? .leftMouseDown : .rightMouseDown
        postMouseEvent(type: type, point: target, button: button)
        heldMouseButton = button
    }
    
    public func mouseUp(button: CGMouseButton = .left, at point: CGPoint? = nil) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        let target = point ?? currentMouseCGLocation()
        
        if isMockMode {
            executedEvents.append("mouseUp(\(button.rawValue), \(target.x), \(target.y))")
            heldMouseButton = nil
            return
        }
        
        let type: CGEventType = (button == .left) ? .leftMouseUp : .rightMouseUp
        postMouseEvent(type: type, point: target, button: button)
        heldMouseButton = nil
    }
    
    // MARK: - Dragging
    
    public func drag(from start: CGPoint, to end: CGPoint) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        
        if isMockMode {
            executedEvents.append("drag(from: (\(start.x), \(start.y)), to: (\(end.x), \(end.y)))")
            return
        }
        
        // Move to start
        postMouseEvent(type: .mouseMoved, point: start, button: .left)
        try await Task.sleep(nanoseconds: 30_000_000)
        
        // Mouse down
        postMouseEvent(type: .leftMouseDown, point: start, button: .left)
        heldMouseButton = .left
        try await Task.sleep(nanoseconds: 50_000_000)
        
        // Smooth drag
        let steps = 10
        for i in 1...steps {
            try Task.checkCancellation()
            let t = CGFloat(i) / CGFloat(steps)
            let current = CGPoint(
                x: start.x + (end.x - start.x) * t,
                y: start.y + (end.y - start.y) * t
            )
            postMouseEvent(type: .leftMouseDragged, point: current, button: .left)
            try await Task.sleep(nanoseconds: 15_000_000)
        }
        
        // Mouse up
        postMouseEvent(type: .leftMouseUp, point: end, button: .left)
        heldMouseButton = nil
    }
    
    // MARK: - Scrolling
    
    public func scroll(deltaY: Int32, deltaX: Int32 = 0) async throws {
        try ActionPermissionManager.checkAutomationPermission()
        
        if isMockMode {
            executedEvents.append("scroll(y: \(deltaY), x: \(deltaX))")
            return
        }
        
        guard let scrollEvent = CGEvent(
            scrollWheelEvent2Source: eventSource,
            units: .line,
            wheelCount: 2,
            wheel1: deltaY,
            wheel2: deltaX,
            wheel3: 0
        ) else {
            throw AUTOError.internalError("Failed to create scroll wheel CGEvent")
        }
        
        scrollEvent.post(tap: .cghidEventTap)
    }
    
    // MARK: - Safety Button Release
    
    /// Safely releases any mouse buttons that were left depressed (e.g. after cancellation or error).
    public func releaseHeldButtons() {
        guard let held = heldMouseButton else { return }
        let current = currentMouseCGLocation()
        
        if isMockMode {
            executedEvents.append("releaseHeldButtons(\(held.rawValue))")
            heldMouseButton = nil
            return
        }
        
        let releaseType: CGEventType = (held == .left) ? .leftMouseUp : .rightMouseUp
        postMouseEvent(type: releaseType, point: current, button: held)
        heldMouseButton = nil
        AppLogger.shared.info("Released held mouse button safely.", category: .cursor)
    }
    
    public func clearMockEvents() {
        executedEvents.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func currentMouseCGLocation() -> CGPoint {
        let loc = NSEvent.mouseLocation
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080.0
        return CoordinateMapper.appKitToCoreGraphicsGlobal(appKitPoint: loc, primaryScreenHeight: primaryHeight)
    }
    
    private func postMouseEvent(
        type: CGEventType,
        point: CGPoint,
        button: CGMouseButton,
        clickCount: Int64 = 1
    ) {
        guard let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: type,
            mouseCursorPosition: point,
            mouseButton: button
        ) else {
            return
        }
        
        if clickCount > 1 {
            event.setIntegerValueField(.mouseEventClickState, value: clickCount)
        }
        
        event.post(tap: .cghidEventTap)
    }
}
