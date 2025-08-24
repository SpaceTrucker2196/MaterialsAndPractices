//
//  SecureConfiguration.swift
//  MaterialsAndPractices
//
//  Centralized secure configuration management for API keys and sensitive parameters.
//  Implements GitHub security best practices for handling API credentials.
//
//  Created by AI Assistant on current date.
//

import Foundation
import Security

/// Secure configuration manager for API keys and sensitive parameters
/// Implements best practices for credential management in iOS applications
class SecureConfiguration {
    
    // MARK: - Shared Instance
    
    static let shared = SecureConfiguration()
    
    private init() {}
    
    // MARK: - Keychain Service Identifiers
    
    private struct KeychainConfig {
        static let service = "MaterialsAndPractices.SecureConfig"
        static let accessGroup = "MaterialsAndPractices.SharedKeychain"
    }
    
    // MARK: - Configuration Keys
    
    enum ConfigKey: String, CaseIterable {
        case debugLoggingEnabled = "debug_logging_enabled"
        case networkTimeoutSeconds = "network_timeout_seconds"
        case maxRetryAttempts = "max_retry_attempts"
        
        var defaultValue: String? {
            switch self {
            case .debugLoggingEnabled:
                return "true"
            case .networkTimeoutSeconds:
                return "30"
            case .maxRetryAttempts:
                return "3"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Retrieves a configuration value, first checking Keychain, then Bundle, then defaults
    /// - Parameter key: Configuration key to retrieve
    /// - Returns: Configuration value or nil if not found
    func getValue(for key: ConfigKey) -> String? {
        // First, try to get from Keychain (for sensitive values)
        if let keychainValue = getFromKeychain(key: key.rawValue) {
            return keychainValue
        }
        
        // Then, try to get from app bundle configuration
        if let bundleValue = getBundleValue(for: key) {
            return bundleValue
        }
        
        // Finally, return default value
        return key.defaultValue
    }
    
    /// Stores a configuration value securely in Keychain
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Configuration key
    /// - Returns: Success status
    @discardableResult
    func setValue(_ value: String, for key: ConfigKey) -> Bool {
        return storeInKeychain(value: value, key: key.rawValue)
    }
    
    /// Removes a configuration value from Keychain
    /// - Parameter key: Configuration key to remove
    /// - Returns: Success status
    @discardableResult
    func removeValue(for key: ConfigKey) -> Bool {
        return removeFromKeychain(key: key.rawValue)
    }
    
    /// Validates that all required configuration values are present
    /// - Returns: Array of missing required keys
    func validateConfiguration() -> [ConfigKey] {
        let requiredKeys: [ConfigKey] = [
            .networkTimeoutSeconds,
            .maxRetryAttempts
        ]
        
        return requiredKeys.filter { getValue(for: $0) == nil }
    }
    
    // MARK: - Convenience Accessors
    
    /// Debug logging enabled status
    var debugLoggingEnabled: Bool {
        return getValue(for: .debugLoggingEnabled)?.lowercased() == "true"
    }
    
    /// Network timeout in seconds
    var networkTimeoutSeconds: TimeInterval {
        guard let timeoutString = getValue(for: .networkTimeoutSeconds),
              let timeout = TimeInterval(timeoutString) else {
            return 30.0
        }
        return timeout
    }
    
    /// Maximum retry attempts for network requests
    var maxRetryAttempts: Int {
        guard let retriesString = getValue(for: .maxRetryAttempts),
              let retries = Int(retriesString) else {
            return 3
        }
        return retries
    }
    
    // MARK: - Private Methods
    
    /// Retrieves value from app bundle configuration
    /// - Parameter key: Configuration key
    /// - Returns: Configuration value from bundle or nil
    private func getBundleValue(for key: ConfigKey) -> String? {
        // Check main bundle for configuration
        if let bundleValue = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String {
            return bundleValue
        }
        
        // Check for configuration plist file
        if let configPath = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
           let configDict = NSDictionary(contentsOfFile: configPath),
           let value = configDict[key.rawValue] as? String {
            return value
        }
        
        return nil
    }
    
    /// Stores value securely in Keychain
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Keychain key
    /// - Returns: Success status
    private func storeInKeychain(value: String, key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConfig.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves value from Keychain
    /// - Parameter key: Keychain key
    /// - Returns: Retrieved value or nil
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConfig.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Removes value from Keychain
    /// - Parameter key: Keychain key
    /// - Returns: Success status
    private func removeFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConfig.service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Configuration Setup Helper

/// Helper class for initial configuration setup
/// Provides methods for setting up configuration during app initialization
struct ConfigurationSetup {
    
    /// Sets up default configuration values
    /// Call this during app initialization to ensure required values are present
    static func setupDefaults() {
        let config = SecureConfiguration.shared
        
        // Set default values for configuration keys that don't have values
        for key in SecureConfiguration.ConfigKey.allCases {
            if config.getValue(for: key) == nil,
               let defaultValue = key.defaultValue {
                config.setValue(defaultValue, for: key)
            }
        }
    }
    
    /// Validates configuration and logs warnings for missing values
    /// Call this during app startup to verify configuration completeness
    static func validateAndLog() {
        let config = SecureConfiguration.shared
        let missingKeys = config.validateConfiguration()
        
        if !missingKeys.isEmpty {
            print("⚠️ Warning: Missing configuration values for keys: \(missingKeys.map { $0.rawValue })")
        }
        
        // Log configuration status
        print("📊 Configuration Status:")
        print("  - Debug Logging: \(config.debugLoggingEnabled)")
        print("  - Network Timeout: \(config.networkTimeoutSeconds)s")
        print("  - Max Retries: \(config.maxRetryAttempts)")
    }
}