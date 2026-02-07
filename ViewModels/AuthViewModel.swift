import Foundation
import SwiftUI

// MARK: - Auth ViewModel

/// ViewModel for managing GitHub authentication
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var tokenInput: String = ""
    @Published private(set) var isValidating = false
    @Published private(set) var isAuthenticated = false
    @Published private(set) var username: String?
    @Published var error: AuthError?
    @Published var showTokenInput = false
    
    // MARK: - Dependencies
    
    private let keychainManager: KeychainManager
    private let apiService: GitHubAPIService
    private let databaseManager: DatabaseManager
    
    // MARK: - Init
    
    init(
        keychainManager: KeychainManager = KeychainManager.shared,
        apiService: GitHubAPIService = GitHubAPIService.shared,
        databaseManager: DatabaseManager = DatabaseManager.shared
    ) {
        self.keychainManager = keychainManager
        self.apiService = apiService
        self.databaseManager = databaseManager
        
        checkAuthentication()
    }
    
    // MARK: - Public Methods
    
    /// Check if user is authenticated
    func checkAuthentication() {
        isAuthenticated = keychainManager.hasGitHubToken
        if isAuthenticated {
            // Validate token in background
            Task {
                await validateStoredToken()
            }
        }
    }
    
    /// Validate and save a new token
    func authenticate() async -> Bool {
        let token = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !token.isEmpty else {
            error = .emptyToken
            return false
        }
        
        guard isValidTokenFormat(token) else {
            error = .invalidFormat
            return false
        }
        
        isValidating = true
        error = nil
        
        do {
            // Validate with GitHub API
            let login = try await apiService.validateToken(token)
            
            // Save to keychain
            try keychainManager.saveGitHubToken(token)
            
            // Update state
            username = login
            isAuthenticated = true
            tokenInput = ""
            showTokenInput = false
            
            // Reset API service state for fresh fetch
            await apiService.resetLastModified()
            
            isValidating = false
            return true
            
        } catch let apiError as GitHubAPIError {
            switch apiError {
            case .unauthorized, .invalidToken:
                error = .invalidToken
            case .forbidden:
                error = .insufficientScope
            case .rateLimited:
                error = .rateLimited
            default:
                error = .networkError(apiError.localizedDescription)
            }
        } catch {
            self.error = .networkError(error.localizedDescription)
        }
        
        isValidating = false
        return false
    }
    
    /// Sign out - remove token and clear data
    func signOut() async {
        do {
            // Delete token from keychain
            try keychainManager.deleteGitHubToken()
            
            // Clear database
            try await databaseManager.clearAllData()
            
            // Reset state
            isAuthenticated = false
            username = nil
            tokenInput = ""
            
            // Reset API state
            await apiService.resetLastModified()
            
        } catch {
            print("Error during sign out: \(error)")
        }
    }
    
    /// Open GitHub token creation page
    func openTokenCreationPage() {
        let url = URL(string: "https://github.com/settings/tokens/new?scopes=notifications&description=GitNotify%20App")!
        NSWorkspace.shared.open(url)
    }
    
    // MARK: - Private Methods
    
    private func validateStoredToken() async {
        guard let token = keychainManager.getGitHubToken() else {
            isAuthenticated = false
            return
        }
        
        do {
            let login = try await apiService.validateToken(token)
            username = login
        } catch {
            // Token might be invalid, but don't force logout
            // User can try refreshing
            print("Token validation failed: \(error)")
        }
    }
    
    private func isValidTokenFormat(_ token: String) -> Bool {
        // GitHub PAT formats:
        // - Classic: ghp_xxxx (40+ chars)
        // - Fine-grained: github_pat_xxxx
        let classicPattern = "^ghp_[a-zA-Z0-9]{36,}$"
        let fineGrainedPattern = "^github_pat_[a-zA-Z0-9_]{22,}$"
        
        let classicRegex = try? NSRegularExpression(pattern: classicPattern)
        let fineGrainedRegex = try? NSRegularExpression(pattern: fineGrainedPattern)
        
        let range = NSRange(token.startIndex..., in: token)
        
        let isClassic = classicRegex?.firstMatch(in: token, range: range) != nil
        let isFineGrained = fineGrainedRegex?.firstMatch(in: token, range: range) != nil
        
        // Also allow legacy tokens (40 hex chars)
        let isLegacy = token.count == 40 && token.allSatisfy { $0.isHexDigit }
        
        return isClassic || isFineGrained || isLegacy
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError, Identifiable {
    case emptyToken
    case invalidFormat
    case invalidToken
    case insufficientScope
    case rateLimited
    case networkError(String)
    
    var id: String {
        switch self {
        case .emptyToken: return "empty"
        case .invalidFormat: return "format"
        case .invalidToken: return "invalid"
        case .insufficientScope: return "scope"
        case .rateLimited: return "rate"
        case .networkError(let msg): return "network-\(msg)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .emptyToken:
            return "Please enter your GitHub token."
        case .invalidFormat:
            return "The token format is invalid."
        case .invalidToken:
            return "This token is invalid or expired."
        case .insufficientScope:
            return "This token doesn't have the 'notifications' permission."
        case .rateLimited:
            return "GitHub API rate limit exceeded. Please try again later."
        case .networkError(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidToken, .insufficientScope:
            return "Create a new token with the 'notifications' scope."
        case .rateLimited:
            return "Wait a few minutes before trying again."
        default:
            return nil
        }
    }
}
