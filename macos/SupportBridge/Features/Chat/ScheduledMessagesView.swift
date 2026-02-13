import SwiftUI

struct ScheduledMessagesView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateScheduled = false
    
    private var scheduledMessages: [ScheduledMessageData] {
        if appState.isAuthenticated {
            return appState.scheduledMessages
        }
        let creator = appState.currentAgent?.name ?? "Agent"
        return [
            ScheduledMessageData(id: "1", conversationId: "conv-3", content: "Follow-up: Have you received the refund?", scheduledFor: Date().addingTimeInterval(3600), createdBy: creator),
            ScheduledMessageData(id: "2", conversationId: "conv-6", content: "Reminder: Exam policy documentation attached", scheduledFor: Date().addingTimeInterval(86400), createdBy: "Mike Chen"),
            ScheduledMessageData(id: "3", conversationId: "conv-7", content: "Admission requirements checklist", scheduledFor: Date().addingTimeInterval(172800), createdBy: creator)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Scheduled Messages")
                    .font(.moltTitleLarge)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button(action: { showCreateScheduled = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                        Text("Schedule Message")
                    }
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.moltPrimary)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            // Scheduled Messages List
            if scheduledMessages.isEmpty {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.moltTextMuted)
                    
                    Text("No scheduled messages")
                        .font(.moltTitleSmall)
                        .foregroundColor(.moltTextSecondary)
                    
                    Text("Schedule messages to send later")
                        .font(.moltBody)
                        .foregroundColor(.moltTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.moltBackground)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(scheduledMessages) { message in
                            ScheduledMessageRow(message: message)
                        }
                    }
                    .padding(Spacing.lg)
                }
                .background(Color.moltBackground)
            }
        }
        .background(Color.moltSurface)
        .task {
            await appState.refreshScheduledMessages()
        }
        .sheet(isPresented: $showCreateScheduled) {
            Text("Schedule Message Sheet")
                .frame(width: 500, height: 600)
        }
    }
}

struct ScheduledMessageRow: View {
    let message: ScheduledMessageData
    @State private var isHovering = false
    
    var timeUntilSend: String {
        let interval = message.scheduledFor.timeIntervalSinceNow
        if interval < 3600 {
            return "in \(Int(interval / 60))m"
        } else if interval < 86400 {
            return "in \(Int(interval / 3600))h"
        } else {
            return "in \(Int(interval / 86400))d"
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Clock Icon
            ZStack {
                Circle()
                    .fill(Color.moltPrimary.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "clock.fill")
                    .foregroundColor(.moltPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                    .lineLimit(2)
                
                HStack(spacing: Spacing.sm) {
                    Label(message.scheduledFor.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                    
                    Text("•")
                        .foregroundColor(.moltTextMuted)
                    
                    Text(timeUntilSend)
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
            }
            
            Spacer()
            
            if isHovering {
                HStack(spacing: Spacing.xs) {
                    Button(action: {}) {
                        Image(systemName: "pencil")
                            .foregroundColor(.moltPrimary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        Image(systemName: "trash")
                            .foregroundColor(.priorityHigh)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.medium)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
