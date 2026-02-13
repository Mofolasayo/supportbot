import SwiftUI

struct TeamInboxView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTeam: Team?
    @State private var selectedCategory: String = "All"
    @State private var selectedConversation: Conversation?
    
    let categories = ["All", "General Info", "Finance", "Admissions", "Technical", "Academic"]
    
    var body: some View {
        HStack(spacing: 0) {
            // Team/Category Selection + List
            VStack(spacing: 0) {
                // Header
                VStack(spacing: Spacing.md) {
                    HStack {
                        Text("My Team")
                            .font(.moltTitleMedium)
                            .foregroundColor(.moltTextPrimary)
                        
                        Spacer()
                    }
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(categories, id: \.self) { category in
                                TeamCategoryPill(
                                    label: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }
                .appHeaderAligned()
                .background(Color.moltSurface)
                
                SubtleDivider()
                
                // Conversation List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredConversations) { conversation in
                            TeamConversationRow(
                                conversation: conversation,
                                isSelected: selectedConversation?.id == conversation.id
                            )
                            .onTapGesture {
                                selectedConversation = conversation
                            }
                            
                            SubtleDivider()
                        }
                    }
                }
                .background(Color.moltSurface)
            }
            .frame(minWidth: 380)
            
            SubtleVerticalDivider()
            
            // Detail View
            if let conversation = selectedConversation {
                TeamConversationDetail(conversation: conversation)
            } else {
                EmptyStateView(
                    icon: "person.3",
                    title: "Team Inbox",
                    message: "Select a conversation to view details"
                )
            }
        }
        .background(Color.moltBackground)
    }
    
    var filteredConversations: [Conversation] {
        var result = appState.conversations.filter { $0.handledBy == .team }
        
        if let team = selectedTeam {
            result = result.filter { $0.assignedTeamId == team.id }
        }
        
        return result
    }
}

// MARK: - Team Category Pill (renamed to avoid conflict)
struct TeamCategoryPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10))
                }
                Text(label)
                    .font(.moltCaption)
            }
            .foregroundColor(isSelected ? .white : .moltTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.large)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Team Conversation Row
struct TeamConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Priority Indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            // Avatar
            Circle()
                .fill(Color.moltSurfaceSecondary)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(conversation.parent?.name.prefix(1).uppercased() ?? "?")
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.parent?.name ?? "Unknown")
                        .font(.moltBodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(.moltTextPrimary)
                    
                    Spacer()
                    
                    // SLA Timer
                    SLATimer(createdAt: conversation.createdAt)
                }
                
                Text(conversation.lastMessagePreview ?? "")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
                    .lineLimit(1)
                
                // Tags
                if let tags = conversation.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10))
                                .foregroundColor(.moltPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.moltPrimaryLight)
                                .cornerRadius(CornerRadius.small)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(isSelected ? Color.moltPrimaryLight : Color.clear)
        .contentShape(Rectangle())
    }
    
    var priorityColor: Color {
        switch conversation.priority {
        case .urgent: return .priorityUrgent
        case .high: return .priorityHigh
        case .medium: return .priorityMedium
        case .low: return .priorityLow
        }
    }
}

// MARK: - SLA Timer
struct SLATimer: View {
    let createdAt: Date
    
    var elapsedMinutes: Int {
        Int(Date().timeIntervalSince(createdAt) / 60)
    }
    
    var isOverdue: Bool {
        elapsedMinutes > 30
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 10))
            Text(formatTime)
                .font(.moltLabel)
        }
        .foregroundColor(isOverdue ? .priorityUrgent : .moltTextMuted)
    }
    
    var formatTime: String {
        if elapsedMinutes < 60 {
            return "\(elapsedMinutes)m"
        } else {
            let hours = elapsedMinutes / 60
            let mins = elapsedMinutes % 60
            return "\(hours)h \(mins)m"
        }
    }
}

// MARK: - Team Conversation Detail
struct TeamConversationDetail: View {
    let conversation: Conversation
    @State private var internalNote = ""
    @State private var showInternalNotes = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.parent?.name ?? "Unknown")
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    Text(conversation.parent?.phoneNumber ?? "")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: Spacing.sm) {
                    Button(action: { showInternalNotes.toggle() }) {
                        Label("Notes", systemImage: "note.text")
                            .font(.moltLabel)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.moltTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showInternalNotes ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                    
                    Button(action: {}) {
                        Label("Resolve", systemImage: "checkmark.circle")
                            .font(.moltLabel)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.priorityLow)
                    .cornerRadius(CornerRadius.medium)
                }
            }
            .appHeaderAligned()
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Content Area
            HStack(spacing: 0) {
                // Chat Area
                VStack(spacing: 0) {
                    // Messages
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(Message.mockList) { message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding(Spacing.lg)
                    }
                    
                    SubtleDivider()
                    
                    // Input
                    TeamMessageInput()
                }
                .background(Color.moltBackground)
                
                // Internal Notes Panel
                if showInternalNotes {
                    SubtleVerticalDivider()
                    InternalNotesPanel(conversationId: conversation.id) 
                }
            }
        }
        .frame(minWidth: 400)
    }
}

// MARK: - Team Message Input
struct TeamMessageInput: View {
    @State private var message = ""
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: {}) {
                Image(systemName: "paperclip")
                    .font(.system(size: 18))
                    .foregroundColor(.moltTextSecondary)
            }
            .buttonStyle(.plain)
            
            TextField("Type a message...", text: $message)
                .textFieldStyle(.plain)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
                .tint(.moltTextPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.large)
            
            Button(action: {}) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(message.isEmpty ? .moltTextMuted : .moltPrimary)
            }
            .buttonStyle(.plain)
            .disabled(message.isEmpty)
        }
        .padding(Spacing.md)
        .background(Color.moltSurface)
    }
}

// MARK: - Internal Notes Panel
struct InternalNotesPanel: View {
    let conversationId: String
    @EnvironmentObject var appState: AppState
    @State private var newNote = ""
    
    var sampleNotes: [(String, String, Date)] {
        let name = appState.currentAgent?.name ?? "Agent"
        return [
            (name, "Parent has been very cooperative. Resolving billing issue now.", Date().addingTimeInterval(-3600)),
            ("Michael Obi", "Checked with finance team - payment was received but not recorded.", Date().addingTimeInterval(-7200))
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Internal Notes")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                Spacer()
                Text("Private")
                    .font(.moltLabel)
                    .foregroundColor(.priorityHigh)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.priorityHigh.opacity(0.15))
                    .cornerRadius(CornerRadius.small)
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()

            
            // Notes List
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(sampleNotes, id: \.0) { note in
                        InternalNoteCard(author: note.0, content: note.1, date: note.2)
                    }
                }
                .padding(Spacing.md)
            }
            
            SubtleDivider()

            
            // Add Note
            VStack(spacing: Spacing.sm) {
                TextEditor(text: $newNote)
                    .scrollContentBackground(.hidden)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                    .tint(.moltTextPrimary)
                    .frame(height: 60)
                    .padding(Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Text("Add Note")
                            .font(.moltLabel)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.moltPrimary)
                            .cornerRadius(CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                    .disabled(newNote.isEmpty)
                }
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
        }
        .frame(width: 280)
        .background(Color.moltBackground)
    }
}

struct InternalNoteCard: View {
    let author: String
    let content: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(author)
                    .font(.moltLabel)
                    .foregroundColor(.moltTextPrimary)
                Spacer()
                Text(timeAgo)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            
            Text(content)
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
        }
        .padding(Spacing.md)
        .background(Color.bubbleTeam)
        .cornerRadius(CornerRadius.medium)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
