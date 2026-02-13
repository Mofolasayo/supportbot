import SwiftUI

struct AdvancedFilterSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    
    @State private var selectedStatus: Set<ConversationStatus> = []
    @State private var selectedPriority: Set<Priority> = []
    @State private var selectedHandler: Set<ConversationHandler> = []
    @State private var dateRange: DateRangeFilter = .all
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var hasAttachments = false
    @State private var unreadOnly = false
    @State private var selectedTags: Set<String> = []
    
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
                
                Text("Advanced Filters")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button("Apply") {
                    applyFilters()
                }
                .buttonStyle(.plain)
                .foregroundColor(.moltPrimary)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Status Filter
                    FilterSection(title: "Status") {
                        ForEach([ConversationStatus.open, .pending, .resolved, .closed], id: \.self) { status in
                            ToggleRow(
                                title: status.rawValue.capitalized,
                                isOn: Binding(
                                    get: { selectedStatus.contains(status) },
                                    set: { if $0 { selectedStatus.insert(status) } else { selectedStatus.remove(status) } }
                                )
                            )
                        }
                    }
                    
                    // Priority Filter
                    FilterSection(title: "Priority") {
                        ForEach([Priority.low, .medium, .high, .urgent], id: \.self) { priority in
                            ToggleRow(
                                title: priority.rawValue.capitalized,
                                isOn: Binding(
                                    get: { selectedPriority.contains(priority) },
                                    set: { if $0 { selectedPriority.insert(priority) } else { selectedPriority.remove(priority) } }
                                )
                            )
                        }
                    }
                    
                    // Handler Filter
                    FilterSection(title: "Handled By") {
                        ForEach([ConversationHandler.bot, .agent, .team], id: \.self) { handler in
                            ToggleRow(
                                title: handler.rawValue.capitalized,
                                isOn: Binding(
                                    get: { selectedHandler.contains(handler) },
                                    set: { if $0 { selectedHandler.insert(handler) } else { selectedHandler.remove(handler) } }
                                )
                            )
                        }
                    }
                    
                    // Date Range
                    FilterSection(title: "Date Range") {
                        Picker("", selection: $dateRange) {
                            ForEach(DateRangeFilter.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        if dateRange == .custom {
                            DatePicker("From", selection: $customStartDate, displayedComponents: [.date])
                            DatePicker("To", selection: $customEndDate, displayedComponents: [.date])
                        }
                    }
                    
                    // Other Options
                    FilterSection(title: "Other") {
                        Toggle("Has attachments", isOn: $hasAttachments)
                        Toggle("Unread only", isOn: $unreadOnly)
                    }
                    
                    // Reset Button
                    Button(action: resetFilters) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Filters")
                        }
                        .font(.moltBody)
                        .foregroundColor(.moltTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.moltSurfaceSecondary)
                        .cornerRadius(CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                }
                .padding(Spacing.lg)
            }
        }
        .frame(width: 500, height: 600)
        .background(Color.moltBackground)
    }
    
    func applyFilters() {
        // Apply filters to appState
        isPresented = false
    }
    
    func resetFilters() {
        selectedStatus.removeAll()
        selectedPriority.removeAll()
        selectedHandler.removeAll()
        dateRange = .all
        hasAttachments = false
        unreadOnly = false
        selectedTags.removeAll()
    }
}

enum DateRangeFilter: String, CaseIterable {
    case all = "All Time"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case custom = "Custom Range"
}

struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.moltLabel)
                .foregroundColor(.moltTextSecondary)
            
            VStack(spacing: 0) {
                content
            }
            .padding(Spacing.md)
            .background(Color.moltSurface)
            .cornerRadius(CornerRadius.medium)
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(.moltBody)
            .foregroundColor(.moltTextPrimary)
    }
}
