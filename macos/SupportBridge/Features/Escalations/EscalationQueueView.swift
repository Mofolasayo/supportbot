import SwiftUI

struct EscalationQueueView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedNavItem: NavItem
    @State private var selectedFilter: EscalationFilter = .all
    @State private var selectedEscalation: Escalation?
    @State private var forwardEscalation: Escalation?

    private var escalationsSource: [Escalation] {
        if appState.isAuthenticated {
            return appState.escalations
        }
        return Escalation.mockList
    }
    
    var filteredEscalations: [Escalation] {
        switch selectedFilter {
        case .all: return escalationsSource
        case .pending: return escalationsSource.filter { $0.status == .pending }
        case .accepted: return escalationsSource.filter { $0.status == .accepted }
        case .urgent: return escalationsSource.filter { $0.priority == .urgent }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Escalation List
            VStack(spacing: 0) {
                // Header
                VStack(spacing: Spacing.md) {
                    HStack {
                        Text("Escalations")
                            .font(.moltTitleMedium)
                            .foregroundColor(.moltTextPrimary)
                        
                        Spacer()
                        
                        Text("\(filteredEscalations.count)")
                            .font(.moltCaption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.priorityHigh)
                            .cornerRadius(CornerRadius.small)
                    }
                    
                    // Filter Pills
                    HStack(spacing: Spacing.sm) {
                        ForEach(EscalationFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                label: filter.label,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                        Spacer()
                    }
                }
                .appHeaderAligned()
                .background(Color.moltSurface)
                
                SubtleDivider()
    
                
                // List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredEscalations) { escalation in
                            EscalationCard(
                                escalation: escalation,
                                isSelected: selectedEscalation?.id == escalation.id,
                                onTakeOwnership: { takeOwnership(escalation) },
                                onForward: { forwardToTeam(escalation) }
                            )
                            .onTapGesture {
                                selectedEscalation = escalation
                            }
                            
                            SubtleDivider()
                
                        }
                    }
                }
                .background(Color.moltSurface)
            }
            .frame(minWidth: 400)
            
            SubtleVerticalDivider()
            
            // Detail Panel
            if let escalation = selectedEscalation {
                EscalationDetailPanel(escalation: escalation)
            } else {
                EmptyStateView(
                    icon: "arrow.up.circle",
                    title: "Select an Escalation",
                    message: "Choose an escalation from the list to view details"
                )
            }
        }
        .background(Color.moltBackground)
        .sheet(item: $forwardEscalation) { escalation in
            if let conversation = appState.conversations.first(where: { $0.id == escalation.conversationId }) ??
                Conversation.mockList.first(where: { $0.id == escalation.conversationId }) {
                ForwardToTeamSheet(
                    conversation: conversation,
                    teams: (appState.teams.isEmpty ? Team.mockList : appState.teams).filter { $0.id != "team-1" }
                )
            }
        }
        .task {
            await appState.refreshEscalations()
            await appState.refreshTeams()
        }
    }
    
    func takeOwnership(_ escalation: Escalation) {
        _Concurrency.Task {
            do {
                try await appState.acceptEscalation(id: escalation.id)
            } catch {
                print("Failed to accept escalation: \(error)")
            }
            openConversation(escalation, takeOwnership: true)
        }
    }
    
    func forwardToTeam(_ escalation: Escalation) {
        forwardEscalation = escalation
    }

    func openConversation(_ escalation: Escalation, takeOwnership: Bool) {
        guard let agent = appState.currentAgent else { return }

        if let idx = appState.conversations.firstIndex(where: { $0.id == escalation.conversationId }) {
            var updated = appState.conversations[idx]
            if takeOwnership {
                updated.assignedAgentId = agent.id
                updated.handledBy = .agent
                appState.conversations[idx] = updated
            }
            appState.selectedConversation = updated
        } else {
            _Concurrency.Task {
                await appState.refreshConversations()
                if let refreshed = appState.conversations.first(where: { $0.id == escalation.conversationId }) {
                    await MainActor.run { appState.selectedConversation = refreshed }
                }
            }
        }

        selectedNavItem = .inbox
    }
}

// MARK: - Escalation Filter
enum EscalationFilter: CaseIterable {
    case all, pending, accepted, urgent
    
    var label: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .urgent: return "Urgent"
        }
    }
}

