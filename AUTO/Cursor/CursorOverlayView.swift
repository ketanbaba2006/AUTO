//
//  CursorOverlayView.swift
//  AUTO
//
//  SwiftUI view rendered inside transparent overlay windows across all monitors.
//  Displays the animated companion buddy, targeting reticle, click ripple animations,
//  and action execution badges with official AUTO branding.
//

import SwiftUI

public struct CursorOverlayView: View {
    public let screenFrame: CGRect
    @ObservedObject public var appState: ApplicationState
    @ObservedObject public var cursorManager: CursorManager
    @ObservedObject public var overlayManager: CursorOverlayManager
    
    public init(
        screenFrame: CGRect,
        appState: ApplicationState,
        cursorManager: CursorManager,
        overlayManager: CursorOverlayManager
    ) {
        self.screenFrame = screenFrame
        self.appState = appState
        self.cursorManager = cursorManager
        self.overlayManager = overlayManager
    }
    
    public init(screenFrame: CGRect) {
        self.screenFrame = screenFrame
        self.appState = .shared
        self.cursorManager = .shared
        self.overlayManager = .shared
    }
    
    private var primaryScreenHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 1080.0
    }
    
    private var localCursorPosition: CGPoint {
        let global = cursorManager.currentPosition
        let localX = global.x - screenFrame.origin.x
        let localY = screenFrame.height - (global.y - screenFrame.origin.y)
        return CGPoint(x: localX, y: localY)
    }
    
    private func localFromCoreGraphics(_ cgPoint: CGPoint) -> CGPoint {
        let localX = cgPoint.x - screenFrame.origin.x
        let screenCGTop = primaryScreenHeight - (screenFrame.origin.y + screenFrame.height)
        let localY = cgPoint.y - screenCGTop
        return CGPoint(x: localX, y: localY)
    }
    
    private var isCursorOnThisScreen: Bool {
        return screenFrame.contains(cursorManager.currentPosition)
    }
    
    public var body: some View {
        ZStack {
            Color.clear
            
            // 1. Targeting Reticle
            if let targetCG = overlayManager.targetLocation {
                let localTarget = localFromCoreGraphics(targetCG)
                targetReticleView(label: overlayManager.targetLabel)
                    .position(localTarget)
            }
            
            // 2. Click Ripple Animation
            if overlayManager.isRippling, let rippleCG = overlayManager.clickRippleLocation {
                let localRipple = localFromCoreGraphics(rippleCG)
                clickRippleView
                    .position(localRipple)
            }
            
            // 3. Companion Buddy
            if isCursorOnThisScreen && appState.isOverlayVisible {
                companionBuddyView
                    .position(
                        x: localCursorPosition.x + 28,
                        y: localCursorPosition.y + 24
                    )
                    .animation(.spring(response: 0.22, dampingFraction: 0.75), value: cursorManager.currentPosition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
    
    // MARK: - Companion Buddy View
    
    @ViewBuilder
    private var companionBuddyView: some View {
        HStack(alignment: .center, spacing: 10) {
            // Triangular glowing buddy
            ZStack {
                TriangleShape()
                    .fill(glowColor)
                    .blur(radius: 6)
                    .frame(width: 22, height: 22)
                
                TriangleShape()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(-35))
            }
            
            // Contextual bubble
            if appState.voiceState == .listening {
                waveformIndicator
            } else if appState.voiceState == .thinking || appState.voiceState == .transcribing {
                processingIndicator
            } else if !appState.currentResponseText.isEmpty {
                responseBubble(text: appState.currentResponseText)
            }
        }
    }
    
    // MARK: - Targeting Reticle
    
    private func targetReticleView(label: String?) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.85), lineWidth: 2)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(Color.cyan.opacity(0.35))
                    .frame(width: 8, height: 8)
            }
            
            if let text = label, !text.isEmpty {
                Text(text)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.75), in: Capsule())
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.6), lineWidth: 1))
            }
        }
    }
    
    // MARK: - Click Ripple View
    
    private var clickRippleView: some View {
        Circle()
            .stroke(Color.cyan, lineWidth: 3)
            .frame(width: 44, height: 44)
            .scaleEffect(1.3)
            .opacity(0.8)
            .animation(.easeOut(duration: 0.4), value: overlayManager.isRippling)
    }
    
    // MARK: - Glow & Bubble Helpers
    
    private var glowColor: Color {
        switch appState.voiceState {
        case .idle:
            return Color.cyan.opacity(0.6)
        case .listening:
            return Color.teal.opacity(0.8)
        case .transcribing:
            return Color.blue.opacity(0.8)
        case .thinking:
            return Color.purple.opacity(0.8)
        case .speaking:
            return Color.green.opacity(0.8)
        case .interrupted:
            return Color.orange.opacity(0.8)
        case .failed:
            return Color.red.opacity(0.8)
        }
    }
    
    private var waveformIndicator: some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.cyan)
                    .frame(
                        width: 3,
                        height: max(6, CGFloat(appState.currentAudioLevel) * 25.0 * CGFloat((index % 2 == 0) ? 1.0 : 0.65))
                    )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(Color.cyan.opacity(0.4), lineWidth: 1)
        )
    }
    
    private var processingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.6)
                .colorInvert()
            Text("Thinking...")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(Color.purple.opacity(0.4), lineWidth: 1)
        )
    }
    
    private func responseBubble(text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(4)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
            .frame(maxWidth: 240, alignment: .leading)
    }
}

public struct TriangleShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = min(rect.width, rect.height)
        let height = size * sqrt(3.0) / 2.0
        
        path.move(to: CGPoint(x: rect.midX, y: rect.midY - height / 1.5))
        path.addLine(to: CGPoint(x: rect.midX - size / 2, y: rect.midY + height / 3))
        path.addLine(to: CGPoint(x: rect.midX + size / 2, y: rect.midY + height / 3))
        path.closeSubpath()
        return path
    }
}
