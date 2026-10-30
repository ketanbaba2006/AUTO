//
//  ElementLocationDetector.swift
//  AUTO
//
//  Parses and maps spatial element coordinates from visual understanding responses.
//

import AppKit
import Foundation

public protocol ElementLocationDetecting: AnyObject, Sendable {
    func parseDirectives(from responseText: String) -> [SpatialPoint]
    func resolveScreenLocation(for point: SpatialPoint, displays: [DisplayInfo]) -> (screenPoint: CGPoint, display: DisplayInfo)?
}

public final class ElementLocationDetector: ElementLocationDetecting, @unchecked Sendable {
    public static let shared = ElementLocationDetector()
    
    public init() {}
    
    public func parseDirectives(from responseText: String) -> [SpatialPoint] {
        return SpatialPoint.parsePoints(from: responseText)
    }
    
    public func resolveScreenLocation(
        for point: SpatialPoint,
        displays: [DisplayInfo]
    ) -> (screenPoint: CGPoint, display: DisplayInfo)? {
        guard !displays.isEmpty else { return nil }
        
        // Find matching display by index (1-based), or fallback to cursor display or primary
        let targetDisplay: DisplayInfo
        if point.screenIndex >= 1 && point.screenIndex <= displays.count {
            targetDisplay = displays[point.screenIndex - 1]
        } else if let cursorDisplay = displays.first(where: { $0.hasCursor }) {
            targetDisplay = cursorDisplay
        } else {
            targetDisplay = displays[0]
        }
        
        let normalized = CGPoint(x: point.x, y: point.y)
        let appKitPoint = ScreenCoordinateManager.normalizedToAppKit(
            normalizedPoint: normalized,
            displayFrame: targetDisplay.frame
        )
        
        return (screenPoint: appKitPoint, display: targetDisplay)
    }
}
