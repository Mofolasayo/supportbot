import SwiftUI

struct ConversationListView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedFilter: ConversationFilter = .all
    @Binding var isInSelectionMode: Bool
    @Binding var selectedIds: Set<String>
    
    init(isInSelectionMode: Binding<Bool> = .constant(false), selectedIds: Binding<Set<String>> = .constant([])) {
        self._isInSelectionMode = isInSelectionMode
        self._selectedIds = selectedIds
    }
    
    var filteredConversations: [Conversation] {
        var result = appState.conversations
        
        // Apply status filter
        switch selectedFilter {
        case .all: break
        case .open: result = result.filter { $0.status == .open }
        case .pending: result = result.filter { $0.status == .pending }
        case .resolved: result = result.filter { $0.status == .resolved }
        case .bot: result = result.filter { $0.handledBy == .bot }
        }
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter {
                $0.parent?.name.localizedCaseInsensitiveContains(searchText) == true ||
                $0.lastMessagePreview?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return result.sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Spacing.md) {
                HStack {
                    Text("Conversations")
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    
                    Spacer()

                    Button(action: {
                        _Concurrency.Task { await appState.refreshConversations() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.moltPrimary)
                    }
                    .buttonStyle(.plain)
                    
                    // Select toggle
                    Button(action: { isInSelectionMode.toggle() }) {
                        Image(systemName: isInSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundColor(isInSelectionMode ? .moltPrimary : .moltTextMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Toggle selection mode")
                    
                    Text("\(filteredConversations.count)")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.moltSurfaceSecondary)
                        .cornerRadius(CornerRadius.small)
                }
                
                // Search
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.moltTextMuted)
                    TextField("Search conversations...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.moltBody)
                        .foregroundColor(.moltTextPrimary)
                        .tint(.moltTextPrimary)
                }
                .padding(Spacing.sm)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.medium)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(ConversationFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                label: filter.label,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color.moltSurface)
            
            SubtleDivider()

            
            if let error = appState.conversationLoadError {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Failed to load conversations")
                        .font(.moltBodySmall)
                        .foregroundColor(.priorityHigh)
                    Text(error)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                        .lineLimit(2)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.priorityHigh.opacity(0.08))
                
                SubtleDivider()
            }

            if appState.isLoadingConversations && filteredConversations.isEmpty {
                ConversationLoadingState()
            } else if filteredConversations.isEmpty {
                ConversationEmptyState()
            } else {
                // Conversation List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredConversations) { conversation in
                            HStack(spacing: 0) {
                                // Selection checkbox
                                if isInSelectionMode {
                                    Button(action: { toggleSelection(conversation.id) }) {
                                        Image(systemName: selectedIds.contains(conversation.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedIds.contains(conversation.id) ? .moltPrimary : .moltTextMuted)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.leading, Spacing.md)
                                }
                                
                                ConversationRow(
                                    conversation: conversation,
                                    isSelected: appState.selectedConversation?.id == conversation.id
                                )
                                .onTapGesture {
                                    if isInSelectionMode {
                                        toggleSelection(conversation.id)
                                    } else {
                                        appState.selectedConversation = conversation
                                        if conversation.unreadCount > 0 {
                                            appState.markConversationRead(conversation.id)
                                        }
                                    }
                                }
                            }
                            
                            SubtleDivider()
                                .padding(.leading, isInSelectionMode ? 84 : 64)
                        }
                        
                        if appState.hasMoreConversations {
                            LoadMoreRow(
                                isLoading: appState.isLoadingMoreConversations,
                                action: {
                                    _Concurrency.Task { await appState.loadMoreConversations() }
                                }
                            )
                        }
                    }
                }
                .background(Color.moltSurface)
            }
        }
    }
    
    func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

// MARK: - Filter
enum ConversationFilter: CaseIterable {
    case all, open, pending, resolved, bot
    
    var label: String {
        switch self {
        case .all: return "All"
        case .open: return "Open"
        case .pending: return "Pending"
        case .resolved: return "Resolved"
        case .bot: return "Bot Active"
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.moltCaption)
                .foregroundColor(isSelected ? .white : .moltTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.large)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Priority Indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.moltSurfaceSecondary)
                    .frame(width: 44, height: 44)
                
