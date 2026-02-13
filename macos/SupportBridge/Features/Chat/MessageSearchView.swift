import SwiftUI

// MARK: - Message Search View
struct MessageSearchView: View {
    let conversationId: String
    let messages: [Message]
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [Message] = []
    var onSelectMessage: ((Message) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            HStack(spacing: Spacing.md) {
                Button(action: { isPresented = false }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.moltTextSecondary)
                }
                .buttonStyle(.plain)
                
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.moltTextMuted)
                    
                    TextField("Search in conversation...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.moltBody)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.moltTextMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.sm)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.medium)
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Results
            if searchText.isEmpty {
                EmptySearchView()
            } else if searchResults.isEmpty {
                NoResultsView(query: searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults) { message in
                            SearchResultRow(
                                message: message,
                                searchQuery: searchText
                            ) {
                                onSelectMessage?(message)
                                isPresented = false
                            }
                            
                            SubtleDivider()
                                .padding(.leading, 64)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
        .background(Color.moltBackground)
        .onChange(of: searchText) { newValue in
            if newValue.count >= 2 {
                performSearch()
            } else {
                searchResults = []
            }
        }
    }
    
    func performSearch() {
        guard searchText.count >= 2 else {
            searchResults = []
            return
        }
        
        searchResults = messages.filter { message in
            message.content.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let message: Message
    let searchQuery: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: avatarIcon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(senderName)
                            .font(.moltBody)
                            .fontWeight(.medium)
                            .foregroundColor(.moltTextPrimary)
                        
                        Spacer()
                        
                        Text(formatDate(message.sentAt))
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                    
                    highlightedText
                        .font(.moltBodySmall)
                        .lineLimit(2)
                }
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    var avatarColor: Color {
        switch message.senderType {
        case .parent: return .moltPrimary
        case .agent: return .priorityLow
        case .bot: return .priorityMedium
        case .team: return .priorityHigh
        case .system: return .moltTextMuted
        }
    }
    
    var avatarIcon: String {
        switch message.senderType {
        case .parent: return "person.fill"
        case .agent: return "headphones"
        case .bot: return "brain"
        case .team: return "person.3.fill"
        case .system: return "gearshape.fill"
        }
    }
    
    var senderName: String {
        switch message.senderType {
        case .parent: return "Parent"
        case .agent: return "Agent"
        case .bot: return "AI Assistant"
        case .team: return "Team"
        case .system: return "System"
        }
    }
    
    var highlightedText: Text {
        let content = message.content
        guard let range = content.range(of: searchQuery, options: .caseInsensitive) else {
            return Text(content)
                .foregroundColor(.moltTextSecondary)
        }
        
        let before = String(content[..<range.lowerBound])
        let match = String(content[range])
        let after = String(content[range.upperBound...])
        
        return Text(before)
            .foregroundColor(.moltTextSecondary)
        + Text(match)
            .foregroundColor(.moltPrimary)
            .fontWeight(.semibold)
        + Text(after)
            .foregroundColor(.moltTextSecondary)
    }
    
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Empty Search View
struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.moltTextMuted)
            
            Text("Search messages")
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
            
            Text("Find text, names, or keywords in this conversation")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
}

// MARK: - No Results View
struct NoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.moltTextMuted)
            
            Text("No results for \"\(query)\"")
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
            
            Text("Try a different search term")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
}

// MARK: - Message Search Button (for ChatDetailView)
struct MessageSearchButton: View {
    let conversationId: String
    let messages: [Message]
    @State private var showSearch = false
    var onSelectMessage: ((Message) -> Void)?
    
    var body: some View {
        Button(action: { showSearch = true }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.moltTextSecondary)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSearch) {
            MessageSearchView(
                conversationId: conversationId,
                messages: messages,
                isPresented: $showSearch,
                onSelectMessage: onSelectMessage
            )
        }
    }
}
