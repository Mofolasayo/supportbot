import SwiftUI

struct AISuggestionsPanel: View {
    let conversation: Conversation
    @EnvironmentObject var appState: AppState
    @State private var suggestedReply = ""
    @State private var isEditing = false
    @State private var showEscalationSheet = false
    @State private var showForwardSheet = false
    @State private var isLoadingInsight = false
    @State private var isTogglingAI = false
    @State private var panelError: String?

    private var currentConversation: Conversation {
        appState.conversations.first(where: { $0.id == conversation.id }) ?? conversation
    }

    private var insight: ConversationAssistantInsight? {
        appState.assistantInsights[conversation.id]
    }

    private var isAIDisabled: Bool {
        !currentConversation.isAIEnabled
    }

    private var supportMembers: [AgentWithWorkload] {
        guard !appState.agents.isEmpty else { return [] }
        return appState.agents.map { agent in
            let activeCount = appState.conversations.filter {
                $0.assignedAgentId == agent.id &&
                ($0.status == .open || $0.status == .pending)
            }.count

            return AgentWithWorkload(
                id: agent.id,
                name: agent.name,
                email: agent.email,
                teamId: agent.teamId ?? "",
                status: agent.status,
                activeConversations: activeCount,
                maxCapacity: 8,
                avatarInitial: agent.avatarInitial
            )
        }
        .sorted { lhs, rhs in
            if lhs.activeConversations == rhs.activeConversations {
                return lhs.name < rhs.name
            }
            return lhs.activeConversations < rhs.activeConversations
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundColor(isAIDisabled ? .moltTextMuted : .moltPrimary)
                        Text("AI Assistant")
                            .font(.moltTitleSmall)
                            .foregroundColor(.moltTextPrimary)
                    }
                    
                    Spacer()
                    
                    if isAIDisabled {
                        Text("Disabled")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.small)
                    }
                }
                .padding(.bottom, Spacing.sm)

                if let panelError {
                    Text(panelError)
                        .font(.moltCaption)
                        .foregroundColor(.priorityHigh)
                        .padding(Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.priorityHigh.opacity(0.08))
                        .cornerRadius(CornerRadius.small)
                }

                if isLoadingInsight && insight == nil {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                        Text("Analyzing latest messages...")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextSecondary)
                    }
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.small)
                } else if isAIDisabled {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .foregroundColor(.moltPrimary)
                            Text("Manual Assist Mode")
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                        }

                        Text("AI automation is disabled for this chat. You can still use a suggested reply, then edit before sending.")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextSecondary)

                        suggestedReplySection

                        Button(action: { toggleAI(enabled: true) }) {
                            HStack(spacing: Spacing.sm) {
                                if isTogglingAI {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                        .scaleEffect(0.8)
                                }
                                Text("Enable Full AI Analysis")
                                    .font(.moltBodySmall)
                                    .foregroundColor(.moltPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.moltPrimaryLight)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTogglingAI)
                    }
                } else {
                    // Analysis Cards
                    VStack(spacing: Spacing.md) {
                        AnalysisCard(
                            title: "Detected Intent",
                            value: insight?.intent ?? "Not available yet",
                            icon: "lightbulb.fill",
                            color: .moltPrimary
                        )
                        
                        AnalysisCard(
                            title: "Sentiment",
                            value: insight?.sentiment ?? "Not available yet",
                            icon: sentimentIcon(),
                            color: sentimentColor()
                        )
                        
                        AnalysisCard(
                            title: "Urgency",
                            value: insight?.urgency ?? "Not available yet",
                            icon: "clock.fill",
                            color: urgencyColor()
                        )
                        
                        AnalysisCard(
                            title: "Confidence",
                            value: insight.map { "\(Int($0.confidence * 100))%" } ?? "Not available yet",
                            icon: "chart.bar.fill",
                            color: confidenceColor()
                        )
                    }
                    
                    SubtleDivider()
                    
                    // Context Summary
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Context Summary")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        Text(insight?.contextSummary ?? "Insight will appear after parent messages are synced.")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextSecondary)
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.small)
                        
                        // Keywords
                        if let keywords = insight?.keywords, !keywords.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(keywords, id: \.self) { keyword in
                                        Text(keyword)
                                            .font(.moltCaption)
                                            .foregroundColor(.moltPrimary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.moltPrimaryLight)
                                            .cornerRadius(CornerRadius.small)
                                    }
                                }
                            }
                        }
                    }
                    
                    SubtleDivider()
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Quick Actions")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        QuickActionButton(
                            icon: "arrow.up.circle",
                            label: "Escalate to Support",
                            color: .priorityHigh
                        ) {
                            showEscalationSheet = true
                            _Concurrency.Task {
                                await appState.refreshAgents()
                            }
                        }
                        
                        QuickActionButton(
                            icon: "person.3.fill",
                            label: "Forward to Team",
                            color: .moltPrimary
                        ) { showForwardSheet = true }
                        
                        QuickActionButton(
                            icon: "cpu.fill",
                            label: "Disable AI for this chat",
                            color: .moltTextSecondary
                        ) { toggleAI(enabled: false) }
                    }
                }
                
                Spacer()
            }
            .padding(Spacing.lg)
        }
        .background(Color.moltSurface)
        .onAppear {
            refreshInsight()
            _Concurrency.Task {
                if appState.teams.isEmpty {
                    await appState.refreshTeams()
                }
                if appState.agents.isEmpty {
                    await appState.refreshAgents()
                }
            }
        }
        .onChange(of: conversation.id) { _ in
            refreshInsight()
        }
        .sheet(isPresented: $showEscalationSheet) {
            CustomerSupportEscalationSheet(
                conversation: conversation,
                isPresented: $showEscalationSheet,
                team: nil,
                members: supportMembers
            )
        }
        .sheet(isPresented: $showForwardSheet) {
            ForwardToTeamSheet(
                conversation: conversation,
                teams: appState.teams.filter { $0.id != currentConversation.assignedTeamId }
            )
        }
    }
    
    private var suggestedReplySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Suggested Reply")
                    .font(.moltLabel)
                    .foregroundColor(.moltTextSecondary)
                Spacer()
                Button(action: { isEditing.toggle() }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.moltCaption)
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }

            if isEditing {
                TextEditor(text: $suggestedReply)
                    .scrollContentBackground(.hidden)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                    .tint(.moltTextPrimary)
                    .frame(minHeight: 110)
                    .padding(Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
            } else {
                Text(suggestedReply.isEmpty ? "No suggestion available yet." : suggestedReply)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.bubbleBot)
                    .cornerRadius(CornerRadius.medium)
            }

            HStack(spacing: Spacing.sm) {
                Button(action: sendSuggestedReply) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send")
                    }
                    .font(.moltBody)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.moltPrimary)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)

                Button(action: { isEditing = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.moltBody)
                    .foregroundColor(.moltPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.moltPrimaryLight)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
        }
    }

    func sendSuggestedReply() {
        let trimmed = suggestedReply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _Concurrency.Task {
            await appState.sendMessage(conversationId: conversation.id, content: trimmed)
            await MainActor.run {
                isEditing = false
            }
            await appState.fetchAssistantInsight(for: conversation.id)
        }
    }

    func refreshInsight() {
        isLoadingInsight = true
        panelError = nil
        _Concurrency.Task {
            await appState.fetchAssistantInsight(for: conversation.id)
            await MainActor.run {
                isLoadingInsight = false
                if let latest = insight {
                    if !isEditing || suggestedReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        suggestedReply = latest.suggestedReply
                    }
                }
            }
        }
    }

    func toggleAI(enabled: Bool) {
        guard !isTogglingAI else { return }
        isTogglingAI = true
        panelError = nil
        _Concurrency.Task {
            do {
                try await appState.setConversationAIEnabled(conversationId: conversation.id, enabled: enabled)
            } catch {
                await MainActor.run {
                    panelError = error.localizedDescription
                }
            }
            await MainActor.run {
                isTogglingAI = false
            }
        }
    }

    func sentimentIcon() -> String {
        switch insight?.sentiment.lowercased() {
        case "negative": return "exclamationmark.triangle.fill"
        case "positive": return "face.smiling.fill"
        default: return "minus.circle"
        }
    }
    
    func sentimentColor() -> Color {
        switch insight?.sentiment.lowercased() {
        case "negative": return .priorityHigh
        case "positive": return .priorityLow
        default: return .moltPrimary
        }
    }
    
    func urgencyColor() -> Color {
        switch insight?.urgency.lowercased() {
        case "urgent": return .priorityUrgent
        case "high": return .priorityHigh
        case "low": return .priorityLow
        default: return .priorityMedium
        }
    }
    
    func confidenceColor() -> Color {
        let confidence = insight?.confidence ?? 0.65
        if confidence >= 0.9 { return .priorityLow }
        if confidence >= 0.75 { return .moltPrimary }
        return .priorityHigh
    }
}

