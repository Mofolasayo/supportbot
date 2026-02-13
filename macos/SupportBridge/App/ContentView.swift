import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("selectedTheme") private var selectedTheme = "System"
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainDashboard()
            } else {
                AuthFlowView()
            }
        }
        .background(Color.moltBackground)
        .preferredColorScheme(colorScheme)
    }
    
    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil  // System
        }
    }
}

// MARK: - Main Dashboard
struct MainDashboard: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedNavItem: NavItem = .inbox
    @State private var isInSelectionMode = false
    @State private var selectedConversationIds: Set<String> = []
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(selectedItem: $selectedNavItem)
                .frame(width: 220)
            
            SubtleVerticalDivider()
            
            // Main Content
            mainContent
        }
        .frame(minWidth: 1200, minHeight: 700)
        .accentColor(.moltPrimary)
        .task(id: appState.authToken) {
            guard appState.authToken != nil else { return }
            await appState.refreshConversations()
        }
        .overlay(alignment: .bottom) {
            // Bulk Actions Toolbar
            if isInSelectionMode && !selectedConversationIds.isEmpty {
                BulkActionsToolbar(
                    selectedCount: selectedConversationIds.count,
                    onResolve: bulkResolve,
                    onAssign: bulkAssign,
                    onCancel: { 
                        isInSelectionMode = false
                        selectedConversationIds.removeAll()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isInSelectionMode)
    }
    
    @ViewBuilder
    var mainContent: some View {
        switch selectedNavItem {
        case .inbox:
            InboxView(
                isInSelectionMode: $isInSelectionMode,
                selectedIds: $selectedConversationIds
            )
        case .workspace:
            MyWorkspaceView(selectedNavItem: $selectedNavItem)
        case .escalations:
            EscalationQueueView(selectedNavItem: $selectedNavItem)
        case .contacts:
            ContactsView()
        case .teamChat:
            TeamChatView()
        case .broadcast:
            BroadcastView()
        case .teams:
            TeamInboxView()
        case .knowledgeBase:
            KnowledgeBaseView()
        case .analytics:
            AnalyticsDashboardView()
        case .templates:
            TemplatesLibraryView()
        case .settings:
            SettingsView()
        }
    }
    
    func bulkResolve() {
        print("Resolving \(selectedConversationIds.count) conversations")
        selectedConversationIds.removeAll()
        isInSelectionMode = false
    }
    
    func bulkAssign() {
        print("Assigning \(selectedConversationIds.count) conversations")
    }
}

// MARK: - Inbox View (Conversation List + Chat)
struct InboxView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isInSelectionMode: Bool
    @Binding var selectedIds: Set<String>
    
    var body: some View {
        HStack(spacing: 0) {
            // Conversation List
            ConversationListView(
                isInSelectionMode: $isInSelectionMode,
                selectedIds: $selectedIds
            )
            .frame(minWidth: 300, idealWidth: 340, maxWidth: 400)
            
            SubtleVerticalDivider()
            
            // Chat Detail
            if let conversation = appState.selectedConversation {
                ChatDetailView(conversation: conversation)
            } else {
                EmptyInboxView()
            }
        }
        .background(Color.moltBackground)
    }
}

// MARK: - Navigation Items
enum NavItem: String, CaseIterable {
    case inbox = "Inbox"
    case workspace = "My Workspace"
    case escalations = "Escalations"
    case contacts = "Contacts"
    case teams = "Teams"
    case teamChat = "Team Chat"
    case broadcast = "Broadcast"
    case knowledgeBase = "Knowledge Base"
    case analytics = "Analytics"
    case templates = "Templates"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .inbox: return "tray.fill"
        case .workspace: return "square.grid.2x2.fill"
        case .escalations: return "arrow.up.circle.fill"
        case .contacts: return "person.text.rectangle"
        case .teamChat: return "bubble.left.and.bubble.right.fill"
        case .broadcast: return "megaphone.fill"
        case .teams: return "person.3.fill"
        case .knowledgeBase: return "book.fill"
        case .analytics: return "chart.bar.fill"
        case .templates: return "doc.text"
        case .settings: return "gearshape.fill"
        }
    }
    
    var badge: Int? {
        switch self {
        case .inbox: return 4
        case .workspace: return 5
        case .escalations: return 2
        case .teamChat: return 1
        default: return nil
        }
    }
}

// MARK: - Bulk Actions Toolbar
struct BulkActionsToolbar: View {
    let selectedCount: Int
    let onResolve: () -> Void
    let onAssign: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            Text("\(selectedCount) selected")
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
            
            Spacer()
            
