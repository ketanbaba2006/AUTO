//
//  DisplayManager.swift
//  AUTO
//
//  Monitors connected hardware displays, resolutions, scale factors, and virtual coordinates.
//  Handles multi-monitor desktop layouts including negative screen coordinates (displays to the left or above primary).
//

import AppKit
import CoreGraphics
import Foundation

@MainActor
public final class DisplayManager: ObservableObject {
    public static let shared = DisplayManager()
    
    @Published public private(set) var displays: [DisplayInfo] = []
    @Published public private(set) var primaryDisplay: DisplayInfo?
    @Published public var selectedDisplayID: CGDirectDisplayID?
    
    private let appState: ApplicationState
    
    public init(appState: ApplicationState) {
        self.appState = appState
        refreshDisplays()
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshDisplays()
            }
        }
    }
    
    public convenience init() {
        self.init(appState: .shared)
    }
    
    /// Refreshes the list of active connected hardware displays.
    public func refreshDisplays() {
        let mouseLocation = NSEvent.mouseLocation
        let primaryScreen = NSScreen.screens.first
        
        let detectedDisplays: [DisplayInfo] = NSScreen.screens.enumerated().map { index, screen in
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? CGDirectDisplayID(index)
            let isPrimary = (screen == primaryScreen)
            let hasCursor = screen.frame.contains(mouseLocation)
            let scaleFactor = screen.backingScaleFactor
            let name = screen.localizedName
            
            return DisplayInfo(
                id: screenNumber,
                name: name,
                frame: screen.frame,
                isPrimary: isPrimary,
                hasCursor: hasCursor,
                scaleFactor: scaleFactor
            )
        }
        
        self.displays = detectedDisplays
        self.primaryDisplay = detectedDisplays.first(where: { $0.isPrimary }) ?? detectedDisplays.first
        
        // Retain or select valid display
        if let currentSelected = selectedDisplayID, !detectedDisplays.contains(where: { $0.id == currentSelected }) {
            selectedDisplayID = primaryDisplay?.id
        } else if selectedDisplayID == nil {
            selectedDisplayID = primaryDisplay?.id
        }
        
        appState.connectedDisplays = detectedDisplays
        AppLogger.shared.info("DisplayManager: Refreshed \(detectedDisplays.count) display(s). Primary ID=\(primaryDisplay?.id ?? 0)", category: .screen)
    }
    
    /// Finds the display that currently contains the mouse cursor.
    public func displayContainingCursor() -> DisplayInfo? {
        let mouseLocation = NSEvent.mouseLocation
        return displays.first(where: { $0.frame.contains(mouseLocation) })
    }
    
    /// Returns the DisplayInfo corresponding to a specific display ID.
    public func display(forID id: CGDirectDisplayID) -> DisplayInfo? {
        return displays.first(where: { $0.id == id })
    }
    
    /// Returns the currently active selected display for capture.
    public func activeSelectedDisplay() -> DisplayInfo? {
        if let id = selectedDisplayID, let matched = display(forID: id) {
            return matched
        }
        return displayContainingCursor() ?? primaryDisplay
    }
    
    // MARK: - Multi-Display Coordinate Mapping
    
    /// Converts a normalized coordinate (0.0...1.0, 0.0...1.0 from top-left) on a specific display
    /// to a global AppKit desktop coordinate point, correctly handling negative virtual origins.
    public func normalizedToGlobal(normalizedPoint: CGPoint, displayID: CGDirectDisplayID) -> CGPoint? {
        guard let disp = display(forID: displayID) else { return nil }
        return ScreenCoordinateManager.normalizedToAppKit(normalizedPoint: normalizedPoint, displayFrame: disp.frame)
    }
    
    /// Converts a global AppKit desktop coordinate point to normalized space within the specified display.
    public func globalToNormalized(globalPoint: CGPoint, displayID: CGDirectDisplayID) -> CGPoint? {
        guard let disp = display(forID: displayID) else { return nil }
        return ScreenCoordinateManager.appKitToNormalized(point: globalPoint, displayFrame: disp.frame)
    }
}