                Text(conversation.parent?.name.prefix(1).uppercased() ?? "?")
                    .font(.moltBody)
                    .foregroundColor(.moltTextSecondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.parent?.name ?? "Unknown")
                        .font(.moltBodySmall)
                        .fontWeight(conversation.unreadCount > 0 ? .semibold : .regular)
                        .foregroundColor(.moltTextPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(timeAgo(conversation.lastMessageAt ?? conversation.createdAt))
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                
                HStack(spacing: Spacing.xs) {
                    Text(appState.conversationPreview(for: conversation))
                        .font(.moltCaption)
                        .foregroundColor(.moltTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                    
                    Spacer(minLength: Spacing.xs)
                    
                    HStack(spacing: Spacing.xs) {
                        StatusChip(status: conversation.status)
                        if let label = assignmentLabel {
                            AssignmentChip(label: label, color: assignmentColor)
                        }
                        HandlerBadge(handledBy: conversation.handledBy)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            
            // Unread Badge
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.moltLabel)
                    .foregroundColor(.white)
                    .frame(minWidth: 20)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.moltPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(isSelected ? Color.moltPrimaryLight : Color.clear)
        .contentShape(Rectangle())
        .contextMenu {
            if conversation.unreadCount > 0 {
                Button("Mark as Read") {
                    appState.markConversationRead(conversation.id)
                }
            } else {
                Button("Mark as Unread") {
                    appState.markConversationUnread(conversation.id)
                }
            }
            Divider()
            if conversation.assignedAgentId == appState.currentAgent?.id {
                Button("Unassign") {
                    appState.assignConversation(conversationId: conversation.id, agentId: nil)
                }
            } else {
                Button("Assign to Me") {
                    appState.assignConversation(conversationId: conversation.id, agentId: appState.currentAgent?.id)
                }
            }
        }
    }
    
    var priorityColor: Color {
        switch conversation.priority {
        case .urgent: return .priorityUrgent
        case .high: return .priorityHigh
        case .medium: return .priorityMedium
        case .low: return .priorityLow
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var assignmentLabel: String? {
        if let agentId = conversation.assignedAgentId {
            if agentId == appState.currentAgent?.id {
                return "You"
            }
            if let agent = appState.agents.first(where: { $0.id == agentId }) {
                let firstName = agent.name.split(separator: " ").first.map(String.init) ?? agent.name
                return firstName
            }
            return "Assigned"
        }
        if conversation.assignedTeamId != nil {
            return "Team"
        }
        return nil
    }

    var assignmentColor: Color {
        if conversation.assignedAgentId == appState.currentAgent?.id {
            return .moltPrimary
        }
        if conversation.assignedTeamId != nil {
            return .priorityHigh
        }
        return .moltTextMuted
    }
}

// MARK: - Handler Badge
struct HandlerBadge: View {
    let handledBy: ConversationHandler
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.moltLabel)
                .lineLimit(1)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .cornerRadius(CornerRadius.small)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    var label: String {
        switch handledBy {
        case .bot: return "Bot"
        case .agent: return "Agent"
        case .team: return "Team"
        }
    }
    
    var icon: String {
        switch handledBy {
        case .bot: return "cpu"
        case .agent: return "person.fill"
        case .team: return "person.3.fill"
        }
    }
    
    var color: Color {
        switch handledBy {
        case .bot: return .priorityMedium
        case .agent: return .moltPrimary
        case .team: return .orange
        }
    }
}

// MARK: - Status Chip
struct StatusChip: View {
    let status: ConversationStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.moltLabel)
            .lineLimit(1)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(CornerRadius.small)
            .fixedSize(horizontal: true, vertical: false)
    }

    var color: Color {
        switch status {
        case .open: return .priorityMedium
        case .pending: return .priorityHigh
        case .resolved: return .priorityLow
        case .closed: return .priorityResolved
        }
    }
}

// MARK: - Assignment Chip
struct AssignmentChip: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.moltLabel)
            .lineLimit(1)
            .truncationMode(.tail)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(CornerRadius.small)
            .frame(maxWidth: 88)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Empty & Loading States
struct ConversationEmptyState: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundColor(.moltTextMuted)
            Text("No conversations yet")
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
            Text("New messages will appear here.")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltSurface)
    }
}

struct ConversationLoadingState: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Loading conversations…")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltSurface)
    }
}

struct LoadMoreRow: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.75)
                }
                Text(isLoading ? "Loading more…" : "Load more")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .background(Color.moltSurface)
    }
}
