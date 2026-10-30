//
//  CompanionPanelView.swift
//  AUTO
//
//  Main floating companion interface hosted beneath the menu bar status item.
//  Coordinates companion conversations, onboarding, settings switching,
//  live audio level visualizers, and push-to-talk speech interaction.
//

import SwiftUI

public struct CompanionPanelView: View {
    @ObservedObject public var appState: ApplicationState
    @ObservedObject public var conversationManager: ConversationManager
    @ObservedObject public var agentOrchestrator: AgentOrchestrator
    
    public init(
        appState: ApplicationState,
        conversationManager: ConversationManager,
        agentOrchestrator: AgentOrchestrator
    ) {
        self.appState = appState
        self.conversationManager = conversationManager
        self.agentOrchestrator = agentOrchestrator
    }
    
    public init() {
        self.appState = .shared
        self.conversationManager = .shared
        self.agentOrchestrator = .shared
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if !appState.isOnboardingCompleted {
                OnboardingView(appState: appState) {
                    appState.isOnboardingCompleted = true
                    if appState.allPermissionsGranted {
                        OverlayWindowManager.shared.showOverlays()
                    }
                }
            } else if appState.isSettingsOpen {
                settingsContainer
            } else {
                companionMainContainer
            }
        }
        .frame(width: appState.isSettingsOpen ? 540 : 350)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.96),
                            Color(red: 0.07, green: 0.08, blue: 0.10).opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Companion Main Container
    private var companionMainContainer: some View {
        VStack(spacing: 12) {
            headerBar
            
            // Autonomous Agent Step Approval Banner
            if let approval = agentOrchestrator.pendingApproval {
                agentStepApprovalCard(for: approval)
            }
            
            // Active Multi-Step Task Progress Card
            if let plan = agentOrchestrator.activePlan {
                taskProgressCard(for: plan)
            }
            
            // High-Risk Action Confirmation Banner
            if let pendingAction = ActionExecutionManager.shared.pendingConfirmationAction {
                actionConfirmationCard(for: pendingAction)
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            // Push-to-talk live visualizer card
            voiceStatusCard
            
            // Conversation interaction
            ConversationView(appState: appState, conversationManager: conversationManager)
            
            Divider().background(Color.white.opacity(0.08))
            
            // Footer controls
            footerBar
        }
        .padding(14)
    }
    
    // MARK: - Agent Step Approval Card
    private func agentStepApprovalCard(for req: StepApprovalRequest) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "hand.raised.fill")
                    .foregroundColor(.yellow)
                Text("Approval Required: \(req.step.title)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(req.consequences)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
            
            HStack(spacing: 8) {
                Button(action: {
                    agentOrchestrator.rejectPendingStep()
                }) {
                    Text("Decline")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    agentOrchestrator.approvePendingStep()
                }) {
                    Text("Authorize Step")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Task Progress Card
    private func taskProgressCard(for plan: AgentTaskPlan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundColor(BrandTheme.Colors.cyan)
                Text(plan.intendedOutcome)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Button(action: {
                    agentOrchestrator.cancelCurrentTask(reason: "User cancelled via UI")
                }) {
                    Text("Stop Task")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.15), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            
            if let step = plan.currentStep {
                Text("Step \(step.stepNumber)/\(plan.totalSteps): \(step.title)")
                    .font(.system(size: 10))
                    .foregroundColor(BrandTheme.Colors.textTertiary)
                    .lineLimit(1)
            }
            
            ProgressView(value: plan.progressFraction)
                .progressViewStyle(LinearProgressViewStyle(tint: BrandTheme.Colors.cyan))
                .scaleEffect(y: 0.6)
        }
        .padding(10)
        .background(BrandTheme.Colors.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(BrandTheme.Colors.cyan.opacity(0.25), lineWidth: 1))
    }
    
    // MARK: - Action Confirmation Card
    private func actionConfirmationCard(for action: AutomationAction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundColor(.yellow)
                Text("Confirm High-Risk Action")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(action.reason)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Button(action: {
                    ActionExecutionManager.shared.rejectPendingAction()
                }) {
                    Text("Decline")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    Task {
                        _ = await ActionExecutionManager.shared.confirmPendingAction()
                    }
                }) {
                    Text("Authorize Action")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 8) {
            // Official AUTO Mascot
            AUTOMascotView(
                state: appState.voiceState,
                powerLevel: appState.currentAudioLevel,
                size: 26,
                showGlow: true
            )
            .onTapGesture {
                AboutWindowManager.shared.showAboutWindow()
            }
            .help("Click to view About AUTO")
            
            VStack(alignment: .leading, spacing: 1) {
                Text(BrandTheme.appName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.Gradients.titleGradient)
                
                Text(appState.statusMessage)
                    .font(.system(size: 10))
                    .foregroundColor(BrandTheme.Colors.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Active Engine Pill
            HStack(spacing: 4) {
                Circle()
                    .fill(appState.isOfflineMode ? Color.orange : BrandTheme.Colors.cyan)
                    .frame(width: 5, height: 5)
                Text(appState.isOfflineMode ? "Local Engine" : "Gemini Hybrid")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06), in: Capsule())
            
            // Screen Sharing Indicator
            if appState.isScreenSharingActive {
                HStack(spacing: 3) {
                    Circle()
                        .fill(BrandTheme.Colors.cyan)
                        .frame(width: 5, height: 5)
                    Image(systemName: "display")
                        .font(.system(size: 9))
                }
                .foregroundColor(BrandTheme.Colors.cyan)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(BrandTheme.Colors.cyan.opacity(0.12), in: Capsule())
                .help("Screen Sharing Active with AUTO")
            }
            
            // Quick Screen Capture Button
            Button(action: { triggerManualScreenCapture() }) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 11))
                    .foregroundColor(appState.screenPreferences.isScreenAwarenessEnabled ? BrandTheme.Colors.cyan : .gray)
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Capture Screen for AUTO")
            
            // Emergency Stop Button
            Button(action: {
                if EmergencyStopManager.shared.isEmergencyStopActive {
                    EmergencyStopManager.shared.resetEmergencyStop()
                } else {
                    EmergencyStopManager.shared.triggerEmergencyStop()
                }
            }) {
                Image(systemName: EmergencyStopManager.shared.isEmergencyStopActive ? "play.circle.fill" : "stop.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(EmergencyStopManager.shared.isEmergencyStopActive ? .yellow : .red.opacity(0.85))
                    .frame(width: 24, height: 24)
                    .background(Color.red.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .help(EmergencyStopManager.shared.isEmergencyStopActive ? "Emergency Stop is Active (Click to Reset)" : "Emergency Stop: Cancel All Actions")
            
            // Toggle Overlay
            Button(action: { OverlayWindowManager.shared.toggleOverlays() }) {
                Image(systemName: appState.isOverlayVisible ? "eye.fill" : "eye.slash")
                    .font(.system(size: 12))
                    .foregroundColor(appState.isOverlayVisible ? BrandTheme.Colors.cyan : .gray)
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help(appState.isOverlayVisible ? "Hide Overlay Buddy" : "Show Overlay Buddy")
        }
    }
    
    private func triggerManualScreenCapture() {
        Task {
            do {
                _ = try await ScreenContextManager.shared.captureCurrentContext(mode: .onDemand)
                appState.statusMessage = "Screen captured!"
            } catch {
                appState.statusMessage = "Capture error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Voice Status Card
    private var voiceStatusCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ListeningIndicatorView(
                    state: appState.voiceState,
                    powerLevel: appState.currentAudioLevel
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.voiceState.statusDescription)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(appState.voiceState.displayColor)
                    
                    if !appState.currentTranscript.isEmpty {
                        Text("\"\(appState.currentTranscript)\"")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    } else {
                        Text(appState.voicePreferences.pushToTalkTrigger.description)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if appState.voiceState == .listening {
                    AudioLevelView(
                        powerLevel: appState.currentAudioLevel,
                        isRecording: true
                    )
                } else if appState.voiceState == .speaking {
                    Button(action: { SpeechOutputManager.shared.stopSpeaking() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.slash.fill")
                                .font(.system(size: 10))
                            Text("Stop")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.6), in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    StatusBadge(
                        title: appState.voiceState.rawValue,
                        color: appState.voiceState.displayColor,
                        pulse: appState.voiceState.isBusy
                    )
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Footer Bar
    private var footerBar: some View {
        HStack {
            Button(action: { appState.isSettingsOpen = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: { AboutWindowManager.shared.showAboutWindow() }) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                    Text("About")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: { NSApp.terminate(nil) }) {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                    Text("Quit")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Settings Container
    private var settingsContainer: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { appState.isSettingsOpen = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back to Companion")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("AUTO Settings")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { CompanionWindowManager.shared.hidePanel() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))
            
            SettingsView(appState: appState)
        }
    }
}