// MARK: - Customer Support Escalation Sheet
struct CustomerSupportEscalationSheet: View {
    let conversation: Conversation
    @Binding var isPresented: Bool
    let team: Team?
    let members: [AgentWithWorkload]
    @EnvironmentObject var appState: AppState
    @State private var selectedMember: AgentWithWorkload?
    @State private var reason = ""
    @State private var isEscalating = false
    @State private var didEscalate = false
    @State private var actionError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Escalate to Customer Support")
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.moltTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    HStack(spacing: Spacing.md) {
                        Circle()
                            .fill(Color.moltSurfaceSecondary)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(conversation.parent?.name.prefix(1) ?? "?")
                                    .font(.moltBody)
                                    .foregroundColor(.moltTextSecondary)
                            )
                        VStack(alignment: .leading) {
                            Text(conversation.parent?.name ?? "Unknown")
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                            Text(conversation.lastMessagePreview ?? "")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                    
                    if isEscalating {
                        HStack(spacing: Spacing.sm) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                .scaleEffect(0.9)
                            Text("Assigning to support...")
                                .font(.moltBodySmall)
                                .foregroundColor(.moltTextSecondary)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.moltPrimaryLight)
                        .cornerRadius(CornerRadius.medium)
                    }
                    
                    if didEscalate {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.priorityLow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Assigned to Customer Support")
                                    .font(.moltBody)
                                    .foregroundColor(.moltTextPrimary)
                                Text("The support team has been notified.")
                                    .font(.moltCaption)
                                    .foregroundColor(.moltTextMuted)
                            }
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.priorityLow.opacity(0.1))
                        .cornerRadius(CornerRadius.medium)
                    }

                    if let actionError {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.priorityHigh)
                            Text(actionError)
                                .font(.moltCaption)
                                .foregroundColor(.priorityHigh)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.priorityHigh.opacity(0.08))
                        .cornerRadius(CornerRadius.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Customer Support Members")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)

                        if members.isEmpty {
                            Text("No agent accounts found yet.")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                                .padding(Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.moltSurfaceSecondary)
                                .cornerRadius(CornerRadius.medium)
                        } else {
                            ForEach(members) { member in
                                MemberSelectionRow(
                                    member: member,
                                    isSelected: selectedMember?.id == member.id
                                ) {
                                    selectedMember = member
                                }
                                .disabled(isEscalating || didEscalate)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Reason for Escalation")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        TextEditor(text: $reason)
                            .scrollContentBackground(.hidden)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .frame(minHeight: 120)
                            .padding(Spacing.sm)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                            .disabled(isEscalating || didEscalate)
                    }
                }
                .padding(Spacing.lg)
            }
            
            SubtleDivider()
            
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
                .disabled(isEscalating)
                
                Button(action: {
                    if didEscalate {
                        isPresented = false
                    } else {
                        escalate()
                    }
                }) {
                    HStack(spacing: Spacing.sm) {
                        if isEscalating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                .scaleEffect(0.85)
                        }
                        Text(didEscalate ? "Done" : "Assign")
                            .font(.moltBody)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.priorityHigh)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(isEscalating || members.isEmpty)
            }
            .padding(Spacing.lg)
        }
        .frame(width: 460, height: 580)
        .background(Color.moltBackground)
        .onAppear {
            syncSelectedMember()
            _Concurrency.Task {
                await appState.refreshAgents()
            }
        }
        .onChange(of: members.map(\.id)) { _ in
            syncSelectedMember()
        }
    }
    
    func escalate() {
        guard !isEscalating else { return }
        guard let selectedMember else {
            actionError = "Select an agent before assigning."
            return
        }

        actionError = nil
        isEscalating = true

        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let escalationReason = trimmedReason.isEmpty
            ? "Customer requires specialist support follow-up."
            : trimmedReason
        let destinationTeamId = team?.id

        _Concurrency.Task {
            do {
                try await appState.forwardConversation(
                    conversationId: conversation.id,
                    teamId: destinationTeamId,
                    agentId: selectedMember.id
                )
                try await appState.createEscalation(
                    conversationId: conversation.id,
                    reason: escalationReason,
                    aiSummary: "Escalated from AI assistant quick actions.",
                    priority: conversation.priority,
                    toTeamId: destinationTeamId,
                    toAgentId: selectedMember.id
                )
                await appState.createTask(
                    title: "Follow up with \(conversation.parent?.name ?? "parent")",
                    description: escalationReason,
                    assignedToId: selectedMember.id,
                    conversationId: conversation.id,
                    priority: conversation.priority,
                    dueDate: nil,
                    tags: ["escalated", "support"]
                )
                await appState.refreshConversations(showLoading: false)
                await appState.refreshEscalations()
                await appState.refreshTasks()
                await MainActor.run {
                    isEscalating = false
                    didEscalate = true
                }
            } catch {
                await MainActor.run {
                    isEscalating = false
                    actionError = error.localizedDescription
                }
            }
        }
    }

    private func syncSelectedMember() {
        guard !members.isEmpty else {
            selectedMember = nil
            return
        }

        guard let selectedMember else {
            self.selectedMember = members.first
            return
        }

        if !members.contains(where: { $0.id == selectedMember.id }) {
            self.selectedMember = members.first
        }
    }
}

