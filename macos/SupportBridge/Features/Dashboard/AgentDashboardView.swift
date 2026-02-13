import SwiftUI

struct AgentDashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var myActiveChats: Int {
        appState.conversations.filter { conv in
            conv.assignedAgentId == appState.currentAgent?.id && conv.status != .resolved
        }.count
    }
    
    var resolvedToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return appState.conversations.filter { conv in
            conv.assignedAgentId == appState.currentAgent?.id &&
            conv.status == .resolved &&
            (conv.lastMessageAt ?? Date.distantPast) >= today
        }.count
    }
    
    var myTasks: Int {
        appState.tasks.filter { $0.assignedTo == appState.currentAgent?.id && $0.status != .completed }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Welcome back, \(appState.currentAgent?.name ?? "Agent")!")
                        .font(.moltTitleLarge)
                        .foregroundColor(.moltTextPrimary)
                    
                    Text("Here's your performance today")
                        .font(.moltBody)
                        .foregroundColor(.moltTextMuted)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                    StatCard(title: "Active Chats", value: "\(myActiveChats)", icon: "bubble.left.fill", color: .moltPrimary)
                    StatCard(title: "Resolved Today", value: "\(resolvedToday)", icon: "checkmark.circle.fill", color: .priorityLow)
                    StatCard(title: "My Tasks", value: "\(myTasks)", icon: "checklist", color: .priorityMedium)
                }
                .padding(.horizontal, Spacing.lg)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Quick Actions")
                        .font(.moltTitleSmall)
                        .foregroundColor(.moltTextPrimary)
                    
                    HStack(spacing: Spacing.md) {
                        QuickActionButton(title: "New Task", icon: "plus.circle.fill", color: .moltPrimary)
                        QuickActionButton(title: "View Queue", icon: "tray.fill", color: .priorityMedium)
                        QuickActionButton(title: "Knowledge Base", icon: "book.fill", color: .priorityHigh)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Recent Activity")
                        .font(.moltTitleSmall)
                        .foregroundColor(.moltTextPrimary)
                    
                    ActivityFeed()
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, Spacing.xl)
        }
        .background(Color.moltBackground)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.moltTextPrimary)
            
            Text(title)
                .font(.moltBody)
                .foregroundColor(.moltTextMuted)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.moltBody)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(color)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Feed
struct ActivityFeed: View {
    let activities = [
        ("Resolved chat with Mrs. Ibrahim", "5m ago", "checkmark.circle.fill", Color.priorityLow),
        ("Created task: Follow up payment", "12m ago", "plus.circle.fill", Color.moltPrimary),
        ("Assigned to Finance team", "1h ago", "person.badge.plus.fill", Color.priorityMedium),
        ("Posted in Team Chat", "2h ago", "bubble.left.fill", Color.priorityHigh)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(activities.indices, id: \.self) { index in
                let activity = activities[index]
                HStack(spacing: Spacing.md) {
                    Image(systemName: activity.2)
                        .foregroundColor(activity.3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.0)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                        Text(activity.1)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                    
                    Spacer()
                }
                .padding(Spacing.md)
                
                if index < activities.count - 1 {
                    SubtleDivider()
                }
            }
        }
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
    }
}
