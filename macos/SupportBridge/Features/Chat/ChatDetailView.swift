import SwiftUI

struct ChatDetailView: View {
    let conversation: Conversation
    @EnvironmentObject var appState: AppState
    @State private var newMessage = ""
    @State private var isAIPanelVisible = true
    @State private var sidePanelMode: SidePanelMode = .ai
    @State private var isTyping = false
    @State private var showCustomerProfile = false
    @State private var replyToMessage: Message? = nil
    @State private var showEmojiPicker = false
    @State private var selectedMessageForReaction: Message? = nil
    @State private var messageToForward: Message? = nil

    var conversationMessages: [Message] {
        appState.messages(for: conversation.id)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Main Chat Area
            VStack(spacing: 0) {
                // Chat Header
                ChatHeader(
                    conversation: conversation, 
                    isAIPanelVisible: $isAIPanelVisible,
                    onAvatarTap: { showCustomerProfile = true },
                    onToggleAI: {
                        if isAIPanelVisible {
                            if sidePanelMode == .ai {
                                isAIPanelVisible = false
                            } else {
                                sidePanelMode = .ai
                            }
                        } else {
                            sidePanelMode = .ai
                            isAIPanelVisible = true
                        }
                    },
                    onShowDetails: {
                        sidePanelMode = .details
                        isAIPanelVisible = true
                    },
                    onResolve: {
                        _Concurrency.Task {
                            await appState.toggleResolve(conversationId: conversation.id)
                        }
                    },
                    onEscalate: {
                        _Concurrency.Task {
                            await appState.toggleEscalate(conversationId: conversation.id)
                        }
                    }
                )
                
                SubtleDivider()
                
                if let error = appState.messageLoadErrors[conversation.id] {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.priorityHigh)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Failed to load messages")
                                .font(.moltBodySmall)
                                .foregroundColor(.priorityHigh)
                            Text(error)
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                                .lineLimit(2)
                        }
                        Spacer()
                        Button("Retry") {
                            _Concurrency.Task { await appState.refreshMessages(for: conversation.id) }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.moltPrimary)
                    }
                    .padding(Spacing.md)
                    .background(Color.priorityHigh.opacity(0.08))
                    SubtleDivider()
                }

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            if conversationMessages.isEmpty {
                                MessageEmptyState()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.xl)
                            } else {
                                ForEach(conversationMessages) { message in
                                    MessageBubble(
                                        message: message,
                                        onReply: { msg in
                                            replyToMessage = msg
                                        },
                                        onReact: { msg in
                                            selectedMessageForReaction = msg
                                            showEmojiPicker = true
                                        },
                                        onStar: { msg in
                                            _Concurrency.Task {
                                                await appState.toggleStarMessageRemote(
                                                    messageId: msg.id,
                                                    conversationId: conversation.id
                                                )
                                            }
                                        },
                                        onForward: { msg in
                                            messageToForward = msg
                                        },
                                        onDelete: { msg in
                                            // Only allow deleting your own messages
                                            if msg.senderType == .agent {
                                                _Concurrency.Task {
                                                    await appState.deleteMessageRemote(
                                                        messageId: msg.id,
                                                        conversationId: conversation.id
                                                    )
                                                }
                                            }
                                        }
                                    )
                                    .id(message.id)
                                }
                            }
                        }
                        .padding(Spacing.lg)
                    }
                    .background(Color.moltBackground)
                    .onChange(of: conversationMessages.count) { _ in
                        if let lastId = conversationMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                SubtleDivider()
                
                // Typing Indicator
                if isTyping {
                    TypingIndicator(name: conversation.parent?.name ?? "User")
                }
                
                // Reply Preview
                // Reply Preview
                if let replyTo = replyToMessage {
                    ReplyPreviewBar(
                        message: replyTo,
                        onDismiss: { replyToMessage = nil },
                        senderName: replyTo.senderType == .agent ? "You" : (conversation.parent?.name ?? "User")
                    )
                }
                
                // Input Area
                MessageInputView(
                    text: $newMessage,
                    onSend: sendMessage,
                    onSendVoice: sendVoiceMessage,
                    onSendAttachment: sendAttachment
                )
            }
            .frame(minWidth: 400)
            
            // AI Panel (collapsible)
            if isAIPanelVisible {
                SubtleVerticalDivider()

                ConversationSidePanel(
                    conversation: conversation,
                    selection: $sidePanelMode
                )
                .frame(width: 320)
            }
        }
        .background(Color.moltSurface)
        .onAppear {
            appState.ensureMessagesLoaded(for: conversation.id)
            if conversation.unreadCount > 0 {
                appState.markConversationRead(conversation.id)
            }
            simulateTyping()
        }
        .onChange(of: conversation.id) { newId in
            appState.ensureMessagesLoaded(for: newId)
            let unread = appState.conversations.first(where: { $0.id == newId })?.unreadCount ?? 0
            if unread > 0 {
                appState.markConversationRead(newId)
            }
            replyToMessage = nil
            simulateTyping()
        }
        .sheet(isPresented: $showCustomerProfile) {
            if let parent = conversation.parent {
                CustomerProfilePopup(
                    parent: parent,
                    conversations: appState.conversations,
                    isPresented: $showCustomerProfile
                )
            }
        }
        .popover(isPresented: $showEmojiPicker) {
            ReactionPicker { emoji in
                if let msg = selectedMessageForReaction {
                    _Concurrency.Task {
                        await appState.addReactionRemote(
                            emoji: emoji,
                            to: msg.id,
                            conversationId: conversation.id
                        )
                    }
                }
                showEmojiPicker = false
                selectedMessageForReaction = nil
            }
        }
        .sheet(item: $messageToForward) { msg in
            ForwardMessageSheet(message: msg, isPresented: Binding(
                get: { true },
                set: { if !$0 { messageToForward = nil } }
            ))
        }
    }
    
    func simulateTyping() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if Bool.random() {
                isTyping = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isTyping = false
                }
            }
        }
    }
    
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let content = newMessage
        newMessage = ""
        replyToMessage = nil

        _Concurrency.Task {
            await appState.sendMessage(conversationId: conversation.id, content: content, messageType: .text)
        }
    }
    
    func sendVoiceMessage(url: URL, duration: TimeInterval) {
        _ = duration
        _Concurrency.Task {
            await appState.uploadAttachmentMessage(
                conversationId: conversation.id,
                fileURL: url,
                fallbackType: .audio
            )
        }
        replyToMessage = nil
    }
    
    func sendAttachment(url: URL, type: MessageType) {
        _Concurrency.Task {
            await appState.uploadAttachmentMessage(
                conversationId: conversation.id,
                fileURL: url,
                fallbackType: type
            )
        }
        replyToMessage = nil
    }
}

