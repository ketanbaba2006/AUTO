//
//  VoiceActivityDetector.swift
//  AUTO
//
//  Real-time voice activity detection (VAD) and RMS energy level calculation.
//  Determines whether incoming audio frames contain voiced speech or ambient silence.
//

import AVFoundation
import Foundation

public final class VoiceActivityDetector: @unchecked Sendable {
    public static let shared = VoiceActivityDetector()
    
    // RMS threshold for speech activity (normalized 0.0 to 1.0)
    public var speechThreshold: Float = 0.04
    private let silenceFrameThreshold: Int = 15
    
    public init() {}
    
    /// Computes RMS audio power level from an audio buffer normalized between 0.0 and 1.0.
    public func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }
        
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameLength))
        // Apply dynamic scale and clamp between 0.0 and 1.0
        let scaled = rms * 6.0
        return min(max(scaled, 0.0), 1.0)
    }
    
    /// Determines whether the given normalized RMS power indicates voiced speech.
    public func isVoiced(powerLevel: Float) -> Bool {
        return powerLevel >= speechThreshold
    }
}

