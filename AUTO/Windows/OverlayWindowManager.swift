//
//  OverlayWindowManager.swift
//  AUTO
//
//  Manages transparent, non-activating, click-through overlay windows across all screens.
//  Hosts CursorOverlayView for visual guidance and companion animations.
//

import AppKit
import SwiftUI

private class PassThroughWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
public final class OverlayWindowManager: NSObject {
    public static let shared = OverlayWindowManager()
    
    private var overlayWindows: [PassThroughWindow] = []
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.recreateOverlays()
            }
        }
    }
    
    public func showOverlays() {
        hideOverlays()
        
        for screen in NSScreen.screens {
            let window = PassThroughWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.hasShadow = false
            window.hidesOnDeactivate = false
            window.setFrame(screen.frame, display: true)
            
            let overlayView = CursorOverlayView(screenFrame: screen.frame)
            let hostingView = NSHostingView(rootView: overlayView)
            hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = .clear
            
            window.contentView = hostingView
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }
        
        ApplicationState.shared.isOverlayVisible = true
        CursorManager.shared.startTracking()
        AppLogger.shared.info("Overlay windows shown on \(overlayWindows.count) screen(s).", category: .ui)
    }
    
    public func hideOverlays() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        ApplicationState.shared.isOverlayVisible = false
        CursorManager.shared.stopTracking()
        AppLogger.shared.info("Overlay windows hidden.", category: .ui)
    }
    
    public func toggleOverlays() {
        if ApplicationState.shared.isOverlayVisible {
            hideOverlays()
        } else {
            showOverlays()
        }
    }
    
    private func recreateOverlays() {
        if ApplicationState.shared.isOverlayVisible {
            showOverlays()
        }
    }
}
