import Foundation
import Security

// MARK: - Keychain Manager

/// Manages secure storage of sensitive data (GitHub token) in macOS Keychain
final class KeychainManager: @unchecked Sendable {
    static let shared = KeychainManager()
    
    private let service: String
    private let accessGroup: String?
    
    /// Account identifier for the GitHub token
    private let githubTokenAccount = "github_personal_access_token"
    
    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.gitnotify.app",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    // MARK: - Public API
    
    /// Save GitHub token to keychain
    /// - Parameter token: The GitHub Personal Access Token
    /// - Throws: KeychainError if save fails
    func saveGitHubToken(_ token: String) throws {
        try save(token, for: githubTokenAccount)
    }
    
    /// Retrieve GitHub token from keychain
    /// - Returns: The stored token, or nil if not found
    func getGitHubToken() -> String? {
        try? retrieve(for: githubTokenAccount)
    }
    
    /// Delete GitHub token from keychain
    /// - Throws: KeychainError if deletion fails
    func deleteGitHubToken() throws {
        try delete(for: githubTokenAccount)
    }
    
    /// Check if a GitHub token exists
    var hasGitHubToken: Bool {
        getGitHubToken() != nil
    }
    
    // MARK: - Private Implementation
    
    private func save(_ value: String, for account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        // Build query
        var query = baseQuery(for: account)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        
        // Delete existing item first (if any)
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private func retrieve(for account: String) throws -> String {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    private func delete(for account: String) throws {
        let query = baseQuery(for: account)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private func baseQuery(for account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unhandledError(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "The requested item was not found in the keychain."
        case .duplicateItem:
            return "An item with this identifier already exists."
        case .invalidData:
            return "The data could not be encoded or decoded."
        case .unhandledError(let status):
            if let message = SecCopyErrorMessageString(status, nil) {
                return "Keychain error: \(message)"
            }
            return "Keychain error with status: \(status)"
        }
    }
}
