//
//  AUTOMascotView.swift
//  AUTO
//
//  Interactive, state-driven AUTO mascot component.
//  Renders the official mascot artwork with live responsive animations:
//  - IDLE: Gentle breathing ambient glow
//  - LISTENING: Audio-reactive cyan eye glow & expanding acoustic rings
//  - THINKING: Rotating purple-cyan cognitive aura
//  - SPEAKING: Rhythmic voice output wave ripples
//  - ERROR/FAILED: Clear amber/red alert ring preserving mascot identity
//

import SwiftUI

public struct AUTOMascotView: View {
    public let state: VoiceState
    public let powerLevel: Float
    public let size: CGFloat
    public let showGlow: Bool
    
    @State private var idlePhase: CGFloat = 0.0
    @State private var thinkingAngle: Double = 0.0
    @State private var speakingPulse: CGFloat = 1.0
    
    public init(
        state: VoiceState = .idle,
        powerLevel: Float = 0.0,
        size: CGFloat = 48.0,
        showGlow: Bool = true
    ) {
        self.state = state
        self.powerLevel = powerLevel
        self.size = size
        self.showGlow = showGlow
    }
    
    public var body: some View {
        ZStack {
            // Dynamic State Aura Background
            if showGlow {
                stateAuraView
            }
            
            // Official Mascot Artwork
            Image(nsImage: BrandAssetManager.shared.mascotImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .strokeBorder(stateBorderGradient, lineWidth: max(1.5, size * 0.035))
                )
                .shadow(color: stateGlowColor.opacity(0.4), radius: size * 0.15, x: 0, y: size * 0.05)
            
            // Dynamic Interactive Overlay
            stateOverlayView
        }
        .frame(width: size * 1.25, height: size * 1.25)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - State Aura View
    @ViewBuilder
    private var stateAuraView: some View {
        switch state {
        case .idle:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [BrandTheme.Colors.cyan.opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.65
                    )
                )
                .scaleEffect(1.0 + idlePhase * 0.08)
                .opacity(0.6 + idlePhase * 0.4)
            
        case .listening:
            // Audio-reactive expanding shockwave
            let energyScale = 1.0 + CGFloat(powerLevel) * 0.35
            Circle()
                .stroke(BrandTheme.Colors.cyan.opacity(0.7 - Double(powerLevel) * 0.3), lineWidth: 2)
                .frame(width: size * 1.15, height: size * 1.15)
                .scaleEffect(energyScale)
                .animation(.easeOut(duration: 0.15), value: powerLevel)
            
            Circle()
                .fill(BrandTheme.Colors.cyan.opacity(0.25 + Double(powerLevel) * 0.35))
                .frame(width: size * 1.1, height: size * 1.1)
                .blur(radius: 6)
            
        case .thinking:
            // Rotating cognitive aura
            Circle()
                .stroke(BrandTheme.Gradients.thinkingAura, lineWidth: max(2, size * 0.05))
                .frame(width: size * 1.18, height: size * 1.18)
                .rotationEffect(.degrees(thinkingAngle))
                .blur(radius: 2)
            
        case .speaking:
            // Concentric speech output waves
            Circle()
                .stroke(Color.green.opacity(0.5), lineWidth: 2)
                .frame(width: size * 1.15, height: size * 1.15)
                .scaleEffect(speakingPulse)
                .opacity(2.0 - Double(speakingPulse))
            
        case .interrupted:
            Circle()
                .stroke(Color.orange.opacity(0.8), lineWidth: 2.5)
                .frame(width: size * 1.12, height: size * 1.12)
            
        case .failed:
            Circle()
                .stroke(Color.red.opacity(0.8), lineWidth: 2)
                .frame(width: size * 1.12, height: size * 1.12)
            
        case .transcribing:
            Circle()
                .stroke(BrandTheme.Colors.electricBlue.opacity(0.7), lineWidth: 2)
                .frame(width: size * 1.14, height: size * 1.14)
                .scaleEffect(1.05)
        }
    }
    
    // MARK: - State Overlay View
    @ViewBuilder
    private var stateOverlayView: some View {
        if state == .listening {
            // Cyan eye glow boost during speech recognition
            let glowIntensity = Double(min(max(powerLevel * 2.0, 0.2), 1.0))
            Circle()
                .fill(BrandTheme.Colors.cyan.opacity(glowIntensity * 0.3))
                .frame(width: size * 0.5, height: size * 0.3)
                .offset(y: size * 0.02)
                .blur(radius: 4)
                .allowsHitTesting(false)
        } else if state == .failed {
            // Small subtle alert badge without altering mascot
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: max(10, size * 0.22)))
                        .foregroundColor(.red)
                        .background(Color.black, in: Circle())
                        .offset(x: size * 0.08, y: -size * 0.08)
                }
                Spacer()
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Visual Helpers
    
    private var stateBorderGradient: LinearGradient {
        switch state {
        case .idle:
            return LinearGradient(
                colors: [BrandTheme.Colors.cyan.opacity(0.6), BrandTheme.Colors.purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .listening:
            return LinearGradient(
                colors: [BrandTheme.Colors.cyan, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        case .transcribing:
            return LinearGradient(
                colors: [BrandTheme.Colors.electricBlue, BrandTheme.Colors.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .thinking:
            return LinearGradient(
                colors: [BrandTheme.Colors.purple, BrandTheme.Colors.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .speaking:
            return LinearGradient(
                colors: [Color.green, BrandTheme.Colors.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .interrupted:
            return LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .top,
                endPoint: .bottom
            )
        case .failed:
            return LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var stateGlowColor: Color {
        switch state {
        case .idle: return BrandTheme.Colors.cyan
        case .listening: return BrandTheme.Colors.cyan
        case .transcribing: return BrandTheme.Colors.electricBlue
        case .thinking: return BrandTheme.Colors.purple
        case .speaking: return Color.green
        case .interrupted: return Color.orange
        case .failed: return Color.red
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            idlePhase = 1.0
        }
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            thinkingAngle = 360.0
        }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            speakingPulse = 1.25
        }
    }
}

