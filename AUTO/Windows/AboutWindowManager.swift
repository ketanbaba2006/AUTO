//
//  AboutWindowManager.swift
//  AUTO
//
//  Manages the dedicated native About AUTO window.
//

import AppKit
import SwiftUI

@MainActor
public final class AboutWindowManager: NSObject {
    public static let shared = AboutWindowManager()
    
    private var window: NSWindow?
    
    public override init() {
        super.init()
    }
    
    public func showAboutWindow() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingView = NSHostingView(rootView: AboutView())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 490),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "About AUTO"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        window.titlebarAppearsTransparent = true
        window.backgroundColor = BrandTheme.Colors.nsDeepNavy
        
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    public func close() {
        window?.close()
        window = nil
    }
}

