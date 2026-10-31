//
//  AutoMemoryManager.swift
//  AUTO
//
//  Native Local SQLite Memory Manager:
//  Stores conversation turns, preferences, task histories, and contextual items
//  strictly in local SQLite storage (~/Library/Application Support/AUTO/auto_memory.sqlite3).
//  Includes sensitive data firewall and ensures zero bulk upload to cloud providers.
//

import Foundation
import SQLite3

public struct AutoMemoryRecord: Identifiable, Sendable {
    public let id: String
    public let category: String
    public let key: String
    public let content: String
    public let importance: Double
    public let timestamp: Date
}

public final class AutoMemoryManager: @unchecked Sendable {
    public static let shared = AutoMemoryManager()
    
    private var db: OpaquePointer?
    private let lock = NSLock()
    private let dbPath: String
    
    public init(customPath: String? = nil) {
        if let custom = customPath {
            self.dbPath = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let autoDir = appSupport.appendingPathComponent("AUTO", isDirectory: true)
            try? FileManager.default.createDirectory(at: autoDir, withIntermediateDirectories: true)
            self.dbPath = autoDir.appendingPathComponent("auto_memory.sqlite3").path
        }
        openDatabase()
        createTables()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    // MARK: - SQLite Setup
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            AppLogger.shared.error("Failed to open SQLite memory database at \(dbPath)", category: .agent)
        }
    }
    
    private func createTables() {
        let sql = """
        CREATE TABLE IF NOT EXISTS auto_memories (
            id TEXT PRIMARY KEY,
            category TEXT,
            key TEXT,
            content TEXT,
            importance REAL,
            created_at REAL
        );
        CREATE TABLE IF NOT EXISTS auto_conversations (
            id TEXT PRIMARY KEY,
            user_transcript TEXT,
            assistant_response TEXT,
            created_at REAL
        );
        CREATE TABLE IF NOT EXISTS auto_tasks (
            id TEXT PRIMARY KEY,
            instruction TEXT,
            status TEXT,
            created_at REAL
        );
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }
    
    // MARK: - Store Memory
    @discardableResult
    public func store(category: String, key: String, content: String, importance: Double = 0.5) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        // Security Firewall: reject sensitive credentials
        if containsSensitiveData(key) || containsSensitiveData(content) {
            AppLogger.shared.warning("Memory rejected: Content contains sensitive patterns (passwords/keys).", category: .agent)
            return false
        }
        
        let id = UUID().uuidString
        let now = Date().timeIntervalSince1970
        let sql = "INSERT OR REPLACE INTO auto_memories (id, category, key, content, importance, created_at) VALUES (?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        
        sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (category as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (key as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (content as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 5, importance)
        sqlite3_bind_double(stmt, 6, now)
        
        return sqlite3_step(stmt) == SQLITE_DONE
    }
    
    // MARK: - Query Relevant Context
    public func retrieveRelevantContext(query: String, limit: Int = 3) -> [AutoMemoryRecord] {
        lock.lock()
        defer { lock.unlock() }
        
        let queryPattern = "%\(query.lowercased())%"
        let sql = "SELECT id, category, key, content, importance, created_at FROM auto_memories WHERE LOWER(key) LIKE ? OR LOWER(content) LIKE ? ORDER BY importance DESC LIMIT ?;"
        var stmt: OpaquePointer?
        var results: [AutoMemoryRecord] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        
        sqlite3_bind_text(stmt, 1, (queryPattern as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (queryPattern as NSString).utf8String, -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(limit))
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(stmt, 0))
            let category = String(cString: sqlite3_column_text(stmt, 1))
            let key = String(cString: sqlite3_column_text(stmt, 2))
            let content = String(cString: sqlite3_column_text(stmt, 3))
            let importance = sqlite3_column_double(stmt, 4)
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))
            
            results.append(AutoMemoryRecord(
                id: id,
                category: category,
                key: key,
                content: content,
                importance: importance,
                timestamp: timestamp
            ))
        }
        
        return results
    }
    
    // MARK: - Sensitive Data Firewall
    private func containsSensitiveData(_ text: String) -> Bool {
        let patterns = [
            "password\\s*[:=]\\s*\\S+",
            "bearer\\s+[A-Za-z0-9_\\-\\.]+",
            "ghp_[A-Za-z0-9]{36}",
            "AIza[0-9A-Za-z\\-_]{35}",
            "-----BEGIN (RSA|EC|PRIVATE) KEY-----",
            "\\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13})\\b"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Purge
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        sqlite3_exec(db, "DELETE FROM auto_memories; DELETE FROM auto_conversations; DELETE FROM auto_tasks;", nil, nil, nil)
    }
}

