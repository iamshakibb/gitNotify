import Foundation
import UserNotifications
import AppKit

// MARK: - System Notification Service

/// Manages macOS system notifications for new GitHub notifications
final class SystemNotificationService: NSObject, ObservableObject, @unchecked Sendable {
    @MainActor static let shared = SystemNotificationService()
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// Lazy initialization to avoid accessing UNUserNotificationCenter before bundle is ready
    private lazy var notificationCenter: UNUserNotificationCenter = {
        UNUserNotificationCenter.current()
    }()
    
    /// Callback when user clicks on a notification
    var onNotificationClicked: ((String) -> Void)?
    
    override init() {
        super.init()
        // Note: delegate is set in setup() after app launches
    }
    
    /// Call this after app finishes launching to avoid bundle proxy errors
    func setup() {
        notificationCenter.delegate = self
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Send Notifications
    
    /// Send a notification for a new GitHub notification
    func sendNotification(for notification: GitHubNotification) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = formatTitle(for: notification)
        content.subtitle = notification.repositoryFullName
        content.body = notification.subjectTitle
        content.sound = .default
        content.categoryIdentifier = "GITHUB_NOTIFICATION"
        
        // Store notification ID in userInfo for handling clicks
        content.userInfo = [
            "notificationId": notification.id,
            "htmlURL": notification.htmlURL ?? "",
            "subjectType": notification.subjectType.rawValue
        ]
        
        // Add thread identifier for grouping
        content.threadIdentifier = notification.repositoryFullName
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
    
    /// Send notifications for multiple new notifications
    func sendNotifications(for notifications: [GitHubNotification]) async {
        // Limit to avoid spamming
        let limitedNotifications = Array(notifications.prefix(5))
        
        for notification in limitedNotifications {
            await sendNotification(for: notification)
        }
        
        // If there are more, send a summary
        if notifications.count > 5 {
            await sendSummaryNotification(count: notifications.count)
        }
    }
    
    /// Send a summary notification when there are many new notifications
    private func sendSummaryNotification(count: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "GitNotify"
        content.body = "You have \(count) new notifications"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "summary-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await notificationCenter.add(request)
    }
    
    /// Remove all delivered notifications
    func removeAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    /// Remove notification by ID
    func removeNotification(id: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
    }
    
    // MARK: - Helpers
    
    private func formatTitle(for notification: GitHubNotification) -> String {
        let icon: String
        switch notification.subjectType {
        case .issue:
            icon = "Issue"
        case .pullRequest:
            icon = "PR"
        case .commit:
            icon = "Commit"
        case .release:
            icon = "Release"
        case .discussion:
            icon = "Discussion"
        default:
            icon = "Notification"
        }
        
        return "\(icon) • \(notification.reason.displayName)"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension SystemNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound]
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification click
        if let htmlURL = userInfo["htmlURL"] as? String, !htmlURL.isEmpty {
            if let url = URL(string: htmlURL) {
                await MainActor.run {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        
        // Notify observers
        if let notificationId = userInfo["notificationId"] as? String {
            await MainActor.run {
                onNotificationClicked?(notificationId)
            }
        }
    }
}
