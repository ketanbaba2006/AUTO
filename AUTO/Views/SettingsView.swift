//
//  SettingsView.swift
//  AUTO
//
//  Complete native macOS settings interface for AUTO:
//  - General: Appearance, Launch at Login, Visibility
//  - Gemini: Primary AI configuration, Keychain key storage, model selection, live test
//  - OmniRoute: Optional gateway, Local & Remote profiles, dynamic discovery, test
//  - AI Routing & Models: Task-based routing rules, dynamic model browser
//  - Conversation: Context limits, memory retention, session reset
//  - Voice: Audio input/output preferences, speech rate, auto-speak
//  - Screen: Multi-monitor display inspection, permission status
//  - Privacy: Zero telemetry confirmation, ephemeral screenshots, data purging
//

import SwiftUI
import ServiceManagement

public enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case gemini = "Gemini"
    case omniRoute = "OmniRoute"
    case routing = "AI Routing"
    case conversation = "Conversation"
    case voice = "Voice"
    case screen = "Screen"
    case automation = "Automation"
    case memory = "Memory"
    case privacy = "Privacy"
    case permissions = "Permissions"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .gemini: return "sparkles"
        case .omniRoute: return "network"
        case .routing: return "arrow.triangle.branch"
        case .conversation: return "bubble.left.and.bubble.right.fill"
        case .voice: return "waveform"
        case .screen: return "display.2"
        case .automation: return "cursorarrow.motionlines"
        case .memory: return "brain.head.profile"
        case .privacy: return "lock.shield.fill"
        case .permissions: return "checkmark.shield.fill"
        case .about: return "info.circle.fill"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject public var appState: ApplicationState
    @State private var selectedTab: SettingsTab = .general
    
    // Gemini state
    @State private var geminiApiKeyInput: String = ""
    @State private var isGeminiKeySaved: Bool = false
    @State private var isTestingGemini: Bool = false
    @State private var geminiTestResult: (success: Bool, message: String)?
    @State private var discoveredGeminiModels: [AIModelInfo] = []
    
    // OmniRoute state
    @State private var omniRouteApiKeyInput: String = ""
    @State private var isOmniRouteKeySaved: Bool = false
    @State private var isTestingOmniRoute: Bool = false
    @State private var omniRouteTestResult: (success: Bool, message: String)?
    @State private var discoveredOmniRouteModels: [AIModelInfo] = []
    @State private var showAddProfileSheet: Bool = false
    @State private var newProfileName: String = ""
    @State private var newProfileBaseURL: String = "http://localhost:20128/v1"
    @State private var newProfileType: OmniRouteProfile.ConnectionType = .local
    
    // Dynamic Model Browser
    @State private var modelBrowserProvider: AIProviderType = .gemini
    @State private var isRefreshingModels: Bool = false
    
    // Privacy state
    @State private var showPurgeConfirmation: Bool = false
    @State private var purgeStatusMessage: String?
    
    // Screen Awareness state
    @State private var isPerformingManualCapture: Bool = false
    @State private var manualCaptureStatus: String? = nil
    @State private var isRefreshingWindowList: Bool = false
    
    public init(appState: ApplicationState) {
        self.appState = appState
    }
    
    public init() {
        self.appState = .shared
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            tabBarHeader
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            ScrollView {
                VStack(spacing: 18) {
                    switch selectedTab {
                    case .general:
                        generalSection
                    case .gemini:
                        geminiSection
                    case .omniRoute:
                        omniRouteSection
                    case .routing:
                        routingAndModelsSection
                    case .conversation:
                        conversationSection
                    case .voice:
                        voiceSection
                    case .screen:
                        screenSection
                    case .automation:
                        automationSection
                    case .memory:
                        memorySection
                    case .privacy:
                        privacySection
                    case .permissions:
                        permissionsSection
                    case .about:
                        AboutView()
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 540, height: 500)
        .background(
            BrandTheme.Colors.deepNavy
        )
        .onAppear {
            loadKeychainKeys()
        }
    }
    
    // MARK: - Tab Bar Header
    private var tabBarHeader: some View {
        VStack(spacing: 8) {
            // Branded Top Bar
            HStack(spacing: 8) {
                Image(nsImage: BrandAssetManager.shared.mascotImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(BrandTheme.appName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.Gradients.titleGradient)
                
                Text("Settings")
                    .font(.system(size: 11))
                    .foregroundColor(BrandTheme.Colors.textTertiary)
                
                Spacer()
                
                Text("v\(BrandTheme.version)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(BrandTheme.Colors.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BrandTheme.Colors.cyan.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(SettingsTab.allCases) { tab in
                        Button(action: { selectedTab = tab }) {
                            HStack(spacing: 5) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 11))
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .regular, design: .rounded))
                            }
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(
                                selectedTab == tab ? Color.white.opacity(0.14) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }
        }
        .background(Color.black.opacity(0.25))
    }
    
    // MARK: - General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingGroupHeader("Application Appearance & Behavior")
            
            HStack {
                Text("Appearance")
                    .foregroundColor(.white)
                Spacer()
                Picker("", selection: $appState.generalPreferences.appearanceMode) {
                    ForEach(AppAppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Companion Visibility")
                        .foregroundColor(.white)
                    Text("Controls whether the floating companion is always present or only during hotkey hold.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                Picker("", selection: $appState.generalPreferences.companionVisibility) {
                    ForEach(CompanionVisibilityMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }
            
            Toggle("Start Minimized in Menu Bar", isOn: $appState.generalPreferences.startMinimized)
                .foregroundColor(.white)
            
            Toggle("Launch AUTO at System Login", isOn: $appState.generalPreferences.launchAtLogin)
                .foregroundColor(.white)
                .onChange(of: appState.generalPreferences.launchAtLogin) { _, newValue in
                    updateLaunchAtLogin(newValue)
                }
        }
    }
    
    // MARK: - Gemini Section
    private var geminiSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                settingGroupHeader("Google Gemini API (Primary Engine)")
                Spacer()
                Toggle("Enabled", isOn: $appState.geminiConfig.isEnabled)
                    .labelsHidden()
            }
            
            Text("Google Gemini handles natural language, reasoning, and multi-monitor screen understanding.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            // API Key Management
            VStack(alignment: .leading, spacing: 6) {
                Text("API Key (Stored securely in macOS Keychain)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    SecureField(isGeminiKeySaved ? "••••••••••••••••••••••••" : "Paste Gemini API Key", text: $geminiApiKeyInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(8)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(.white)
                    
                    Button("Save") {
                        saveGeminiKey()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.cyan, in: RoundedRectangle(cornerRadius: 8))
                    .disabled(geminiApiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    if isGeminiKeySaved {
                        Button("Clear") {
                            removeGeminiKey()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 7)
                    }
                }
                
                if isGeminiKeySaved {
                    Label("Key securely saved in Keychain", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                }
            }
            
            // Model Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Selected Model")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    TextField("Model ID (e.g. gemini-2.5-flash)", text: $appState.geminiConfig.selectedModelId)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(8)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(.white)
                    
                    Button(action: { fetchGeminiModels() }) {
                        HStack(spacing: 4) {
                            if isRefreshingModels {
                                ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11))
                            }
                            Text("Fetch Models")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRefreshingModels || !isGeminiKeySaved)
                }
            }
            
            // Connection Testing
            HStack(spacing: 12) {
                Button(action: { testGeminiConnection() }) {
                    HStack(spacing: 6) {
                        if isTestingGemini {
                            ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "bolt.fill")
                        }
                        Text("Test Gemini Connection")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isTestingGemini || !isGeminiKeySaved)
                
                if let result = geminiTestResult {
                    HStack(spacing: 6) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(result.success ? .green : .orange)
                        Text(result.message)
                            .font(.system(size: 11))
                            .foregroundColor(result.success ? .green : .orange)
                    }
                }
            }
            
            // Token Usage metrics
            if let usage = appState.lastTokenUsage {
                HStack(spacing: 16) {
                    tokenBadge(label: "Prompt Tokens", count: usage.promptTokens)
                    tokenBadge(label: "Candidates", count: usage.completionTokens)
                    tokenBadge(label: "Total Session", count: usage.totalTokens)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - OmniRoute Section
    private var omniRouteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                settingGroupHeader("OmniRoute API Gateway (Optional)")
                Spacer()
                Toggle("Enabled", isOn: $appState.omniRouteConfig.isEnabled)
                    .labelsHidden()
            }
            
            Text("OmniRoute routes requests to alternative local or remote OpenAI-compatible models.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            // Profile Selector & Management
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Connection Profiles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Button("+ Add Profile") {
                        showAddProfileSheet.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.cyan)
                }
                
                ForEach(appState.omniRouteProfiles) { profile in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(profile.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(profile.connectionType.rawValue)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Color.cyan.opacity(0.15), in: Capsule())
                                
                                if appState.activeOmniRouteProfileId == profile.id {
                                    Text("ACTIVE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.green.opacity(0.15), in: Capsule())
                                }
                            }
                            Text(profile.baseURL)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if appState.activeOmniRouteProfileId != profile.id {
                            Button("Select") {
                                appState.activeOmniRouteProfileId = profile.id
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                        }
                        
                        if appState.omniRouteProfiles.count > 1 {
                            Button(action: { deleteProfile(profile) }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Active Profile Details
            if let activeId = appState.activeOmniRouteProfileId,
               let activeIndex = appState.omniRouteProfiles.firstIndex(where: { $0.id == activeId }) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Profile Settings: \(appState.omniRouteProfiles[activeIndex].name)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base URL")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        TextField("http://localhost:20128/v1", text: $appState.omniRouteProfiles[activeIndex].baseURL)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .padding(8)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Model ID")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        TextField("default", text: $appState.omniRouteProfiles[activeIndex].defaultModel)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .padding(8)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key (Optional for local servers; Keychain stored)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        HStack {
                            SecureField(isOmniRouteKeySaved ? "••••••••••••••••" : "Optional Bearer Token", text: $omniRouteApiKeyInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(8)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                            
                            Button("Save Key") {
                                saveOmniRouteKey(for: appState.omniRouteProfiles[activeIndex].apiKeyAccount)
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.cyan, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            
            // Test Connection
            HStack(spacing: 12) {
                Button(action: { testOmniRouteConnection() }) {
                    HStack(spacing: 6) {
                        if isTestingOmniRoute {
                            ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "bolt.horizontal.fill")
                        }
                        Text("Test OmniRoute Connection")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isTestingOmniRoute)
                
                if let result = omniRouteTestResult {
                    HStack(spacing: 6) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(result.success ? .green : .orange)
                        Text(result.message)
                            .font(.system(size: 11))
                            .foregroundColor(result.success ? .green : .orange)
                    }
                }
            }
            
            // Add Profile Popover / Sheet
            if showAddProfileSheet {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add New OmniRoute Profile")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    TextField("Profile Name", text: $newProfileName)
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundColor(.white)
                    
                    TextField("Base URL (e.g. http://localhost:20128/v1)", text: $newProfileBaseURL)
                        .textFieldStyle(.plain)
                        .padding(6)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundColor(.white)
                    
                    Picker("Type", selection: $newProfileType) {
                        Text("Local").tag(OmniRouteProfile.ConnectionType.local)
                        Text("Remote").tag(OmniRouteProfile.ConnectionType.remote)
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Button("Cancel") { showAddProfileSheet = false }
                            .buttonStyle(.plain)
                            .foregroundColor(.gray)
                        Spacer()
                        Button("Create Profile") { createNewProfile() }
                            .buttonStyle(.plain)
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.cyan, in: RoundedRectangle(cornerRadius: 6))
                            .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Routing & Models Section
    private var routingAndModelsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingGroupHeader("Task-Based AI Routing")
            Text("Configure which AI provider handles specific computational tasks.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                ForEach(0..<appState.aiRoutingRules.count, id: \.self) { index in
                    HStack {
                        Text(appState.aiRoutingRules[index].task.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $appState.aiRoutingRules[index].provider) {
                            ForEach(AIProviderType.allCases) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 180)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            
            Button("Reset to Recommended Defaults") {
                appState.aiRoutingRules = AIRoutingRule.defaultRules()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundColor(.cyan)
            
            Divider().background(Color.white.opacity(0.1))
            
            settingGroupHeader("Dynamic Model Browser")
            
            HStack {
                Picker("Provider", selection: $modelBrowserProvider) {
                    ForEach(AIProviderType.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
                
                Spacer()
                
                Button(action: { refreshDiscoveredModels() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
            }
            
            let models = (modelBrowserProvider == .gemini) ? discoveredGeminiModels : discoveredOmniRouteModels
            if models.isEmpty {
                Text("No cached models. Click 'Refresh' or run a connection test to discover available models.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(models) { model in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(model.displayName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    if model.supportsVision {
                                        Text("Vision")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.yellow)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.yellow.opacity(0.15), in: Capsule())
                                    }
                                    if model.isLocal {
                                        Text("Local")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.green.opacity(0.15), in: Capsule())
                                    }
                                }
                                Text("ID: \(model.id)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button("Select") {
                                if modelBrowserProvider == .gemini {
                                    appState.geminiConfig.selectedModelId = model.id
                                } else {
                                    appState.omniRouteConfig.selectedModelId = model.id
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.cyan)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }
    
    // MARK: - Conversation Section
    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingGroupHeader("Conversation History & Memory")
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Maximum Context History")
                        .foregroundColor(.white)
                    Text("Controls how many previous turns are sent to the AI for conversational context.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                Picker("", selection: $appState.maxHistoryTurns) {
                    Text("5 Turns").tag(5)
                    Text("10 Turns").tag(10)
                    Text("20 Turns").tag(20)
                    Text("30 Turns").tag(30)
                }
                .pickerStyle(.menu)
                .frame(width: 130)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            settingGroupHeader("Session Management")
            
            HStack(spacing: 12) {
                Button(action: { ConversationManager.shared.clearConversation() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Clear Conversation")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                Button(action: { ConversationManager.shared.resetSession() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Session")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Voice Section
    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingGroupHeader("Voice Input & Hold-to-Talk")
            
            // Push-to-Talk Trigger selection
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Push-to-Talk Trigger")
                        .foregroundColor(.white)
                    Text("Hold designated key to speak; release to process AI guidance.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                Picker("", selection: $appState.voicePreferences.pushToTalkTrigger) {
                    ForEach(PushToTalkTrigger.allCases) { trigger in
                        Text(trigger.rawValue).tag(trigger)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 190)
            }
            
            // Microphone Device Selection
            let mics = MicrophoneDeviceManager.shared.listAvailableInputDevices()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Input Microphone")
                        .foregroundColor(.white)
                    Text(mics.isEmpty ? "No input devices found" : "Connected audio input source")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                Picker("", selection: Binding(
                    get: { appState.voicePreferences.selectedMicId ?? mics.first?.id ?? "" },
                    set: { appState.voicePreferences.selectedMicId = $0 }
                )) {
                    ForEach(mics) { mic in
                        Text(mic.name).tag(mic.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 190)
            }
            
            // Speech Recognition Locale
            HStack {
                Text("Recognition Language")
                    .foregroundColor(.white)
                Spacer()
                Picker("", selection: $appState.voicePreferences.speechRecognitionLocale) {
                    Text("English (US)").tag("en-US")
                    Text("English (UK)").tag("en-GB")
                    Text("English (Australia)").tag("en-AU")
                    Text("English (India)").tag("en-IN")
                    Text("Spanish").tag("es-ES")
                    Text("French").tag("fr-FR")
                    Text("German").tag("de-DE")
                    Text("Japanese").tag("ja-JP")
                }
                .pickerStyle(.menu)
                .frame(width: 190)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            settingGroupHeader("Natural Speech Output (Text-to-Speech)")
            
            Toggle("Auto-Speak AI Responses", isOn: $appState.voicePreferences.autoSpeakResponse)
                .foregroundColor(.white)
            
            // Natural Voice Picker
            let voices = SpeechOutputManager.shared.availableVoices()
            if !voices.isEmpty {
                HStack {
                    Text("Voice Synthesizer")
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { appState.voicePreferences.voiceIdentifier ?? voices.first?.id ?? "" },
                        set: { appState.voicePreferences.voiceIdentifier = $0 }
                    )) {
                        ForEach(voices.prefix(20)) { voice in
                            Text("\(voice.name) (\(voice.language))").tag(voice.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 220)
                }
            }
            
            // Speech Rate
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Speech Rate")
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.1fx", appState.voicePreferences.speechRate))
                        .foregroundColor(.gray)
                        .font(.system(size: 11, design: .monospaced))
                }
                Slider(value: $appState.voicePreferences.speechRate, in: 0.5...1.5, step: 0.05)
                    .accentColor(.cyan)
            }
            
            // Preview button
            HStack {
                Button(action: {
                    SpeechOutputManager.shared.speak(text: "Hello! I am AUTO, your personal desktop companion.")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Test Voice Output")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                if SpeechOutputManager.shared.isSpeaking {
                    Button("Stop") {
                        SpeechOutputManager.shared.stopSpeaking()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Screen Section
    private var screenSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingGroupHeader("Screen Awareness & Sharing Controls")
            
            Toggle("Enable Screen Awareness", isOn: $appState.screenPreferences.isScreenAwarenessEnabled)
                .toggleStyle(.switch)
                .tint(BrandTheme.Colors.cyan)
            
            Text("Allows AUTO to capture authorized screen context and answer questions about what is on your display.")
                .font(.system(size: 11))
                .foregroundColor(BrandTheme.Colors.textSecondary)
            
            // Mode Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Awareness Mode")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                
                Picker("", selection: $appState.screenPreferences.mode) {
                    ForEach(ScreenAwarenessMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(appState.screenPreferences.mode.description)
                    .font(.system(size: 10))
                    .foregroundColor(BrandTheme.Colors.textTertiary)
                    .padding(.top, 2)
            }
            .padding(10)
            .background(BrandTheme.Colors.surfaceNavy, in: RoundedRectangle(cornerRadius: 8))
            
            // Sharing and Manual Capture Action Bar
            HStack(spacing: 10) {
                if appState.isScreenSharingActive {
                    Button(action: {
                        ScreenCaptureManager.shared.stopContinuousSharing()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Screen Sharing")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 6, height: 6)
                        Text("Active Sharing Session")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.cyan)
                    }
                } else {
                    Button(action: {
                        ScreenCaptureManager.shared.startContinuousSharing()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "play.circle.fill")
                            Text("Start Screen Sharing")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(BrandTheme.Colors.cyan, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .disabled(!appState.screenPreferences.isScreenAwarenessEnabled || !appState.hasScreenRecordingPermission)
                }
                
                Spacer()
                
                // Manual capture button
                Button(action: { performManualCapture() }) {
                    HStack(spacing: 4) {
                        if isPerformingManualCapture {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "camera.viewfinder")
                        }
                        Text("Capture Now")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(isPerformingManualCapture || !appState.hasScreenRecordingPermission)
            }
            .padding(10)
            .background(BrandTheme.Colors.surfaceNavy, in: RoundedRectangle(cornerRadius: 8))
            
            if let status = manualCaptureStatus {
                Text(status)
                    .font(.system(size: 11))
                    .foregroundColor(status.contains("Error") ? .red : BrandTheme.Colors.cyan)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // MARK: - Source Target Selection
            settingGroupHeader("Capture Target & Source")
            
            VStack(alignment: .leading, spacing: 10) {
                Picker("Target Source", selection: $appState.screenPreferences.sourceType) {
                    ForEach(CaptureSourceType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                if appState.screenPreferences.sourceType == .display {
                    // Display selector
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Display")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                        
                        Picker("", selection: $appState.screenPreferences.selectedDisplayID) {
                            Text("Auto (Display Containing Cursor)").tag(Optional<CGDirectDisplayID>.none)
                            ForEach(appState.connectedDisplays) { disp in
                                Text("\(disp.name) (\(Int(disp.frame.width))×\(Int(disp.frame.height)))").tag(Optional(disp.id))
                            }
                        }
                        .labelsHidden()
                    }
                } else {
                    // Window selector
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Selected Application Window")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { refreshWindows() }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh Windows")
                                }
                                .font(.system(size: 10))
                                .foregroundColor(BrandTheme.Colors.cyan)
                            }
                            .buttonStyle(.plain)
                            .disabled(isRefreshingWindowList)
                        }
                        
                        Picker("", selection: $appState.screenPreferences.selectedWindowID) {
                            Text("Select an open window...").tag(Optional<CGWindowID>.none)
                            ForEach(appState.availableWindows) { win in
                                Text(win.displayName).tag(Optional(win.id))
                            }
                        }
                        .labelsHidden()
                    }
                }
            }
            .padding(10)
            .background(BrandTheme.Colors.surfaceNavy, in: RoundedRectangle(cornerRadius: 8))
            
            Divider().background(Color.white.opacity(0.1))
            
            // MARK: - Quality & Accessibility Context
            settingGroupHeader("Visual Intelligence & Image Quality")
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Maximum Dimension")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $appState.screenPreferences.maxDimension) {
                        Text("1920 px (High Detail)").tag(1920)
                        Text("1536 px (Balanced)").tag(1536)
                        Text("1280 px (Fast Latency)").tag(1280)
                    }
                    .frame(width: 170)
                }
                
                Toggle("Include Accessibility Context", isOn: $appState.screenPreferences.includeAccessibilityContext)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                
                Text("When granted, AUTO inspects the active application title and focused window to provide grounded assistance.")
                    .font(.system(size: 10))
                    .foregroundColor(BrandTheme.Colors.textTertiary)
            }
            .padding(10)
            .background(BrandTheme.Colors.surfaceNavy, in: RoundedRectangle(cornerRadius: 8))
            
            Divider().background(Color.white.opacity(0.1))
            
            // MARK: - Hardware Displays
            settingGroupHeader("Hardware Display Diagnostics")
            
            VStack(spacing: 8) {
                ForEach(appState.connectedDisplays) { display in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(display.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                if display.isPrimary {
                                    Text("Main")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.cyan)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.cyan.opacity(0.15), in: Capsule())
                                }
                            }
                            
                            Text("Bounds: \(Int(display.frame.origin.x)),\(Int(display.frame.origin.y)) | \(Int(display.frame.width)) × \(Int(display.frame.height)) @ \(Int(display.scaleFactor))x scale")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            settingGroupHeader("Screen & Accessibility Permissions")
            
            VStack(spacing: 8) {
                PermissionRow(type: .screenRecording, isGranted: appState.hasScreenRecordingPermission) {
                    _ = ScreenCapturePermissionManager.shared.requestScreenCaptureAccess()
                }
                PermissionRow(type: .accessibility, isGranted: appState.hasAccessibilityPermission) {
                    _ = PermissionManager.shared.requestAccessibilityPermission()
                }
            }
            
            // Privacy notice
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(BrandTheme.Colors.cyan)
                    .font(.system(size: 12))
                Text("Zero Permanent Storage: Captured screen content is held ephemerally in RAM during AI reasoning and discarded immediately. No image files are saved to your drive.")
                    .font(.system(size: 10))
                    .foregroundColor(BrandTheme.Colors.textSecondary)
            }
            .padding(10)
            .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func performManualCapture() {
        isPerformingManualCapture = true
        manualCaptureStatus = "Capturing screen..."
        Task {
            do {
                let context = try await ScreenContextManager.shared.captureCurrentContext(mode: .onDemand)
                isPerformingManualCapture = false
                manualCaptureStatus = "Captured successfully (\(context.screenshotJPEG.count / 1024) KB)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    manualCaptureStatus = nil
                }
            } catch {
                isPerformingManualCapture = false
                manualCaptureStatus = "Capture Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func refreshWindows() {
        isRefreshingWindowList = true
        Task {
            _ = try? await WindowCaptureManager.shared.refreshShareableWindows()
            isRefreshingWindowList = false
        }
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingGroupHeader("Privacy & Processing Architecture")
            
            VStack(alignment: .leading, spacing: 10) {
                privacyFactRow(
                    icon: "shield.lefthalf.filled",
                    title: "Local vs. Cloud AI Disclosure",
                    description: "Desktop automation, coordinate mapping, audio metering, local memory, and emergency stop run 100% locally. Voice text and screenshots are sent via HTTPS strictly to your configured provider (Google Gemini or OmniRoute)."
                )
                privacyFactRow(
                    icon: "lock.shield.fill",
                    title: "Zero Telemetry Policy",
                    description: "AUTO contains zero analytics, zero user behavior tracking, and zero crash telemetry. No accounts or registrations required."
                )
                privacyFactRow(
                    icon: "key.fill",
                    title: "macOS Keychain Security",
                    description: "API keys are encrypted and stored exclusively in your local hardware-backed macOS Keychain."
                )
                privacyFactRow(
                    icon: "eye.slash.fill",
                    title: "Ephemeral Screenshots",
                    description: "Screenshots are held in volatile RAM only during inference and discarded immediately afterward."
                )
                privacyFactRow(
                    icon: "hand.raised.fill",
                    title: "Sensitive Credential Rejection",
                    description: "Local memory actively scans and rejects passwords, bearer tokens, private keys, and CVVs."
                )
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            
            settingGroupHeader("Data Retention & Granular Purging")
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Conversation Retention:")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $appState.agentPreferences.retentionDays) {
                        Text("7 Days").tag(7)
                        Text("30 Days").tag(30)
                        Text("90 Days").tag(90)
                        Text("Indefinite").tag(365)
                    }
                    .frame(width: 130)
                }
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack(spacing: 10) {
                    Button("Clear Chat History") {
                        ConversationMemory.shared.clear()
                        purgeStatusMessage = "Conversation history cleared."
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    
                    Button("Clear Local Memory") {
                        MemoryManager.shared.clearAll()
                        purgeStatusMessage = "Local memory cleared."
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    
                    Button("Clear Task History") {
                        ActionExecutionManager.shared.clearHistory()
                        purgeStatusMessage = "Task action history cleared."
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            
            settingGroupHeader("Master Data Purge")
            
            Button("Purge All Local Data & Reset Keychain") {
                showPurgeConfirmation = true
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.red)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
            .alert("Purge All Local Data?", isPresented: $showPurgeConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Purge All", role: .destructive) {
                    purgeAllData()
                }
            } message: {
                Text("This will remove all stored API keys from Keychain, reset user preferences, clear conversation memory, and wipe local agent memory.")
            }
            
            if let msg = purgeStatusMessage {
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Permissions Section
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            settingGroupHeader("Unified System Permissions")
            
            Text("AUTO requires macOS system permissions to observe desktop state, hear voice requests, and guide cursor movements. If permissions are withheld, AUTO gracefully degrades into reduced capability mode.")
                .font(.system(size: 11))
                .foregroundColor(BrandTheme.Colors.textSecondary)
            
            VStack(spacing: 8) {
                permissionRowItem(
                    name: "Microphone",
                    icon: "mic.fill",
                    status: appState.hasMicrophonePermission,
                    purpose: "Required for Hold-Control push-to-talk voice conversations.",
                    reducedMode: "Voice interactions disabled; text chat remains functional.",
                    onAction: {
                        Task { _ = await PermissionManager.shared.requestMicrophonePermission() }
                    }
                )
                
                permissionRowItem(
                    name: "Speech Recognition",
                    icon: "waveform.badge.mic",
                    status: appState.hasSpeechRecognitionPermission,
                    purpose: "Transcribes spoken voice into text locally or via Apple Speech.",
                    reducedMode: "Spoken transcription disabled; typed chat remains functional.",
                    onAction: {
                        Task { _ = await PermissionManager.shared.requestSpeechRecognitionPermission() }
                    }
                )
                
                permissionRowItem(
                    name: "Screen Recording",
                    icon: "display",
                    status: appState.hasScreenRecordingPermission,
                    purpose: "Captures display snapshots for visual understanding and element localization.",
                    reducedMode: "Visual screen analysis disabled; chat answers remain functional.",
                    onAction: {
                        _ = PermissionManager.shared.requestScreenRecordingPermission()
                    }
                )
                
                permissionRowItem(
                    name: "Accessibility",
                    icon: "hand.raised.fill",
                    status: appState.hasAccessibilityPermission,
                    purpose: "Enables UI element inspection and assistive cursor movement guidance.",
                    reducedMode: "Desktop automation disabled; guidance limited to chat answers.",
                    onAction: {
                        _ = PermissionManager.shared.requestAccessibilityPermission()
                    }
                )
                
                permissionRowItem(
                    name: "Notifications",
                    icon: "bell.badge.fill",
                    status: appState.hasNotificationPermission,
                    purpose: "Delivers task completion alerts and approval requests when AUTO is in background.",
                    reducedMode: "Background task alerts will not trigger banner notifications.",
                    onAction: {
                        Task { _ = await PermissionManager.shared.requestNotificationPermission() }
                    }
                )
            }
            
            HStack {
                Spacer()
                Button("Refresh All Permissions") {
                    PermissionManager.shared.refreshPermissions()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(BrandTheme.Colors.cyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(BrandTheme.Colors.cyan.opacity(0.12), in: Capsule())
            }
        }
    }
    
    private func permissionRowItem(
        name: String,
        icon: String,
        status: Bool,
        purpose: String,
        reducedMode: String,
        onAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(status ? .green : .orange)
                    .frame(width: 20)
                
                Text(name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if status {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Granted")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    }
                } else {
                    Button(action: onAction) {
                        Text("Grant / Settings")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cyan, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(purpose)
                .font(.system(size: 10))
                .foregroundColor(BrandTheme.Colors.textSecondary)
            
            if !status {
                Text("Reduced mode: \(reducedMode)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.orange.opacity(0.9))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Component Helpers
    private func settingGroupHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }
    
    private func tokenBadge(label: String, count: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }
    
    private func privacyFactRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.green)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Actions
    private func loadKeychainKeys() {
        isGeminiKeySaved = KeychainManager.shared.hasKey(
            key: KeychainManager.geminiApiKeyAccount,
            service: KeychainManager.defaultService
        )
        isOmniRouteKeySaved = KeychainManager.shared.hasKey(
            key: KeychainManager.omniRouteApiKeyAccount,
            service: KeychainManager.defaultService
        )
    }
    
    private func saveGeminiKey() {
        let trimmed = geminiApiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try KeychainManager.shared.save(
                key: KeychainManager.geminiApiKeyAccount,
                value: trimmed,
                service: KeychainManager.defaultService
            )
            isGeminiKeySaved = true
            appState.hasGeminiKey = true
            geminiApiKeyInput = ""
        } catch {
            geminiTestResult = (false, "Keychain save error: \(error.localizedDescription)")
        }
    }
    
    private func removeGeminiKey() {
        try? KeychainManager.shared.delete(
            key: KeychainManager.geminiApiKeyAccount,
            service: KeychainManager.defaultService
        )
        isGeminiKeySaved = false
        appState.hasGeminiKey = false
        geminiTestResult = nil
    }
    
    private func saveOmniRouteKey(for account: String) {
        let trimmed = omniRouteApiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try? KeychainManager.shared.save(
            key: account,
            value: trimmed,
            service: KeychainManager.defaultService
        )
        isOmniRouteKeySaved = true
        appState.hasOmniRouteKey = true
        omniRouteApiKeyInput = ""
    }
    
    private func testGeminiConnection() {
        isTestingGemini = true
        geminiTestResult = nil
        Task {
            let start = Date()
            do {
                let success = try await AIProviderManager.shared.testConnection(for: .gemini)
                let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                geminiTestResult = (success, "Connected (\(elapsed)ms)")
            } catch {
                geminiTestResult = (false, error.localizedDescription)
            }
            isTestingGemini = false
        }
    }
    
    private func testOmniRouteConnection() {
        isTestingOmniRoute = true
        omniRouteTestResult = nil
        Task {
            let start = Date()
            do {
                let success = try await AIProviderManager.shared.testConnection(for: .omniRoute)
                let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                omniRouteTestResult = (success, "Connected (\(elapsed)ms)")
            } catch {
                omniRouteTestResult = (false, error.localizedDescription)
            }
            isTestingOmniRoute = false
        }
    }
    
    private func fetchGeminiModels() {
        isRefreshingModels = true
        Task {
            if let models = try? await AIProviderManager.shared.discoverModels(for: .gemini) {
                discoveredGeminiModels = models
            }
            isRefreshingModels = false
        }
    }
    
    private func refreshDiscoveredModels() {
        Task {
            if modelBrowserProvider == .gemini {
                if let models = try? await AIProviderManager.shared.discoverModels(for: .gemini) {
                    discoveredGeminiModels = models
                }
            } else {
                if let models = try? await AIProviderManager.shared.discoverModels(for: .omniRoute) {
                    discoveredOmniRouteModels = models
                }
            }
        }
    }
    
    // MARK: - Automation Section
    private var automationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrandTheme.Colors.cyan)
                Text("Cursor Intelligence & Desktop Automation")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Emergency Failsafe Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .foregroundColor(EmergencyStopManager.shared.isEmergencyStopActive ? .yellow : .red)
                    Text("Emergency Failsafe")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if EmergencyStopManager.shared.isEmergencyStopActive {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.2), in: Capsule())
                    }
                }
                
                Text("Immediately halts any running mouse movements, click sequences, or key entries. Safe state is restored automatically.")
                    .font(.system(size: 11))
                    .foregroundColor(BrandTheme.Colors.textTertiary)
                
                HStack {
                    Button(action: {
                        if EmergencyStopManager.shared.isEmergencyStopActive {
                            EmergencyStopManager.shared.resetEmergencyStop()
                        } else {
                            EmergencyStopManager.shared.triggerEmergencyStop()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: EmergencyStopManager.shared.isEmergencyStopActive ? "arrow.counterclockwise" : "stop.fill")
                            Text(EmergencyStopManager.shared.isEmergencyStopActive ? "Reset Emergency Stop" : "Trigger Emergency Stop Now")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(EmergencyStopManager.shared.isEmergencyStopActive ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(EmergencyStopManager.shared.isEmergencyStopActive ? Color.yellow : Color.red, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
            
            // Input Controls
            VStack(alignment: .leading, spacing: 10) {
                Text("Input Automation Controls")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Toggle("Enable Mouse Movement & Clicking", isOn: $appState.automationPreferences.isMouseControlEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: BrandTheme.Colors.cyan))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                
                Toggle("Enable Keyboard Text Entry", isOn: $appState.automationPreferences.isKeyboardControlEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: BrandTheme.Colors.cyan))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                
                Toggle("Render Visual Cursor Overlay & Reticles", isOn: $appState.automationPreferences.isCursorOverlayEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: BrandTheme.Colors.cyan))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            
            // Safety & Gating
            VStack(alignment: .leading, spacing: 10) {
                Text("Safety & Permission Gating")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Toggle("Require User Confirmation for High-Risk Actions", isOn: $appState.automationPreferences.requireConfirmationForHighRisk)
                    .toggleStyle(SwitchToggleStyle(tint: BrandTheme.Colors.cyan))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                
                Toggle("Safe Action Mode (Verify Element Focus)", isOn: $appState.automationPreferences.safeActionMode)
                    .toggleStyle(SwitchToggleStyle(tint: BrandTheme.Colors.cyan))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                
                HStack {
                    Text("Accessibility Trust Status:")
                        .font(.system(size: 11))
                        .foregroundColor(BrandTheme.Colors.textSecondary)
                    Spacer()
                    if appState.hasAccessibilityPermission {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.green)
                    } else {
                        Button("Authorize in Settings") {
                            ActionPermissionManager.shared.openAccessibilitySettings()
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            
            // Action History
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recent Action History")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    if !ActionExecutionManager.shared.actionHistory.isEmpty {
                        Button("Clear History") {
                            ActionExecutionManager.shared.clearActionHistory()
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .buttonStyle(.plain)
                    }
                }
                
                if ActionExecutionManager.shared.actionHistory.isEmpty {
                    Text("No actions executed yet.")
                        .font(.system(size: 11))
                        .foregroundColor(BrandTheme.Colors.textTertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 6) {
                        ForEach(ActionExecutionManager.shared.actionHistory.prefix(8)) { record in
                            HStack(spacing: 8) {
                                Image(systemName: record.actionType.iconName)
                                    .font(.system(size: 11))
                                    .foregroundColor(record.wasSuccessful ? .green : .red)
                                    .frame(width: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.summary)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(record.statusString)
                                        .font(.system(size: 9))
                                        .foregroundColor(BrandTheme.Colors.textTertiary)
                                }
                                
                                Spacer()
                                
                                Text(record.riskLevel.rawValue)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color(nsColor: record.riskLevel.displayColor))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color(nsColor: record.riskLevel.displayColor).opacity(0.15), in: Capsule())
                            }
                            .padding(6)
                            .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Memory Section
    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(BrandTheme.Colors.cyan)
                Text("Autonomous Agent Memory & Preferences")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Memory Controls
            VStack(alignment: .leading, spacing: 10) {
                Text("Memory Storage Settings")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Toggle("Enable AUTO Local Memory", isOn: $appState.agentPreferences.isMemoryEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: BrandTheme.Colors.cyan))
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                
                Text("When enabled, AUTO remembers your preferred settings, project notes, and frequent workflow instructions. No passwords or sensitive credentials are ever stored.")
                    .font(.system(size: 11))
                    .foregroundColor(BrandTheme.Colors.textTertiary)
                
                Divider().background(Color.white.opacity(0.08))
                
                HStack {
                    Text("Memory Retention:")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $appState.agentPreferences.retentionDays) {
                        Text("7 Days").tag(7)
                        Text("30 Days").tag(30)
                        Text("90 Days").tag(90)
                        Text("Indefinite").tag(365)
                    }
                    .frame(width: 130)
                }
                
                HStack {
                    Text("Max Stored Memories:")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(appState.agentPreferences.maxStoredMemories) items")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BrandTheme.Colors.cyan)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            
            // Memory Management Actions
            VStack(alignment: .leading, spacing: 10) {
                Text("Memory Maintenance")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Button(action: {
                        MemoryManager.shared.clearCategory(.temporaryContext)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Clear Temporary Context")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        MemoryManager.shared.clearAll()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Clear All Memories")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            
            // Stored Memory Items List
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Stored Memory Items (\(MemoryManager.shared.getAll().count))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                let memories = MemoryManager.shared.getAll()
                if memories.isEmpty {
                    Text("No stored memories yet. Tell AUTO 'Remember that I prefer short answers' to create your first memory.")
                        .font(.system(size: 11))
                        .foregroundColor(BrandTheme.Colors.textTertiary)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 6) {
                        ForEach(memories.prefix(12)) { item in
                            HStack(spacing: 8) {
                                Image(systemName: item.category.iconName)
                                    .font(.system(size: 11))
                                    .foregroundColor(BrandTheme.Colors.cyan)
                                    .frame(width: 16)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.key)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(item.content)
                                        .font(.system(size: 10))
                                        .foregroundColor(BrandTheme.Colors.textTertiary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    MemoryManager.shared.delete(id: item.id)
                                }) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(6)
                            .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private func createNewProfile() {
        let profile = OmniRouteProfile(
            name: newProfileName,
            baseURL: newProfileBaseURL,
            apiKeyAccount: "omniroute_\(UUID().uuidString.prefix(8))",
            connectionType: newProfileType
        )
        appState.omniRouteProfiles.append(profile)
        appState.activeOmniRouteProfileId = profile.id
        showAddProfileSheet = false
        newProfileName = ""
        newProfileBaseURL = "http://localhost:20128/v1"
    }
    
    private func deleteProfile(_ profile: OmniRouteProfile) {
        appState.omniRouteProfiles.removeAll(where: { $0.id == profile.id })
        if appState.activeOmniRouteProfileId == profile.id {
            appState.activeOmniRouteProfileId = appState.omniRouteProfiles.first?.id
        }
    }
    
    private func purgeAllData() {
        PrivacyManager.shared.purgeAllData()
        ConversationMemory.shared.clear()
        MemoryManager.shared.clearAll()
        ActionExecutionManager.shared.clearHistory()
        loadKeychainKeys()
        purgeStatusMessage = "All preferences, memory, history, and Keychain secrets have been purged."
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                AppLogger.shared.error("Failed to update LaunchAtLogin: \(error)", category: .lifecycle)
            }
        }
    }
}
