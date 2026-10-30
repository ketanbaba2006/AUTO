//
//  AppLifecycleManager.swift
//  AUTO
//
//  Coordinates application lifecycle events, background execution,
//  system sleep/wake notifications, and graceful shutdown.
//

import AppKit
import Combine

@MainActor
public final class AppLifecycleManager: ObservableObject {
    public static let shared = AppLifecycleManager()
    
    @Published public private(set) var isRunning: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupSystemNotifications()
    }
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        AppLogger.shared.info("AppLifecycleManager: Starting AUTO application lifecycle...", category: .lifecycle)
        
        // Start the central companion coordinator
        CompanionManager.shared.start()
    }
    
    public func terminate() {
        guard isRunning else { return }
        isRunning = false
        AppLogger.shared.info("AppLifecycleManager: Gracefully shutting down AUTO...", category: .lifecycle)
        
        // Stop companion manager and tear down sessions
        CompanionManager.shared.stop()
    }
    
    public func quitApplication() {
        terminate()
        NSApp.terminate(nil)
    }
    
    private func setupSystemNotifications() {
        let center = NSWorkspace.shared.notificationCenter
        
        center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleSystemSleep()
            }
        }
        
        center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleSystemWake()
            }
        }
        
        center.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleScreensSleep()
            }
        }
        
        center.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleScreensWake()
            }
        }
    }
    
    private func handleSystemSleep() {
        AppLogger.shared.info("System going to sleep; suspending active companion sessions.", category: .lifecycle)
        OverlayWindowManager.shared.hideOverlays()
        VoiceSessionManager.shared.stop()
    }
    
    private func handleSystemWake() {
        AppLogger.shared.info("System woke up; refreshing display metrics and permissions.", category: .lifecycle)
        PermissionManager.shared.refreshPermissions()
        DisplayManager.shared.refreshDisplays()
        
        if ApplicationState.shared.isOnboardingCompleted &&
           ApplicationState.shared.allPermissionsGranted &&
           ApplicationState.shared.generalPreferences.companionVisibility == .alwaysVisible {
            OverlayWindowManager.shared.showOverlays()
        }
        VoiceSessionManager.shared.start()
    }
    
    private func handleScreensSleep() {
        AppLogger.shared.debug("Displays went to sleep; hiding overlay windows.", category: .lifecycle)
        OverlayWindowManager.shared.hideOverlays()
    }
    
    private func handleScreensWake() {
        AppLogger.shared.debug("Displays woke up; refreshing overlays.", category: .lifecycle)
        DisplayManager.shared.refreshDisplays()
        if ApplicationState.shared.isOnboardingCompleted &&
           ApplicationState.shared.allPermissionsGranted &&
           ApplicationState.shared.generalPreferences.companionVisibility == .alwaysVisible {
            OverlayWindowManager.shared.showOverlays()
        }
    }
}

