import Foundation
import SwiftUI
import Combine

// MARK: - Notifications ViewModel

/// Main ViewModel for managing GitHub notifications
@MainActor
final class NotificationsViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published private(set) var notifications: [GitHubNotification] = []
    @Published private(set) var filteredNotifications: [GitHubNotification] = []
    @Published var selectedCategory: NotificationCategory = .all
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published var error: AppError?
    @Published private(set) var lastRefreshDate: Date?
    
    // MARK: - Computed Properties
    
    var hasUnread: Bool {
        notifications.contains { $0.unread }
    }
    
    var unreadCount: Int {
        notifications.filter { $0.unread }.count
    }
    
    var unreadCountByCategory: [NotificationCategory: Int] {
        var counts: [NotificationCategory: Int] = [:]
        for category in NotificationCategory.allCases {
            counts[category] = notifications.filter(by: category).filter { $0.unread }.count
        }
        return counts
    }
    
    // MARK: - Dependencies
    
    private let apiService: GitHubAPIService
    private let databaseManager: DatabaseManager
    private let keychainManager: KeychainManager
    private let notificationService: SystemNotificationService
    private let pollingService: PollingService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(
        apiService: GitHubAPIService = GitHubAPIService.shared,
        databaseManager: DatabaseManager = DatabaseManager.shared,
        keychainManager: KeychainManager = KeychainManager.shared,
        notificationService: SystemNotificationService = SystemNotificationService.shared,
        pollingService: PollingService = PollingService.shared
    ) {
        self.apiService = apiService
        self.databaseManager = databaseManager
        self.keychainManager = keychainManager
        self.notificationService = notificationService
        self.pollingService = pollingService
        
        setupBindings()
        setupPollingCallbacks()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Update filtered notifications when category changes
        $selectedCategory
            .combineLatest($notifications)
            .map { category, notifications in
                notifications.filter(by: category)
            }
            .assign(to: &$filteredNotifications)
    }
    
    private func setupPollingCallbacks() {
        pollingService.onNewNotifications = { [weak self] newNotifications in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Send system notifications for new items
                if await self.notificationService.isAuthorized {
                    await self.notificationService.sendNotifications(for: newNotifications)
                }
                
                // Reload from database
                self.loadFromDatabase()
            }
        }
        
        pollingService.onPollComplete = { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    self?.lastRefreshDate = Date()
                    self?.loadFromDatabase()
                case .failure(let error):
                    self?.error = AppError(error: error)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Load notifications from local database
    func loadFromDatabase() {
        Task {
            do {
                notifications = try await databaseManager.fetchAllNotifications()
            } catch {
                self.error = AppError(error: error)
            }
        }
    }
    
    /// Refresh notifications from GitHub API
    func refresh() async {
        guard !isRefreshing else { return }
        
        guard let token = keychainManager.getGitHubToken() else {
            error = AppError(title: "Not Authenticated", message: "Please add your GitHub token.")
            return
        }
        
        isRefreshing = true
        error = nil
        
        do {
            let result = try await apiService.fetchNotifications(
                token: token,
                all: false,
                useLastModified: false
            )
            
            if !result.notModified {
                // Get existing IDs for new notification detection
                let existingIds = try await databaseManager.getNotificationIds()
                let newNotifications = result.notifications.filter { !existingIds.contains($0.id) }
                
                // Save to database
                try await databaseManager.upsertNotifications(result.notifications)
                
                // Notify about new ones
                if !newNotifications.isEmpty && notificationService.isAuthorized {
                    await notificationService.sendNotifications(for: newNotifications)
                }
            }
            
            loadFromDatabase()
            lastRefreshDate = Date()
            
        } catch {
            self.error = AppError(error: error)
        }
        
        isRefreshing = false
    }
    
    /// Mark a single notification as read
    func markAsRead(_ notification: GitHubNotification) async {
        guard let token = keychainManager.getGitHubToken() else { return }
        
        // Optimistic update
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].unread = false
        }
        
        do {
            // Update local database
            try await databaseManager.markAsRead(id: notification.id)
            
            // Sync with GitHub
            try await apiService.markThreadAsRead(threadId: notification.id, token: token)
            
            // Remove from notification center
            notificationService.removeNotification(id: notification.id)
            
        } catch {
            // Revert on failure
            loadFromDatabase()
            self.error = AppError(error: error)
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() async {
        guard let token = keychainManager.getGitHubToken() else { return }
        
        // Optimistic update
        for index in notifications.indices {
            notifications[index].unread = false
        }
        
        do {
            // Update local database
            try await databaseManager.markAllAsRead()
            
            // Sync with GitHub
            try await apiService.markAllAsRead(token: token)
            
            // Clear all system notifications
            notificationService.removeAllNotifications()
            
        } catch {
            // Revert on failure
            loadFromDatabase()
            self.error = AppError(error: error)
        }
    }
    
    /// Open notification in browser
    func openInBrowser(_ notification: GitHubNotification) {
        guard let urlString = notification.htmlURL,
              let url = URL(string: urlString) else {
            return
        }
        
        NSWorkspace.shared.open(url)
        
        // Mark as read
        Task {
            await markAsRead(notification)
        }
    }
    
    /// Start background polling
    func startPolling(interval: TimeInterval) {
        pollingService.start(interval: interval)
    }
    
    /// Stop background polling
    func stopPolling() {
        pollingService.stop()
    }
    
    /// Trigger manual poll
    func pollNow() async {
        await pollingService.pollNow()
    }
}

// MARK: - Array Extension for Filtering

extension Array where Element == GitHubNotification {
    func filter(by category: NotificationCategory) -> [GitHubNotification] {
        switch category {
        case .all:
            return self
        case .mentioned:
            return filter { $0.reason == .mention || $0.reason == .teamMention }
        case .assignedTask:
            return filter {
                $0.reason == .assign ||
                $0.reason == .reviewRequested ||
                $0.reason == .approvalRequested
            }
        case .comments:
            return filter { $0.reason == .comment || $0.reason == .author }
        }
    }
}

// MARK: - App Error

struct AppError: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let isRecoverable: Bool
    
    init(title: String, message: String, isRecoverable: Bool = true) {
        self.title = title
        self.message = message
        self.isRecoverable = isRecoverable
    }
    
    init(error: Error) {
        if let apiError = error as? GitHubAPIError {
            self.title = "GitHub API Error"
            self.message = apiError.localizedDescription
            self.isRecoverable = true
        } else if let dbError = error as? DatabaseError {
            self.title = "Database Error"
            self.message = dbError.localizedDescription
            self.isRecoverable = false
        } else if let pollingError = error as? PollingError {
            self.title = "Sync Error"
            self.message = pollingError.localizedDescription
            self.isRecoverable = true
        } else {
            self.title = "Error"
            self.message = error.localizedDescription
            self.isRecoverable = true
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.id == rhs.id
    }
}
