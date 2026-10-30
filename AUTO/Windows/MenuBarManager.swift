//
//  MenuBarManager.swift
//  AUTO
//
//  Manages the NSStatusItem in the macOS menu bar and coordinates the floating panel.
//

import AppKit

@MainActor
public final class MenuBarManager: NSObject {
    public static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    public weak var companionWindowManager: CompanionWindowManager?
    
    public override init() {
        super.init()
    }
    
    public func setupStatusItem(companionWindowManager: CompanionWindowManager) {
        self.companionWindowManager = companionWindowManager
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        
        button.image = BrandAssetManager.shared.menuBarMascotIcon(size: 18.0)
        button.image?.isTemplate = true
        button.toolTip = "AUTO - Your Personal AI Desktop Companion"
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        AppLogger.shared.info("MenuBarManager initialized with official AUTO mascot status item.", category: .ui)
    }
    
    public var statusItemButtonFrame: NSRect? {
        return statusItem?.button?.window?.frame
    }
    
    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            companionWindowManager?.togglePanel()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu(title: "AUTO")
        
        let aboutItem = NSMenuItem(title: "About AUTO...", action: #selector(openAboutWindow), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(title: "Toggle Companion Panel", action: #selector(togglePanelAction), keyEquivalent: "t")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit AUTO", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // Restore toggle behavior on subsequent left clicks
    }
    
    @objc private func openAboutWindow() {
        AboutWindowManager.shared.showAboutWindow()
    }
    
    @objc private func togglePanelAction() {
        companionWindowManager?.togglePanel()
    }
    
    @objc private func openSettingsAction() {
        companionWindowManager?.showPanel()
        ApplicationState.shared.isSettingsOpen = true
    }
    
    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
