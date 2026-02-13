import SwiftUI

// MARK: - Forward Message Sheet
struct ForwardMessageSheet: View {
    let message: Message
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedContacts: Set<String> = []
    @State private var note = ""
    @State private var isSending = false
    @State private var sendError: String?
    
    var filteredConversations: [Conversation] {
        let source = appState.conversations
            .filter { $0.id != message.conversationId }
            .sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }

        if searchText.isEmpty {
            return source
        }
        return source.filter { conv in
            (conv.parent?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (conv.parent?.phoneNumber.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("Forward to")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button(action: forwardMessage) {
                    HStack(spacing: Spacing.xs) {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                .scaleEffect(0.8)
                        }
                        Text("Send")
                            .font(.moltBody)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedContacts.isEmpty || isSending ? .moltTextMuted : .moltPrimary)
                }
                .buttonStyle(.plain)
                .disabled(selectedContacts.isEmpty || isSending)
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Message Preview
            HStack(spacing: Spacing.md) {
                Image(systemName: "arrowshape.turn.up.forward.fill")
                    .foregroundColor(.moltTextMuted)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Forwarding message")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                    Text(message.content)
                        .font(.moltBodySmall)
                        .foregroundColor(.moltTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(Spacing.md)
            .background(Color.moltSurfaceSecondary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Optional note")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                TextField("Add context for recipients...", text: $note)
                    .textFieldStyle(.plain)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                    .padding(Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                    .disabled(isSending)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
            
            // Search
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.moltTextMuted)
                
                TextField("Search contacts...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.moltBody)
            }
            .padding(Spacing.sm)
            .background(Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
            .padding(Spacing.md)

            if let sendError {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.priorityHigh)
                    Text(sendError)
                        .font(.moltCaption)
                        .foregroundColor(.priorityHigh)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.priorityHigh.opacity(0.08))
                .cornerRadius(CornerRadius.medium)
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
            
            // Selected contacts chips
            if !selectedContacts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(Array(selectedContacts), id: \.self) { contactId in
                            if let contact = findContact(id: contactId) {
                                SelectedContactChip(contact: contact) {
                                    selectedContacts.remove(contactId)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .frame(height: 40)
                
                SubtleDivider()
            }
            
            // Contact List
            ScrollView {
                LazyVStack(spacing: 0) {
                    // All Contacts Section
                    if searchText.isEmpty {
                        Text("All Contacts")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .padding(.top, Spacing.md)
                            .padding(.bottom, Spacing.sm)
                    }
                    
                    ForEach(filteredConversations) { conv in
                        ForwardContactRow(
                            conversation: conv,
                            isSelected: selectedContacts.contains(conv.id)
                        ) {
                            if !isSending {
                                if selectedContacts.contains(conv.id) {
                                    selectedContacts.remove(conv.id)
                                } else {
                                    selectedContacts.insert(conv.id)
                                }
                            }
                        }
                        
                        SubtleDivider()
                            .padding(.leading, 64)
                    }
                }
            }
            .background(Color.moltSurface)
        }
        .frame(width: 400, height: 500)
        .background(Color.moltBackground)
    }
    
    func findContact(id: String) -> Conversation? {
        appState.conversations.first { $0.id == id }
    }
    
    func forwardMessage() {
        guard !selectedContacts.isEmpty else { return }
        guard !isSending else { return }
        isSending = true
        sendError = nil

        _Concurrency.Task {
            do {
                let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                try await appState.forwardMessage(
                    messageId: message.id,
                    toConversationIDs: Array(selectedContacts),
                    note: trimmedNote.isEmpty ? nil : trimmedNote
                )
                await MainActor.run {
                    isSending = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    sendError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Forward Contact Row
struct ForwardContactRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.moltPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Text(conversation.parent?.name.prefix(1).uppercased() ?? "?")
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.moltPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.parent?.name ?? "Unknown")
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.moltTextPrimary)
                    
                    if let preview = conversation.lastMessagePreview {
                        Text(preview)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.moltPrimary : Color.moltDivider, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.moltPrimary)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Contact Chip
struct SelectedContactChip: View {
    let contact: Conversation
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(contact.parent?.name ?? "Unknown")
                .font(.moltCaption)
                .foregroundColor(.moltTextPrimary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.moltTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.moltSurfaceSecondary)
        .cornerRadius(16)
    }
}

// MARK: - Forward Button (for context menu)
struct ForwardMessageButton: View {
    let message: Message
    @State private var showSheet = false
    
    var body: some View {
        Button(action: { showSheet = true }) {
            Label("Forward", systemImage: "arrowshape.turn.up.forward")
        }
        .sheet(isPresented: $showSheet) {
            ForwardMessageSheet(message: message, isPresented: $showSheet)
        }
    }
}