// MARK: - Reply Preview Bar
struct ReplyPreviewBar: View {
    let message: Message
    let onDismiss: () -> Void
    var senderName: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Replying to \(senderName)")
                    .font(.moltLabel)
                    .foregroundColor(.moltPrimary)
                
                Text(message.content)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
                    .lineLimit(1)
            }
            .padding(.leading, 8)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.moltPrimary)
                    .frame(width: 3)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.moltTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 4) // Reduced padding slightly
        .background(Color.moltSurfaceSecondary)
    }
}

// MARK: - Chat Header
struct ChatHeader: View {
    let conversation: Conversation
    @Binding var isAIPanelVisible: Bool
    var onAvatarTap: (() -> Void)? = nil
    var onToggleAI: (() -> Void)? = nil
    var onShowDetails: (() -> Void)? = nil
    var onResolve: (() -> Void)? = nil
    var onEscalate: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Avatar (clickable for profile)
            Button(action: { onAvatarTap?() }) {
                ZStack {
                    if let avatarUrl = conversation.parent?.avatarUrl, let url = URL(string: avatarUrl) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.moltSurfaceSecondary)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.moltSurfaceSecondary)
                            .frame(width: 40, height: 40)
                        
                        Text(conversation.parent?.name.prefix(1).uppercased() ?? "?")
                            .font(.moltBody)
                            .foregroundColor(.moltTextSecondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("View customer profile")
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conversation.parent?.name ?? "Unknown")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Text(conversation.parent?.phoneNumber ?? "")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            
            Spacer()
            
            // Status
            HStack(spacing: Spacing.sm) {
                StatusBadge(status: conversation.status)
                HandlerBadge(handledBy: conversation.handledBy)
            }
            
            // Actions
            HStack(spacing: Spacing.xs) {
                IconButton(icon: "phone.fill") { print("Simulated call") }
                IconButton(icon: "arrow.up.circle") { onEscalate?() } // Escalate
                IconButton(icon: "checkmark.circle") { onResolve?() } // Resolve
                IconButton(icon: "info.circle") { onShowDetails?() }
                IconButton(icon: isAIPanelVisible ? "sidebar.right" : "sparkles") {
                    onToggleAI?()
                }
                
                Menu {
                    Button("Mark as Resolved") { }
                    Button("Assign to Team") { }
                    Button("Add Note") { }
                    Divider()
                    Button("Close Conversation") { }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.moltTextSecondary)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.moltSurface)
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.moltTextSecondary)
                .frame(width: 32, height: 32)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ConversationStatus
    
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
        case .open: return .priorityMedium
        case .pending: return .priorityHigh
        case .resolved: return .priorityLow
        case .closed: return .priorityResolved
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    let name: String
    @State private var animationOffset: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(name)
                .font(.moltCaption)
                .foregroundColor(.moltTextSecondary)
            
            Text("is typing")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.moltPrimary)
                        .frame(width: 6, height: 6)
                        .offset(y: animationOffset[index])
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(Color.moltSurface)
        .onAppear {
            animateDots()
        }
    }
    
    func animateDots() {
        for i in 0..<3 {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15)
            ) {
                animationOffset[i] = -4
            }
        }
    }
}

