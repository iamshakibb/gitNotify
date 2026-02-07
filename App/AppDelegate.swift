import AppKit
import UserNotifications
import SwiftUI

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize database
        setupDatabase()
        
        // Setup notification handling
        setupNotifications()
        
        // Start background polling if authenticated
        startPollingIfAuthenticated()
        
        // Request notification permissions
        Task {
            await requestNotificationPermission()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop polling
        Task { @MainActor in
            PollingService.shared.stop()
        }
    }
    
    // MARK: - Setup
    
    private func setupDatabase() {
        Task {
            do {
                try await DatabaseManager.shared.setup()
                print("Database initialized successfully")
            } catch {
                print("Failed to initialize database: \(error)")
                // Show alert to user
                await MainActor.run {
                    self.showErrorAlert(
                        title: "Database Error",
                        message: "Failed to initialize the database. The app may not function correctly.\n\nError: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func setupNotifications() {
        // Initialize the notification service now that the app bundle is ready
        Task { @MainActor in
            SystemNotificationService.shared.setup()
            
            // Set up notification click handler
            SystemNotificationService.shared.onNotificationClicked = { notificationId in
                // Mark as read when clicked
                Task {
                    try? await DatabaseManager.shared.markAsRead(id: notificationId)
                }
            }
        }
    }
    
    private func requestNotificationPermission() async {
        let granted = await SystemNotificationService.shared.requestAuthorization()
        print("Notification permission: \(granted ? "granted" : "denied")")
    }
    
    private func startPollingIfAuthenticated() {
        guard KeychainManager.shared.hasGitHubToken else {
            print("No token found, skipping polling start")
            return
        }
        
        Task { @MainActor in
            // Load settings for poll interval
            do {
                let settings = try await DatabaseManager.shared.loadSettings()
                let interval = settings.pollIntervalSeconds
                PollingService.shared.start(interval: interval)
                print("Started polling with interval: \(interval) seconds")
            } catch {
                // Use default interval
                PollingService.shared.start(interval: 20 * 60)
                print("Started polling with default interval")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showErrorAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Handle URL Schemes (optional)

extension AppDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle any custom URL schemes if needed
        for url in urls {
            print("Opened with URL: \(url)")
        }
    }
}
