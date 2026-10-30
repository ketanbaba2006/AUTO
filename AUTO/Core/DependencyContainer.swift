//
//  DependencyContainer.swift
//  AUTO
//
//  Central Dependency Injection container decoupling services from UI and managers.
//  Enables testability, modularity, and clean service lifecycle.
//

import Foundation

@MainActor
public final class DependencyContainer: ObservableObject {
    public static let shared = DependencyContainer()
    
    public let applicationState: ApplicationState
    public let keychainService: KeychainService
    public let privacyService: PrivacyService
    public let permissionService: PermissionService
    public let eventManager: EventManager
    public let aiProviderManager: AIProviderService
    public let audioCaptureService: AudioCaptureService
    public let pushToTalkService: PushToTalkService
    public let screenCaptureService: ScreenCaptureService
    public let speechOutputService: SpeechOutputService
    public let cursorManager: CursorManager
    public let agentManager: AgentManager
    public let displayManager: DisplayManager
    public let menuBarManager: MenuBarManager
    public let companionWindowManager: CompanionWindowManager
    public let overlayWindowManager: OverlayWindowManager
    
    public init(
        applicationState: ApplicationState,
        keychainService: KeychainService,
        privacyService: PrivacyService,
        permissionService: PermissionService,
        eventManager: EventManager,
        aiProviderManager: AIProviderService,
        audioCaptureService: AudioCaptureService,
        pushToTalkService: PushToTalkService,
        screenCaptureService: ScreenCaptureService,
        speechOutputService: SpeechOutputService,
        cursorManager: CursorManager,
        agentManager: AgentManager,
        displayManager: DisplayManager,
        menuBarManager: MenuBarManager,
        companionWindowManager: CompanionWindowManager,
        overlayWindowManager: OverlayWindowManager
    ) {
        self.applicationState = applicationState
        self.keychainService = keychainService
        self.privacyService = privacyService
        self.permissionService = permissionService
        self.eventManager = eventManager
        self.aiProviderManager = aiProviderManager
        self.audioCaptureService = audioCaptureService
        self.pushToTalkService = pushToTalkService
        self.screenCaptureService = screenCaptureService
        self.speechOutputService = speechOutputService
        self.cursorManager = cursorManager
        self.agentManager = agentManager
        self.displayManager = displayManager
        self.menuBarManager = menuBarManager
        self.companionWindowManager = companionWindowManager
        self.overlayWindowManager = overlayWindowManager
    }
    
    public convenience init() {
        self.init(
            applicationState: .shared,
            keychainService: KeychainManager.shared,
            privacyService: PrivacyManager.shared,
            permissionService: PermissionManager.shared,
            eventManager: .shared,
            aiProviderManager: AIProviderManager.shared,
            audioCaptureService: AudioCaptureManager.shared,
            pushToTalkService: PushToTalkManager.shared,
            screenCaptureService: ScreenCaptureManager.shared,
            speechOutputService: SpeechOutputManager.shared,
            cursorManager: .shared,
            agentManager: .shared,
            displayManager: .shared,
            menuBarManager: .shared,
            companionWindowManager: .shared,
            overlayWindowManager: .shared
        )
    }
}
