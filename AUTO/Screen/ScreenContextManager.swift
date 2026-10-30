//
//  ScreenContextManager.swift
//  AUTO
//
//  Central manager for structured visual screen context.
//  Coordinates display and window snapshots, Accessibility metadata inspection,
//  and feeds visual payloads to Gemini and ConversationManager.
//

import AppKit
import Foundation

@MainActor
public final class ScreenContextManager: ObservableObject {
    public static let shared = ScreenContextManager()
    
    @Published public private(set) var latestCaptures: [ScreenCaptureResult] = []
    @Published public private(set) var currentVisualContext: VisualScreenContext?
    
    private let screenCaptureManager: ScreenCaptureManager
    private let windowCaptureManager: WindowCaptureManager
    private let displayManager: DisplayManager
    private let accessibilityInspector: AccessibilityVisualInspector
    private let appState: ApplicationState
    
    public init(
        screenCaptureManager: ScreenCaptureManager,
        windowCaptureManager: WindowCaptureManager,
        displayManager: DisplayManager,
        accessibilityInspector: AccessibilityVisualInspector,
        appState: ApplicationState
    ) {
        self.screenCaptureManager = screenCaptureManager
        self.windowCaptureManager = windowCaptureManager
        self.displayManager = displayManager
        self.accessibilityInspector = accessibilityInspector
        self.appState = appState
    }
    
    public convenience init() {
        self.init(
            screenCaptureManager: .shared,
            windowCaptureManager: .shared,
            displayManager: .shared,
            accessibilityInspector: .shared,
            appState: .shared
        )
    }
    
    /// Captures the authorized screen or window context based on user preferences.
    @discardableResult
    public func captureCurrentContext(mode: ScreenAwarenessMode = .onDemand) async throws -> VisualScreenContext {
        let prefs = appState.screenPreferences
        
        var displayInfo: DisplayInfo? = nil
        var windowInfo: WindowInfo? = nil
        var jpegData: Data = Data()
        var base64String: String = ""
        
        switch prefs.sourceType {
        case .display:
            let captureResult: ScreenCaptureResult
            if let targetDisplayID = prefs.selectedDisplayID {
                captureResult = try await screenCaptureManager.captureDisplay(
                    displayID: targetDisplayID,
                    maxDimension: prefs.maxDimension,
                    compressionQuality: prefs.compressionQuality
                )
            } else {
                captureResult = try await screenCaptureManager.captureActiveDisplay()
            }
            
            displayInfo = displayManager.display(forID: captureResult.displayID)
            jpegData = captureResult.imageData
            base64String = captureResult.base64String
            self.latestCaptures = [captureResult]
            
        case .window:
            guard let windowID = prefs.selectedWindowID else {
                // If no window selected, fall back to active display
                let captureResult = try await screenCaptureManager.captureActiveDisplay()
                displayInfo = displayManager.display(forID: captureResult.displayID)
                jpegData = captureResult.imageData
                base64String = captureResult.base64String
                self.latestCaptures = [captureResult]
                break
            }
            
            let processed = try await windowCaptureManager.captureWindow(
                windowID: windowID,
                maxDimension: prefs.maxDimension,
                compressionQuality: prefs.compressionQuality
            )
            
            windowInfo = appState.availableWindows.first(where: { $0.id == windowID })
            jpegData = processed.jpegData
            base64String = processed.base64String
        }
        
        // Optional Accessibility Metadata
        var axContext: AccessibilityVisualContext? = nil
        if prefs.includeAccessibilityContext && appState.hasAccessibilityPermission {
            axContext = accessibilityInspector.captureVisualContext()
        }
        
        let visualContext = VisualScreenContext(
            timestamp: Date(),
            displayInfo: displayInfo,
            windowInfo: windowInfo,
            screenshotJPEG: jpegData,
            base64String: base64String,
            accessibilityContext: axContext,
            mode: mode
        )
        
        self.currentVisualContext = visualContext
        self.appState.activeScreenContext = visualContext
        
        AppLogger.shared.info("ScreenContextManager: Captured context in mode [\(mode.rawValue)] (\(jpegData.count) bytes)", category: .screen)
        return visualContext
    }
    
    /// Clears the current visual context from memory.
    public func clear() {
        self.latestCaptures = []
        self.currentVisualContext = nil
        self.appState.activeScreenContext = nil
        ScreenshotProcessor.shared.clearCache()
    }
}
