//
//  CompanionWindowManager.swift
//  AUTO
//
//  Manages the floating companion NSPanel that drops down below the menu bar status item.
//  Non-activating, transparent background, with auto-dismiss on outside clicks.
//

import AppKit
import SwiftUI

private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
public final class CompanionWindowManager: NSObject {
    public static let shared = CompanionWindowManager()
    
    private var panel: NSPanel?
    private var clickOutsideMonitor: Any?
    private let panelWidth: CGFloat = 340
    private let defaultHeight: CGFloat = 460
    
    public override init() {
        super.init()
    }
    
    deinit {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    public var isPanelVisible: Bool {
        return panel?.isVisible ?? false
    }
    
    public func togglePanel() {
        if isPanelVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }
    
    public func showPanel() {
        if panel == nil {
            createPanel()
        }
        
        positionPanelBelowStatusItem()
        panel?.makeKeyAndOrderFront(nil)
        panel?.orderFrontRegardless()
        ApplicationState.shared.isCompanionPanelOpen = true
        installClickOutsideMonitor()
        AppLogger.shared.debug("Companion panel displayed.", category: .ui)
    }
    
    public func hidePanel() {
        panel?.orderOut(nil)
        ApplicationState.shared.isCompanionPanelOpen = false
        removeClickOutsideMonitor()
        AppLogger.shared.debug("Companion panel hidden.", category: .ui)
    }
    
    private func createPanel() {
        let rootView = CompanionPanelView()
            .frame(width: panelWidth)
        
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: defaultHeight)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        
        let customPanel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: defaultHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        customPanel.isFloatingPanel = true
        customPanel.level = .floating
        customPanel.isOpaque = false
        customPanel.backgroundColor = .clear
        customPanel.hasShadow = true
        customPanel.hidesOnDeactivate = false
        customPanel.isExcludedFromWindowsMenu = true
        customPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        customPanel.isMovableByWindowBackground = false
        customPanel.titleVisibility = .hidden
        customPanel.titlebarAppearsTransparent = true
        
        customPanel.contentView = hostingView
        self.panel = customPanel
    }
    
    private func positionPanelBelowStatusItem() {
        guard let panel = panel else { return }
        guard let buttonFrame = MenuBarManager.shared.statusItemButtonFrame else { return }
        
        let fittingSize = panel.contentView?.fittingSize ?? CGSize(width: panelWidth, height: defaultHeight)
        let actualHeight = max(fittingSize.height, 300)
        let gap: CGFloat = 6.0
        
        let x = buttonFrame.midX - (panelWidth / 2.0)
        let y = buttonFrame.minY - actualHeight - gap
        
        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: actualHeight), display: true)
    }
    
    private func installClickOutsideMonitor() {
        removeClickOutsideMonitor()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return }
            let mouseLoc = NSEvent.mouseLocation
            
            // If click was inside panel or inside status item, do not hide
            if panel.frame.contains(mouseLoc) { return }
            if let buttonFrame = MenuBarManager.shared.statusItemButtonFrame, buttonFrame.contains(mouseLoc) {
                return
            }
            
            self.hidePanel()
        }
    }
    
    private func removeClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
}
