//
//  MockKeychainService.swift
//  AUTOTests
//
//  In-memory mock keychain service for unit testing without touching macOS Keychain.
//

import Foundation
import AUTO

public final class MockKeychainService: KeychainService, @unchecked Sendable {
    private var storage: [String: String] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func save(key: String, value: String, service: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage["\(service):\(key)"] = value
    }
    
    public func get(key: String, service: String) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage["\(service):\(key)"]
    }
    
    public func delete(key: String, service: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: "\(service):\(key)")
    }
    
    public func hasKey(key: String, service: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage["\(service):\(key)"] != nil
    }
    
    public func clearAll(service: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}

