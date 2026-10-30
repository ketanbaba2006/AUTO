//
//  PermissionManager.swift
//  AUTO
//
//  Comprehensive permission management for AUTO:
//  - Microphone access (AVFoundation)
//  - Screen Recording access (CoreGraphics / ScreenCaptureKit)
//  - Accessibility access (ApplicationServices)
//  - Deep links to macOS System Settings
//

import AppKit
import AVFoundation
import ApplicationServices
import CoreGraphics
import Speech
import UserNotifications

@MainActor
public protocol PermissionService: AnyObject {
    func refreshPermissions()
    func requestMicrophonePermission() async -> Bool
    func requestSpeechRecognitionPermission() async -> Bool
    func requestScreenRecordingPermission() -> Bool
    func requestAccessibilityPermission() -> Bool
    func requestNotificationPermission() async -> Bool
    func openSettings(for permission: PermissionType)
    func revealAppInFinder()
}

@MainActor
public final class PermissionManager: PermissionService, ObservableObject {
    public static let shared = PermissionManager()
    
    private let appState: ApplicationState
    private var pollingTimer: Timer?
    
    public init(appState: ApplicationState) {
        self.appState = appState
        refreshPermissions()
    }
    
    public convenience init() {
        self.init(appState: .shared)
    }
    
    public func startPolling(interval: TimeInterval = 2.0) {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPermissions()
            }
        }
    }
    
    public func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    public func refreshPermissions() {
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let speechStatus = SFSpeechRecognizer.authorizationStatus() == .authorized
        let screenStatus = CGPreflightScreenCaptureAccess()
        let accessibilityStatus = AXIsProcessTrusted()
        
        let changed = (appState.hasMicrophonePermission != micStatus) ||
                      (appState.hasSpeechRecognitionPermission != speechStatus) ||
                      (appState.hasScreenRecordingPermission != screenStatus) ||
                      (appState.hasAccessibilityPermission != accessibilityStatus)
        
        appState.hasMicrophonePermission = micStatus
        appState.hasSpeechRecognitionPermission = speechStatus
        appState.hasScreenRecordingPermission = screenStatus
        appState.hasAccessibilityPermission = accessibilityStatus
        appState.hasInputMonitoringPermission = accessibilityStatus
        
        // UNUserNotificationCenter requires an app bundle with a valid identifier; guard against standalone CLI runs
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                Task { @MainActor [weak self] in
                    self?.appState.hasNotificationPermission = (settings.authorizationStatus == .authorized)
                }
            }
        }
        
        if changed {
            AppLogger.shared.info(
                "Permissions updated: mic=\(micStatus), speech=\(speechStatus), screen=\(screenStatus), accessibility=\(accessibilityStatus)",
                category: .permissions
            )
        }
    }
    
    public func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            appState.hasMicrophonePermission = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            appState.hasMicrophonePermission = granted
            return granted
        case .denied, .restricted:
            openSettings(for: .microphone)
            return false
        @unknown default:
            return false
        }
    }
    
    public func requestSpeechRecognitionPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            appState.hasSpeechRecognitionPermission = true
            return true
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    continuation.resume(returning: authStatus == .authorized)
                }
            }
            appState.hasSpeechRecognitionPermission = granted
            return granted
        case .denied, .restricted:
            openSettings(for: .speechRecognition)
            return false
        @unknown default:
            return false
        }
    }
    
    public func requestScreenRecordingPermission() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            appState.hasScreenRecordingPermission = true
            return true
        }
        
        // Triggers the macOS system prompt
        let granted = CGRequestScreenCaptureAccess()
        if !granted {
            openSettings(for: .screenRecording)
        }
        appState.hasScreenRecordingPermission = granted
        return granted
    }
    
    public func requestAccessibilityPermission() -> Bool {
        if AXIsProcessTrusted() {
            appState.hasAccessibilityPermission = true
            return true
        }
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            openSettings(for: .accessibility)
        }
        appState.hasAccessibilityPermission = trusted
        return trusted
    }
    
    public func requestNotificationPermission() async -> Bool {
        guard Bundle.main.bundleIdentifier != nil else {
            appState.hasNotificationPermission = false
            return false
        }
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            appState.hasNotificationPermission = granted
            return granted
        } catch {
            appState.hasNotificationPermission = false
            return false
        }
    }
    
    public func openSettings(for permission: PermissionType) {
        let urlString: String
        switch permission {
        case .microphone:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .speechRecognition:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition"
        case .screenRecording:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        case .accessibility:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        case .inputMonitoring:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        case .notifications:
            urlString = "x-apple.systempreferences:com.apple.preference.notifications"
        }
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
            AppLogger.shared.info("Opened System Settings for: \(permission.rawValue)", category: .permissions)
        }
    }
    
    public func revealAppInFinder() {
        let bundleURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
    }
}
