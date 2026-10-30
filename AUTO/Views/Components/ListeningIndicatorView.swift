//
//  ListeningIndicatorView.swift
//  AUTO
//
//  Animated vector visualizer for the live listening and speech states.
//

import SwiftUI

public struct ListeningIndicatorView: View {
    public let state: VoiceState
    public let powerLevel: Float
    
    @State private var pulse: Bool = false
    
    public init(state: VoiceState, powerLevel: Float = 0.0) {
        self.state = state
        self.powerLevel = powerLevel
    }
    
    public var body: some View {
        ZStack {
            // Ambient outer ripple when listening or speaking
            if state == .listening || state == .speaking {
                Circle()
                    .stroke(state.displayColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulse ? 1.6 : 1.0)
                    .opacity(pulse ? 0.0 : 0.8)
                    .animation(
                        Animation.easeOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: pulse
                    )
                    .frame(width: 44, height: 44)
            }
            
            // Core indicator circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [state.displayColor, state.displayColor.opacity(0.6)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 20
                    )
                )
                .frame(width: 32, height: 32)
                .scaleEffect(state == .listening ? (1.0 + CGFloat(powerLevel) * 0.4) : 1.0)
                .animation(.easeOut(duration: 0.1), value: powerLevel)
            
            // Icon overlay
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
        }
        .onAppear {
            pulse = true
        }
    }
    
    private var iconName: String {
        switch state {
        case .idle: return "mic.fill"
        case .listening: return "waveform"
        case .transcribing: return "text.bubble.fill"
        case .thinking: return "brain"
        case .speaking: return "speaker.wave.2.fill"
        case .interrupted: return "hand.raised.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