            Button(action: onResolve) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle")
                    Text("Resolve All")
                }
                .font(.moltBody)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.priorityLow)
                .cornerRadius(CornerRadius.medium)
            }
            .buttonStyle(.plain)
            
            Button(action: onAssign) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "person.badge.plus")
                    Text("Assign")
                }
                .font(.moltBody)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.moltPrimary)
                .cornerRadius(CornerRadius.medium)
            }
            .buttonStyle(.plain)
            
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.moltBody)
                    .foregroundColor(.moltTextSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
        .shadow(color: Color.black.opacity(0.15), radius: 10)
        .padding(Spacing.lg)
    }
}

// MARK: - Empty State
struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 56))
                .foregroundColor(.moltTextMuted)
            
            Text("Select a conversation")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextSecondary)
            
            Text("Choose a conversation from the list to view messages")
                .font(.moltBody)
                .foregroundColor(.moltTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
}

// MARK: - My Workspace View (Unified: Dashboard + Queue + Tasks)
struct MyWorkspaceView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedNavItem: NavItem
    @State private var selectedTab = 0  // 0 = Queue, 1 = Tasks
    @State private var showNotifications = false
    @State private var showCreateTask = false
    
    var myConversations: [Conversation] {
        appState.conversations.filter { $0.assignedAgentId == appState.currentAgent?.id && $0.status == .open }
    }

    var myTasks: [Task] {
        appState.tasks.filter { $0.assignedTo == appState.currentAgent?.id }
    }

    var activeTasks: [Task] {
        myTasks.filter { $0.status != .completed && $0.status != .cancelled }
    }

    var completedTasks: [Task] {
        myTasks.filter { $0.status == .completed }
    }

    var completedTodayCount: Int {
        let calendar = Calendar.current
        return completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.isDateInToday(completedAt)
        }.count
    }

    var averageQueueAge: String {
        let timestamps = myConversations.compactMap { $0.lastMessageAt }
        guard !timestamps.isEmpty else { return "--" }
        let total = timestamps.reduce(0.0) { partial, date in
            partial + max(0, Date().timeIntervalSince(date))
        }
        let avg = total / Double(timestamps.count)
        if avg < 60 {
            return "\(Int(avg))s"
        }
        if avg < 3600 {
            return "\(Int(avg / 60))m"
        }
        return "\(Int(avg / 3600))h"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with greeting
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Workspace")
                        .font(.moltTitleLarge)
                        .foregroundColor(.moltTextPrimary)
                    Text("Welcome back, \(appState.currentAgent?.name ?? "Agent")!")
                        .font(.moltBody)
                        .foregroundColor(.moltTextMuted)
                }
                Spacer()
                
                // Notification Bell
                Button(action: { showNotifications = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.moltTextSecondary)
                        
                        Circle()
                            .fill(Color.priorityHigh)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                    .padding(Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showNotifications) {
                    NotificationsPopover()
                }
                
                Button(action: { showCreateTask = true }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                        Text("New Task")
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
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Stats Row
            HStack(spacing: Spacing.md) {
                WorkspaceStatCard(title: "My Queue", value: "\(myConversations.count)", icon: "person.crop.rectangle.stack.fill", color: .moltPrimary)
                WorkspaceStatCard(title: "Open Tasks", value: "\(activeTasks.count)", icon: "checkmark.circle", color: .priorityHigh)
                WorkspaceStatCard(title: "Resolved Today", value: "\(completedTodayCount)", icon: "checkmark.circle.fill", color: .priorityLow)
                WorkspaceStatCard(title: "Avg Queue Age", value: averageQueueAge, icon: "clock.fill", color: .priorityMedium)
            }
            .padding(Spacing.lg)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Main Content: Queue + Tasks panels
            HStack(spacing: 0) {
                // Left Panel: My Queue
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Active Conversations")
                            .font(.moltTitleSmall)
                            .foregroundColor(.moltTextPrimary)
                        Spacer()
                        Text("\(myConversations.count)")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(10)
                    }
                    .padding(Spacing.md)
                    .background(Color.moltSurface)
                    
                    SubtleDivider()
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(myConversations) { conv in
                                WorkspaceConversationRow(conversation: conv, selectedNavItem: $selectedNavItem)
                                SubtleDivider()
                            }
                            
                            if myConversations.isEmpty {
                                VStack(spacing: Spacing.md) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 40))
                                        .foregroundColor(.moltTextMuted)
                                    Text("No active conversations")
                                        .font(.moltBody)
                                        .foregroundColor(.moltTextMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.xxl)
                            }
                        }
                    }
                    .background(Color.moltBackground)
                }
                .frame(minWidth: 350)
                
                SubtleVerticalDivider()
                
                // Right Panel: Tasks
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("My Tasks")
                            .font(.moltTitleSmall)
                            .foregroundColor(.moltTextPrimary)
                        Spacer()
                        
                        HStack(spacing: Spacing.xs) {
                            ForEach(["Active", "Completed"], id: \.self) { tab in
                                Button(action: { selectedTab = tab == "Active" ? 0 : 1 }) {
                                    Text(tab)
                                        .font(.moltLabel)
                                        .foregroundColor(selectedTab == (tab == "Active" ? 0 : 1) ? .moltPrimary : .moltTextMuted)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(selectedTab == (tab == "Active" ? 0 : 1) ? Color.moltPrimaryLight : Color.clear)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.moltSurface)
                    
                    SubtleDivider()
                    
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm) {
                            if selectedTab == 0 {
                                if activeTasks.isEmpty {
                                    WorkspaceTaskEmptyState(label: "No active tasks")
                                } else {
                                    ForEach(activeTasks.prefix(8)) { task in
                                        WorkspaceTaskRow(task: task)
                                    }
                                }
                            } else {
                                if completedTasks.isEmpty {
                                    WorkspaceTaskEmptyState(label: "No completed tasks")
                                } else {
                                    ForEach(completedTasks.prefix(8)) { task in
                                        WorkspaceTaskRow(task: task)
                                    }
                                }
                            }
                        }
                        .padding(Spacing.md)
                    }
                    .background(Color.moltBackground)
                }
                .frame(minWidth: 320)
            }
        }
        .background(Color.moltBackground)
        .sheet(isPresented: $showCreateTask) {
            WorkspaceCreateTaskSheet(isPresented: $showCreateTask)
                .environmentObject(appState)
        }
        .task {
            await appState.refreshTasks()
        }
    }
}

