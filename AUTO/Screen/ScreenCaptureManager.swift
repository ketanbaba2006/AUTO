//
//  ScreenCaptureManager.swift
//  AUTO
//
//  Production ScreenCaptureKit capture service.
//  Supports full display capture, selected display capture, individual window capture,
//  multi-monitor layouts, and controlled periodic sampling for active screen sharing.
//

import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

public struct ScreenCaptureResult: Sendable {
    public let imageData: Data
    public let base64String: String
    public let displayFrame: CGRect
    public let isCursorDisplay: Bool
    public let displayIndex: Int
    public let displayID: CGDirectDisplayID
    public let pixelSize: CGSize
    
    public init(
        imageData: Data,
        base64String: String,
        displayFrame: CGRect,
        isCursorDisplay: Bool,
        displayIndex: Int,
        displayID: CGDirectDisplayID,
        pixelSize: CGSize
    ) {
        self.imageData = imageData
        self.base64String = base64String
        self.displayFrame = displayFrame
        self.isCursorDisplay = isCursorDisplay
        self.displayIndex = displayIndex
        self.displayID = displayID
        self.pixelSize = pixelSize
    }
}

public protocol ScreenCaptureService: AnyObject, Sendable {
    func captureAllScreens() async throws -> [ScreenCaptureResult]
    func captureDisplay(displayID: CGDirectDisplayID) async throws -> ScreenCaptureResult
    func captureActiveDisplay() async throws -> ScreenCaptureResult
}

@MainActor
public final class ScreenCaptureManager: ObservableObject, ScreenCaptureService {
    public static let shared = ScreenCaptureManager()
    
    @Published public private(set) var currentState: ScreenCaptureState = .idle
    @Published public private(set) var isSharingActive: Bool = false
    
    private let displayManager: DisplayManager
    private let windowCaptureManager: WindowCaptureManager
    private let screenshotProcessor: ScreenshotProcessor
    private let appState: ApplicationState
    
    private var sharingTimer: Timer?
    private var isCapturing = false
    
    public init(
        displayManager: DisplayManager,
        windowCaptureManager: WindowCaptureManager,
        screenshotProcessor: ScreenshotProcessor,
        appState: ApplicationState
    ) {
        self.displayManager = displayManager
        self.windowCaptureManager = windowCaptureManager
        self.screenshotProcessor = screenshotProcessor
        self.appState = appState
    }
    
    public convenience init() {
        self.init(
            displayManager: .shared,
            windowCaptureManager: .shared,
            screenshotProcessor: .shared,
            appState: .shared
        )
    }
    
    // MARK: - Single & Active Display Capture
    
    /// Conformance to ScreenCaptureService protocol
    public func captureDisplay(displayID: CGDirectDisplayID) async throws -> ScreenCaptureResult {
        return try await captureDisplay(
            displayID: displayID,
            maxDimension: appState.screenPreferences.maxDimension,
            compressionQuality: appState.screenPreferences.compressionQuality
        )
    }
    
    /// Captures the currently active display (the user's selected display or display containing the mouse cursor).
    public func captureActiveDisplay() async throws -> ScreenCaptureResult {
        let activeDisplay = displayManager.activeSelectedDisplay()
        guard let displayID = activeDisplay?.id else {
            throw AUTOError.screenCaptureError(reason: "No active display available for capture.")
        }
        return try await captureDisplay(displayID: displayID)
    }
    
