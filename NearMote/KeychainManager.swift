//
//  KeychainManager.swift
//  NearMote
//
//  Created by Claude on 17/01/2026.
//

import Foundation
import Security

class KeychainManager {
    // Update service to NearMote; keep legacy fallback for migration
    private let service = "illitrate-Publicashions.NearMote"
    private let legacyService = "illitrate-Publicashions.MacRemote"

    private enum Keys {
        static let hostname = "ssh.hostname"
        static let username = "ssh.username"
        static let authMethod = "ssh.authMethod"
        static let password = "ssh.password"
        static let privateKey = "ssh.privateKey"
    }

    enum KeychainError: Error {
        case duplicateItem
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }

    /// Save SSH credentials to the keychain
    func saveCredentials(_ credentials: SSHCredentials) throws {
        try save(key: Keys.hostname, value: credentials.hostname)
        try save(key: Keys.username, value: credentials.username)
        try save(key: Keys.authMethod, value: credentials.authMethod.rawValue)

        // Clear old auth data first
        try? delete(key: Keys.password)
        try? delete(key: Keys.privateKey)

        // Save the appropriate auth credential
        switch credentials.authMethod {
        case .password:
            if let password = credentials.password {
                try save(key: Keys.password, value: password)
            }
        case .privateKey:
            if let privateKey = credentials.privateKey {
                try save(key: Keys.privateKey, value: privateKey)
            }
        }
    }

    /// Load SSH credentials from the keychain
    func loadCredentials() -> SSHCredentials? {
        guard let hostname = try? load(key: Keys.hostname),
              let username = try? load(key: Keys.username),
              let authMethodRaw = try? load(key: Keys.authMethod),
              let authMethod = AuthMethod(rawValue: authMethodRaw) else {
            return nil
        }

        switch authMethod {
        case .password:
            guard let password = try? load(key: Keys.password) else {
                return nil
            }
            return SSHCredentials(hostname: hostname, username: username, authMethod: .password, password: password)

        case .privateKey:
            guard let privateKey = try? load(key: Keys.privateKey) else {
                return nil
            }
            return SSHCredentials(hostname: hostname, username: username, authMethod: .privateKey, privateKey: privateKey)
        }
    }

    /// Clear all SSH credentials from the keychain
    func clearCredentials() throws {
        try delete(key: Keys.hostname)
        try delete(key: Keys.username)
        try delete(key: Keys.authMethod)
        try delete(key: Keys.password)
        try delete(key: Keys.privateKey)
    }

    /// Check if credentials exist in the keychain
    func hasCredentials() -> Bool {
        return loadCredentials() != nil
    }

    // MARK: - Private Keychain Operations

    private func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // Try to add the item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Item exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]

            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unknown(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }

    private func load(key: String) throws -> String {
        // Helper to perform a single service lookup
        func lookup(serviceName: String) throws -> String? {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            switch status {
            case errSecSuccess:
                guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
                    throw KeychainError.invalidData
                }
                return value
            case errSecItemNotFound:
                return nil
            default:
                throw KeychainError.unknown(status)
            }
        }

        // Try current service first
        if let value = try lookup(serviceName: service) {
            return value
        }
        // Fallback to legacy service for previously saved credentials
        if let legacyValue = try lookup(serviceName: legacyService) {
            return legacyValue
        }

        throw KeychainError.itemNotFound
    }

    private func delete(key: String) throws {
        // Delete for both current and legacy service namespaces
        let services = [service, legacyService]
        for svc in services {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: svc,
                kSecAttrAccount as String: key
            ]
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.unknown(status)
            }
        }
    }
}

