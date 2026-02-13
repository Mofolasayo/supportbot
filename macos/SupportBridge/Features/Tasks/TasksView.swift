import SwiftUI

struct TasksView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: TaskFilter = .myTasks
    @State private var selectedStatus: Task.TaskStatus? = nil
    @State private var showCreateTask = false
    @State private var taskToEdit: Task?
    
    var filteredTasks: [Task] {
        var tasks = appState.tasks
        
        // Filter by ownership
        switch selectedFilter {
        case .myTasks:
            tasks = tasks.filter { $0.assignedTo == appState.currentAgent?.id }
        case .teamTasks:
            tasks = tasks.filter { $0.assignedTo != appState.currentAgent?.id }
        case .all:
            break
        }
        
        // Filter by status
        if let status = selectedStatus {
            tasks = tasks.filter { $0.status == status }
        }
        
        return tasks.sorted { task1, task2 in
            // Overdue first
            if task1.isOverdue != task2.isOverdue {
                return task1.isOverdue
            }
            // Then by priority
            if task1.priority != task2.priority {
                return task1.priority.rawValue > task2.priority.rawValue
            }
            // Then by due date
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            return task1.createdAt > task2.createdAt
        }
    }
    
    var taskCounts: (todo: Int, inProgress: Int, completed: Int) {
        let myTasks = appState.tasks.filter { $0.assignedTo == appState.currentAgent?.id }
        return (
            todo: myTasks.filter { $0.status == .todo }.count,
            inProgress: myTasks.filter { $0.status == .inProgress }.count,
            completed: myTasks.filter { $0.status == .completed }.count
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tasks")
                    .font(.moltTitleLarge)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
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
            
            SubtleDivider()
            
            // Filter Tabs
            HStack(spacing: Spacing.md) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        title: filter.title,
                        count: countFor(filter),
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Status Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    StatusChip(
                        status: nil,
                        isSelected: selectedStatus == nil,
                        action: { selectedStatus = nil }
                    )
                    
                    ForEach(Task.TaskStatus.allCases, id: \.self) { status in
                        if status != .cancelled {
                            StatusChip(
                                status: status,
                                isSelected: selectedStatus == status,
                                action: { selectedStatus = status }
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Task List
            if filteredTasks.isEmpty {
                EmptyTasksView(filter: selectedFilter)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task, onTap: {
                                taskToEdit = task
                            }, onToggleStatus: {
                                _Concurrency.Task {
                                    await appState.toggleTaskStatus(taskId: task.id)
                                }
                            })
                        }
                    }
                    .padding(Spacing.lg)
                }
                .background(Color.moltBackground)
            }
        }
        .background(Color.moltSurface)
        .task {
            await appState.refreshTasks()
        }
        .sheet(isPresented: $showCreateTask) {
            CreateTaskSheet(isPresented: $showCreateTask)
        }
        .sheet(item: $taskToEdit) { task in
            TaskDetailSheet(task: task, isPresented: Binding(
                get: { taskToEdit != nil },
                set: { if !$0 { taskToEdit = nil } }
            ))
        }
    }
    
    func countFor(_ filter: TaskFilter) -> Int {
        switch filter {
        case .myTasks:
            return appState.tasks.filter { $0.assignedTo == appState.currentAgent?.id && $0.status != .completed }.count
        case .teamTasks:
            return appState.tasks.filter { $0.assignedTo != appState.currentAgent?.id && $0.status != .completed }.count
        case .all:
            return appState.tasks.filter { $0.status != .completed }.count
        }
    }
}

// MARK: - Task Filter
enum TaskFilter: String, CaseIterable {
    case myTasks = "My Tasks"
    case teamTasks = "Team"
    case all = "All Tasks"
    
    var title: String { rawValue }
}

// MARK: - Filter Tab
struct FilterTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.moltBody)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.moltLabel)
                        .foregroundColor(isSelected ? .white : .moltTextMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.moltPrimaryLight : Color.clear)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Chip
struct StatusChip: View {
    let status: Task.TaskStatus?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let status = status {
                    Image(systemName: status.icon)
                        .font(.system(size: 12))
                }
                Text(status?.rawValue ?? "All")
                    .font(.moltLabel)
            }
            .foregroundColor(isSelected ? .white : .moltTextSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let task: Task
    let onTap: () -> Void
    let onToggleStatus: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Status checkbox
                Button(action: onToggleStatus) {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.status == .completed ? .moltPrimary : .moltTextMuted)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(task.title)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .strikethrough(task.status == .completed)
                        
                        if task.isOverdue {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.priorityHigh)
                        }
                        
                        Spacer()
                        
                        PriorityBadge(priority: task.priority)
                    }
                    
                    HStack(spacing: Spacing.sm) {
                        if let dueDate = task.dueDate {
                            Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(.moltCaption)
                                .foregroundColor(task.isOverdue ? .priorityHigh : .moltTextMuted)
                        }
                        
                        if let conversationId = task.conversationId {
                            Label("From Chat", systemImage: "bubble.left")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                        }
                        
                        if let tags = task.tags, !tags.isEmpty {
                            ForEach(tags.prefix(2), id: \.self) { tag in
                                Text(tag)
                                    .font(.moltLabel)
                                    .foregroundColor(.moltTextSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.moltSurfaceSecondary)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State
struct EmptyTasksView: View {
    let filter: TaskFilter
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.moltTextMuted)
            
            Text("No tasks \(emptyMessage)")
                .font(.moltTitleSmall)
                .foregroundColor(.moltTextSecondary)
            
            Text("Create a task to track important actions")
                .font(.moltBody)
                .foregroundColor(.moltTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
    
    var emptyMessage: String {
        switch filter {
        case .myTasks: return "assigned to you"
        case .teamTasks: return "for the team"
        case .all: return "yet"
        }
    }
}
