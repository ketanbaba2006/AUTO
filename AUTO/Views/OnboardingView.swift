//
//  OnboardingView.swift
//  AUTO
//
//  Interactive onboarding flow introducing AUTO, granting permissions,
//  configuring AI keys, explaining voice push-to-talk, local memory, and safety.
//

import SwiftUI

public struct OnboardingView: View {
    @ObservedObject public var appState: ApplicationState
    public let onComplete: () -> Void
    
    @State private var currentStep: Int = 0
    @State private var geminiKeyInput: String = ""
    @State private var isKeySaved: Bool = false
    @State private var errorMessage: String?
    
    public init(
        appState: ApplicationState,
        onComplete: @escaping () -> Void
    ) {
        self.appState = appState
        self.onComplete = onComplete
    }
    
    public init(onComplete: @escaping () -> Void) {
        self.appState = .shared
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            headerView
            
            Group {
                switch currentStep {
                case 0: welcomeStepView
                case 1: permissionsStepView
                case 2: aiSetupStepView
                case 3: voiceAndScreenStepView
                case 4: memoryAndSafetyStepView
                default: welcomeStepView
                }
            }
            .frame(maxHeight: .infinity)
            
            navigationButtons
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            BrandTheme.Gradients.panelBackdrop
        )
    }
    
    private var headerView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(nsImage: BrandAssetManager.shared.mascotImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(BrandTheme.appName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.Gradients.titleGradient)
                
                Spacer()
                
                Text("Step \(currentStep + 1) of 5")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(BrandTheme.Colors.cyan)
            }
            
            Text(BrandTheme.tagline)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(BrandTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Step 0: Welcome
    private var welcomeStepView: some View {
        VStack(spacing: 14) {
            Image(nsImage: BrandAssetManager.shared.mascotImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(BrandTheme.Gradients.cardBorder, lineWidth: 2)
                )
                .shadow(color: BrandTheme.Colors.cyan.opacity(0.45), radius: 16, x: 0, y: 6)
                .padding(.top, 4)
            
            Text("Meet Your AI Desktop Companion")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                featureBullet(icon: "waveform", text: "Hold Control to talk naturally anytime from any application")
                featureBullet(icon: "display.2", text: "Multi-monitor screen and window visual intelligence")
                featureBullet(icon: "hand.point.up.left.fill", text: "Permission-based cursor guidance and automated task assistance")
                featureBullet(icon: "brain.head.profile", text: "Local private memory: remembers your preferences with zero cloud tracking")
                featureBullet(icon: "checkmark.seal.fill", text: "100% Free Forever: No subscriptions, accounts, ads, or paywalls")
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Step 1: Permissions
    private var permissionsStepView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("System Permissions")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("AUTO respects macOS privacy. If permissions are withheld, AUTO gracefully functions in reduced capability mode.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            ScrollView {
                VStack(spacing: 6) {
                    PermissionRow(
                        type: .accessibility,
                        isGranted: appState.hasAccessibilityPermission,
                        onAction: {
                            _ = PermissionManager.shared.requestAccessibilityPermission()
                        }
                    )
                    
                    PermissionRow(
                        type: .microphone,
                        isGranted: appState.hasMicrophonePermission,
                        onAction: {
                            Task {
                                _ = await PermissionManager.shared.requestMicrophonePermission()
                            }
                        }
                    )
                    
                    PermissionRow(
                        type: .speechRecognition,
                        isGranted: appState.hasSpeechRecognitionPermission,
                        onAction: {
                            Task {
                                _ = await PermissionManager.shared.requestSpeechRecognitionPermission()
                            }
                        }
                    )
                    
                    PermissionRow(
                        type: .screenRecording,
                        isGranted: appState.hasScreenRecordingPermission,
                        onAction: {
                            _ = PermissionManager.shared.requestScreenRecordingPermission()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Step 2: AI Setup
    private var aiSetupStepView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect AI Engine")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("AUTO uses Google Gemini as its primary intelligence engine. Keys are encrypted in your macOS Keychain.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 6) {
                SecureField("Enter Gemini API Key (AIza...)", text: $geminiKeyInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.white)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                
                if isKeySaved {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Saved securely to macOS Keychain")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 11, weight: .medium))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Optional OmniRoute Gateway")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(BrandTheme.Colors.cyan)
                
                Text("You can also connect local LLMs (Ollama, LM Studio) or custom endpoints via OmniRoute anytime in Settings. OmniRoute is completely optional.")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.85))
            }
            .padding(10)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Step 3: Voice & Screen
    private var voiceAndScreenStepView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice & Visual Guidance")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                interactionTipRow(
                    icon: "control",
                    title: "Push-to-Talk (Hold ⌃ Control)",
                    description: "Hold the Control key, speak naturally, and release to process. AUTO streams responses and speaks answers aloud."
                )
                
                interactionTipRow(
                    icon: "speaker.wave.2.slash.fill",
                    title: "Instant Voice Interruption",
                    description: "Interrupt AUTO at any millisecond by holding ⌃ Control again or speaking 'Stop'."
                )
                
                interactionTipRow(
                    icon: "display.and.cursorarrow",
                    title: "Screen & Multi-Monitor Awareness",
                    description: "AUTO captures display snapshots only when analyzing requests. Coordinates are mapped seamlessly across multi-monitor setups."
                )
            }
        }
    }
    
    // MARK: - Step 4: Memory & Emergency Safety
    private var memoryAndSafetyStepView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory & Desktop Safety")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                interactionTipRow(
                    icon: "brain.head.profile",
                    title: "Private Local Memory",
                    description: "AUTO stores preferences in ~/Library/Application Support/AUTO/agent_memory.json. Passwords and credentials are automatically rejected."
                )
                
                interactionTipRow(
                    icon: "shield.checkered",
                    title: "High-Risk Action Confirmation",
                    description: "File organization, deletions, and form submissions require explicit single-click user approval before executing."
                )
                
                interactionTipRow(
                    icon: "octagon.fill",
                    title: "Emergency Stop Failsafe",
                    description: "Say 'Stop', click the red Stop button in the panel header, or press Escape to instantly abort all active operations."
                )
            }
        }
    }
    
    private func featureBullet(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.cyan)
                .frame(width: 18)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    private func interactionTipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(BrandTheme.Colors.cyan)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(BrandTheme.Colors.textSecondary)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    currentStep -= 1
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            if currentStep < 4 {
                Button(action: { currentStep += 1 }) {
                    Text("Continue")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.cyan, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button(action: finishOnboarding) {
                    Text("Get Started")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(Color.cyan, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func finishOnboarding() {
        if !geminiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                try KeychainManager.shared.save(
                    key: KeychainManager.geminiApiKeyAccount,
                    value: geminiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                appState.hasGeminiKey = true
                isKeySaved = true
            } catch {
                errorMessage = "Keychain save error: \(error.localizedDescription)"
                return
            }
        }
        
        appState.isOnboardingCompleted = true
        onComplete()
    }
}
