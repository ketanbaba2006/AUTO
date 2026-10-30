//
//  CursorOverlayManager.swift
//  AUTO
//
//  Manages the visual companion cursor overlay states, targeting reticles,
//  click ripples, and execution badges rendered across multi-monitor overlay windows.
//

import AppKit
import CoreGraphics
import Foundation

@MainActor
public final class CursorOverlayManager: ObservableObject {
    public static let shared = CursorOverlayManager()
    
    @Published public private(set) var visualState: CursorOverlayVisualState = .idle
    @Published public private(set) var targetLocation: CGPoint? = nil
    @Published public private(set) var targetLabel: String? = nil
    @Published public private(set) var clickRippleLocation: CGPoint? = nil
    @Published public private(set) var isRippling: Bool = false
    
    private var rippleDismissTask: Task<Void, Never>? = nil
    
    public init() {}
    
    /// Updates the overlay visual state.
    public func updateVisualState(_ state: CursorOverlayVisualState) {
        self.visualState = state
        
        switch state {
        case .idle:
            self.targetLocation = nil
            self.targetLabel = nil
            self.isRippling = false
            
        case .targeting(let point, let label):
            self.targetLocation = point
            self.targetLabel = label
            self.isRippling = false
            
        case .moving(let from, let to):
            self.targetLocation = to
            _ = from
            
        case .clicking(let point):
            self.targetLocation = point
            triggerClickRipple(at: point)
            
        case .executing(let label):
            self.targetLabel = label
            
        case .error:
            self.isRippling = false
        }
    }
    
    /// Triggers an expanding animated click ripple ring at the target coordinate.
    public func triggerClickRipple(at point: CGPoint) {
        self.clickRippleLocation = point
        self.isRippling = true
        
        rippleDismissTask?.cancel()
        rippleDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000) // 450ms animation duration
            self.isRippling = false
            self.clickRippleLocation = nil
        }
    }
}

