//
//  MicrophoneDeviceManager.swift
//  AUTO
//
//  Discovers available microphone input hardware, monitors audio device connections
//  and disconnections, and manages selected microphone settings.
//

import AVFoundation
import Combine

public protocol MicrophoneDeviceService: AnyObject, Sendable {
    func listAvailableInputDevices() -> [AudioDevice]
    func getDefaultInputDevice() -> AudioDevice?
    func device(withID id: String) -> AudioDevice?
}

public final class MicrophoneDeviceManager: MicrophoneDeviceService, @unchecked Sendable {
    public static let shared = MicrophoneDeviceManager()
    
    private let deviceChangeSubject = PassthroughSubject<[AudioDevice], Never>()
    public var deviceChangePublisher: AnyPublisher<[AudioDevice], Never> {
        return deviceChangeSubject.eraseToAnyPublisher()
    }
    
    private let lock = NSLock()
    private var cachedDevices: [AudioDevice] = []
    
    public init() {
        setupDeviceNotifications()
        _ = refreshDevices()
    }
    
    public func listAvailableInputDevices() -> [AudioDevice] {
        lock.lock()
        defer { lock.unlock() }
        if cachedDevices.isEmpty {
            cachedDevices = fetchInputDevices()
        }
        return cachedDevices
    }
    
    public func getDefaultInputDevice() -> AudioDevice? {
        let devices = listAvailableInputDevices()
        return devices.first(where: { $0.isDefault }) ?? devices.first
    }
    
    public func device(withID id: String) -> AudioDevice? {
        return listAvailableInputDevices().first(where: { $0.id == id })
    }
    
    public func refreshDevices() -> [AudioDevice] {
        let updated = fetchInputDevices()
        lock.lock()
        self.cachedDevices = updated
        lock.unlock()
        deviceChangeSubject.send(updated)
        AppLogger.shared.debug("Discovered \(updated.count) audio input devices.", category: .voice)
        return updated
    }
    
    private func fetchInputDevices() -> [AudioDevice] {
        let deviceTypes: [AVCaptureDevice.DeviceType]
        if #available(macOS 14.0, *) {
            deviceTypes = [.microphone, .external]
        } else {
            deviceTypes = [.builtInMicrophone, .externalUnknown]
        }
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .audio,
            position: .unspecified
        )
        let defaultDevice = AVCaptureDevice.default(for: .audio)
        
        return discoverySession.devices.map { device in
            AudioDevice(
                id: device.uniqueID,
                name: device.localizedName,
                isDefault: device.uniqueID == defaultDevice?.uniqueID
            )
        }
    }
    
    private func setupDeviceNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVCaptureDevice.wasConnectedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let device = notification.object as? AVCaptureDevice, device.hasMediaType(.audio) {
                AppLogger.shared.info("Audio input device connected: \(device.localizedName)", category: .voice)
                _ = self?.refreshDevices()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: AVCaptureDevice.wasDisconnectedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let device = notification.object as? AVCaptureDevice, device.hasMediaType(.audio) {
                AppLogger.shared.info("Audio input device disconnected: \(device.localizedName)", category: .voice)
                _ = self?.refreshDevices()
            }
        }
    }
}
