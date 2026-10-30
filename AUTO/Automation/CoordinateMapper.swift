//
//  CoordinateMapper.swift
//  AUTO
//
//  Accurate coordinate mapping across multi-monitor setups, Retina displays,
//  negative desktop coordinate spaces, window-relative frames, and screenshot pixel grids.
//

import AppKit
import CoreGraphics
import Foundation

public struct CoordinateMapper: Sendable {
    
    // MARK: - Bounds Validation
    
    /// Validates if a target global desktop point falls within any connected display.
    public static func isPointValidOnAnyDisplay(_ point: CGPoint, displays: [DisplayInfo]) -> Bool {
        return displays.contains { $0.frame.contains(point) }
    }
    
    /// Validates if a point falls within a specific display's frame.
    public static func isPoint(_ point: CGPoint, within display: DisplayInfo) -> Bool {
        return display.frame.contains(point)
    }
    
    /// Clamps a point to be within the safe visible bounds of a display (inset by margin).
    public static func clampToDisplayBounds(_ point: CGPoint, display: DisplayInfo, margin: CGFloat = 4.0) -> CGPoint {
        let minX = display.frame.minX + margin
        let maxX = display.frame.maxX - margin
        let minY = display.frame.minY + margin
        let maxY = display.frame.maxY - margin
        
        let clampedX = min(max(point.x, minX), maxX)
        let clampedY = min(max(point.y, minY), maxY)
        return CGPoint(x: clampedX, y: clampedY)
    }
    
    // MARK: - Screenshot to Global Desktop Coordinates
    
    /// Converts a pixel coordinate from a captured screenshot (top-left origin, scaled/downsampled)
    /// to global CoreGraphics desktop coordinates (top-left origin of primary display).
    public static func screenshotPixelToGlobalCoreGraphics(
        pixelPoint: CGPoint,
        screenshotPixelSize: CGSize,
        displayFrame: CGRect
    ) -> CGPoint? {
        guard screenshotPixelSize.width > 0 && screenshotPixelSize.height > 0 else {
            return nil
        }
        
        // Normalized inside screenshot [0.0 ... 1.0]
        let normX = min(max(pixelPoint.x / screenshotPixelSize.width, 0.0), 1.0)
        let normY = min(max(pixelPoint.y / screenshotPixelSize.height, 0.0), 1.0)
        
        // Map to display bounds in points
        let globalX = displayFrame.origin.x + (normX * displayFrame.width)
        let globalY = displayFrame.origin.y + (normY * displayFrame.height)
        
        let targetPoint = CGPoint(x: globalX, y: globalY)
        guard displayFrame.contains(targetPoint) else {
            return nil
        }
        return targetPoint
    }
    
    /// Converts a normalized coordinate (0.0 ... 1.0, 0.0 ... 1.0 from top-left)
    /// to global CoreGraphics desktop coordinates for mouse event simulation.
    public static func normalizedToGlobalCoreGraphics(
        normalizedPoint: CGPoint,
        display: DisplayInfo
    ) -> CGPoint {
        let clampedX = min(max(normalizedPoint.x, 0.0), 1.0)
        let clampedY = min(max(normalizedPoint.y, 0.0), 1.0)
        
        let globalX = display.frame.origin.x + (clampedX * display.frame.width)
        let globalY = display.frame.origin.y + (clampedY * display.frame.height)
        
        return CGPoint(x: globalX, y: globalY)
    }
    
    // MARK: - Window-Relative to Global Desktop Coordinates
    
    /// Converts a point relative to an application window's frame (top-left origin) to global desktop coordinates.
    public static func windowRelativeToGlobal(
        relativePoint: CGPoint,
        windowFrame: CGRect
    ) -> CGPoint {
        return CGPoint(
            x: windowFrame.origin.x + relativePoint.x,
            y: windowFrame.origin.y + relativePoint.y
        )
    }
    
    /// Converts global desktop coordinates to a window-relative point.
    public static func globalToWindowRelative(
        globalPoint: CGPoint,
        windowFrame: CGRect
    ) -> CGPoint? {
        guard windowFrame.contains(globalPoint) else { return nil }
        return CGPoint(
            x: globalPoint.x - windowFrame.origin.x,
            y: globalPoint.y - windowFrame.origin.y
        )
    }
    
    // MARK: - AppKit <-> CoreGraphics Conversion (Multi-Display Aware)
    
    /// Converts AppKit mouse coordinates (bottom-left origin) to CoreGraphics coordinates (top-left origin).
    /// Uses the primary display height as the reference coordinate flip.
    public static func appKitToCoreGraphicsGlobal(appKitPoint: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        return CGPoint(
            x: appKitPoint.x,
            y: primaryScreenHeight - appKitPoint.y
        )
    }
    
    /// Converts CoreGraphics coordinates (top-left origin) to AppKit mouse coordinates (bottom-left origin).
    public static func coreGraphicsToAppKitGlobal(cgPoint: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        return CGPoint(
            x: cgPoint.x,
            y: primaryScreenHeight - cgPoint.y
        )
    }
    
    // MARK: - Display Resolution & Retina Scaling
    
    /// Scales logical points to physical display pixels given a backing scale factor.
    public static func pointsToPhysicalPixels(_ point: CGPoint, scaleFactor: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scaleFactor, y: point.y * scaleFactor)
    }
    
    /// Scales physical display pixels to logical points given a backing scale factor.
    public static func physicalPixelsToPoints(_ pixel: CGPoint, scaleFactor: CGFloat) -> CGPoint {
        guard scaleFactor > 0 else { return pixel }
        return CGPoint(x: pixel.x / scaleFactor, y: pixel.y / scaleFactor)
    }
    
    // MARK: - Display Resolver
    
    /// Finds which display contains a global point.
    public static func findDisplay(for point: CGPoint, in displays: [DisplayInfo]) -> DisplayInfo? {
        return displays.first { $0.frame.contains(point) }
    }
}

