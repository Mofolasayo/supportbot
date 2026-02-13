import SwiftUI

// MARK: - Agent Queue View (My Queue)
struct AgentQueueView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedNavItem: NavItem
    @State private var showAssignmentSheet = false
    @State private var selectedItem: QueueItem?

    private var myQueue: [QueueItem] {
        appState.queueAssigned.map { QueueItem(conversation: $0) }
    }

    private var unassignedQueue: [QueueItem] {
        appState.queueUnassigned.map { QueueItem(conversation: $0) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Workload
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Queue")
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    Text("\(myQueue.count) active conversations")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                
                Spacer()
                
                // Current workload
                WorkloadIndicator(current: myQueue.count, max: 8)
            }
            .appHeaderAligned()
            
            SubtleDivider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // My Active Queue
                    if !myQueue.isEmpty {
                        QueueSection(title: "My Queue", items: myQueue) { item in
                            openConversation(item, takeOwnership: false)
                        }
                    }
                    
                    // Unassigned (for taking ownership)
                    if !unassignedQueue.isEmpty {
                        SubtleDivider()
                            .padding(.vertical, Spacing.sm)
                        
                        QueueSection(title: "Unassigned", items: unassignedQueue, showTakeButton: true) { item in
                            openConversation(item, takeOwnership: true)
                        }
                    }
                    
                    // Team workload overview
                    SubtleDivider()
                        .padding(.vertical, Spacing.sm)
                    
                    TeamWorkloadSection()
                }
                .padding(Spacing.lg)
            }
        }
        .background(Color.moltBackground)
        .sheet(item: $selectedItem) { item in
            QueueItemDetailSheet(item: item, isPresented: .constant(true))
        }
        .task {
            await appState.refreshQueue()
        }
    }
    
    func openConversation(_ item: QueueItem, takeOwnership: Bool) {
        if takeOwnership {
            _Concurrency.Task {
                do {
                    try await appState.takeQueueOwnership(conversationId: item.conversationId)
                } catch {
                    print("Failed to take ownership: \(error)")
                }
                selectConversation(item)
            }
        } else {
            selectConversation(item)
        }

        selectedNavItem = .inbox
    }

    private func selectConversation(_ item: QueueItem) {
        if let conversation = appState.conversations.first(where: { $0.id == item.conversationId }) {
            appState.selectedConversation = conversation
        } else {
            _Concurrency.Task {
                await appState.refreshConversations()
                if let refreshed = appState.conversations.first(where: { $0.id == item.conversationId }) {
                    await MainActor.run {
                        appState.selectedConversation = refreshed
                    }
                }
            }
        }
    }
}

// MARK: - Workload Indicator
struct WorkloadIndicator: View {
    let current: Int
    let max: Int
    
    var percentage: Double {
        Double(current) / Double(max)
    }
    
    var color: Color {
        if percentage >= 0.85 { return .priorityUrgent }
        if percentage >= 0.6 { return .priorityMedium }
        return .priorityLow
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(current)/\(max)")
                .font(.moltLabel)
                .foregroundColor(color)
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.moltSurfaceSecondary)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * percentage, height: 6)
                }
            }
            .frame(width: 100, height: 6)
        }
    }
}

// MARK: - Queue Section
struct QueueSection: View {
    let title: String
    let items: [QueueItem]
    var showTakeButton: Bool = false
    let onSelect: (QueueItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(.moltLabel)
                    .foregroundColor(.moltTextSecondary)
                
                Text("\(items.count)")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(10)
            }
            
            ForEach(items) { item in
                QueueItemCard(item: item, showTakeButton: showTakeButton, onSelect: onSelect)
            }
        }
    }
}

