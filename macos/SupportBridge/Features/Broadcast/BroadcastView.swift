import SwiftUI

// MARK: - Broadcast View
struct BroadcastView: View {
    @EnvironmentObject var appState: AppState
    @State private var showComposer = false
    @State private var selectedBroadcast: BroadcastMessage?

    private var broadcasts: [BroadcastMessage] {
        if appState.isAuthenticated {
            return appState.broadcasts
        }
        return BroadcastMessage.mockList
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Broadcast Messages")
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    Text("Send messages to multiple parents at once")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                
                Spacer()
                
                Button(action: { showComposer = true }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus")
                        Text("New Broadcast")
                    }
                    .font(.moltBody)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.moltPrimary)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
            .appHeaderAligned()
            
            SubtleDivider()
            
            // Broadcast List
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(broadcasts) { broadcast in
                        BroadcastCard(broadcast: broadcast) {
                            selectedBroadcast = broadcast
                        }
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .background(Color.moltBackground)
        .sheet(isPresented: $showComposer) {
            BroadcastComposer(isPresented: $showComposer) { draft in
                _Concurrency.Task {
                    do {
                        _ = try await appState.createBroadcast(
                            title: draft.title,
                            content: draft.content,
                            recipientFilter: draft.recipientFilter,
                            scheduledAt: nil
                        )
                    } catch {
                        print("Failed to save broadcast: \(error)")
                    }
                }
            } onSend: { broadcast in
                _Concurrency.Task {
                    do {
                        let created = try await appState.createBroadcast(
                            title: broadcast.title,
                            content: broadcast.content,
                            recipientFilter: broadcast.recipientFilter,
                            scheduledAt: broadcast.scheduledAt
                        )
                        if broadcast.status == .sending {
                            try await appState.sendBroadcast(id: created.id)
                        }
                    } catch {
                        print("Failed to send broadcast: \(error)")
                    }
                }
            }
        }
        .sheet(item: $selectedBroadcast) { broadcast in
            BroadcastDetailView(broadcast: broadcast, isPresented: .constant(true))
        }
        .task {
            await appState.refreshBroadcasts()
        }
    }
}

// MARK: - Broadcast Card
struct BroadcastCard: View {
    let broadcast: BroadcastMessage
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    // Status Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(broadcast.status.rawValue.capitalized)
                            .font(.moltCaption)
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(CornerRadius.small)
                    
                    Spacer()
                    
                    // Date
                    if let date = broadcast.sentAt ?? broadcast.scheduledAt {
                        Text(formatDate(date))
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                }
                
                Text(broadcast.title)
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.moltTextPrimary)
                
                Text(broadcast.content)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
                    .lineLimit(2)
                
                SubtleDivider()
                
                // Stats
                HStack(spacing: Spacing.lg) {
                    StatLabel(icon: "person.2", value: "\(broadcast.recipientCount)", label: "Recipients")
                    StatLabel(icon: "checkmark.circle", value: "\(broadcast.deliveredCount)", label: "Delivered")
                    StatLabel(icon: "eye", value: "\(broadcast.readCount)", label: "Read")
                }
            }
            .padding(Spacing.lg)
            .background(Color.moltSurface)
            .cornerRadius(CornerRadius.large)
        }
        .buttonStyle(.plain)
    }
    
    var statusColor: Color {
        switch broadcast.status {
        case .draft: return .moltTextMuted
        case .scheduled: return .priorityMedium
        case .sending: return .moltPrimary
        case .sent: return .priorityLow
        case .failed: return .priorityUrgent
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Stat Label
struct StatLabel: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.moltTextMuted)
            Text(value)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
            Text(label)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
    }
}

