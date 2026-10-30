//
//  AudioCaptureManager.swift
//  AUTO
//
//  Native microphone audio capture service using AVAudioEngine.
//  Streams PCM audio buffers to speech recognition backends and publishes
//  real-time audio power levels for visual metering.
//

import AVFoundation
import Combine

public protocol AudioCaptureService: AnyObject, Sendable {
    var isCapturing: Bool { get }
    var audioPowerPublisher: AnyPublisher<Float, Never> { get }
    func setBufferHandler(_ handler: (@Sendable (AVAudioPCMBuffer) -> Void)?)
    func startCapture() throws
    func stopCapture() -> Data?
}

public final class AudioCaptureManager: AudioCaptureService, @unchecked Sendable {
    public static let shared = AudioCaptureManager()
    
    private let powerSubject = PassthroughSubject<Float, Never>()
    public var audioPowerPublisher: AnyPublisher<Float, Never> {
        return powerSubject.eraseToAnyPublisher()
    }
    
    public private(set) var isCapturing: Bool = false
    private var audioEngine: AVAudioEngine?
    private var bufferHandler: (@Sendable (AVAudioPCMBuffer) -> Void)?
    private var recordedAudioData: Data = Data()
    private let lock = NSLock()
    
    public init() {}
    
    public func setBufferHandler(_ handler: (@Sendable (AVAudioPCMBuffer) -> Void)?) {
        lock.lock()
        defer { lock.unlock() }
        self.bufferHandler = handler
    }
    
    public func startCapture() throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            throw AUTOError.permissionDenied(
                permission: "Microphone",
                instructions: "Please grant Microphone access in macOS System Settings > Privacy & Security."
            )
        }
        
        guard !isCapturing else {
            AppLogger.shared.debug("AudioCaptureManager: Already capturing, ignoring start request.", category: .voice)
            return
        }
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)
        
        guard hardwareFormat.sampleRate > 0 && hardwareFormat.channelCount > 0 else {
            throw AUTOError.audioCaptureError(reason: "Invalid hardware audio format detected (sampleRate: \(hardwareFormat.sampleRate), channels: \(hardwareFormat.channelCount)).")
        }
        
        recordedAudioData.removeAll()
        
        // Tap with 1024-frame buffer size for low-latency live metering and STT streaming
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // 1. Calculate live audio power for UI meters
            let power = VoiceActivityDetector.shared.calculateRMS(from: buffer)
            self.powerSubject.send(power)
            
            // 2. Stream buffer to active speech recognizer
            self.lock.lock()
            let handler = self.bufferHandler
            self.lock.unlock()
            handler?(buffer)
        }
        
        try engine.start()
        self.audioEngine = engine
        self.isCapturing = true
        AppLogger.shared.info("Audio capture started successfully (format: \(hardwareFormat)).", category: .voice)
    }
    
    public func stopCapture() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        guard isCapturing, let engine = audioEngine else {
            return nil
        }
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.audioEngine = nil
        self.isCapturing = false
        self.bufferHandler = nil
        self.powerSubject.send(0.0)
        
        AppLogger.shared.info("Audio capture stopped safely.", category: .voice)
        return recordedAudioData
    }
}
