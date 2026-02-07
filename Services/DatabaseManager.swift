import Foundation
import GRDB

// MARK: - Database Manager

/// Manages SQLite database operations using GRDB
/// Using actor to ensure thread-safe access to database queue
actor DatabaseManager {
    static nonisolated let shared = DatabaseManager()
    
    private var dbQueue: DatabaseQueue?
    
    private init() {}
    
    // MARK: - Setup
    
    /// Initialize the database
    func setup() throws {
        let fileManager = FileManager.default
        
        // Get Application Support directory
        guard let appSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw DatabaseError.directoryNotFound
        }
        
        // Create app-specific directory
        let appDirectoryURL = appSupportURL.appendingPathComponent("GitNotify", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appDirectoryURL.path) {
            try fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true)
        }
        
        // Database file path
        let dbURL = appDirectoryURL.appendingPathComponent("gitnotify.sqlite")
        
        // Create database queue
        dbQueue = try DatabaseQueue(path: dbURL.path)
        
        // Run migrations
        try runMigrations()
    }
    
    // MARK: - Migrations
    
    private func runMigrations() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        var migrator = DatabaseMigrator()
        
        // Initial schema
        migrator.registerMigration("v1_initial") { db in
            // Notifications table
            try db.create(table: "notifications", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("repository_full_name", .text).notNull()
                t.column("repository_owner_avatar_url", .text)
                t.column("subject_title", .text).notNull()
                t.column("subject_type", .text).notNull()
                t.column("subject_url", .text)
                t.column("reason", .text).notNull()
                t.column("unread", .boolean).notNull().defaults(to: true)
                t.column("updated_at", .datetime).notNull()
                t.column("last_read_at", .datetime)
            }
            
            // Settings table
            try db.create(table: "settings", ifNotExists: true) { t in
                t.column("key", .text).primaryKey()
                t.column("value", .text).notNull()
            }
            
            // Indexes
            try db.create(
                index: "idx_notifications_reason",
                on: "notifications",
                columns: ["reason"],
                ifNotExists: true
            )
            
            try db.create(
                index: "idx_notifications_updated",
                on: "notifications",
                columns: ["updated_at"],
                ifNotExists: true
            )
            
            try db.create(
                index: "idx_notifications_unread",
                on: "notifications",
                columns: ["unread"],
                ifNotExists: true
            )
        }
        
        try migrator.migrate(dbQueue)
    }
    
    // MARK: - Notifications CRUD
    
    /// Save or update notifications
    func upsertNotifications(_ notifications: [GitHubNotification]) throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        try dbQueue.write { db in
            for notification in notifications {
                try notification.save(db, onConflict: .replace)
            }
        }
    }
    
    /// Fetch all notifications
    func fetchAllNotifications() throws -> [GitHubNotification] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        return try dbQueue.read { db in
            try GitHubNotification
                .order(GitHubNotification.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }
    
    /// Fetch notifications by category
    func fetchNotifications(for category: NotificationCategory) throws -> [GitHubNotification] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        return try dbQueue.read { db in
            let request: QueryInterfaceRequest<GitHubNotification>
            
            switch category {
            case .all:
                request = GitHubNotification.all()
            case .mentioned:
                request = GitHubNotification.filter(
                    [NotificationReason.mention.rawValue, NotificationReason.teamMention.rawValue]
                        .contains(GitHubNotification.Columns.reason)
                )
            case .assignedTask:
                request = GitHubNotification.filter(
                    [NotificationReason.assign.rawValue, NotificationReason.reviewRequested.rawValue, NotificationReason.approvalRequested.rawValue]
                        .contains(GitHubNotification.Columns.reason)
                )
            case .comments:
                request = GitHubNotification.filter(
                    [NotificationReason.comment.rawValue, NotificationReason.author.rawValue]
                        .contains(GitHubNotification.Columns.reason)
                )
            }
            
            return try request
                .order(GitHubNotification.Columns.updatedAt.desc)
                .fetchAll(db)
        }
    }
    
    /// Fetch unread notifications count
    func fetchUnreadCount() throws -> Int {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        return try dbQueue.read { db in
            try GitHubNotification
                .filter(GitHubNotification.Columns.unread == true)
                .fetchCount(db)
        }
    }
    
    /// Mark notification as read
    func markAsRead(id: String) throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE notifications SET unread = 0 WHERE id = ?",
                arguments: [id]
            )
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE notifications SET unread = 0")
        }
    }
    
    /// Delete old notifications (older than 30 days)
    func cleanupOldNotifications() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        try dbQueue.write { db in
            try GitHubNotification
                .filter(GitHubNotification.Columns.updatedAt < thirtyDaysAgo)
                .deleteAll(db)
        }
    }
    
    /// Get notification IDs
    func getNotificationIds() throws -> Set<String> {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        return try dbQueue.read { db in
            let ids = try String.fetchAll(db, sql: "SELECT id FROM notifications")
            return Set(ids)
        }
    }
    
    // MARK: - Settings CRUD
    
    /// Save a setting
    func saveSetting(key: SettingsKey, value: String) throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        try dbQueue.write { db in
            let record = SettingRecord(key: key.rawValue, value: value)
            try record.save(db, onConflict: .replace)
        }
    }
    
    /// Get a setting value
    func getSetting(key: SettingsKey) throws -> String? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        return try dbQueue.read { db in
            try SettingRecord
                .filter(SettingRecord.Columns.key == key.rawValue)
                .fetchOne(db)?
                .value
        }
    }
    
    /// Load all settings
    func loadSettings() throws -> AppSettings {
        var settings = AppSettings.default
        
        if let pollInterval = try getSetting(key: .pollIntervalMinutes),
           let interval = Int(pollInterval) {
            settings.pollIntervalMinutes = interval
        }
        
        if let showBadge = try getSetting(key: .showBadge) {
            settings.showBadge = showBadge == "true"
        }
        
        if let notificationsEnabled = try getSetting(key: .notificationsEnabled) {
            settings.notificationsEnabled = notificationsEnabled == "true"
        }
        
        if let launchAtLogin = try getSetting(key: .launchAtLogin) {
            settings.launchAtLogin = launchAtLogin == "true"
        }
        
        if let menuBarIconStyleRaw = try getSetting(key: .menuBarIconStyle),
           let iconStyle = MenuBarIconStyle(rawValue: menuBarIconStyleRaw) {
            settings.menuBarIconStyle = iconStyle
        }
        
        if let lastPollDate = try getSetting(key: .lastPollDate),
           let timestamp = Double(lastPollDate) {
            settings.lastPollDate = Date(timeIntervalSince1970: timestamp)
        }
        
        if let lastModified = try getSetting(key: .lastModifiedHeader) {
            settings.lastModifiedHeader = lastModified
        }
        
        return settings
    }
    
    /// Save all settings
    func saveSettings(_ settings: AppSettings) throws {
        try saveSetting(key: .pollIntervalMinutes, value: String(settings.pollIntervalMinutes))
        try saveSetting(key: .showBadge, value: String(settings.showBadge))
        try saveSetting(key: .notificationsEnabled, value: String(settings.notificationsEnabled))
        try saveSetting(key: .launchAtLogin, value: String(settings.launchAtLogin))
        try saveSetting(key: .menuBarIconStyle, value: settings.menuBarIconStyle.rawValue)
        
        if let lastPollDate = settings.lastPollDate {
            try saveSetting(key: .lastPollDate, value: String(lastPollDate.timeIntervalSince1970))
        }
        
        if let lastModified = settings.lastModifiedHeader {
            try saveSetting(key: .lastModifiedHeader, value: lastModified)
        }
    }
    
    // MARK: - Cleanup
    
    /// Clear all data (for logout)
    func clearAllData() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        
        try dbQueue.write { db in
            try db.execute(sql: "DELETE FROM notifications")
            try db.execute(sql: "DELETE FROM settings")
        }
    }
}

// MARK: - Database Errors

enum DatabaseError: LocalizedError {
    case notInitialized
    case directoryNotFound
    case migrationFailed
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database has not been initialized."
        case .directoryNotFound:
            return "Could not find Application Support directory."
        case .migrationFailed:
            return "Database migration failed."
        }
    }
}
