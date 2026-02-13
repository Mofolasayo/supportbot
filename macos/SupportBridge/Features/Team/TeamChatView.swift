import SwiftUI

// MARK: - Team Chat View
struct TeamChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedChannel: TeamChatChannel?
    @State private var selectedDM: Agent?
    @State private var newMessage = ""

    private var channels: [TeamChatChannel] {
        if appState.isAuthenticated {
            return appState.teamChannels
        }
        return TeamChatChannel.mockList
    }

    private var dmAgents: [Agent] {
        if appState.isAuthenticated && !appState.agents.isEmpty {
            return appState.agents.filter { $0.id != appState.currentAgent?.id }
        }
        return AgentWithWorkload.mockList.map {
            Agent(
                id: $0.id,
                email: $0.email,
                name: $0.name,
                role: .agent,
                status: $0.status,
                teamId: $0.teamId,
                avatarUrl: nil,
                isActive: true
            )
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar - Channels & DMs
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Team Chat")
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    Spacer()
                }
                .appHeaderAligned()
                
                SubtleDivider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Channels Section
                        ChannelSection(
                            title: "Channels",
                            channels: channels,
                            selectedChannel: $selectedChannel,
                            onSelectChannel: { channel in
                                selectedChannel = channel
                                selectedDM = nil
                                _Concurrency.Task { await appState.loadChannelMessages(channelId: channel.id) }
                            }
                        )
                        
                        SubtleDivider()
                        
                        // Direct Messages Section
                        DMSection(
                            title: "Direct Messages",
                            agents: dmAgents,
                            selectedDM: $selectedDM,
                            onSelectDM: { agent in
                                selectedDM = agent
                                selectedChannel = nil
                                _Concurrency.Task { await appState.loadDMMessages(agentId: agent.id) }
                            }
                        )
                    }
                    .padding(Spacing.md)
                }
            }
            .frame(width: 220)
            .background(Color.moltSurface)
            
            SubtleVerticalDivider()
            
            // Chat Area
            VStack(spacing: 0) {
                if let channel = selectedChannel {
                    ChannelChatArea(channel: channel, newMessage: $newMessage)
                } else if let dm = selectedDM {
                    DMChatArea(agent: dm, newMessage: $newMessage)
                } else {
                    EmptyChatState()
                }
            }
            .background(Color.moltBackground)
        }
        .task {
            await appState.refreshTeamChannels()
            await appState.refreshAgents()
        }
    }
}

// MARK: - Channel Section
struct ChannelSection: View {
    let title: String
    let channels: [TeamChatChannel]
    @Binding var selectedChannel: TeamChatChannel?
    let onSelectChannel: (TeamChatChannel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.moltLabel)
                .foregroundColor(.moltTextMuted)
            
            ForEach(channels) { channel in
                ChannelRow(
                    channel: channel,
                    isSelected: selectedChannel?.id == channel.id,
                    action: { onSelectChannel(channel) }
                )
            }
        }
    }
}

// MARK: - Channel Row
struct ChannelRow: View {
    let channel: TeamChatChannel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: channel.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
                
                Text(channel.name)
                    .font(.moltBody)
                    .foregroundColor(isSelected ? .moltTextPrimary : .moltTextSecondary)
                
                Spacer()
                
                if channel.unreadCount > 0 {
                    Text("\(channel.unreadCount)")
                        .font(.moltCaption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.moltPrimary)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.moltPrimaryLight : Color.clear)
            .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DM Section
struct DMSection: View {
    let title: String
    let agents: [Agent]
    @Binding var selectedDM: Agent?
    let onSelectDM: (Agent) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.moltLabel)
                .foregroundColor(.moltTextMuted)
            
            ForEach(agents) { agent in
                DMRow(
                    agent: agent,
                    isSelected: selectedDM?.id == agent.id,
                    action: { onSelectDM(agent) }
                )
            }
        }
    }
}

