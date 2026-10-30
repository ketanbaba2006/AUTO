//
//  CursorManager.swift
//  AUTO
//
//  Coordinates companion buddy cursor positioning, modes, spatial pointing,
//  and links with CursorOverlayManager and MouseActionManager.
//

import AppKit
import Combine

public enum CursorBuddyMode: Sendable {
    case followingCursor
    case navigatingToTarget
    case pointingAtTarget
}

@MainActor
public final class CursorManager: ObservableObject {
    public static let shared = CursorManager()
    
    @Published public var mode: CursorBuddyMode = .followingCursor
    @Published public var currentPosition: CGPoint = .zero
    @Published public var targetPoint: SpatialPoint?
    @Published public var isVisible: Bool = true
    
    private var trackingTimer: Timer?
    
    public init() {
        self.currentPosition = NSEvent.mouseLocation
    }
    
    public func startTracking() {
        stopTracking()
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.mode == .followingCursor {
                    self.currentPosition = NSEvent.mouseLocation
                }
            }
        }
    }
    
    public func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    public func pointAt(target: SpatialPoint) {
        self.targetPoint = target
        self.mode = .navigatingToTarget
        
        let targetCG = CGPoint(x: target.x, y: target.y)
        CursorOverlayManager.shared.updateVisualState(.targeting(targetCG, label: target.label))
        
        AppLogger.shared.info("Navigating cursor buddy to target: (\(target.x), \(target.y)) [\(target.label)]", category: .cursor)
    }
    
    public func resetToCursorFollowing() {
        self.targetPoint = nil
        self.mode = .followingCursor
        self.currentPosition = NSEvent.mouseLocation
        CursorOverlayManager.shared.updateVisualState(.idle)
    }
}
