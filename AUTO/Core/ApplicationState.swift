//
//  ApplicationState.swift
//  AUTO
//
//  Central observable state for the AUTO macOS companion.
//  Maintains unified application state across AppKit windows and SwiftUI views.
//

import SwiftUI
import Combine

@MainActor
public final class ApplicationState: ObservableObject {
    public static let shared = ApplicationState()
    
    // MARK: - Voice & Interaction State
    @Published public var voiceState: VoiceState = .idle
    @Published public var currentTranscript: String = ""
    @Published public var currentAudioLevel: Float = 0.0
    @Published public var currentResponseText: String = ""
    @Published public var activeSpatialPoint: SpatialPoint?
    @Published public var statusMessage: String = "Ready"
    
    // MARK: - Window & Overlay Visibility
    @Published public var isCompanionPanelOpen: Bool = false
    @Published public var isOverlayVisible: Bool = false
    @Published public var isSettingsOpen: Bool = false
    
    // MARK: - Onboarding & Lifecycle
    @Published public var isOnboardingCompleted: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingCompleted, forKey: "com.auto.hasCompletedOnboarding")
        }
    }
    
    // MARK: - Permissions State
    @Published public var hasMicrophonePermission: Bool = false
    @Published public var hasSpeechRecognitionPermission: Bool = false
    @Published public var hasScreenRecordingPermission: Bool = false
    @Published public var hasAccessibilityPermission: Bool = false
    @Published public var hasInputMonitoringPermission: Bool = false
    @Published public var hasNotificationPermission: Bool = false
    
    public var allPermissionsGranted: Bool {
        return hasMicrophonePermission && hasSpeechRecognitionPermission && hasScreenRecordingPermission && hasAccessibilityPermission
    }
    
    // MARK: - AI & Providers
    @Published public var activeAIProvider: AIProviderType = .gemini {
        didSet {
            UserDefaults.standard.set(activeAIProvider.rawValue, forKey: "com.auto.activeAIProvider")
        }
    }
    
    @Published public var hasGeminiKey: Bool = false
    @Published public var hasOmniRouteKey: Bool = false
    @Published public var lastTokenUsage: TokenUsage?
    
    @Published public var geminiConfig: AIProviderConfiguration {
        didSet {
            if let encoded = try? JSONEncoder().encode(geminiConfig) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.geminiConfig")
            }
        }
    }
    
    @Published public var omniRouteConfig: AIProviderConfiguration {
        didSet {
            if let encoded = try? JSONEncoder().encode(omniRouteConfig) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.omniRouteConfig")
            }
        }
    }
    
    // MARK: - OmniRoute Connection Profiles
    @Published public var omniRouteProfiles: [OmniRouteProfile] {
        didSet {
            if let encoded = try? JSONEncoder().encode(omniRouteProfiles) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.omniRouteProfiles")
            }
        }
    }
    
    @Published public var activeOmniRouteProfileId: UUID? {
        didSet {
            if let id = activeOmniRouteProfileId {
                UserDefaults.standard.set(id.uuidString, forKey: "com.auto.activeOmniRouteProfileId")
            } else {
                UserDefaults.standard.removeObject(forKey: "com.auto.activeOmniRouteProfileId")
            }
        }
    }
    
    // MARK: - Task-Based AI Routing
    @Published public var aiRoutingRules: [AIRoutingRule] {
        didSet {
            if let encoded = try? JSONEncoder().encode(aiRoutingRules) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.aiRoutingRules")
            }
        }
    }
    
    // MARK: - Conversation Settings
    @Published public var maxHistoryTurns: Int {
        didSet {
            UserDefaults.standard.set(maxHistoryTurns, forKey: "com.auto.maxHistoryTurns")
        }
    }
    
    // MARK: - User Preferences
    @Published public var generalPreferences: GeneralPreferences {
        didSet {
            if let encoded = try? JSONEncoder().encode(generalPreferences) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.generalPreferences")
            }
        }
    }
    
    @Published public var voicePreferences: VoicePreferences {
        didSet {
            if let encoded = try? JSONEncoder().encode(voicePreferences) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.voicePreferences")
            }
        }
    }
    
    // MARK: - Screen Awareness & Visual Intelligence
    @Published public var screenPreferences: ScreenCapturePreferences {
        didSet {
            if let encoded = try? JSONEncoder().encode(screenPreferences) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.screenPreferences")
            }
        }
    }
    
    @Published public var screenCaptureState: ScreenCaptureState = .idle
    @Published public var isScreenSharingActive: Bool = false
    @Published public var availableWindows: [WindowInfo] = []
    @Published public var activeScreenContext: VisualScreenContext?
    
    // MARK: - Automation & Cursor Control
    @Published public var automationPreferences: AutomationPreferences {
        didSet {
            if let encoded = try? JSONEncoder().encode(automationPreferences) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.automationPreferences")
            }
        }
    }
    @Published public var isAutomationExecuting: Bool = false
    @Published public var pendingConfirmationAction: AutomationAction? = nil
    @Published public var isEmergencyStopActive: Bool = false
    
    // MARK: - Autonomous Agent & Memory
    @Published public var agentPreferences: AgentPreferences {
        didSet {
            if let encoded = try? JSONEncoder().encode(agentPreferences) {
                UserDefaults.standard.set(encoded, forKey: "com.auto.agentPreferences")
                UserDefaults.standard.set(agentPreferences.isMemoryEnabled, forKey: "com.auto.isMemoryEnabled")
            }
        }
    }
    
    // MARK: - Hardware Displays
    @Published public var connectedDisplays: [DisplayInfo] = []
    
    // MARK: - Initialization
    public init() {
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "com.auto.hasCompletedOnboarding")
        
        // Active AI Provider
        if let savedProviderString = UserDefaults.standard.string(forKey: "com.auto.activeAIProvider"),
           let savedProvider = AIProviderType(rawValue: savedProviderString) {
            self.activeAIProvider = savedProvider
        } else {
            self.activeAIProvider = .gemini
        }
        
        // Gemini Config
        if let data = UserDefaults.standard.data(forKey: "com.auto.geminiConfig"),
           let decoded = try? JSONDecoder().decode(AIProviderConfiguration.self, from: data) {
            self.geminiConfig = decoded
        } else {
            self.geminiConfig = .defaultGeminiConfig()
        }
        
        // OmniRoute Config
        if let data = UserDefaults.standard.data(forKey: "com.auto.omniRouteConfig"),
           let decoded = try? JSONDecoder().decode(AIProviderConfiguration.self, from: data) {
            self.omniRouteConfig = decoded
        } else {
            self.omniRouteConfig = .defaultOmniRouteConfig()
        }
        
        // OmniRoute Profiles
        let loadedProfiles: [OmniRouteProfile]
        if let data = UserDefaults.standard.data(forKey: "com.auto.omniRouteProfiles"),
           let decoded = try? JSONDecoder().decode([OmniRouteProfile].self, from: data) {
            loadedProfiles = decoded
        } else {
            loadedProfiles = [OmniRouteProfile.defaultLocalProfile()]
        }
        self.omniRouteProfiles = loadedProfiles
        
        // Active Profile ID
        if let idString = UserDefaults.standard.string(forKey: "com.auto.activeOmniRouteProfileId"),
           let id = UUID(uuidString: idString) {
            self.activeOmniRouteProfileId = id
        } else {
            self.activeOmniRouteProfileId = loadedProfiles.first?.id
        }
        
        // AI Routing Rules
        if let data = UserDefaults.standard.data(forKey: "com.auto.aiRoutingRules"),
           let decoded = try? JSONDecoder().decode([AIRoutingRule].self, from: data) {
            self.aiRoutingRules = decoded
        } else {
            self.aiRoutingRules = AIRoutingRule.defaultRules()
        }
        
        // Conversation limits
        let savedMaxTurns = UserDefaults.standard.integer(forKey: "com.auto.maxHistoryTurns")
        self.maxHistoryTurns = savedMaxTurns > 0 ? savedMaxTurns : 10
        
        // General Preferences
        if let data = UserDefaults.standard.data(forKey: "com.auto.generalPreferences"),
           let decoded = try? JSONDecoder().decode(GeneralPreferences.self, from: data) {
            self.generalPreferences = decoded
        } else {
            self.generalPreferences = .default
        }
        
        // Voice Preferences
        if let data = UserDefaults.standard.data(forKey: "com.auto.voicePreferences"),
           let decoded = try? JSONDecoder().decode(VoicePreferences.self, from: data) {
            self.voicePreferences = decoded
        } else {
            self.voicePreferences = .default
        }
        
        // Screen Preferences
        if let data = UserDefaults.standard.data(forKey: "com.auto.screenPreferences"),
           let decoded = try? JSONDecoder().decode(ScreenCapturePreferences.self, from: data) {
            self.screenPreferences = decoded
        } else {
            self.screenPreferences = .default
        }
        
        // Automation Preferences
        if let data = UserDefaults.standard.data(forKey: "com.auto.automationPreferences"),
           let decoded = try? JSONDecoder().decode(AutomationPreferences.self, from: data) {
            self.automationPreferences = decoded
        } else {
            self.automationPreferences = .default
        }
        
        // Agent & Memory Preferences
        if let data = UserDefaults.standard.data(forKey: "com.auto.agentPreferences"),
           let decoded = try? JSONDecoder().decode(AgentPreferences.self, from: data) {
            self.agentPreferences = decoded
        } else {
            self.agentPreferences = .default
        }
    }
    
    public func resetSession() {
        voiceState = .idle
        currentTranscript = ""
        currentResponseText = ""
        activeSpatialPoint = nil
        currentAudioLevel = 0.0
        statusMessage = "Ready"
        lastTokenUsage = nil
        activeScreenContext = nil
        if screenCaptureState != .sharing {
            screenCaptureState = .idle
        }
    }
}
