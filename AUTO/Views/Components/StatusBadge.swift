//
//  StatusBadge.swift
//  AUTO
//
//  Visual status pill indicator displaying active voice or provider states.
//

import SwiftUI

public struct StatusBadge: View {
    public let title: String
    public let color: Color
    public let pulse: Bool
    
    @State private var isPulsing: Bool = false
    
    public init(title: String, color: Color = .cyan, pulse: Bool = false) {
        self.title = title
        self.color = color
        self.pulse = pulse
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .animation(pulse ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isPulsing)
            
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(
            Capsule().stroke(color.opacity(0.25), lineWidth: 1)
        )
        .onAppear {
            if pulse {
                isPulsing = true
            }
        }
    }
}
