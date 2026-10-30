//
//  AudioWaveformView.swift
//  AUTO
//
//  Real-time audio waveform feedback indicator.
//

import SwiftUI

public struct AudioWaveformView: View {
    public let powerLevel: Float
    public let isRecording: Bool
    
    public init(powerLevel: Float, isRecording: Bool) {
        self.powerLevel = powerLevel
        self.isRecording = isRecording
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<6) { index in
                let factor = heightFactor(for: index)
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: isRecording ? [.cyan, .blue] : [.gray.opacity(0.4), .gray.opacity(0.2)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 4,
                        height: isRecording ? max(6, CGFloat(powerLevel) * 36.0 * factor) : 6
                    )
                    .animation(.easeOut(duration: 0.12), value: powerLevel)
            }
        }
        .frame(height: 40)
    }
    
    private func heightFactor(for index: Int) -> CGFloat {
        switch index {
        case 0, 5: return 0.5
        case 1, 4: return 0.8
        default: return 1.0
        }
    }
}
