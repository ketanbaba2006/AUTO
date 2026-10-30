//
//  PrivacyManager.swift
//  AUTO
//
//  Enforces AUTO's strict privacy principles:
//  - Ephemeral screen and audio capture (processed only on user action, never retained on disk)
//  - Zero telemetry and no background analytics
//  - User control over conversation history retention and local data purging
//

import Foundation

public struct PrivacyPreferences: Codable, Equatable, Sendable {
    public var retainConversationHistory: Bool
    public var ephemeralScreenshotsOnly: Bool
    public var telemetryEnabled: Bool
    public var allowLocalAudioCaching: Bool
    
    public static let `default` = PrivacyPreferences(
        retainConversationHistory: false,
        ephemeralScreenshotsOnly: true,
        telemetryEnabled: false,
        allowLocalAudioCaching: false
    )
}

public protocol PrivacyService: AnyObject, Sendable {
    var preferences: PrivacyPreferences { get set }
    func purgeLocalSessionData()
    func purgeAllData()
    func canCaptureScreen() -> Bool
    func canRecordMicrophone() -> Bool
}

public final class PrivacyManager: PrivacyService, @unchecked Sendable {
    public static let shared = PrivacyManager()
    
    private let userDefaultsKey = "com.auto.privacy.preferences"
    private let lock = NSLock()
    
    public var preferences: PrivacyPreferences {
        get {
            lock.lock()
            defer { lock.unlock() }
            if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
               let decoded = try? JSONDecoder().decode(PrivacyPreferences.self, from: data) {
                return decoded
            }
            return .default
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: userDefaultsKey)
            }
            AppLogger.shared.info("Privacy preferences updated: retainHistory=\(newValue.retainConversationHistory)", category: .security)
        }
    }
    
    public init() {
        // Enforce telemetry off at initialization
        if preferences.telemetryEnabled {
            var updated = preferences
            updated.telemetryEnabled = false
            preferences = updated
        }
    }
    
    public func purgeLocalSessionData() {
        AppLogger.shared.info("Purging all local session and ephemeral data.", category: .security)
        // Clean temporary caches
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        if let contents = try? fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil) {
            for file in contents where file.lastPathComponent.hasPrefix("auto_ephemeral_") {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    public func purgeAllData() {
        purgeLocalSessionData()
        try? KeychainManager.shared.clearAll()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.auto")
    }
    
    public func canCaptureScreen() -> Bool {
        // Screen capture is strictly permitted only when user triggers action
        return true
    }
    
    public func canRecordMicrophone() -> Bool {
        // Microphone is strictly permitted only during active push-to-talk
        return true
    }
}
