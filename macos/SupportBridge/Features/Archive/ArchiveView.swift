import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    
    var archivedConversations: [Conversation] {
        appState.conversations
            .filter { $0.status == .closed || $0.status == .resolved }
            .sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
    }
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return archivedConversations
        }
        return archivedConversations.filter { conv in
            conv.parent?.name.localizedCaseInsensitiveContains(searchText) ?? false ||
            conv.lastMessagePreview?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Archive")
                    .font(.moltTitleLarge)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Text("\(archivedConversations.count) conversations")
                    .font(.moltBody)
                    .foregroundColor(.moltTextMuted)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.moltTextMuted)
                TextField("Search archived conversations...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.moltBody)
            }
            .padding(Spacing.md)
            .background(Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Archived Conversations List
            if filteredConversations.isEmpty {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 60))
                        .foregroundColor(.moltTextMuted)
                    
                    Text(searchText.isEmpty ? "No archived conversations" : "No results found")
                        .font(.moltTitleSmall)
                        .foregroundColor(.moltTextSecondary)
                    
                    if searchText.isEmpty {
                        Text("Resolved and closed conversations will appear here")
                            .font(.moltBody)
                            .foregroundColor(.moltTextMuted)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.moltBackground)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        ForEach(filteredConversations) { conversation in
                            ArchivedConversationRow(conversation: conversation)
                        }
                    }
                    .padding(Spacing.md)
                }
                .background(Color.moltBackground)
            }
        }
        .background(Color.moltSurface)
    }
}

// MARK: - Archived Conversation Row
struct ArchivedConversationRow: View {
    @EnvironmentObject var appState: AppState
    let conversation: Conversation
    
    var body: some View {
        Button(action: {
            appState.selectedConversation = conversation
        }) {
            HStack(spacing: Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.moltSurfaceSecondary)
                        .frame(width: 40, height: 40)
                    Text(conversation.parent?.name.prefix(1).uppercased() ?? "?")
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.parent?.name ?? "Unknown")
                            .font(.moltBody)
                            .fontWeight(.medium)
                            .foregroundColor(.moltTextPrimary)
                        
                        Spacer()
                        
                        if let lastMessageAt = conversation.lastMessageAt {
                            Text(lastMessageAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                        }
                    }
                    
                    if let preview = conversation.lastMessagePreview {
                        Text(preview)
                            .font(.moltBody)
                            .foregroundColor(.moltTextMuted)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: Spacing.xs) {
                        StatusBadge(status: conversation.status)
                        
                        if let tags = conversation.tags {
                            ForEach(tags.prefix(2), id: \.self) { tag in
                                Text(tag)
                                    .font(.moltLabel)
                                    .foregroundColor(.moltTextSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.moltSurfaceSecondary)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                // Restore button
                Button(action: {
                    appState.toggleResolve(conversationId: conversation.id)
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}
