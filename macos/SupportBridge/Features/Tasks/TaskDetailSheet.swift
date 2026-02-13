import SwiftUI

struct TaskDetailSheet: View {
    @EnvironmentObject var appState: AppState
    let task: Task
    @Binding var isPresented: Bool
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var editedDueDate: Date?
    @State private var editedPriority: Priority
    @State private var editedStatus: Task.TaskStatus
    
    init(task: Task, isPresented: Binding<Bool>) {
        self.task = task
        self._isPresented = isPresented
        _editedTitle = State(initialValue: task.title)
        _editedDescription = State(initialValue: task.description ?? "")
        _editedDueDate = State(initialValue: task.dueDate)
        _editedPriority = State(initialValue: task.priority)
        _editedStatus = State(initialValue: task.status)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(isEditing ? "Cancel" : "Close") {
                    if isEditing {
                        isEditing = false
                        resetEdits()
                    } else {
                        isPresented = false
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.moltTextSecondary)
                
                Spacer()
                
                Text(isEditing ? "Edit Task" : "Task Details")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                if isEditing {
                    Button("Save") {
                        saveChanges()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.moltPrimary)
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.moltPrimary)
                }
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Title
                    if isEditing {
                        TextField("Task title", text: $editedTitle)
                            .textFieldStyle(.plain)
                            .font(.moltTitleSmall)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    } else {
                        Text(task.title)
                            .font(.moltTitleSmall)
                            .foregroundColor(.moltTextPrimary)
                    }
                    
                    // Status & Priority
                    HStack(spacing: Spacing.md) {
                        if isEditing {
                            Menu {
                                ForEach(Task.TaskStatus.allCases, id: \.self) { status in
                                    Button(action: { editedStatus = status }) {
                                        Label(status.rawValue, systemImage: status.icon)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: editedStatus.icon)
                                    Text(editedStatus.rawValue)
                                }
                                .font(.moltLabel)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(statusColor(editedStatus))
                                .cornerRadius(CornerRadius.small)
                            }
                            .menuStyle(.borderlessButton)
                        } else {
                            HStack {
                                Image(systemName: task.status.icon)
                                Text(task.status.rawValue)
                            }
                            .font(.moltLabel)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(statusColor(task.status))
                            .cornerRadius(CornerRadius.small)
                        }
                        
                        if isEditing {
                            Menu {
                                ForEach([Priority.low, .medium, .high, .urgent], id: \.self) { p in
                                    Button(p.rawValue.capitalized) {
                                        editedPriority = p
                                    }
                                }
                            } label: {
                                PriorityBadge(priority: editedPriority)
                            }
                            .menuStyle(.borderlessButton)
                        } else {
                            PriorityBadge(priority: task.priority)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Description")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        if isEditing {
                            TextEditor(text: $editedDescription)
                                .font(.moltBody)
                                .frame(height: 100)
                                .padding(Spacing.sm)
                                .background(Color.moltSurfaceSecondary)
                                .cornerRadius(CornerRadius.medium)
                        } else {
                            Text(task.description ?? "No description")
                                .font(.moltBody)
                                .foregroundColor(task.description == nil ? .moltTextMuted : .moltTextPrimary)
                        }
                    }
                    
                    // Details Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Details")
                            .font(.moltTitleSmall)
                            .foregroundColor(.moltTextPrimary)
                        
                        DetailRow(icon: "person", label: "Created by", value: task.createdByName ?? "Unknown")
                        DetailRow(icon: "calendar", label: "Created", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
                        
                        if let assignedTo = task.assignedTo {
                            DetailRow(icon: "person.circle", label: "Assigned to", value: assignedTo == appState.currentAgent?.id ? "You" : "Other Agent")
                        }
                        
                        if isEditing {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.moltTextMuted)
                                Text("Due date")
                                    .font(.moltBody)
                                    .foregroundColor(.moltTextSecondary)
                                Spacer()
                                DatePicker("", selection: Binding(
                                    get: { editedDueDate ?? Date() },
                                    set: { editedDueDate = $0 }
                                ), displayedComponents: [.date])
                                .labelsHidden()
                            }
                        } else if let dueDate = task.dueDate {
                            DetailRow(
                                icon: "calendar.badge.clock",
                                label: "Due date",
                                value: dueDate.formatted(date: .long, time: .omitted),
                                highlighted: task.isOverdue
                            )
                        }
                        
                        if let completedAt = task.completedAt {
                            DetailRow(icon: "checkmark.circle.fill", label: "Completed", value: completedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        
                        if let conversationId = task.conversationId {
                            Button(action: { /* Navigate to conversation */ }) {
                                HStack {
                                    Image(systemName: "bubble.left")
                                        .foregroundColor(.moltTextMuted)
                                    Text("Linked conversation")
                                        .font(.moltBody)
                                        .foregroundColor(.moltTextSecondary)
                                    Spacer()
                                    Text("View")
                                        .font(.moltBody)
                                        .foregroundColor(.moltPrimary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.moltTextMuted)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.moltSurface)
                    .cornerRadius(CornerRadius.large)
                    
                    // Actions
                    if !isEditing && task.status != .completed {
                        Button(action: {
                            appState.toggleTaskStatus(taskId: task.id)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Complete")
                            }
                            .font(.moltBody)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.priorityLow)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !isEditing {
                        Button(action: {
                            appState.deleteTask(id: task.id)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Task")
                            }
                            .font(.moltBody)
                            .foregroundColor(.priorityHigh)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.moltBackground)
        }
        .frame(width: 500, height: 700)
        .background(Color.moltBackground)
    }
    
    func statusColor(_ status: Task.TaskStatus) -> Color {
        switch status {
        case .todo: return .priorityMedium
        case .inProgress: return .moltPrimary
        case .completed: return .priorityLow
        case .cancelled: return .priorityResolved
        }
    }
    
    func resetEdits() {
        editedTitle = task.title
        editedDescription = task.description ?? ""
        editedDueDate = task.dueDate
        editedPriority = task.priority
        editedStatus = task.status
    }
    
    func saveChanges() {
        var updatedTask = task
        updatedTask.title = editedTitle
        updatedTask.description = editedDescription.isEmpty ? nil : editedDescription
        updatedTask.dueDate = editedDueDate
        updatedTask.priority = editedPriority
        updatedTask.status = editedStatus

        _Concurrency.Task {
            await appState.updateTaskRemote(updatedTask)
            await MainActor.run {
                isEditing = false
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var highlighted: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(highlighted ? .priorityHigh : .moltTextMuted)
            Text(label)
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
            Spacer()
            Text(value)
                .font(.moltBody)
                .foregroundColor(highlighted ? .priorityHigh : .moltTextPrimary)
        }
    }
}
