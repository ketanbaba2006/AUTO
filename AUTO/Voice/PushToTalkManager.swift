//
//  PushToTalkManager.swift
//  AUTO
//
//  Global push-to-talk shortcut monitor.
//  Uses a listen-only CoreGraphics session event tap (CGEvent.tapCreate)
//  to detect global press and release of the designated push-to-talk modifier key
//  (Control by default).
//

import AppKit
import Combine
import CoreGraphics

public enum PushToTalkState: Sendable, Equatable {
    case pressed
    case released
}

public protocol PushToTalkService: AnyObject, Sendable {
    var isCurrentlyPressed: Bool { get }
    var transitionPublisher: AnyPublisher<PushToTalkState, Never> { get }
    func start()
    func stop()
}

public final class PushToTalkManager: PushToTalkService, @unchecked Sendable {
    public static let shared = PushToTalkManager()
    
    private let subject = PassthroughSubject<PushToTalkState, Never>()
    public var transitionPublisher: AnyPublisher<PushToTalkState, Never> {
        return subject.eraseToAnyPublisher()
    }
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    public private(set) var isCurrentlyPressed: Bool = false
    private let lock = NSLock()
    
    public init() {}
    
    deinit {
        stop()
    }
    
    public func start() {
        lock.lock()
        defer { lock.unlock() }
        
        guard eventTap == nil else { return }
        guard AXIsProcessTrusted() else {
            AppLogger.shared.notice("PushToTalkManager: Accessibility not trusted; event tap cannot be installed until granted.", category: .voice)
            return
        }
        
        let monitoredTypes: [CGEventType] = [.flagsChanged, .keyDown, .keyUp]
        let eventMask = monitoredTypes.reduce(CGEventMask(0)) { mask, type in
            mask | (CGEventMask(1) << type.rawValue)
        }
        
        let callback: CGEventTapCallBack = { _, eventType, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let manager = Unmanaged<PushToTalkManager>.fromOpaque(userInfo).takeUnretainedValue()
            return manager.handleEventTap(eventType: eventType, event: event)
        }
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            AppLogger.shared.error("Failed to create CGEvent tap for push-to-talk.", category: .voice)
            return
        }
        
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            AppLogger.shared.error("Failed to create CFRunLoopSource for event tap.", category: .voice)
            return
        }
        
        self.eventTap = tap
        self.runLoopSource = source
        
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        AppLogger.shared.info("Global PushToTalkManager event tap installed.", category: .voice)
    }
    
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        
        isCurrentlyPressed = false
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
    }
    
    private func handleEventTap(eventType: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Automatically re-enable tap if disabled by system timeout
        if eventType == .tapDisabledByTimeout || eventType == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                AppLogger.shared.debug("PushToTalkManager: Re-enabled event tap after system timeout.", category: .voice)
            }
            return Unmanaged.passUnretained(event)
        }
        
        let flags = event.flags
        let isControlPressed = flags.contains(.maskControl)
        let isOptionPressed = flags.contains(.maskAlternate)
        
        let trigger = MainActor.assumeIsolated {
            ApplicationState.shared.voicePreferences.pushToTalkTrigger
        }
        var isTriggerActive = false
        
        switch trigger {
        case .controlKeyHold:
            isTriggerActive = isControlPressed
        case .optionKeyHold:
            isTriggerActive = isOptionPressed
        case .controlOptionHold:
            isTriggerActive = isControlPressed && isOptionPressed
        case .fnKeyHold:
            isTriggerActive = flags.contains(.maskSecondaryFn)
        }
        
        lock.lock()
        let wasPressed = isCurrentlyPressed
        if isTriggerActive && !wasPressed {
            isCurrentlyPressed = true
            lock.unlock()
            subject.send(.pressed)
            AppLogger.shared.debug("Push-to-talk trigger PRESSED (trigger: \(trigger.rawValue)).", category: .voice)
        } else if !isTriggerActive && wasPressed {
            isCurrentlyPressed = false
            lock.unlock()
            subject.send(.released)
            AppLogger.shared.debug("Push-to-talk trigger RELEASED.", category: .voice)
        } else {
            lock.unlock()
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    /// Allows programmatically triggering push-to-talk (e.g. from UI buttons or tests)
    public func simulateTrigger(state: PushToTalkState) {
        lock.lock()
        let wasPressed = isCurrentlyPressed
        if (state == .pressed && wasPressed) || (state == .released && !wasPressed) {
            lock.unlock()
            return
        }
        isCurrentlyPressed = (state == .pressed)
        lock.unlock()
        subject.send(state)
    }
}