    /// Captures a specific display by its direct display ID using modern ScreenCaptureKit APIs.
    public func captureDisplay(
        displayID: CGDirectDisplayID,
        maxDimension: Int = 1920,
        compressionQuality: Double = 0.80
    ) async throws -> ScreenCaptureResult {
        guard CGPreflightScreenCaptureAccess() else {
            updateState(.permissionRequired)
            throw AUTOError.permissionDenied(
                permission: "Screen Recording",
                instructions: "Please grant Screen Recording permission in macOS System Settings."
            )
        }
        
        updateState(.capturing)
        
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let targetSCDisplay = content.displays.first(where: { $0.displayID == displayID }) else {
                throw AUTOError.screenCaptureError(reason: "Target display with ID \(displayID) not found.")
            }
            
            // Exclude AUTO's companion panel and overlays to prevent AI from seeing itself
            let ownBundleID = Bundle.main.bundleIdentifier ?? "com.auto.desktop"
            let ownWindows = content.windows.filter { $0.owningApplication?.bundleIdentifier == ownBundleID }
            
            let filter = SCContentFilter(display: targetSCDisplay, excludingWindows: ownWindows)
            let config = SCStreamConfiguration()
            
            // Optimal dimension scaling
            let width = targetSCDisplay.width
            let height = targetSCDisplay.height
            let maxSide = max(width, height)
            if maxSide > maxDimension {
                let scale = Double(maxDimension) / Double(maxSide)
                config.width = Int(Double(width) * scale)
                config.height = Int(Double(height) * scale)
            } else {
                config.width = width
                config.height = height
            }
            
            config.showsCursor = true
            config.scalesToFit = true
            
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            updateState(.processing)
            
            let processed = try screenshotProcessor.process(
                cgImage: cgImage,
                maxDimension: maxDimension,
                compressionQuality: compressionQuality
            )
            
            let mouseLocation = NSEvent.mouseLocation
            let displayFrame = targetSCDisplay.frame
            let isCursorDisplay = displayFrame.contains(mouseLocation)
            
            let result = ScreenCaptureResult(
                imageData: processed.jpegData,
                base64String: processed.base64String,
                displayFrame: displayFrame,
                isCursorDisplay: isCursorDisplay,
                displayIndex: 1,
                displayID: displayID,
                pixelSize: processed.targetPixelSize
            )
            
            updateState(isSharingActive ? .sharing : .completed)
            AppLogger.shared.info("ScreenCaptureManager: Successfully captured display \(displayID) (\(processed.compressedByteCount) bytes).", category: .screen)
            return result
        } catch {
            updateState(.failed(reason: error.localizedDescription))
            throw error
        }
    }
    
    // MARK: - Multi-Display Capture
    
    /// Captures all connected displays simultaneously.
    public func captureAllScreens() async throws -> [ScreenCaptureResult] {
        guard CGPreflightScreenCaptureAccess() else {
            updateState(.permissionRequired)
            throw AUTOError.permissionDenied(
                permission: "Screen Recording",
                instructions: "Please grant Screen Recording permission in macOS System Settings."
            )
        }
        
        updateState(.capturing)
        
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard !content.displays.isEmpty else {
                throw AUTOError.screenCaptureError(reason: "No active displays found for capture.")
            }
            
            let ownBundleID = Bundle.main.bundleIdentifier ?? "com.auto.desktop"
            let ownWindows = content.windows.filter { $0.owningApplication?.bundleIdentifier == ownBundleID }
            let mouseLocation = NSEvent.mouseLocation
            
            var results: [ScreenCaptureResult] = []
            
            for (index, display) in content.displays.enumerated() {
                let filter = SCContentFilter(display: display, excludingWindows: ownWindows)
                let config = SCStreamConfiguration()
                
                let maxDim = appState.screenPreferences.maxDimension
                let maxSide = max(display.width, display.height)
                if maxSide > maxDim {
                    let scale = Double(maxDim) / Double(maxSide)
                    config.width = Int(Double(display.width) * scale)
                    config.height = Int(Double(display.height) * scale)
                } else {
                    config.width = display.width
                    config.height = display.height
                }
                
                config.showsCursor = true
                config.scalesToFit = true
                
                let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                let processed = try screenshotProcessor.process(
                    cgImage: cgImage,
                    maxDimension: maxDim,
                    compressionQuality: appState.screenPreferences.compressionQuality
                )
                
                let displayFrame = display.frame
                let isCursorDisplay = displayFrame.contains(mouseLocation)
                
                results.append(ScreenCaptureResult(
                    imageData: processed.jpegData,
                    base64String: processed.base64String,
                    displayFrame: displayFrame,
                    isCursorDisplay: isCursorDisplay,
                    displayIndex: index + 1,
                    displayID: display.displayID,
                    pixelSize: processed.targetPixelSize
                ))
            }
            
            // Prioritize cursor display first
            results.sort { $0.isCursorDisplay && !$1.isCursorDisplay }
            updateState(isSharingActive ? .sharing : .completed)
            return results
        } catch {
            updateState(.failed(reason: error.localizedDescription))
            throw error
        }
    }
    
    // MARK: - Window Capture Bridge
    
    /// Captures a specific application window.
    public func captureWindow(windowID: CGWindowID) async throws -> ProcessedScreenshot {
        updateState(.capturing)
        do {
            let processed = try await windowCaptureManager.captureWindow(
                windowID: windowID,
                maxDimension: appState.screenPreferences.maxDimension,
                compressionQuality: appState.screenPreferences.compressionQuality
            )
            updateState(isSharingActive ? .sharing : .completed)
            return processed
        } catch {
            updateState(.failed(reason: error.localizedDescription))
            throw error
        }
    }
    
    // MARK: - Continuous Screen Sharing (Mode C)
    
    /// Starts controlled periodic screen sampling while manual screen sharing is active.
    public func startContinuousSharing(interval: TimeInterval = 3.0) {
        guard !isSharingActive else { return }
        guard CGPreflightScreenCaptureAccess() else {
            updateState(.permissionRequired)
            _ = ScreenCapturePermissionManager.shared.requestScreenCaptureAccess()
            return
        }
        
        isSharingActive = true
        appState.isScreenSharingActive = true
        updateState(.sharing)
        AppLogger.shared.info("ScreenCaptureManager: Manual screen sharing session started.", category: .screen)
        
        // Initial immediate capture
        Task {
            _ = try? await ScreenContextManager.shared.captureCurrentContext()
        }
        
        // Periodic sampling timer
        sharingTimer?.invalidate()
        sharingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isSharingActive, !self.isCapturing else { return }
                self.isCapturing = true
                defer { self.isCapturing = false }
                _ = try? await ScreenContextManager.shared.captureCurrentContext()
            }
        }
    }
    
    /// Stops continuous screen sharing session and tears down timers.
    public func stopContinuousSharing() {
        guard isSharingActive else { return }
        sharingTimer?.invalidate()
        sharingTimer = nil
        isSharingActive = false
        appState.isScreenSharingActive = false
        updateState(.idle)
        AppLogger.shared.info("ScreenCaptureManager: Manual screen sharing session stopped.", category: .screen)
    }
    
    private func updateState(_ state: ScreenCaptureState) {
        self.currentState = state
        self.appState.screenCaptureState = state
    }
}
