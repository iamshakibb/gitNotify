import Foundation
import Combine

// MARK: - Polling Service

/// Manages background polling for GitHub notifications
final class PollingService: ObservableObject, @unchecked Sendable {
    static let shared = PollingService()
    
    @Published private(set) var isPolling = false
    @Published private(set) var lastPollDate: Date?
    @Published private(set) var nextPollDate: Date?
    @Published private(set) var lastError: Error?
    
    private var timer: Timer?
    private var pollInterval: TimeInterval = 20 * 60 // Default 20 minutes
    
    /// Callback when polling completes with new notifications
    var onNewNotifications: (([GitHubNotification]) -> Void)?
    
    /// Callback when poll completes (success or failure)
    var onPollComplete: ((Result<Int, Error>) -> Void)?
    
    private init() {}
    
    // MARK: - Control
    
    /// Start polling with the specified interval
    /// - Parameter interval: Poll interval in seconds
    func start(interval: TimeInterval) {
        stop()
        
        pollInterval = interval
        isPolling = true
        
        // Schedule first poll immediately
        Task {
            await poll()
        }
        
        // Schedule recurring polls
        scheduleNextPoll()
    }
    
    /// Stop polling
    func stop() {
        timer?.invalidate()
        timer = nil
        isPolling = false
        nextPollDate = nil
    }
    
    /// Update the polling interval
    /// - Parameter interval: New interval in seconds
    func updateInterval(_ interval: TimeInterval) {
        pollInterval = interval
        
        if isPolling {
            // Reschedule with new interval
            timer?.invalidate()
            scheduleNextPoll()
        }
    }
    
    /// Manually trigger a poll
    func pollNow() async {
        await poll()
        
        // Reschedule next poll
        if isPolling {
            timer?.invalidate()
            scheduleNextPoll()
        }
    }
    
    // MARK: - Private
    
    private func scheduleNextPoll() {
        nextPollDate = Date().addingTimeInterval(pollInterval)
        
        let newTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.poll()
            }
        }
        timer = newTimer
        
        // Allow timer to fire even when UI is busy
        RunLoop.main.add(newTimer, forMode: .common)
    }
    
    private func poll() async {
        guard let token = KeychainManager.shared.getGitHubToken() else {
            await MainActor.run {
                lastError = PollingError.noToken
            }
            onPollComplete?(.failure(PollingError.noToken))
            return
        }
        
        await MainActor.run {
            lastError = nil
        }
        
        let databaseManager = DatabaseManager.shared
        let apiService = GitHubAPIService.shared
        
        do {
            // Load settings for Last-Modified header
            let settings = try await databaseManager.loadSettings()
            await apiService.setLastModified(settings.lastModifiedHeader)
            
            // Fetch notifications
            let result = try await apiService.fetchNotifications(
                token: token,
                all: false,
                useLastModified: true
            )
            
            await MainActor.run {
                lastPollDate = Date()
            }
            
            // If not modified, nothing new
            if result.notModified {
                onPollComplete?(.success(0))
                return
            }
            
            // Get existing notification IDs
            let existingIds = try await databaseManager.getNotificationIds()
            
            // Find new notifications
            let newNotifications = result.notifications.filter { !existingIds.contains($0.id) }
            
            // Save to database
            try await databaseManager.upsertNotifications(result.notifications)
            
            // Update Last-Modified in settings
            var updatedSettings = settings
            updatedSettings.lastPollDate = await MainActor.run { lastPollDate }
            try await databaseManager.saveSettings(updatedSettings)
            
            // Notify about new notifications
            if !newNotifications.isEmpty {
                onNewNotifications?(newNotifications)
            }
            
            // Update poll interval if GitHub suggests a different one
            if let suggestedInterval = result.pollInterval {
                let newInterval = TimeInterval(suggestedInterval)
                if newInterval > pollInterval {
                    await MainActor.run {
                        updateInterval(newInterval)
                    }
                }
            }
            
            onPollComplete?(.success(newNotifications.count))
            
        } catch {
            await MainActor.run {
                lastError = error
            }
            onPollComplete?(.failure(error))
            print("Polling failed: \(error)")
        }
        
        // Update next poll date
        await MainActor.run {
            nextPollDate = Date().addingTimeInterval(pollInterval)
        }
    }
}

// MARK: - Polling Errors

enum PollingError: LocalizedError {
    case noToken
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No GitHub token configured."
        case .networkUnavailable:
            return "Network is unavailable."
        }
    }
}
