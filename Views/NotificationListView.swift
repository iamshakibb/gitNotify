import SwiftUI

// MARK: - Notification List View

/// Scrollable list of notifications
struct NotificationListView: View {
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(notificationsVM.filteredNotifications) { notification in
                    // Use enhanced layout for Assigned tab
                    if notificationsVM.selectedCategory == .assignedTask {
                        AssignedTaskRowView(notification: notification)
                    } else {
                        NotificationRowView(notification: notification)
                    }
                    
                    if notification.id != notificationsVM.filteredNotifications.last?.id {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Notification Row View

/// Single notification row
struct NotificationRowView: View {
    let notification: GitHubNotification
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Type icon
            typeIcon
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Repository name
                Text(notification.repositoryFullName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Title
                Text(notification.subjectTitle)
                    .font(.system(size: 13, weight: notification.unread ? .semibold : .regular))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Meta info
                HStack(spacing: 8) {
                    // Reason badge
                    Text(notification.reason.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(reasonColor.opacity(0.15))
                        .foregroundColor(reasonColor)
                        .cornerRadius(4)
                    
                    // Time
                    Text(notification.timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 8) {
                // Unread indicator
                if notification.unread {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                // Open in browser button
                if isHovered {
                    Button(action: {
                        notificationsVM.openInBrowser(notification)
                    }) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open in browser")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            notificationsVM.openInBrowser(notification)
        }
        .contextMenu {
            Button("Open in Browser") {
                notificationsVM.openInBrowser(notification)
            }
            
            Button("Mark as Read") {
                Task {
                    await notificationsVM.markAsRead(notification)
                }
            }
            .disabled(!notification.unread)
            
            Divider()
            
            Button("Copy Link") {
                if let url = notification.htmlURL {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double-click to open in browser")
    }
    
    // MARK: - Type Icon
    
    private var typeIcon: some View {
        ZStack {
            Circle()
                .fill(typeColor.opacity(0.15))
                .frame(width: 32, height: 32)
            
            Image(systemName: notification.subjectType.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(typeColor)
        }
    }
    
    // MARK: - Colors
    
    private var typeColor: Color {
        switch notification.subjectType {
        case .issue:
            return .green
        case .pullRequest:
            return .purple
        case .commit:
            return .orange
        case .release:
            return .blue
        case .discussion:
            return .cyan
        case .repositoryVulnerabilityAlert:
            return .red
        case .checkSuite:
            return .yellow
        case .unknown:
            return .gray
        }
    }
    
    private var reasonColor: Color {
        switch notification.reason {
        case .mention, .teamMention:
            return .orange
        case .reviewRequested:
            return .purple
        case .assign:
            return .blue
        case .comment:
            return .green
        case .securityAlert:
            return .red
        case .ciActivity:
            return .yellow
        default:
            return .secondary
        }
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        let unreadStatus = notification.unread ? "Unread" : "Read"
        return "\(unreadStatus) \(notification.subjectType.displayName): \(notification.subjectTitle) in \(notification.repositoryFullName), \(notification.reason.displayName), \(notification.timeAgo)"
    }
}

// MARK: - Assigned Task Row View

/// Enhanced row view for assigned tasks with project emphasis
struct AssignedTaskRowView: View {
    let notification: GitHubNotification
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Project header with avatar (emphasized)
            HStack(spacing: 8) {
                // Repository avatar
                if let avatarURLString = notification.repositoryOwnerAvatarURL,
                   let avatarURL = URL(string: avatarURLString) {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "building.2.crop.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
                
                // Repository name (prominent)
                Text(notification.repositoryFullName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Unread indicator
                if notification.unread {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Assignment type badge row
            HStack(spacing: 8) {
                // Reason badge (colorful and prominent)
                HStack(spacing: 4) {
                    Image(systemName: reasonIcon)
                        .font(.system(size: 10, weight: .bold))
                    Text(notification.reason.displayName)
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(reasonColor)
                .foregroundColor(.white)
                .cornerRadius(6)
                
                // Subject type badge
                HStack(spacing: 4) {
                    Image(systemName: notification.subjectType.icon)
                        .font(.system(size: 10))
                    Text(notification.subjectType.displayName)
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .foregroundColor(.secondary)
                .cornerRadius(4)
                
                Spacer()
                
                // Time
                Text(notification.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Subject title
            Text(notification.subjectTitle)
                .font(.system(size: 13, weight: notification.unread ? .medium : .regular))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .background(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            notificationsVM.openInBrowser(notification)
        }
        .contextMenu {
            Button("Open in Browser") {
                notificationsVM.openInBrowser(notification)
            }
            
            Button("Mark as Read") {
                Task {
                    await notificationsVM.markAsRead(notification)
                }
            }
            .disabled(!notification.unread)
            
            Divider()
            
            Button("Copy Link") {
                if let url = notification.htmlURL {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double-click to open in browser")
    }
    
    // MARK: - Reason Properties
    
    private var reasonIcon: String {
        switch notification.reason {
        case .assign:
            return "person.fill.checkmark"
        case .reviewRequested:
            return "eye.fill"
        case .approvalRequested:
            return "checkmark.seal.fill"
        default:
            return "bell.fill"
        }
    }
    
    private var reasonColor: Color {
        switch notification.reason {
        case .assign:
            return .blue
        case .reviewRequested:
            return .purple
        case .approvalRequested:
            return .orange
        default:
            return .gray
        }
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        let unreadStatus = notification.unread ? "Unread" : "Read"
        return "\(unreadStatus) \(notification.reason.displayName) for \(notification.subjectType.displayName): \(notification.subjectTitle) in \(notification.repositoryFullName), \(notification.timeAgo)"
    }
}

// MARK: - Preview

#Preview {
    let notification = GitHubNotification(
        id: "1",
        repositoryFullName: "owner/repo",
        repositoryOwnerAvatarURL: nil,
        subjectTitle: "Fix critical bug in authentication flow",
        subjectType: .pullRequest,
        subjectURL: "https://api.github.com/repos/owner/repo/pulls/123",
        reason: .reviewRequested,
        unread: true,
        updatedAt: Date().addingTimeInterval(-3600),
        lastReadAt: nil
    )
    
    NotificationRowView(notification: notification)
        .environmentObject(NotificationsViewModel())
        .frame(width: 400)
}