// MARK: - Queue Item Card
struct QueueItemCard: View {
    let item: QueueItem
    var showTakeButton: Bool = false
    let onSelect: (QueueItem) -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Priority indicator
            Rectangle()
                .fill(priorityColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.parentName)
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.moltTextPrimary)
                    
                    QueuePriorityBadge(priority: item.priority)
                    
                    Spacer()
                    
                    // Waiting time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(item.waitingTimeFormatted)
                    }
                    .font(.moltCaption)
                    .foregroundColor(waitingTimeColor)
                }
                
                Text(item.preview)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
                    .lineLimit(1)
            }
            
            if showTakeButton {
                Button(action: { onSelect(item) }) {
                    Text("Take")
                        .font(.moltCaption)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.moltPrimary)
                        .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { onSelect(item) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.moltTextMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.md)
        .background(isHovered ? Color.moltSurfaceSecondary : Color.moltSurface)
        .cornerRadius(CornerRadius.medium)
        .contentShape(Rectangle())
        .onTapGesture {
            if !showTakeButton {
                onSelect(item)
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    var priorityColor: Color {
        switch item.priority {
        case .urgent: return .priorityUrgent
        case .high: return .priorityHigh
        case .medium: return .priorityMedium
        case .low: return .priorityLow
        }
    }
    
    var waitingTimeColor: Color {
        if item.waitingTime > 3600 { return .priorityUrgent }
        if item.waitingTime > 1800 { return .priorityHigh }
        return .moltTextMuted
    }
}

// MARK: - Queue Priority Badge (renamed to avoid conflict)
struct QueuePriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(CornerRadius.small)
    }
    
    var color: Color {
        switch priority {
        case .urgent: return .priorityUrgent
        case .high: return .priorityHigh
        case .medium: return .priorityMedium
        case .low: return .priorityLow
        }
    }
}

// MARK: - Team Workload Section
struct TeamWorkloadSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Team Workload")
                    .font(.moltLabel)
                    .foregroundColor(.moltTextSecondary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Auto-Assign")
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }
            
            ForEach(AgentWithWorkload.mockList) { agent in
                AgentWorkloadRow(agent: agent)
            }
            
            // Recommendation
            if let leastBusy = AgentWithWorkload.leastBusyAgent() {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.priorityMedium)
                    Text("Recommended: \(leastBusy.name) has the lowest workload")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextSecondary)
                }
                .padding(Spacing.sm)
                .background(Color.priorityMedium.opacity(0.1))
                .cornerRadius(CornerRadius.medium)
            }
        }
    }
}

// MARK: - Agent Workload Row
struct AgentWorkloadRow: View {
    let agent: AgentWithWorkload
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Avatar
            Circle()
                .fill(Color.moltSurfaceSecondary)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(agent.avatarInitial)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextSecondary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(agent.name)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                Text(agent.status.rawValue.capitalized)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            
            Spacer()
            
            // Workload bar
            HStack(spacing: 4) {
                Text("\(agent.activeConversations)/\(agent.maxCapacity)")
                    .font(.moltCaption)
                    .foregroundColor(workloadColor)
                
                // Mini progress bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.moltSurfaceSecondary)
                        .frame(width: 60, height: 4)
                    
                    Capsule()
                        .fill(workloadColor)
                        .frame(width: 60 * agent.workloadPercentage, height: 4)
                }
            }
        }
        .padding(Spacing.sm)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.medium)
    }
    
    var statusColor: Color {
        switch agent.status {
        case .online: return .priorityLow
        case .away: return .priorityMedium
        case .busy: return .priorityHigh
        case .offline: return .moltTextMuted
        }
    }
    
    var workloadColor: Color {
        if agent.workloadPercentage >= 0.85 { return .priorityUrgent }
        if agent.workloadPercentage >= 0.6 { return .priorityMedium }
        return .priorityLow
    }
}

// MARK: - Queue Item Detail Sheet
struct QueueItemDetailSheet: View {
    let item: QueueItem
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Queue Item Details")
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.moltTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text(item.parentName)
                        .font(.moltTitleSmall)
                        .foregroundColor(.moltTextPrimary)
                    QueuePriorityBadge(priority: item.priority)
                }
                
                Text(item.preview)
                    .font(.moltBody)
                    .foregroundColor(.moltTextSecondary)
                
                HStack {
                    Text("Waiting: \(item.waitingTimeFormatted)")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Text("Open Conversation")
                        .font(.moltBody)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.moltPrimary)
                        .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
        }
        .frame(width: 400, height: 300)
        .background(Color.moltBackground)
    }
}
