//
//  CursorAnimationManager.swift
//  AUTO
//
//  Flight path geometry and bezier animation calculations for cursor pointing.
//

import CoreGraphics
import Foundation

public struct CursorAnimationManager: Sendable {
    
    /// Generates a smooth bezier arc between starting and ending points.
    public static func calculateArcControlPoint(from start: CGPoint, to end: CGPoint, arcHeight: CGFloat = 80.0) -> CGPoint {
        let midX = (start.x + end.x) / 2.0
        let midY = (start.y + end.y) / 2.0
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx * dx + dy * dy)
        
        guard distance > 0 else {
            return CGPoint(x: midX, y: midY + arcHeight)
        }
        
        // Normal vector pointing perpendicular to direction
        let normalX = -dy / distance
        let normalY = dx / distance
        
        return CGPoint(
            x: midX + normalX * arcHeight,
            y: midY + normalY * arcHeight
        )
    }
    
    /// Evaluates quadratic bezier point at parameter t (0.0 ... 1.0).
    public static func evaluateBezier(p0: CGPoint, p1: CGPoint, p2: CGPoint, t: CGFloat) -> CGPoint {
        let oneMinusT = 1.0 - t
        let term0 = oneMinusT * oneMinusT
        let term1 = 2.0 * oneMinusT * t
        let term2 = t * t
        
        let x = term0 * p0.x + term1 * p1.x + term2 * p2.x
        let y = term0 * p0.y + term1 * p1.y + term2 * p2.y
        
        return CGPoint(x: x, y: y)
    }
    
    /// Calculates tangent rotation angle in radians at parameter t.
    public static func evaluateTangentAngle(p0: CGPoint, p1: CGPoint, p2: CGPoint, t: CGFloat) -> CGFloat {
        let dx = 2.0 * (1.0 - t) * (p1.x - p0.x) + 2.0 * t * (p2.x - p1.x)
        let dy = 2.0 * (1.0 - t) * (p1.y - p0.y) + 2.0 * t * (p2.y - p1.y)
        return atan2(dy, dx)
    }
}
