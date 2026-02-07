import Foundation

// MARK: - App Constants

enum Constants {
    // MARK: - App Info
    
    static let appName = "GitNotify"
    static let bundleIdentifier = "com.gitnotify.app"
    
    // MARK: - GitHub API
    
    enum GitHub {
        static let baseURL = "https://api.github.com"
        static let apiVersion = "2022-11-28"
        static let tokenCreationURL = "https://github.com/settings/tokens/new?scopes=notifications&description=GitNotify%20App"
    }
    
    // MARK: - Polling
    
    enum Polling {
        static let defaultIntervalMinutes = 20
        static let minIntervalMinutes = 5
        static let maxIntervalMinutes = 60
        
        static var defaultIntervalSeconds: TimeInterval {
            TimeInterval(defaultIntervalMinutes * 60)
        }
    }
    
    // MARK: - UI
    
    enum UI {
        static let popoverWidth: CGFloat = 400
        static let popoverHeight: CGFloat = 520
        static let maxNotificationsPerBatch = 5
    }
    
    // MARK: - Keychain
    
    enum Keychain {
        static let service = "com.gitnotify.app"
        static let tokenAccount = "github_personal_access_token"
    }
    
    // MARK: - Database
    
    enum Database {
        static let fileName = "gitnotify.sqlite"
        static let notificationRetentionDays = 30
    }
}