// MARK: - DM Row
struct DMRow: View {
    let agent: Agent
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Avatar with status
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.moltSurfaceSecondary)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(agent.avatarInitial)
                                .font(.moltCaption)
                                .foregroundColor(.moltTextSecondary)
                        )
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: 2)
                }
                
                Text(agent.name)
                    .font(.moltBody)
                    .foregroundColor(isSelected ? .moltTextPrimary : .moltTextSecondary)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.moltPrimaryLight : Color.clear)
            .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
    
    var statusColor: Color {
        switch agent.status {
        case .online: return .priorityLow
        case .away: return .priorityMedium
        case .busy: return .priorityHigh
        case .offline: return .moltTextMuted
        }
    }
}

// MARK: - Channel Chat Area
struct ChannelChatArea: View {
    @EnvironmentObject var appState: AppState
    let channel: TeamChatChannel
    @Binding var newMessage: String

    private var messages: [TeamChatMessage] {
        if let loaded = appState.channelMessages[channel.id], !loaded.isEmpty {
            return loaded
        }
        return TeamChatMessage.messagesForChannel(channel.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: channel.icon)
                    .foregroundColor(.moltPrimary)
                Text(channel.name)
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                Spacer()
            }
            .appHeaderAligned()
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Messages
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(messages) { message in
                        TeamMessageBubble(message: message, isCurrentUser: message.senderId == appState.currentAgent?.id)
                    }
                }
                .padding(Spacing.lg)
            }
            
            SubtleDivider()
            
            // Input
            TeamChatInput(text: $newMessage, placeholder: "Message #\(channel.name)") {
                let content = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !content.isEmpty else { return }
                _Concurrency.Task {
                    do {
                        try await appState.sendChannelMessage(channelId: channel.id, content: content)
                        await MainActor.run { newMessage = "" }
                    } catch {
                        print("Failed to send channel message: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - DM Chat Area
struct DMChatArea: View {
    @EnvironmentObject var appState: AppState
    let agent: Agent
    @Binding var newMessage: String

    private var messages: [TeamChatMessage] {
        if let loaded = appState.dmMessages[agent.id], !loaded.isEmpty {
            return loaded
        }
        return TeamChatMessage.messagesForDM(agent.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(Color.moltSurfaceSecondary)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(agent.avatarInitial)
                            .font(.moltBody)
                            .foregroundColor(.moltTextSecondary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.name)
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    Text(agent.status.rawValue.capitalized)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                Spacer()
            }
            .appHeaderAligned()
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Messages
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(messages) { message in
                        TeamMessageBubble(message: message, isCurrentUser: message.senderId == appState.currentAgent?.id)
                    }
                }
                .padding(Spacing.lg)
            }
            
            SubtleDivider()
            
            // Input
            TeamChatInput(text: $newMessage, placeholder: "Message \(agent.name)") {
                let content = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !content.isEmpty else { return }
                _Concurrency.Task {
                    do {
                        try await appState.sendDM(agentId: agent.id, content: content)
                        await MainActor.run { newMessage = "" }
                    } catch {
                        print("Failed to send DM: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Team Message Bubble
struct TeamMessageBubble: View {
    let message: TeamChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.moltLabel)
                        .foregroundColor(.moltTextMuted)
                }
                
                Text(message.content)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                    .padding(Spacing.md)
                    .background(isCurrentUser ? Color.moltPrimary.opacity(0.2) : Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                
                Text(formatTime(message.sentAt))
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Team Chat Input
struct TeamChatInput: View {
    @Binding var text: String
    let placeholder: String
    var onSend: () -> Void = {}
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: {}) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.moltTextSecondary)
            }
            .buttonStyle(.plain)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
                .tint(.moltTextPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.large)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(text.isEmpty ? .moltTextMuted : .moltPrimary)
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
        }
        .padding(Spacing.md)
        .background(Color.moltSurface)
    }
}

// MARK: - Empty Chat State
struct EmptyChatState: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.moltTextMuted)
            Text("Select a channel or DM")
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
            Text("Start a conversation with your team")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
