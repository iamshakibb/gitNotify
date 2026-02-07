import SwiftUI

// MARK: - Category Tabs View

/// Segmented picker for notification categories
struct CategoryTabsView: View {
    @Binding var selectedCategory: NotificationCategory
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(NotificationCategory.allCases) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category,
                        unreadCount: notificationsVM.unreadCountByCategory[category] ?? 0
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(4)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: NotificationCategory
    let isSelected: Bool
    let unreadCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.system(size: 11, weight: .medium))
                
                Text(category.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.accentColor)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.rawValue) notifications, \(unreadCount) unread")
    }
}

// MARK: - Preview

#Preview {
    CategoryTabsView(selectedCategory: .constant(.all))
        .environmentObject(NotificationsViewModel())
        .padding()
        .frame(width: 400)
}