// MARK: - Broadcast Composer
struct BroadcastComposer: View {
    @Binding var isPresented: Bool
    let onSaveDraft: (BroadcastMessage) -> Void
    let onSend: (BroadcastMessage) -> Void
    @State private var title = ""
    @State private var content = ""
    @State private var recipientFilter: BroadcastMessage.RecipientFilter = .all
    @State private var scheduleDate: Date = Date()
    @State private var isScheduled = false
    @State private var showTemplates = false
    @State private var isSending = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Broadcast")
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Title
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Title")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        TextField("Broadcast title", text: $title)
                            .textFieldStyle(.plain)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }
                    
                    // Recipients
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Recipients")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        HStack(spacing: Spacing.sm) {
                            RecipientOption(title: "All Parents", icon: "person.3", isSelected: recipientFilter == .all) {
                                recipientFilter = .all
                            }
                            RecipientOption(title: "By Class", icon: "square.grid.2x2", isSelected: recipientFilter == .byClass) {
                                recipientFilter = .byClass
                            }
                            RecipientOption(title: "Custom", icon: "person.crop.rectangle.stack", isSelected: recipientFilter == .custom) {
                                recipientFilter = .custom
                            }
                        }
                    }
                    
                    // Message Content
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Message")
                                .font(.moltLabel)
                                .foregroundColor(.moltTextSecondary)
                            Spacer()
                            Button(action: { showTemplates = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Use Template")
                                }
                                .font(.moltCaption)
                                .foregroundColor(.moltPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        TextEditor(text: $content)
                            .scrollContentBackground(.hidden)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .frame(height: 150)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }
                    
                    // Schedule Toggle
                    Toggle(isOn: $isScheduled) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.moltPrimary)
                            Text("Schedule for later")
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(.moltPrimary)
                    
                    if isScheduled {
                        DatePicker("Send Date", selection: $scheduleDate, displayedComponents: [.date, .hourAndMinute])
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltPrimary)
                    }
                }
                .padding(Spacing.lg)
            }
            
            SubtleDivider()
            
            // Actions
            HStack(spacing: Spacing.md) {
                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.moltSurfaceSecondary)
                        .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                
                Button(action: saveDraft) {
                    Text("Save Draft")
                        .font(.moltBody)
                        .foregroundColor(.moltPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.moltPrimaryLight)
                        .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                
                Button(action: sendBroadcast) {
                    HStack(spacing: Spacing.sm) {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                .scaleEffect(0.85)
                        }
                        Text(isScheduled ? "Schedule" : "Send Now")
                            .font(.moltBody)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(canSend ? Color.moltPrimary : Color.moltTextMuted)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(!canSend || isSending)
            }
            .padding(Spacing.lg)
        }
        .frame(width: 550, height: 650)
        .background(Color.moltBackground)
        .sheet(isPresented: $showTemplates) {
            BroadcastTemplatePicker(templates: BroadcastTemplate.mockList) { template in
                title = template.title
                content = template.content
                showTemplates = false
            }
        }
    }
    
    var canSend: Bool {
        !title.isEmpty && !content.isEmpty
    }
    
    func saveDraft() {
        let draft = buildBroadcast(status: .draft)
        onSaveDraft(draft)
        isPresented = false
    }
    
    func sendBroadcast() {
        let status: BroadcastMessage.BroadcastStatus = isScheduled ? .scheduled : .sending
        let broadcast = buildBroadcast(status: status)
        isSending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onSend(broadcast)
            isSending = false
            isPresented = false
        }
    }
    
    func buildBroadcast(status: BroadcastMessage.BroadcastStatus) -> BroadcastMessage {
        let now = Date()
        let recipients: Int
        switch recipientFilter {
        case .all: recipients = 450
        case .byClass: recipients = 120
        case .byGrade: recipients = 180
        case .custom: recipients = 60
        }
        return BroadcastMessage(
            id: UUID().uuidString,
            title: title,
            content: content,
            recipientFilter: recipientFilter,
            scheduledAt: isScheduled ? scheduleDate : nil,
            sentAt: status == .sent ? now : nil,
            status: status,
            recipientCount: recipients,
            deliveredCount: 0,
            readCount: 0
        )
    }
}

// MARK: - Broadcast Template
struct BroadcastTemplate: Identifiable {
    let id: String
    let title: String
    let content: String
    
    static let mockList: [BroadcastTemplate] = [
        BroadcastTemplate(
            id: "bt-1",
            title: "School Resumption Notice",
            content: "Dear Parents, this is to remind you that school resumes on January 6th, 2026. Please ensure all students arrive by 7:30 AM for orientation."
        ),
        BroadcastTemplate(
            id: "bt-2",
            title: "Fee Payment Reminder",
            content: "Kindly note that school fees are due by January 15th. Payments can be made via bank transfer or the online portal."
        ),
        BroadcastTemplate(
            id: "bt-3",
            title: "PTA Meeting Invitation",
            content: "You are invited to the PTA meeting scheduled for Friday at 4 PM in the school hall. We look forward to your attendance."
        ),
        BroadcastTemplate(
            id: "bt-4",
            title: "Public Holiday Announcement",
            content: "Please note that the school will be closed on the upcoming public holiday. Classes resume the next business day."
        )
    ]
}

// MARK: - Broadcast Template Picker
struct BroadcastTemplatePicker: View {
    let templates: [BroadcastTemplate]
    let onSelect: (BroadcastTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Broadcast Templates")
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.moltTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(templates) { template in
                        Button(action: {
                            onSelect(template)
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(template.title)
                                    .font(.moltBody)
                                    .fontWeight(.medium)
                                    .foregroundColor(.moltTextPrimary)
                                Text(template.content)
                                    .font(.moltCaption)
                                    .foregroundColor(.moltTextSecondary)
                                    .lineLimit(2)
                            }
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .frame(width: 500, height: 420)
        .background(Color.moltBackground)
    }
}

// MARK: - Recipient Option
struct RecipientOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
                Text(title)
                    .font(.moltCaption)
                    .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(isSelected ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? Color.moltPrimary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Broadcast Detail View
struct BroadcastDetailView: View {
    let broadcast: BroadcastMessage
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Broadcast Details")
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(broadcast.title)
                        .font(.moltTitleSmall)
                        .foregroundColor(.moltTextPrimary)
                    
                    Text(broadcast.content)
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                    
                    SubtleDivider()
                    
                    // Stats
                    HStack(spacing: Spacing.xl) {
                        DetailStat(value: "\(broadcast.recipientCount)", label: "Recipients")
                        DetailStat(value: "\(broadcast.deliveredCount)", label: "Delivered")
                        DetailStat(value: "\(broadcast.readCount)", label: "Read")
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .frame(width: 450, height: 400)
        .background(Color.moltBackground)
    }
}

// MARK: - Detail Stat
struct DetailStat: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.moltTitleMedium)
                .foregroundColor(.moltPrimary)
            Text(label)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
        }
    }
}
