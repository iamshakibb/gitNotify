import SwiftUI

// MARK: - Empty State View

/// Shown when there are no notifications
struct EmptyStateView: View {
    let category: NotificationCategory
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
    
    private var icon: String {
        switch category {
        case .all:
            return "bell.slash"
        case .mentioned:
            return "at.badge.minus"
        case .assignedTask:
            return "person.badge.minus"
        case .comments:
            return "bubble.left.and.bubble.right"
        }
    }
    
    private var title: String {
        switch category {
        case .all:
            return "All Caught Up!"
        case .mentioned:
            return "No Mentions"
        case .assignedTask:
            return "No Assignments"
        case .comments:
            return "No Comments"
        }
    }
    
    private var subtitle: String {
        switch category {
        case .all:
            return "You have no unread notifications.\nEnjoy your peace of mind."
        case .mentioned:
            return "No one has @mentioned you recently.\nYour inbox is clear."
        case .assignedTask:
            return "No issues or PRs assigned to you.\nNo pending reviews."
        case .comments:
            return "No comments or activity\non your issues and PRs."
        }
    }
}

// MARK: - Preview

#Preview("Empty - All") {
    EmptyStateView(category: .all)
        .frame(width: 400, height: 300)
}

#Preview("Empty - Mentioned") {
    EmptyStateView(category: .mentioned)
        .frame(width: 400, height: 300)
}

#Preview("Empty - Assigned") {
    EmptyStateView(category: .assignedTask)
        .frame(width: 400, height: 300)
}

#Preview("Empty - Comments") {
    EmptyStateView(category: .comments)
        .frame(width: 400, height: 300)
}
