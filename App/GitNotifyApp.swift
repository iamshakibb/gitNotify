import SwiftUI

// MARK: - App Entry Point

@main
struct GitNotifyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var notificationsVM = NotificationsViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var authVM = AuthViewModel()
    
    var body: some Scene {
        // Menu Bar Extra (macOS 13+)
        MenuBarExtra {
            MainPopoverView()
                .environmentObject(notificationsVM)
                .environmentObject(settingsVM)
                .environmentObject(authVM)
        } label: {
            MenuBarLabel(
                hasUnread: notificationsVM.hasUnread,
                unreadCount: notificationsVM.unreadCount,
                showBadge: settingsVM.showBadge,
                iconStyle: settingsVM.menuBarIconStyle
            )
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Label

struct MenuBarLabel: View {
    let hasUnread: Bool
    let unreadCount: Int
    let showBadge: Bool
    let iconStyle: MenuBarIconStyle
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if iconStyle.isCustomAsset {
                // Custom asset (e.g., GitHub logo)
                Image(iconStyle.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            } else {
                // SF Symbol
                Image(systemName: hasUnread ? iconStyle.unreadIconName : iconStyle.iconName)
                    .symbolRenderingMode(.hierarchical)
            }
            
            // Badge overlay
            if hasUnread && showBadge && unreadCount > 0 {
                Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .offset(x: 8, y: -4)
            }
        }
        .accessibilityLabel("GitNotify: \(unreadCount) unread notifications")
    }
}
