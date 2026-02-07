import Foundation
import GRDB

// MARK: - Menu Bar Icon Style

/// Available icon styles for the menu bar
enum MenuBarIconStyle: String, CaseIterable, Codable, Identifiable {
    case bell = "bell"
    case gitBranch = "git_branch"
    case network = "network"
    case github = "github"
    
    var id: String { rawValue }
    
    /// SF Symbol name for the icon (github uses custom asset)
    var iconName: String {
        switch self {
        case .bell:
            return "bell.fill"
        case .gitBranch:
            return "arrow.triangle.branch"
        case .network:
            return "network"
        case .github:
            return "octagon.fill" // Fallback SF Symbol resembling GitHub shape
        }
    }
    
    /// SF Symbol name for unread state
    var unreadIconName: String {
        switch self {
        case .bell:
            return "bell.badge.fill"
        case .gitBranch:
            return "arrow.triangle.branch"
        case .network:
            return "network"
        case .github:
            return "octagon.fill" // Fallback SF Symbol
        }
    }
    
    /// Whether this style uses a custom asset (not SF Symbol)
    var isCustomAsset: Bool {
        // GitHub now uses SF Symbol fallback, so no custom asset needed
        false
    }
    
    /// Display name for settings UI
    var displayName: String {
        switch self {
        case .bell:
            return "Bell"
        case .gitBranch:
            return "Git Branch"
        case .network:
            return "Network"
        case .github:
            return "GitHub"
        }
    }
}

// MARK: - App Settings Model

/// User preferences and app settings
struct AppSettings: Codable, Equatable {
    /// Poll interval in minutes (default: 20)
    var pollIntervalMinutes: Int
    
    /// Whether to show unread badge on menu bar icon
    var showBadge: Bool
    
    /// Whether notifications are enabled
    var notificationsEnabled: Bool
    
    /// Whether to launch at login
    var launchAtLogin: Bool
    
    /// Menu bar icon style
    var menuBarIconStyle: MenuBarIconStyle
    
    /// Last successful poll timestamp
    var lastPollDate: Date?
    
    /// Last-Modified header from GitHub for efficient polling
    var lastModifiedHeader: String?
    
    /// Default settings
    static let `default` = AppSettings(
        pollIntervalMinutes: 20,
        showBadge: true,
        notificationsEnabled: true,
        launchAtLogin: false,
        menuBarIconStyle: .gitBranch,
        lastPollDate: nil,
        lastModifiedHeader: nil
    )
    
    /// Poll interval converted to seconds
    var pollIntervalSeconds: TimeInterval {
        TimeInterval(pollIntervalMinutes * 60)
    }
    
    /// Minimum poll interval (5 minutes)
    static let minPollInterval = 5
    
    /// Maximum poll interval (60 minutes)
    static let maxPollInterval = 60
}

// MARK: - GRDB Database Support

/// Individual setting stored in database
struct SettingRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "settings" }
    
    let key: String
    let value: String
    
    enum Columns: String, ColumnExpression {
        case key
        case value
    }
}

// MARK: - Settings Keys

enum SettingsKey: String, CaseIterable {
    case pollIntervalMinutes = "poll_interval_minutes"
    case showBadge = "show_badge"
    case notificationsEnabled = "notifications_enabled"
    case launchAtLogin = "launch_at_login"
    case menuBarIconStyle = "menu_bar_icon_style"
    case lastPollDate = "last_poll_date"
    case lastModifiedHeader = "last_modified_header"
}