// MARK: - Message Empty State
struct MessageEmptyState: View {
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 26))
                .foregroundColor(.moltTextMuted)
            Text("No messages yet")
                .font(.moltBodySmall)
                .foregroundColor(.moltTextSecondary)
            Text("Start the conversation to see messages here.")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Side Panel
enum SidePanelMode: String, CaseIterable, Identifiable {
    case ai = "AI"
    case details = "Details"

    var id: String { rawValue }
}

struct ConversationSidePanel: View {
    let conversation: Conversation
    @Binding var selection: SidePanelMode

    var body: some View {
        VStack(spacing: 0) {
            if selection == .ai {
                AISuggestionsPanel(conversation: conversation)
            } else {
                ConversationDetailsPanel(conversation: conversation)
            }
        }
        .background(Color.moltSurface)
    }
}

struct ConversationDetailsPanel: View {
    let conversation: Conversation
    @EnvironmentObject var appState: AppState
    @State private var notes = ""
    @State private var newTag = ""
    @State private var tags: [String] = []

    private var tagKey: String {
        (conversation.tags ?? []).joined(separator: "|")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.moltSurfaceSecondary)
                                .frame(width: 44, height: 44)
                            Text(conversation.parent?.name.prefix(1).uppercased() ?? "?")
                                .font(.moltBody)
                                .foregroundColor(.moltTextSecondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(conversation.parent?.name ?? "Unknown")
                                .font(.moltTitleSmall)
                                .foregroundColor(.moltTextPrimary)
                            Text(conversation.parent?.phoneNumber ?? "")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                        }

                        Spacer()
                    }

                    if let email = conversation.parent?.email, !email.isEmpty {
                        ConversationDetailRow(label: "Email", value: email)
                    }
                    if let lastSeen = conversation.parent?.lastSeen, conversation.parent?.isOnline == false {
                        ConversationDetailRow(label: "Last seen", value: lastSeen.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                ConversationDetailSection(title: "Conversation") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ConversationDetailRow(label: "Status", value: conversation.status.rawValue.capitalized)
                        ConversationDetailRow(label: "Priority", value: conversation.priority.rawValue.capitalized)
                        ConversationDetailRow(label: "Handler", value: conversation.handledBy.rawValue.capitalized)
                        if let lastAt = conversation.lastMessageAt {
                            ConversationDetailRow(label: "Last message", value: lastAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        ConversationDetailRow(label: "Assigned to", value: assignmentLabel)
                    }
                }

                ConversationDetailSection(title: "Tags") {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        if tags.isEmpty {
                            Text("No tags yet")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: Spacing.sm)], alignment: .leading, spacing: Spacing.sm) {
                                ForEach(tags, id: \.self) { tag in
                                    TagChip(tag: tag) {
                                        removeTag(tag)
                                    }
                                }
                            }
                        }

                        HStack(spacing: Spacing.sm) {
                            TextField("Add tag", text: $newTag)
                                .textFieldStyle(.plain)
                                .font(.moltBodySmall)
                                .foregroundColor(.moltTextPrimary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 6)
                                .background(Color.moltSurfaceSecondary)
                                .cornerRadius(CornerRadius.small)

                            Button("Add") {
                                addTag()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.moltPrimary)
                            .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }

                ConversationDetailSection(title: "Notes") {
                    VStack(spacing: Spacing.sm) {
                        TextEditor(text: $notes)
                            .scrollContentBackground(.hidden)
                            .font(.moltBodySmall)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .frame(height: 90)
                            .padding(Spacing.sm)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)

                        Button("Save Notes") {
                            if let parentId = conversation.parent?.id {
                                appState.updateParentNotes(parentId: parentId, notes: notes)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.moltPrimary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .onAppear { syncFromConversation() }
        .onChange(of: conversation.id) { _ in syncFromConversation() }
        .onChange(of: tagKey) { _ in syncFromConversation() }
    }

    private var assignmentLabel: String {
        if let agentId = conversation.assignedAgentId {
            if agentId == appState.currentAgent?.id {
                return "You"
            }
            if let agent = appState.agents.first(where: { $0.id == agentId }) {
                return agent.name
            }
            return "Assigned"
        }
        if conversation.assignedTeamId != nil {
            return "Team Queue"
        }
        return "Unassigned"
    }

    private func syncFromConversation() {
        notes = conversation.parent?.notes ?? ""
        tags = conversation.tags ?? []
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !tags.contains(trimmed) {
            tags.append(trimmed)
            appState.updateConversationTags(conversationId: conversation.id, tags: tags)
        }
        newTag = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        appState.updateConversationTags(conversationId: conversation.id, tags: tags)
    }
}

struct ConversationDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.moltLabel)
                .foregroundColor(.moltTextSecondary)
            content
        }
    }
}

struct ConversationDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
            Spacer()
            Text(value)
                .font(.moltCaption)
                .foregroundColor(.moltTextSecondary)
        }
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.moltLabel)
                .foregroundColor(.moltPrimary)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundColor(.moltTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.moltPrimaryLight)
        .cornerRadius(CornerRadius.small)
    }
}
