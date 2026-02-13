import SwiftUI

struct ConversationTimelineView: View {
    @EnvironmentObject var appState: AppState
    let conversationId: String
    
    // Mock timeline events - in production, generate from conversation history
    var events: [TimelineEventData] {
        let agentName = appState.currentAgent?.name ?? "Agent"
        return [
            TimelineEventData(type: .created, title: "Conversation Created", description: "Initiated by parent", time: Date().addingTimeInterval(-86400), icon: "plus.circle.fill", color: .priorityMedium),
            TimelineEventData(type: .message, title: "First Message", description: "What are the school hours?", time: Date().addingTimeInterval(-86300), icon: "bubble.left.fill", color: .moltPrimary),
            TimelineEventData(type: .assigned, title: "Assigned to Agent", description: agentName, time: Date().addingTimeInterval(-85000), icon: "person.badge.plus.fill", color: .priorityHigh),
            TimelineEventData(type: .statusChange, title: "Status Changed", description: "Open → Pending", time: Date().addingTimeInterval(-82000), icon: "arrow.triangle.2.circlepath", color: .priorityMedium),
            TimelineEventData(type: .note, title: "Note Added", description: "Checked with admin team", time: Date().addingTimeInterval(-75600), icon: "note.text", color: .priorityLow),
            TimelineEventData(type: .resolved, title: "Resolved", description: "Issue resolved successfully", time: Date().addingTimeInterval(-72000), icon: "checkmark.circle.fill", color: .priorityLow)
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Timeline")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            
            SubtleDivider()
            
            // Timeline
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(events.indices, id: \.self) { index in
                        TimelineEventRow(event: events[index], isLast: index == events.count - 1)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.moltBackground)
        }
        .frame(width: 320)
        .background(Color.moltSurface)
    }
}

struct TimelineEventData: Identifiable {
    let id = UUID()
    let type: TimelineEventType
    let title: String
    let description: String
    let time: Date
    let icon: String
    let color: Color
}

enum TimelineEventType {
    case created, message, assigned, statusChange, priorityChange, note, taskCreated, resolved
}

struct TimelineEventRow: View {
    let event: TimelineEventData
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timeline Line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: event.icon)
                        .font(.system(size: 14))
                        .foregroundColor(event.color)
                }
                
                if !isLast {
                    Rectangle()
                        .fill(Color.moltSurfaceSecondary)
                        .frame(width: 2)
                        .padding(.top, 4)
                }
            }
            
            // Event Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.moltBody)
                    .fontWeight(.medium)
                    .foregroundColor(.moltTextPrimary)
                
                Text(event.description)
                    .font(.moltBody)
                    .foregroundColor(.moltTextMuted)
                
                Text(event.time.formatted(date: .abbreviated, time: .shortened))
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            .padding(.bottom, Spacing.lg)
            
            Spacer()
        }
    }
}
