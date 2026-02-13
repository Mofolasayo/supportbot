import SwiftUI

// Add AppNotification model to Models.swift first
struct NotificationCenterView: View {
    @EnvironmentObject var appState: AppState
    @State private var filterType: NotificationFilterType = .all
    
    var filteredNotifications: [AppNotification] {
        let source = appState.notifications
        switch filterType {
        case .all:
            return source
        case .messages:
            return source.filter { $0.type.lowercased().contains("message") }
        case .tasks:
            return source.filter { $0.type.lowercased().contains("task") }
        case .mentions:
            return source.filter { $0.type.lowercased().contains("mention") }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.moltTitleLarge)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button("Mark All Read") {
                    Task { await appState.markAllNotificationsRead() }
                }
                .buttonStyle(.plain)
                .foregroundColor(.moltPrimary)
                .font(.moltBody)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(NotificationFilterType.allCases, id: \.self) { type in
                        FilterChipView(
                            title: type.rawValue,
                            isSelected: filterType == type,
                            action: { filterType = type }
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Notifications List
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(filteredNotifications) { notification in
                        NotificationRow(notification: notification) {
                            Task { await appState.markNotificationRead(id: notification.id) }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.moltBackground)
        }
        .background(Color.moltSurface)
        .task {
            await appState.refreshNotifications()
        }
    }
}

enum NotificationFilterType: String, CaseIterable {
    case all = "All"
    case messages = "Messages"
    case tasks = "Tasks"
    case mentions = "Mentions"
}

struct FilterChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.moltLabel)
                .foregroundColor(isSelected ? .white : .moltTextSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 6)
                .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onSelect: () -> Void

    private var icon: String {
        let type = notification.type.lowercased()
        if type.contains("message") { return "bubble.left.fill" }
        if type.contains("task") { return "checkmark.circle.fill" }
        if type.contains("mention") { return "at" }
        return "bell.fill"
    }

    private var color: Color {
        let type = notification.type.lowercased()
        if type.contains("message") { return .moltPrimary }
        if type.contains("task") { return .priorityMedium }
        if type.contains("mention") { return .priorityHigh }
        return .moltTextMuted
    }

    private var timeLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.moltBody)
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .foregroundColor(.moltTextPrimary)
                    
                    Text(notification.message)
                        .font(.moltBody)
                        .foregroundColor(.moltTextMuted)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(timeLabel)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                    
                    if !notification.isRead {
                        Circle()
                            .fill(Color.moltPrimary)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(Spacing.md)
            .background(notification.isRead ? Color.clear : Color.moltSurface)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}
