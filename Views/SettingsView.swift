import SwiftUI

// MARK: - Settings View

/// Settings panel for app configuration
struct SettingsView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Account Section
                    settingsSection(title: "Account") {
                        accountRow
                    }
                    
                    // Appearance Section
                    settingsSection(title: "Appearance") {
                        appearanceSection
                    }
                    
                    // Polling Section
                    settingsSection(title: "Sync") {
                        pollingSection
                    }
                    
                    // Notifications Section
                    settingsSection(title: "Notifications") {
                        notificationsSection
                    }
                    
                    // General Section
                    settingsSection(title: "General") {
                        generalSection
                    }
                    
                    // About Section
                    settingsSection(title: "About") {
                        aboutSection
                    }
                }
                .padding()
            }
        }
        .frame(width: 400, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .confirmationDialog(
            "Sign Out",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await authVM.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("This will remove your GitHub token and clear all notification data.")
        }
    }
    
    // MARK: - Section Builder
    
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Account Row
    
    private var accountRow: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                if let username = authVM.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Connected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text("GitHub Personal Access Token")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Sign Out") {
                showSignOutConfirmation = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.red)
        }
        .padding()
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Menu Bar Icon")
                        .font(.subheadline)
                    
                    Spacer()
                }
                
                // Icon style picker
                HStack(spacing: 12) {
                    ForEach(MenuBarIconStyle.allCases) { style in
                        IconStyleButton(
                            style: style,
                            isSelected: settingsVM.menuBarIconStyle == style
                        ) {
                            settingsVM.menuBarIconStyle = style
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Polling Section
    
    private var pollingSection: some View {
        VStack(spacing: 0) {
            // Interval slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Refresh Interval")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(settingsVM.pollIntervalFormatted)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
                
                Slider(
                    value: $settingsVM.pollIntervalMinutes,
                    in: Double(AppSettings.minPollInterval)...Double(AppSettings.maxPollInterval),
                    step: 5
                )
                .tint(.accentColor)
                
                HStack {
                    Text("5 min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("60 min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
                .padding(.leading)
            
            // Last synced
            HStack {
                Text("Last Synced")
                    .font(.subheadline)
                
                Spacer()
                
                Text(settingsVM.lastPollFormatted ?? "Never")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Notifications")
                        .font(.subheadline)
                    Text("Show alerts for new notifications")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $settingsVM.notificationsEnabled)
                    .toggleStyle(.switch)
                    .tint(.accentColor)
                    .labelsHidden()
            }
            .padding()
            
            Divider()
                .padding(.leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Menu Bar Badge")
                        .font(.subheadline)
                    Text("Show unread count on icon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $settingsVM.showBadge)
                    .toggleStyle(.switch)
                    .tint(.accentColor)
                    .labelsHidden()
            }
            .padding()
        }
    }
    
    // MARK: - General Section
    
    private var generalSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Launch at Login")
                    .font(.subheadline)
                Text("Start GitNotify when you log in")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $settingsVM.launchAtLogin)
                .toggleStyle(.switch)
                .tint(.accentColor)
                .labelsHidden()
        }
        .padding()
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Version")
                    .font(.subheadline)
                
                Spacer()
                
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
                .padding(.leading)
            
            Button(action: {
                if let url = URL(string: "https://github.com") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack {
                    Text("View on GitHub")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(AuthViewModel())
}

// MARK: - Icon Style Button

struct IconStyleButton: View {
    let style: MenuBarIconStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                        .frame(width: 48, height: 48)
                    
                    if style.isCustomAsset {
                        // For custom assets like GitHub logo
                        Image(style.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(isSelected ? .accentColor : .primary)
                    } else {
                        Image(systemName: style.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isSelected ? .accentColor : .primary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                
                Text(style.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
