import SwiftUI

// MARK: - Main Popover View

/// Primary view displayed in the menu bar popover
struct MainPopoverView: View {
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            if !authVM.isAuthenticated {
                TokenInputView()
            } else {
                // Header
                headerView
                
                Divider()
                
                // Category Tabs
                CategoryTabsView(selectedCategory: $notificationsVM.selectedCategory)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                Divider()
                
                // Notification List
                if notificationsVM.isLoading && notificationsVM.notifications.isEmpty {
                    loadingView
                } else if notificationsVM.filteredNotifications.isEmpty {
                    EmptyStateView(category: notificationsVM.selectedCategory)
                } else {
                    NotificationListView()
                }
                
                Divider()
                
                // Footer
                footerView
            }
        }
        .frame(width: 400, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settingsVM)
                .environmentObject(authVM)
        }
        .onAppear {
            notificationsVM.loadFromDatabase()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text("GitNotify")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Refresh button
            Button(action: {
                Task {
                    await notificationsVM.refresh()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .rotationEffect(.degrees(notificationsVM.isRefreshing ? 360 : 0))
                    .animation(
                        notificationsVM.isRefreshing
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: notificationsVM.isRefreshing
                    )
            }
            .buttonStyle(.plain)
            .disabled(notificationsVM.isRefreshing)
            .help("Refresh notifications")
            
            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading notifications...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // Last updated
            if let lastRefresh = notificationsVM.lastRefreshDate {
                Text("Updated \(lastRefresh, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Mark all as read
            if notificationsVM.hasUnread {
                Button("Mark All as Read") {
                    Task {
                        await notificationsVM.markAllAsRead()
                    }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    MainPopoverView()
        .environmentObject(NotificationsViewModel())
        .environmentObject(SettingsViewModel())
        .environmentObject(AuthViewModel())
}
