import SwiftUI

struct TemplatesLibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: TemplateCategory = .all
    @State private var showCreateTemplate = false
    @State private var templateToEdit: ResponseTemplate?
    @State private var searchText = ""
    
    var templatesSource: [ResponseTemplate] {
        appState.cannedResponses.isEmpty ? ResponseTemplate.mockList : appState.cannedResponses
    }
    
    var filteredTemplates: [ResponseTemplate] {
        var templates = templatesSource
        
        if selectedCategory != .all {
            templates = templates.filter { $0.category.rawValue.lowercased() == selectedCategory.rawValue.lowercased() }
        }
        
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.title.localizedCaseInsensitiveContains(searchText) ||
                template.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return templates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Templates")
                    .font(.moltTitleLarge)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button(action: { showCreateTemplate = true }) {
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
                    ForEach(TemplateCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            count: templatesSource.filter {
                                category == .all || $0.category.rawValue.lowercased() == category.rawValue.lowercased()
                            }.count,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.md)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Templates List
            if filteredTemplates.isEmpty {
                EmptyTemplatesView(searchText: searchText)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(template: template, onEdit: {
                                templateToEdit = template
                            })
                        }
                    }
                    .padding(Spacing.lg)
                }
                .background(Color.moltBackground)
            }
        }
        .background(Color.moltSurface)
        .sheet(isPresented: $showCreateTemplate) {
            TemplateEditorSheet(template: nil)
                .frame(width: 520, height: 620)
        }
        .sheet(item: $templateToEdit) { template in
            TemplateEditorSheet(template: template)
                .frame(width: 520, height: 620)
        }
        .task {
            await appState.refreshCannedResponses()
        }
    }
}

// MARK: - Template Category
enum TemplateCategory: String, CaseIterable {
    case all = "All"
    case greeting = "Greeting"
    case general = "General"
    case fees = "Fees"
    case academic = "Academic"
    case closing = "Closing"
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: TemplateCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(category.rawValue)
                if category == .all {
                    Text("(\(count))")
                        .foregroundColor(.moltTextMuted)
                }
            }
            .font(.moltLabel)
            .foregroundColor(isSelected ? .white : .moltTextSecondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: ResponseTemplate
    let onEdit: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(template.title)
                    .font(.moltBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                if isHovering {
                    HStack(spacing: Spacing.xs) {
                        Button(action: onEdit) {
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
            
            Text(template.content)
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
                .lineLimit(2)
            
            HStack {
                Text(template.category.rawValue)
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

// MARK: - Template Editor Sheet
struct TemplateEditorSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let template: ResponseTemplate?
    @State private var title: String
    @State private var content: String
    @State private var category: ResponseTemplate.TemplateCategory
    @State private var shortcut: String
    @State private var isSaving = false

    init(template: ResponseTemplate?) {
        self.template = template
        _title = State(initialValue: template?.title ?? "")
        _content = State(initialValue: template?.content ?? "")
        _category = State(initialValue: template?.category ?? .general)
        _shortcut = State(initialValue: template?.shortcut ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(template == nil ? "New Template" : "Edit Template")
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
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Title")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        TextField("Template title", text: $title)
                            .textFieldStyle(.plain)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Category")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        Picker("Category", selection: $category) {
                            ForEach(ResponseTemplate.TemplateCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Shortcut")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        TextField("/shortcut", text: $shortcut)
                            .textFieldStyle(.plain)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Content")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextSecondary)
                        TextEditor(text: $content)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(height: 180)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }
                }
                .padding(Spacing.lg)
            }

            SubtleDivider()

            HStack(spacing: Spacing.md) {
                if let template = template {
                    Button(role: .destructive) {
                        _Concurrency.Task {
                            do {
                                try await appState.deleteCannedResponse(id: template.id)
                                dismiss()
                            } catch {
                                print("Failed to delete template: \(error)")
                            }
                        }
                    } label: {
                        Text("Delete")
                            .font(.moltBody)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Color.priorityHigh)
                            .cornerRadius(CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: saveTemplate) {
                    HStack(spacing: Spacing.xs) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Save")
                            .font(.moltBody)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(canSave ? Color.moltPrimary : Color.moltTextMuted)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(!canSave || isSaving)
            }
            .padding(Spacing.lg)
        }
        .background(Color.moltBackground)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveTemplate() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanShortcut = shortcut.trimmingCharacters(in: .whitespacesAndNewlines)

        isSaving = true
        _Concurrency.Task {
            do {
                if let template = template {
                    try await appState.updateCannedResponse(
                        id: template.id,
                        title: cleanTitle,
                        content: cleanContent,
                        category: category,
                        shortcut: cleanShortcut.isEmpty ? nil : cleanShortcut
                    )
                } else {
                    _ = try await appState.createCannedResponse(
                        title: cleanTitle,
                        content: cleanContent,
                        category: category,
                        shortcut: cleanShortcut.isEmpty ? nil : cleanShortcut
                    )
                }
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                isSaving = false
                print("Failed to save template: \(error)")
            }
        }
    }
}

// MARK: - Empty State
struct EmptyTemplatesView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.moltTextMuted)
            
            Text(searchText.isEmpty ? "No templates yet" : "No templates found")
                .font(.moltTitleSmall)
                .foregroundColor(.moltTextSecondary)
            
            Text(searchText.isEmpty ? "Create your first template to speed up responses" : "Try a different search term")
                .font(.moltBody)
                .foregroundColor(.moltTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
}
