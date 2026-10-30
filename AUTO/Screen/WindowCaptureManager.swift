//
//  WindowCaptureManager.swift
//  AUTO
//
//  Discovers shareable on-screen application windows and captures individual windows
//  using ScreenCaptureKit's desktop-independent window filters.
//

import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

@MainActor
public final class WindowCaptureManager: ObservableObject {
    public static let shared = WindowCaptureManager()
    
    @Published public private(set) var availableWindows: [WindowInfo] = []
    @Published public private(set) var isRefreshing: Bool = false
    
    private let screenshotProcessor: ScreenshotProcessor
    
    public init(screenshotProcessor: ScreenshotProcessor = .shared) {
        self.screenshotProcessor = screenshotProcessor
    }
    
    /// Discovers all eligible on-screen application windows excluding AUTO's own windows.
    @discardableResult
    public func refreshShareableWindows() async throws -> [WindowInfo] {
        guard CGPreflightScreenCaptureAccess() else {
            throw AUTOError.permissionDenied(
                permission: "Screen Recording",
                instructions: "Please grant Screen Recording permission in macOS System Settings."
            )
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        let ownBundleID = Bundle.main.bundleIdentifier ?? "com.auto.desktop"
        
        // Filter windows: must belong to other apps, have reasonable size, and be on screen
        let filtered = content.windows.compactMap { scWindow -> WindowInfo? in
            let app = scWindow.owningApplication
            if app?.bundleIdentifier == ownBundleID { return nil }
            if scWindow.frame.width < 50 || scWindow.frame.height < 50 { return nil }
            
            let appName = app?.applicationName ?? "Application"
            let title = scWindow.title ?? ""
            
            // Skip system menubar or background window artifacts
            if appName == "Window Server" || appName == "Dock" || appName == "SystemUIServer" {
                return nil
            }
            
            return WindowInfo(
                id: scWindow.windowID,
                title: title,
                appName: appName,
                bundleIdentifier: app?.bundleIdentifier,
                frame: scWindow.frame,
                isOnScreen: scWindow.isOnScreen
            )
        }
        
        // Sort windows by application name and title
        let sorted = filtered.sorted {
            if $0.appName == $1.appName {
                return $0.title < $1.title
            }
            return $0.appName < $1.appName
        }
        
        self.availableWindows = sorted
        ApplicationState.shared.availableWindows = sorted
        AppLogger.shared.info("WindowCaptureManager: Discovered \(sorted.count) eligible application window(s).", category: .screen)
        return sorted
    }
    
    /// Captures a specific application window by its window ID.
    public func captureWindow(
        windowID: CGWindowID,
        maxDimension: Int = 1920,
        compressionQuality: Double = 0.80
    ) async throws -> ProcessedScreenshot {
        guard CGPreflightScreenCaptureAccess() else {
            throw AUTOError.permissionDenied(
                permission: "Screen Recording",
                instructions: "Please grant Screen Recording permission in macOS System Settings."
            )
        }
        
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        guard let targetSCWindow = content.windows.first(where: { $0.windowID == windowID }) else {
            throw AUTOError.screenCaptureError(reason: "Window with ID #\(windowID) is no longer available.")
        }
        
        let filter = SCContentFilter(desktopIndependentWindow: targetSCWindow)
        let config = SCStreamConfiguration()
        
        // Optimize resolution while preserving aspect ratio
        let frame = targetSCWindow.frame
        let maxSide = max(frame.width, frame.height)
        if maxSide > CGFloat(maxDimension) {
            let scale = CGFloat(maxDimension) / maxSide
            config.width = Int(frame.width * scale)
            config.height = Int(frame.height * scale)
        } else {
            config.width = Int(frame.width)
            config.height = Int(frame.height)
        }
        
        config.showsCursor = false
        config.scalesToFit = true
        
        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        let processed = try screenshotProcessor.process(
            cgImage: cgImage,
            maxDimension: maxDimension,
            compressionQuality: compressionQuality
        )
        
        AppLogger.shared.info("WindowCaptureManager: Captured window \"\(targetSCWindow.title ?? "")\" (\(processed.compressedByteCount) bytes).", category: .screen)
        return processed
    }
}

