import SwiftUI

struct CreateTaskSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedConversation: Conversation?
    @State private var assignedTo: String?
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var priority: Priority = .medium
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(.moltTextSecondary)
                
                Spacer()
                
                Text("New Task")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button("Create") {
                    createTask()
                }
                .buttonStyle(.plain)
                .foregroundColor(canSave ? .moltPrimary : .moltTextMuted)
                .disabled(!canSave)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Title
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Title *")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        TextField("Enter task title", text: $title)
                            .textFieldStyle(.plain)
                            .font(.moltBody)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Description")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        TextEditor(text: $description)
                            .font(.moltBody)
                            .frame(height: 100)
                            .padding(Spacing.sm)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }
                    
                    // Linked Conversation
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Linked Conversation")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        Menu {
                            Button("None") {
                                selectedConversation = nil
                            }
                            ForEach(appState.conversations.prefix(10)) { conv in
                                Button(conv.parent?.name ?? "Unknown") {
                                    selectedConversation = conv
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedConversation?.parent?.name ?? "Select conversation")
                                    .foregroundColor(selectedConversation == nil ? .moltTextMuted : .moltTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.moltTextMuted)
                            }
                            .font(.moltBody)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .menuStyle(.borderlessButton)
                    }
                    
                    // Assign To
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Assign To")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        Menu {
                            Button("Me (default)") {
                                assignedTo = appState.currentAgent?.id
                            }
                            Button("Unassigned") {
                                assignedTo = nil
                            }
                        } label: {
                            HStack {
                                Text(assignedTo == appState.currentAgent?.id || assignedTo == nil ? "Me" : "Other Agent")
                                    .foregroundColor(.moltTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.moltTextMuted)
                            }
                            .font(.moltBody)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .menuStyle(.borderlessButton)
                    }
                    
                    // Priority
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Priority")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        HStack(spacing: Spacing.sm) {
                            ForEach([Priority.low, .medium, .high, .urgent], id: \.self) { p in
                                Button(action: { priority = p }) {
                                    Text(p.rawValue.capitalized)
                                        .font(.moltLabel)
                                        .foregroundColor(priority == p ? .white : .moltTextSecondary)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(priority == p ? priorityColor(p) : Color.moltSurfaceSecondary)
                                        .cornerRadius(CornerRadius.small)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Due Date
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Toggle("Set due date", isOn: $hasDueDate)
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        
                        if hasDueDate {
                            DatePicker("", selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ), displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                        }
                    }
                }
                .padding(Spacing.lg)
            }
        }
        .frame(width: 500, height: 650)
        .background(Color.moltBackground)
    }
    
    func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .priorityLow
        case .medium: return .priorityMedium
        case .high: return .priorityHigh
        case .urgent: return .priorityUrgent
        }
    }
    
    func createTask() {
        _Concurrency.Task {
            await appState.createTask(
                title: title,
                description: description.isEmpty ? nil : description,
                assignedToId: assignedTo ?? appState.currentAgent?.id,
                conversationId: selectedConversation?.id,
                priority: priority,
                dueDate: hasDueDate ? dueDate : nil,
                tags: tags.isEmpty ? nil : tags
            )
            await MainActor.run {
                isPresented = false
            }
        }
    }
}
