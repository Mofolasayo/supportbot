import SwiftUI

// MARK: - Customer Profile Popup
struct CustomerProfilePopup: View {
    let parent: Parent
    let conversations: [Conversation]
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var notes = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with avatar
            VStack(spacing: Spacing.md) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.moltTextMuted)
                    }
                    .buttonStyle(.plain)
                }
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.moltPrimary, .moltPrimary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Text(parent.name.prefix(1))
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Name
                Text(parent.name)
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                
                // Contact Info
                HStack(spacing: Spacing.lg) {
                    ContactBadge(icon: "phone.fill", value: parent.phoneNumber)
                    if let email = parent.email {
                        ContactBadge(icon: "envelope.fill", value: email)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Children/Students
                    if let students = parent.studentNames, !students.isEmpty {
                        ProfileSection(title: "Children/Students", icon: "person.2.fill") {
                            VStack(spacing: Spacing.sm) {
                                ForEach(students, id: \.self) { student in
                                    StudentRow(name: student)
                                }
                            }
                        }
                    }
                    
                    // Conversation History Summary
                    ProfileSection(title: "Conversation History", icon: "bubble.left.and.bubble.right.fill") {
                        VStack(spacing: Spacing.sm) {
                            HStack {
                                StatBox(value: "\(parentConversations.count)", label: "Total Chats")
                                StatBox(value: "\(openConversations.count)", label: "Open")
                                StatBox(value: "\(resolvedConversations.count)", label: "Resolved")
                            }
                            
                            if !parentConversations.isEmpty {
                                SubtleDivider()
                                    .padding(.vertical, Spacing.sm)
                                
                                ForEach(parentConversations.prefix(3)) { conv in
                                    ConversationSummaryRow(conversation: conv)
                                }
                            }
                        }
                    }

                    // Shared Media
                    ProfileSection(title: "Shared Media", icon: "photo.on.rectangle") {
                        if sharedMedia.isEmpty {
                            Text("No shared images yet")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                                .padding(Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.moltSurfaceSecondary)
                                .cornerRadius(CornerRadius.medium)
                        } else {
                            SharedMediaGrid(messages: sharedMedia)
                        }
                    }
                    
                    // Notes
                    ProfileSection(title: "Notes", icon: "note.text") {
                        TextEditor(text: $notes)
                            .scrollContentBackground(.hidden)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .frame(height: 80)
                            .padding(Spacing.sm)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }
                    
                    // Quick Actions
                    ProfileSection(title: "Quick Actions", icon: "bolt.fill") {
                        HStack(spacing: Spacing.sm) {
                            ProfileActionButton(icon: "phone.fill", label: "Call", color: .priorityLow) { }
                            ProfileActionButton(icon: "message.fill", label: "New Chat", color: .moltPrimary) { }
                            ProfileActionButton(icon: "flag.fill", label: "Flag", color: .priorityHigh) { }
                        }
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .frame(width: 420, height: 600)
        .background(Color.moltBackground)
        .cornerRadius(CornerRadius.large)
        .shadow(color: Color.black.opacity(0.25), radius: 30)
        .onAppear {
            parentConversations.forEach { conversation in
                appState.ensureMessagesLoaded(for: conversation.id)
            }
        }
    }
    
    var parentConversations: [Conversation] {
        conversations.filter { $0.parentId == parent.id }
    }
    
    var openConversations: [Conversation] {
        parentConversations.filter { $0.status == .open || $0.status == .pending }
    }
    
    var resolvedConversations: [Conversation] {
        parentConversations.filter { $0.status == .resolved }
    }

    var sharedMedia: [Message] {
        parentConversations.flatMap { conversation in
            appState.messages(for: conversation.id)
        }
        .filter { $0.senderType == .parent && $0.messageType == .image }
    }
}

// MARK: - Contact Badge
struct ContactBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.moltPrimary)
            Text(value)
                .font(.moltCaption)
                .foregroundColor(.moltTextSecondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.moltSurfaceSecondary)
        .cornerRadius(CornerRadius.small)
    }
}

// MARK: - Profile Section
struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.moltPrimary)
                Text(title)
                    .font(.moltLabel)
                    .foregroundColor(.moltTextSecondary)
            }
            
            content
        }
    }
}

// MARK: - Student Row
struct StudentRow: View {
    let name: String
    
    var body: some View {
        HStack {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 14))
                .foregroundColor(.moltPrimary)
            Text(name)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
            Spacer()
            Text("Grade 7A")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
        .padding(Spacing.sm)
        .background(Color.moltSurfaceSecondary)
        .cornerRadius(CornerRadius.medium)
    }
}

// MARK: - Shared Media Grid
struct SharedMediaGrid: View {
    let messages: [Message]
    private let columns = [GridItem(.adaptive(minimum: 90), spacing: Spacing.sm)]
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.sm) {
            ForEach(messages) { message in
                SharedMediaTile(message: message)
            }
        }
        .padding(.top, Spacing.xs)
    }
}

struct SharedMediaTile: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(Color.moltSurfaceSecondary)
                    .frame(height: 70)
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.moltPrimary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(Color.moltBorder, lineWidth: 1)
            )
            
            Text(label)
                .font(.moltCaption)
                .foregroundColor(.moltTextSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var iconName: String {
        if message.imageUrl?.contains("receipt") == true { return "doc.text.image" }
        if message.imageUrl?.contains("bank") == true { return "building.columns" }
        if message.imageUrl?.contains("medical") == true { return "cross.case" }
        return "photo"
    }
    
    var label: String {
        guard let key = message.imageUrl, !key.isEmpty else { return "Image" }
        return key.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.moltTitleSmall)
                .foregroundColor(.moltPrimary)
            Text(label)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(Color.moltSurfaceSecondary)
        .cornerRadius(CornerRadius.medium)
    }
}

// MARK: - Conversation Summary Row
struct ConversationSummaryRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(conversation.lastMessagePreview ?? "No preview")
                .font(.moltCaption)
                .foregroundColor(.moltTextSecondary)
                .lineLimit(1)
            
            Spacer()
            
            Text(timeAgo)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
    }
    
    var statusColor: Color {
        switch conversation.status {
        case .open: return .priorityLow
        case .pending: return .priorityMedium
        case .resolved: return .moltTextMuted
        case .closed: return .moltTextMuted
        }
    }
    
    var timeAgo: String {
        guard let date = conversation.lastMessageAt else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Profile Action Button
struct ProfileActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Text(label)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}
