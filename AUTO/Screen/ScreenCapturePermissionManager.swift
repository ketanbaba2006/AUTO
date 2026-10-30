//
//  ScreenCapturePermissionManager.swift
//  AUTO
//
//  Coordinates macOS Screen Recording authorization, preflight checks,
//  and deep linking to System Settings.
//

import AppKit
import CoreGraphics
import Foundation

@MainActor
public final class ScreenCapturePermissionManager: ObservableObject {
    public static let shared = ScreenCapturePermissionManager()
    
    private let appState: ApplicationState
    
    public init(appState: ApplicationState) {
        self.appState = appState
        refreshPermissionStatus()
    }
    
    public convenience init() {
        self.init(appState: .shared)
    }
    
    /// Checks whether the user has granted Screen Recording access.
    @discardableResult
    public func refreshPermissionStatus() -> Bool {
        let isAuthorized = CGPreflightScreenCaptureAccess()
        appState.hasScreenRecordingPermission = isAuthorized
        
        if isAuthorized && appState.screenCaptureState == .permissionRequired {
            appState.screenCaptureState = .idle
        } else if !isAuthorized && appState.screenCaptureState == .idle {
            appState.screenCaptureState = .permissionRequired
        }
        
        AppLogger.shared.debug("ScreenCapturePermissionManager: Screen Recording authorized = \(isAuthorized)", category: .screen)
        return isAuthorized
    }
    
    /// Triggers system permission prompt for Screen Recording.
    public func requestScreenCaptureAccess() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            appState.hasScreenRecordingPermission = true
            return true
        }
        
        // This prompts the macOS dialog if not previously prompted
        let requested = CGRequestScreenCaptureAccess()
        appState.hasScreenRecordingPermission = requested
        
        if !requested {
            openSystemSettings()
        }
        return requested
    }
    
    /// Opens macOS System Settings directly to Privacy & Security > Screen Recording.
    public func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
            AppLogger.shared.info("Opened macOS System Settings to Screen Recording pane.", category: .screen)
        }
    }
}

