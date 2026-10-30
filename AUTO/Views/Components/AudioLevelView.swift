//
//  AudioLevelView.swift
//  AUTO
//
//  Dynamic bar-based audio metering visualizer showing real-time microphone input volume.
//

import SwiftUI

public struct AudioLevelView: View {
    public let powerLevel: Float
    public let isRecording: Bool
    
    private let barCount = 12
    
    public init(powerLevel: Float, isRecording: Bool) {
        self.powerLevel = powerLevel
        self.isRecording = isRecording
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let scale = barHeightFactor(for: index)
                let height = isRecording ? max(4.0, CGFloat(powerLevel) * 28.0 * scale) : 4.0
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: isRecording ? [.cyan, .blue] : [.gray.opacity(0.3), .gray.opacity(0.1)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: height)
                    .animation(.easeOut(duration: 0.08), value: powerLevel)
            }
        }
        .frame(height: 32)
    }
    
    private func barHeightFactor(for index: Int) -> CGFloat {
        let center = Double(barCount - 1) / 2.0
        let dist = abs(Double(index) - center)
        let factor = 1.0 - (dist / center) * 0.5
        return CGFloat(factor)
    }
}

