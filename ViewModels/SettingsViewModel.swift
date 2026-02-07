import Foundation
import SwiftUI
import ServiceManagement

// MARK: - Settings ViewModel

/// ViewModel for managing app settings
@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var settings: AppSettings
    @Published private(set) var isSaving = false
    @Published var error: AppError?
    
    /// Flag to prevent saving during initialization
    private var isInitialized = false
    
    // Poll interval as Double for slider binding
    @Published var pollIntervalMinutes: Double {
        didSet {
            guard isInitialized else { return }
            settings.pollIntervalMinutes = Int(pollIntervalMinutes)
            saveSettings()
        }
    }
    
    @Published var showBadge: Bool {
        didSet {
            guard isInitialized else { return }
            settings.showBadge = showBadge
            saveSettings()
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            guard isInitialized else { return }
            settings.notificationsEnabled = notificationsEnabled
            saveSettings()
        }
    }
    
    @Published var launchAtLogin: Bool {
        didSet {
            guard isInitialized else { return }
            settings.launchAtLogin = launchAtLogin
            updateLaunchAtLogin()
            saveSettings()
        }
    }
    
    @Published var menuBarIconStyle: MenuBarIconStyle {
        didSet {
            guard isInitialized else { return }
            settings.menuBarIconStyle = menuBarIconStyle
            saveSettings()
        }
    }
    
    // MARK: - Dependencies
    
    private let databaseManager: DatabaseManager
    private let pollingService: PollingService
    
    // MARK: - Init
    
    init(databaseManager: DatabaseManager = .shared, pollingService: PollingService = .shared) {
        self.databaseManager = databaseManager
        self.pollingService = pollingService
        
        // Start with default settings, load from database asynchronously
        let defaultSettings = AppSettings.default
        self.settings = defaultSettings
        self.pollIntervalMinutes = Double(defaultSettings.pollIntervalMinutes)
        self.showBadge = defaultSettings.showBadge
        self.notificationsEnabled = defaultSettings.notificationsEnabled
        self.launchAtLogin = defaultSettings.launchAtLogin
        self.menuBarIconStyle = defaultSettings.menuBarIconStyle
        
        // Load settings asynchronously after init
        Task {
            await self.loadSettingsAsync()
            self.isInitialized = true
        }
    }
    
    /// Load settings asynchronously from database
    private func loadSettingsAsync() async {
        do {
            let loadedSettings = try await databaseManager.loadSettings()
            self.settings = loadedSettings
            self.pollIntervalMinutes = Double(loadedSettings.pollIntervalMinutes)
            self.showBadge = loadedSettings.showBadge
            self.notificationsEnabled = loadedSettings.notificationsEnabled
            self.launchAtLogin = loadedSettings.launchAtLogin
            self.menuBarIconStyle = loadedSettings.menuBarIconStyle
        } catch {
            // Keep default settings on error
            self.error = AppError(error: error)
        }
    }
    
    // MARK: - Public Methods
    
    /// Reload settings from database
    func loadSettings() {
        Task {
            await loadSettingsAsync()
        }
    }
    
    /// Apply current settings (restart polling with new interval)
    func applySettings() {
        let interval = TimeInterval(settings.pollIntervalMinutes * 60)
        pollingService.updateInterval(interval)
    }
    
    /// Reset settings to defaults
    func resetToDefaults() {
        let defaults = AppSettings.default
        pollIntervalMinutes = Double(defaults.pollIntervalMinutes)
        showBadge = defaults.showBadge
        notificationsEnabled = defaults.notificationsEnabled
        launchAtLogin = defaults.launchAtLogin
        menuBarIconStyle = defaults.menuBarIconStyle
    }
    
    // MARK: - Private Methods
    
    private func saveSettings() {
        Task {
            isSaving = true
            defer { isSaving = false }
            
            do {
                try await databaseManager.saveSettings(settings)
            } catch {
                self.error = AppError(error: error)
            }
        }
    }
    
    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}

// MARK: - Formatted Values

extension SettingsViewModel {
    var pollIntervalFormatted: String {
        let minutes = Int(pollIntervalMinutes)
        if minutes == 1 {
            return "1 minute"
        } else if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }
    
    var lastPollFormatted: String? {
        guard let lastPoll = settings.lastPollDate else {
            return nil
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastPoll, relativeTo: Date())
    }
}
