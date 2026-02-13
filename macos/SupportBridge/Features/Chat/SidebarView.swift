import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedItem: NavItem
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo/Brand Header
            HStack(spacing: Spacing.sm) {
                SupportBridgeMark(size: 24)
                
                Text("SupportBridge")
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)

                Spacer()

                ConnectionBadge(isConnected: appState.isRealtimeConnected)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appHeaderAligned()
            
            SubtleDivider()

            
            // Navigation Items
            ScrollView {
                VStack(spacing: Spacing.xs) {
                    ForEach(NavItem.allCases, id: \.self) { item in
                        SidebarNavItem(
                            item: item,
                            isSelected: selectedItem == item,
                            badge: badge(for: item)
                        ) {
                            selectedItem = item
                        }
                    }
                }
                .padding(Spacing.sm)
            }
            
            Spacer()
            
            SubtleDivider()

            
            // Agent Profile
            AgentProfileCard(onSettingsTap: { selectedItem = .settings })
                .padding(Spacing.md)
        }
        .background(Color.moltSurface)
    }

    private func badge(for item: NavItem) -> Int? {
        switch item {
        case .inbox:
            let totalUnread = appState.conversations.reduce(0) { $0 + max(0, $1.unreadCount) }
            return totalUnread > 0 ? totalUnread : nil
        case .workspace:
            guard let currentAgentID = appState.currentAgent?.id else { return nil }
            let assigned = appState.conversations.filter {
                $0.assignedAgentId == currentAgentID && ($0.status == .open || $0.status == .pending)
            }
            return assigned.isEmpty ? nil : assigned.count
        case .escalations:
            let pending = appState.escalations.filter { $0.status == .pending || $0.status == .accepted }
            return pending.isEmpty ? nil : pending.count
        case .teamChat:
            let unread = appState.notifications.filter { !$0.isRead }.count
            return unread > 0 ? unread : nil
        default:
            return nil
        }
    }
}

// MARK: - Sidebar Navigation Item
struct SidebarNavItem: View {
    let item: NavItem
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
                    .frame(width: 24)
                
                Text(item.rawValue)
                    .font(.moltBody)
                    .foregroundColor(isSelected ? .moltTextPrimary : .moltTextSecondary)
                
                Spacer()
                
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.moltLabel)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.moltPrimary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.moltPrimaryLight : Color.clear)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Connection Badge
struct ConnectionBadge: View {
    let isConnected: Bool

    private var label: String { isConnected ? "Live" : "Syncing" }
    private var dotColor: Color { isConnected ? .priorityLow : .moltTextMuted }
    private var textColor: Color { isConnected ? .moltTextSecondary : .moltTextMuted }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.moltCaption)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.moltSurfaceSecondary)
        .clipShape(Capsule())
    }
}

// MARK: - Agent Profile Card
struct AgentProfileCard: View {
    @EnvironmentObject var appState: AppState
    let onSettingsTap: () -> Void

    private var agentName: String {
        appState.currentAgent?.name ?? "Agent"
    }

    private var agentEmail: String {
        appState.currentAgent?.email ?? "agent@example.com"
    }

    private var agentInitials: String {
        let parts = agentName.split(separator: " ").filter { !$0.isEmpty }
        let first = parts.first?.first.map(String.init) ?? "A"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    private var statusLabel: String {
        (appState.currentAgent?.status.rawValue ?? "offline").capitalized
    }

    private var statusColor: Color {
        switch appState.currentAgent?.status ?? .offline {
        case .online: return .priorityLow
        case .away: return .priorityMedium
        case .busy: return .priorityHigh
        case .offline: return .moltTextMuted
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar
            Circle()
                .fill(Color.moltPrimary)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(agentInitials)
                        .font(.moltBody)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(agentName)
                    .font(.moltBodySmall)
                    .foregroundColor(.moltTextPrimary)
                    .lineLimit(1)

                Text(agentEmail)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextSecondary)
                }
            }
            
            Spacer()
            
            Menu {
                Button("Settings") { onSettingsTap() }
                SubtleDivider()
                Button("Sign Out") { appState.signOut() }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.moltTextSecondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(Spacing.sm)
        .background(Color.moltSurfaceSecondary)
        .cornerRadius(CornerRadius.medium)
    }
}