// MARK: - Escalation Card
struct EscalationCard: View {
    let escalation: Escalation
    let isSelected: Bool
    let onTakeOwnership: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header Row
            HStack {
                // Priority Badge
                PriorityBadge(priority: escalation.priority)
                
                Spacer()
                
                // Time
                Text(timeAgo(escalation.createdAt))
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                
                // Status
                EscalationStatusBadge(status: escalation.status)
            }
            
            // Reason
            Text(escalation.reason)
                .font(.moltBody)
                .fontWeight(.medium)
                .foregroundColor(.moltTextPrimary)
                .lineLimit(2)
            
            // AI Summary
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.moltPrimary)
                
                Text(escalation.aiSummary)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
                    .lineLimit(3)
            }
            .padding(Spacing.sm)
            .background(Color.bubbleBot)
            .cornerRadius(CornerRadius.medium)
            
            // Actions
            HStack(spacing: Spacing.md) {
                Button(action: onTakeOwnership) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 12))
                        Text("Take Ownership")
                            .font(.moltLabel)
                    }
                    .foregroundColor(.moltPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.moltPrimaryLight)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                
                Button(action: onForward) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                        Text("Forward to Team")
                            .font(.moltLabel)
                    }
                    .foregroundColor(.moltTextSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding(Spacing.lg)
        .background(isSelected ? Color.moltPrimaryLight.opacity(0.5) : Color.clear)
        .contentShape(Rectangle())
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Escalation Detail Panel
struct EscalationDetailPanel: View {
    let escalation: Escalation
    @State private var internalNote = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Escalation Details")
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    Text("ID: \(escalation.id)")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                Spacer()
                PriorityBadge(priority: escalation.priority)
            }
            .appHeaderAligned()
            .background(Color.moltSurface)
            
            SubtleDivider()

            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Reason Section
                    DetailSection(title: "Escalation Reason") {
                        Text(escalation.reason)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                    }
                    
                    // AI Summary Section
                    DetailSection(title: "AI Summary") {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.moltPrimary)
                            Text(escalation.aiSummary)
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                        }
                    }
                    
                    // Status Timeline
                    DetailSection(title: "Timeline") {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            TimelineItem(
                                title: "Escalated",
                                time: escalation.createdAt,
                                icon: "arrow.up.circle.fill",
                                isComplete: true
                            )
                            
                            if let acceptedAt = escalation.acceptedAt {
                                TimelineItem(
                                    title: "Accepted",
                                    time: acceptedAt,
                                    icon: "checkmark.circle.fill",
                                    isComplete: true
                                )
                            }
                            
                            TimelineItem(
                                title: "Resolved",
                                time: nil,
                                icon: "checkmark.seal.fill",
                                isComplete: escalation.status == .completed
                            )
                        }
                    }
                    
                    // Internal Notes Section
                    DetailSection(title: "Add Internal Note") {
                        VStack(spacing: Spacing.sm) {
                            TextEditor(text: $internalNote)
                                .scrollContentBackground(.hidden)
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                                .tint(.moltTextPrimary)
                                .frame(height: 80)
                                .padding(Spacing.sm)
                                .background(Color.moltSurfaceSecondary)
                                .cornerRadius(CornerRadius.medium)
                            
                            HStack {
                                Spacer()
                                Button(action: {}) {
                                    Text("Add Note")
                                        .font(.moltLabel)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, Spacing.lg)
                                        .padding(.vertical, Spacing.sm)
                                        .background(Color.moltPrimary)
                                        .cornerRadius(CornerRadius.medium)
                                }
                                .buttonStyle(.plain)
                                .disabled(internalNote.isEmpty)
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.moltBackground)
        }
        .frame(minWidth: 350)
    }
}

// MARK: - Supporting Views
struct PriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.moltLabel)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
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

struct EscalationStatusBadge: View {
    let status: Escalation.EscalationStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.moltLabel)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(CornerRadius.small)
    }
    
    var color: Color {
        switch status {
        case .pending: return .priorityHigh
        case .accepted: return .moltPrimary
        case .completed: return .priorityLow
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.moltLabel)
                .foregroundColor(.moltTextMuted)
            
            content
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.moltSurface)
                .cornerRadius(CornerRadius.medium)
        }
    }
}

struct TimelineItem: View {
    let title: String
    let time: Date?
    let icon: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(isComplete ? .priorityLow : .moltTextMuted)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                if let time = time {
                    Text(formatDate(time))
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                } else {
                    Text("Pending")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.moltTextMuted)
            
            Text(title)
                .font(.moltTitleSmall)
                .foregroundColor(.moltTextPrimary)
            
            Text(message)
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
}
