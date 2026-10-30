//
//  KeychainManager.swift
//  AUTO
//
//  Secure abstraction for storing sensitive credentials (such as Gemini and OmniRoute
//  API keys) in the macOS Keychain. Ensures credentials are never persisted in
//  UserDefaults, plain-text configuration files, logs, or source code.
//

import Foundation
import Security

public protocol KeychainService: Sendable {
    func save(key: String, value: String, service: String) throws
    func get(key: String, service: String) throws -> String?
    func delete(key: String, service: String) throws
    func hasKey(key: String, service: String) -> Bool
    func clearAll(service: String) throws
}

public final class KeychainManager: KeychainService, @unchecked Sendable {
    public static let shared = KeychainManager()
    
    public static let defaultService = "com.auto.desktop.companion"
    public static let geminiApiKeyAccount = "gemini_api_key"
    public static let omniRouteApiKeyAccount = "omniroute_api_key"
    
    private let lock = NSLock()
    
    public init() {}
    
    public func save(key: String, value: String, service: String = KeychainManager.defaultService) throws {
        lock.lock()
        defer { lock.unlock() }
        
        guard let data = value.data(using: .utf8) else {
            throw AUTOError.keychainError(status: errSecParam, message: "Failed to encode value as UTF-8 data.")
        }
        
        // Build base query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        // Check if item already exists
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // Update existing item
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                AppLogger.shared.error("Failed to update Keychain item for '\(key)': status \(updateStatus)", category: .security)
                throw AUTOError.keychainError(status: updateStatus, message: "Failed to update Keychain item.")
            }
            AppLogger.shared.debug("Keychain item updated successfully for '\(key)'.", category: .security)
        } else if status == errSecItemNotFound {
            // Add new item
            var newQuery = query
            newQuery[kSecValueData as String] = data
            // Accessible when user unlocked the device
            newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            
            let addStatus = SecItemAdd(newQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                AppLogger.shared.error("Failed to add Keychain item for '\(key)': status \(addStatus)", category: .security)
                throw AUTOError.keychainError(status: addStatus, message: "Failed to add Keychain item.")
            }
            AppLogger.shared.debug("Keychain item added successfully for '\(key)'.", category: .security)
        } else {
            AppLogger.shared.error("Keychain query failed for '\(key)' with status \(status)", category: .security)
            throw AUTOError.keychainError(status: status, message: "Keychain query returned status \(status).")
        }
    }
    
    public func get(key: String, service: String = KeychainManager.defaultService) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            guard let data = item as? Data, let string = String(data: data, encoding: .utf8) else {
                throw AUTOError.keychainError(status: errSecDecode, message: "Corrupted or non-UTF8 data found in Keychain.")
            }
            return string
        } else if status == errSecItemNotFound {
            return nil
        } else {
            AppLogger.shared.error("Keychain read failed for '\(key)' with status \(status)", category: .security)
            throw AUTOError.keychainError(status: status, message: "Keychain read failed with status \(status).")
        }
    }
    
    public func delete(key: String, service: String = KeychainManager.defaultService) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            AppLogger.shared.error("Failed to delete Keychain item '\(key)': status \(status)", category: .security)
            throw AUTOError.keychainError(status: status, message: "Failed to delete Keychain item.")
        }
        AppLogger.shared.debug("Keychain item deleted for '\(key)'.", category: .security)
    }
    
    public func hasKey(key: String, service: String = KeychainManager.defaultService) -> Bool {
        do {
            let value = try get(key: key, service: service)
            return value != nil && !value!.isEmpty
        } catch {
            return false
        }
    }
    
    public func clearAll(service: String = KeychainManager.defaultService) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            AppLogger.shared.error("Failed to clear Keychain items for service '\(service)': status \(status)", category: .security)
            throw AUTOError.keychainError(status: status, message: "Failed to clear Keychain items.")
        }
        AppLogger.shared.info("Cleared all Keychain items for service '\(service)'.", category: .security)
    }
}
