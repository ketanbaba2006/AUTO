//
//  CompanionManager.swift
//  AUTO
//
//  Main application coordinator orchestrating voice, AI, permissions, windows,
//  and companion lifecycle state.
//

import AppKit
import Combine
import SwiftUI

@MainActor
public final class CompanionManager: ObservableObject {
    public static let shared = CompanionManager()
    
    public let container: DependencyContainer
    private var cancellables = Set<AnyCancellable>()
    
    public init(container: DependencyContainer) {
        self.container = container
        bindEvents()
    }
    
    public convenience init() {
        self.init(container: .shared)
    }
    
    public func start() {
        AppLogger.shared.info("Starting AUTO CompanionManager...", category: .lifecycle)
        
        // Check stored credentials
        container.applicationState.hasGeminiKey = container.keychainService.hasKey(
            key: KeychainManager.geminiApiKeyAccount,
            service: KeychainManager.defaultService
        )
        container.applicationState.hasOmniRouteKey = container.keychainService.hasKey(
            key: KeychainManager.omniRouteApiKeyAccount,
            service: KeychainManager.defaultService
        )
        
        // Refresh permissions & displays
        container.permissionService.refreshPermissions()
        container.displayManager.refreshDisplays()
        
        // Setup menu bar icon
        container.menuBarManager.setupStatusItem(companionWindowManager: container.companionWindowManager)
        
        // Start voice session coordination
        VoiceSessionManager.shared.start()
        
        // If onboarding completed and permissions granted, activate overlay
        if container.applicationState.isOnboardingCompleted &&
           container.applicationState.allPermissionsGranted &&
           container.applicationState.generalPreferences.companionVisibility == .alwaysVisible {
            container.overlayWindowManager.showOverlays()
        } else if !container.applicationState.isOnboardingCompleted {
            // Auto open panel for onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.container.companionWindowManager.showPanel()
            }
        }
    }
    
    public func stop() {
        AppLogger.shared.info("Stopping AUTO CompanionManager...", category: .lifecycle)
        VoiceSessionManager.shared.stop()
        container.overlayWindowManager.hideOverlays()
        container.companionWindowManager.hidePanel()
    }
    
    private func bindEvents() {
        container.eventManager.eventSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: AUTOEvent) {
        switch event {
        case .requestToggleCompanionPanel:
            container.companionWindowManager.togglePanel()
        case .requestToggleOverlay:
            container.overlayWindowManager.toggleOverlays()
        case .requestOpenSettings:
            openSettingsWindow()
        case .requestOpenOnboarding:
            container.applicationState.isOnboardingCompleted = false
            container.companionWindowManager.showPanel()
        default:
            break
        }
    }
    
    public func openSettingsWindow() {
        // Toggle settings modal or create native window
        container.applicationState.isSettingsOpen = true
        container.companionWindowManager.showPanel()
    }
}