// MARK: - Forward To Team Sheet
struct ForwardToTeamSheet: View {
    let conversation: Conversation
    let teams: [Team]
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeam: Team?
    @State private var reason = ""
    @State private var isForwarding = false
    @State private var didForward = false
    @State private var forwardedTeamName = ""
    @State private var actionError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Forward to Team")
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.moltTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    HStack(spacing: Spacing.md) {
                        Circle()
                            .fill(Color.moltSurfaceSecondary)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(conversation.parent?.name.prefix(1) ?? "?")
                                    .font(.moltBody)
                                    .foregroundColor(.moltTextSecondary)
                            )
                        VStack(alignment: .leading) {
                            Text(conversation.parent?.name ?? "Unknown")
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                            Text(conversation.lastMessagePreview ?? "")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                    
                    if isForwarding {
                        HStack(spacing: Spacing.sm) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                .scaleEffect(0.9)
                            Text("Forwarding to team...")
                                .font(.moltBodySmall)
                                .foregroundColor(.moltTextSecondary)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.moltPrimaryLight)
                        .cornerRadius(CornerRadius.medium)
                    }
                    
                    if didForward {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.priorityLow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Forwarded to \(forwardedTeamName)")
                                    .font(.moltBody)
                                    .foregroundColor(.moltTextPrimary)
                                Text("The team has been notified and will pick this up shortly.")
                                    .font(.moltCaption)
                                    .foregroundColor(.moltTextMuted)
                            }
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.priorityLow.opacity(0.1))
                        .cornerRadius(CornerRadius.medium)
                    }

                    if let actionError {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.priorityHigh)
                            Text(actionError)
                                .font(.moltCaption)
                                .foregroundColor(.priorityHigh)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.priorityHigh.opacity(0.08))
                        .cornerRadius(CornerRadius.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Select Team")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        ForEach(teams) { team in
                            TeamSelectionRow(team: team, isSelected: selectedTeam?.id == team.id) {
                                selectedTeam = team
                            }
                            .disabled(isForwarding || didForward)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Reason for Forwarding")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        TextEditor(text: $reason)
                            .scrollContentBackground(.hidden)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .frame(minHeight: 120)
                            .padding(Spacing.sm)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                            .disabled(isForwarding || didForward)
                    }
                }
                .padding(Spacing.lg)
            }
            
            SubtleDivider()
            
            HStack(spacing: Spacing.md) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.moltSurfaceSecondary)
                        .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(isForwarding)
                
                Button(action: {
                    if didForward {
                        dismiss()
                    } else {
                        forward()
                    }
                }) {
                    HStack(spacing: Spacing.sm) {
                        if isForwarding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                .scaleEffect(0.85)
                        }
                        Text(didForward ? "Done" : "Forward")
                            .font(.moltBody)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(selectedTeam != nil ? Color.moltPrimary : Color.moltTextMuted)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(selectedTeam == nil || isForwarding)
            }
            .padding(Spacing.lg)
        }
        .frame(width: 460, height: 580)
        .background(Color.moltBackground)
        .onAppear {
            if selectedTeam == nil {
                selectedTeam = teams.first
            }
        }
    }
    
    func forward() {
        guard let team = selectedTeam else { return }
        guard !isForwarding else { return }
        actionError = nil
        isForwarding = true
        forwardedTeamName = team.name

        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        _Concurrency.Task {
            do {
                try await appState.forwardConversation(
                    conversationId: conversation.id,
                    teamId: team.id,
                    agentId: nil
                )

                if !trimmedReason.isEmpty {
                    try await appState.createEscalation(
                        conversationId: conversation.id,
                        reason: trimmedReason,
                        aiSummary: "Forwarded from AI assistant quick actions.",
                        priority: conversation.priority,
                        toTeamId: team.id,
                        toAgentId: nil
                    )
                }

                await appState.refreshConversations(showLoading: false)
                await appState.refreshEscalations()
                await MainActor.run {
                    isForwarding = false
                    didForward = true
                }
            } catch {
                await MainActor.run {
                    isForwarding = false
                    actionError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Member Selection Row
struct MemberSelectionRow: View {
    let member: AgentWithWorkload
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(Color.moltSurfaceSecondary)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(member.avatarInitial)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextSecondary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.moltBody)
                        .foregroundColor(.moltTextPrimary)
                    Text(member.status.rawValue.capitalized)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.moltPrimary)
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Team Selection Row
struct TeamSelectionRow: View {
    let team: Team
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name)
                        .font(.moltBody)
                        .foregroundColor(.moltTextPrimary)
                    if let desc = team.description {
                        Text(desc)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.moltPrimary)
                }
            }
            .padding(Spacing.md)
            .background(isSelected ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Analysis Card
struct AnalysisCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .cornerRadius(CornerRadius.small)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                Text(value)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
            }
            
            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.moltSurfaceSecondary)
        .cornerRadius(CornerRadius.medium)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.moltBodySmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.moltTextMuted)
            }
            .padding(Spacing.sm)
            .background(Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}
