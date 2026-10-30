//
//  ScreenCoordinateManager.swift
//  AUTO
//
//  Handles coordinate space conversions between AppKit (bottom-left origin),
//  CoreGraphics/ScreenCaptureKit (top-left origin), and normalized (0.0...1.0) space.
//

import AppKit
import CoreGraphics

public struct ScreenCoordinateManager: Sendable {
    
    /// Converts a point from AppKit coordinates (bottom-left origin) to
    /// CoreGraphics coordinates (top-left origin) within a given display frame.
    public static func appKitToCoreGraphics(point: CGPoint, displayFrame: CGRect) -> CGPoint {
        let x = point.x
        let y = displayFrame.maxY - (point.y - displayFrame.minY)
        return CGPoint(x: x, y: y)
    }
    
    /// Converts a point from CoreGraphics coordinates (top-left origin) to
    /// AppKit coordinates (bottom-left origin) within a given display frame.
    public static func coreGraphicsToAppKit(point: CGPoint, displayFrame: CGRect) -> CGPoint {
        let x = point.x
        let y = displayFrame.maxY - (point.y - displayFrame.minY)
        return CGPoint(x: x, y: y)
    }
    
    /// Converts a normalized coordinate (0.0...1.0, 0.0...1.0 from top-left)
    /// to an absolute AppKit screen point.
    public static func normalizedToAppKit(normalizedPoint: CGPoint, displayFrame: CGRect) -> CGPoint {
        let clampedX = min(max(normalizedPoint.x, 0.0), 1.0)
        let clampedY = min(max(normalizedPoint.y, 0.0), 1.0)
        
        let screenX = displayFrame.origin.x + (clampedX * displayFrame.width)
        // Normalized Y is top-down (0 = top, 1 = bottom)
        let screenY = displayFrame.origin.y + ((1.0 - clampedY) * displayFrame.height)
        
        return CGPoint(x: screenX, y: screenY)
    }
    
    /// Converts an absolute AppKit screen point to a normalized coordinate (0.0...1.0, 0.0...1.0 top-left).
    public static func appKitToNormalized(point: CGPoint, displayFrame: CGRect) -> CGPoint {
        guard displayFrame.width > 0 && displayFrame.height > 0 else {
            return .zero
        }
        
        let relativeX = point.x - displayFrame.origin.x
        let relativeY = point.y - displayFrame.origin.y
        
        let normX = min(max(relativeX / displayFrame.width, 0.0), 1.0)
        let normY = min(max((displayFrame.height - relativeY) / displayFrame.height, 0.0), 1.0)
        
        return CGPoint(x: normX, y: normY)
    }
    
    /// Finds the display frame that contains the given AppKit point.
    public static func findDisplay(containing point: CGPoint, in displays: [CGRect]) -> CGRect? {
        return displays.first(where: { $0.contains(point) })
    }
}
