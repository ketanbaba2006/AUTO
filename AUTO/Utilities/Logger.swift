//
//  Logger.swift
//  AUTO
//
//  Centralized structured logging system for the AUTO application.
//  Provides privacy-safe categorized logging using Apple's unified logging (os.Logger).
//

import Foundation
import os.log

public enum LogCategory: String, Sendable {
    case app = "App"
    case lifecycle = "Lifecycle"
    case ai = "AI"
    case voice = "Voice"
    case screen = "Screen"
    case cursor = "Cursor"
    case security = "Security"
    case permissions = "Permissions"
    case ui = "UI"
    case agent = "Agent"
}

public final class AppLogger: @unchecked Sendable {
    public static let shared = AppLogger()
    
    private let subsystem: String
    private var loggers: [LogCategory: Logger] = [:]
    private let lock = NSLock()
    
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.auto.companion") {
        self.subsystem = subsystem
    }
    
    private func getLogger(for category: LogCategory) -> Logger {
        lock.lock()
        defer { lock.unlock() }
        
        if let existing = loggers[category] {
            return existing
        }
        let newLogger = Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = newLogger
        return newLogger
    }
    
    public func debug(_ message: String, category: LogCategory = .app) {
        let logger = getLogger(for: category)
        logger.debug("[\(category.rawValue, privacy: .public)] \(message, privacy: .public)")
    }
    
    public func info(_ message: String, category: LogCategory = .app) {
        let logger = getLogger(for: category)
        logger.info("[\(category.rawValue, privacy: .public)] \(message, privacy: .public)")
    }
    
    public func notice(_ message: String, category: LogCategory = .app) {
        let logger = getLogger(for: category)
        logger.notice("[\(category.rawValue, privacy: .public)] \(message, privacy: .public)")
    }
    
    public func warning(_ message: String, category: LogCategory = .app) {
        let logger = getLogger(for: category)
        logger.warning("[\(category.rawValue, privacy: .public)] ⚠️ \(message, privacy: .public)")
    }
    
    public func error(_ message: String, category: LogCategory = .app) {
        let logger = getLogger(for: category)
        logger.error("[\(category.rawValue, privacy: .public)] 🛑 \(message, privacy: .public)")
    }
    
    public func fault(_ message: String, category: LogCategory = .app) {
        let logger = getLogger(for: category)
        logger.fault("[\(category.rawValue, privacy: .public)] 💥 \(message, privacy: .public)")
    }
    
    /// Redacts sensitive strings like API keys or tokens from debug output
    public static func sanitize(_ sensitiveText: String) -> String {
        guard sensitiveText.count > 6 else { return "******" }
        let prefix = sensitiveText.prefix(3)
        let suffix = sensitiveText.suffix(3)
        return "\(prefix)...\(suffix)"
    }
}
