//
//  AppDelegate.swift
//  AUTO
//
//  NSApplicationDelegate handling application launch, menu bar accessory mode,
//  and termination lifecycle.
//

import AppKit

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.shared.info("AUTO application launched.", category: .lifecycle)
        
        // Set official application icon image for Dock, app switcher, and system dialogs
        NSApplication.shared.applicationIconImage = BrandAssetManager.shared.appIconImage
        
        // Configure as menu bar accessory (LSUIElement behavior in code)
        // This ensures AUTO lives in the menu bar and does not take up a Dock icon.
        NSApp.setActivationPolicy(.accessory)
        
        // Start the application lifecycle manager
        AppLifecycleManager.shared.start()
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // As a menu-bar resident companion, AUTO continues running when panels/windows close.
        return false
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        AppLogger.shared.info("AUTO application terminating.", category: .lifecycle)
        AppLifecycleManager.shared.terminate()
    }
}

