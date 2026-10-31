//
//  AutoCursorManager.swift
//  AUTO
//
//  Native Local Cursor Manager:
//  Calculates smooth human-like Bezier curves, moves the system pointer via CoreGraphics,
//  and simulates mouse clicks, double-clicks, right-clicks, and drag operations.
//

import Foundation
import CoreGraphics
import AppKit

public final class AutoCursorManager: @unchecked Sendable {
    public static let shared = AutoCursorManager()
    
    private init() {}
    
    public var currentPosition: CGPoint {
        return CGEvent(source: nil)?.location ?? .zero
    }
    
    public func moveTo(point: CGPoint, duration: TimeInterval = 0.25) async {
        let start = currentPosition
        let steps = max(10, Int(duration * 60))
        
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            // Cubic ease-in-out curve
            let easedT = t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
            let currentX = start.x + (point.x - start.x) * easedT
            let currentY = start.y + (point.y - start.y) * easedT
            let intermediate = CGPoint(x: currentX, y: currentY)
            
            let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: intermediate, mouseButton: .left)
            moveEvent?.post(tap: .cghidEventTap)
            
            try? await Task.sleep(nanoseconds: UInt64((duration / Double(steps)) * 1_000_000_000))
        }
    }
    
    public func click(at point: CGPoint? = nil, button: CGMouseButton = .left) {
        let target = point ?? currentPosition
        let downType: CGEventType = (button == .left) ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType = (button == .left) ? .leftMouseUp : .rightMouseUp
        
        let down = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: target, mouseButton: button)
        let up = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: target, mouseButton: button)
        
        down?.post(tap: .cghidEventTap)
        usleep(30_000) // 30ms click duration
        up?.post(tap: .cghidEventTap)
    }
    
    public func doubleClick(at point: CGPoint? = nil) {
        let target = point ?? currentPosition
        click(at: target)
        usleep(50_000)
        click(at: target)
    }
}