// MARK: - Workspace Supporting Views
struct WorkspaceStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.moltTextPrimary)
                Text(title)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.moltBackground)
        .cornerRadius(CornerRadius.medium)
    }
}

struct WorkspaceConversationRow: View {
    let conversation: Conversation
    @EnvironmentObject var appState: AppState
    @Binding var selectedNavItem: NavItem
    
    var body: some View {
        Button(action: {
            appState.selectedConversation = conversation
            selectedNavItem = .inbox
        }) {
            HStack(spacing: Spacing.md) {
                // Avatar
                Circle()
                    .fill(priorityColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(conversation.parent?.name.prefix(1).uppercased() ?? "?")
                            .font(.moltBody)
                            .fontWeight(.medium)
                            .foregroundColor(priorityColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.parent?.name ?? "Unknown")
                            .font(.moltBody)
                            .fontWeight(.medium)
                            .foregroundColor(.moltTextPrimary)
                        
                        Spacer()
                        
                        if conversation.unreadCount > 0 {
                            Circle()
                                .fill(Color.moltPrimary)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    if let preview = conversation.lastMessagePreview {
                        Text(preview)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                            .lineLimit(1)
                    }
                }
                
                // Priority indicator
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    var priorityColor: Color {
        switch conversation.priority {
        case .urgent: return .priorityUrgent
        case .high: return .priorityHigh
        case .medium: return .priorityMedium
        case .low: return .priorityLow
        }
    }
}

struct WorkspaceTaskRow: View {
    let task: Task
    @State private var isHovering = false
    
    var priorityColor: Color {
        switch task.priority {
        case .urgent: return .priorityUrgent
        case .high: return .priorityHigh
        case .medium: return .priorityMedium
        case .low: return .priorityLow
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checkbox
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(task.status == .completed ? .priorityLow : .moltTextMuted)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.moltBody)
                    .foregroundColor(task.status == .completed ? .moltTextMuted : .moltTextPrimary)
                    .strikethrough(task.status == .completed)
                    .lineLimit(1)
                
                HStack(spacing: Spacing.sm) {
                    Text(task.priority.rawValue.capitalized)
                        .font(.moltLabel)
                        .foregroundColor(priorityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.15))
                        .cornerRadius(4)
                    
                    Label(dueDateLabel, systemImage: "calendar")
                        .font(.moltCaption)
                        .foregroundColor(isDueToday ? .priorityHigh : .moltTextMuted)
                }
            }
            
            Spacer()
            
            if isHovering && task.status != .completed {
                Button(action: {}) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.priorityLow)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.small)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var isDueToday: Bool {
        guard let dueDate = task.dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    private var dueDateLabel: String {
        guard let dueDate = task.dueDate else { return "No due date" }
        let calendar = Calendar.current
        if calendar.isDateInToday(dueDate) {
            return "Today"
        }
        if calendar.isDateInTomorrow(dueDate) {
            return "Tomorrow"
        }
        if calendar.isDateInYesterday(dueDate) {
            return "Yesterday"
        }
        return dueDate.formatted(date: .abbreviated, time: .omitted)
    }
}

struct WorkspaceTaskEmptyState: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.small)
    }
}

struct WorkspaceCreateTaskSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var details = ""
    @State private var priority: Priority = .medium

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Create Task")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)

            TextField("Task title", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Description (optional)", text: $details)
                .textFieldStyle(.roundedBorder)

            Picker("Priority", selection: $priority) {
                Text("Low").tag(Priority.low)
                Text("Medium").tag(Priority.medium)
                Text("High").tag(Priority.high)
                Text("Urgent").tag(Priority.urgent)
            }
            .pickerStyle(.segmented)

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Create") {
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    _Concurrency.Task {
                        await appState.createTask(
                            title: trimmed,
                            description: details.isEmpty ? nil : details,
                            assignedToId: appState.currentAgent?.id,
                            conversationId: appState.selectedConversation?.id,
                            priority: priority,
                            dueDate: nil,
                            tags: []
                        )
                        await MainActor.run {
                            isPresented = false
                        }
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Spacing.lg)
        .frame(width: 420)
    }
}

// MARK: - Notifications Popover (Clean minimal design)
struct NotificationsPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Clear all")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            
            // Notifications List
            VStack(spacing: 0) {
                NotificationItem(title: "New message", subtitle: "Mrs. Ibrahim sent a payment query", time: "2m", isUnread: true)
                NotificationItem(title: "Task assigned", subtitle: "Follow up on payment dispute", time: "15m", isUnread: true)
                NotificationItem(title: "Mention", subtitle: "@you in #support channel", time: "1h", isUnread: false)
                NotificationItem(title: "Resolved", subtitle: "Chat with Mr. Adeyemi closed", time: "3h", isUnread: false)
            }
        }
        .frame(width: 300)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
    }
}

struct NotificationItem: View {
    let title: String
    let subtitle: String
    let time: String
    let isUnread: Bool
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Unread indicator
            Circle()
                .fill(isUnread ? Color.moltPrimary : Color.clear)
                .frame(width: 6, height: 6)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.moltCaption)
                        .fontWeight(isUnread ? .semibold : .regular)
                        .foregroundColor(.moltTextPrimary)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.moltLabel)
                        .foregroundColor(.moltTextMuted)
                }
                
                Text(subtitle)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(isHovering ? Color.moltSurfaceSecondary : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}



// MARK: - Templates Library View (Full Implementation)
struct TemplatesLibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory = 0
    @State private var searchText = ""
    
    let categories = ["All", "Greetings", "Admissions", "Finance", "Academic"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Templates")
                    .font(.moltTitleLarge)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus")
                        Text("New Template")
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
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.moltTextMuted)
                TextField("Search templates...", text: $searchText)
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
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(categories.indices, id: \.self) { index in
                        Button(action: { selectedCategory = index }) {
                            Text(categories[index])
                                .font(.moltLabel)
                                .foregroundColor(selectedCategory == index ? .white : .moltTextSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, 6)
                                .background(selectedCategory == index ? Color.moltPrimary : Color.moltSurfaceSecondary)
                                .cornerRadius(CornerRadius.small)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Templates List
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    TemplateCardView(title: "Welcome Message", content: "Hello! Thank you for contacting SupportBridge. How can I assist you today?", category: "Greetings")
                    TemplateCardView(title: "Admission Requirements", content: "Thank you for your interest in admission. The requirements include...", category: "Admissions")
                    TemplateCardView(title: "Payment Confirmation", content: "We have received your payment. Your receipt number is...", category: "Finance")
                    TemplateCardView(title: "Exam Schedule", content: "The examination schedule for this semester is as follows...", category: "Academic")
                }
                .padding(Spacing.lg)
            }
            .background(Color.moltBackground)
        }
        .background(Color.moltSurface)
    }
}

struct TemplateCardView: View {
    let title: String
    let content: String
    let category: String
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(title)
                    .font(.moltBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                if isHovering {
                    HStack(spacing: Spacing.xs) {
                        Button(action: {}) {
                            Image(systemName: "pencil")
                                .foregroundColor(.moltPrimary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {}) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.moltPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Text(content)
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
                .lineLimit(2)
            
            HStack {
                Text(category)
                    .font(.moltLabel)
                    .foregroundColor(.moltTextMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(4)
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Use")
                    }
                    .font(.moltLabel)
                    .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
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
