import SwiftUI

// MARK: - Quick Templates Picker
struct QuickTemplatesView: View {
    @EnvironmentObject var appState: AppState
    let onSelect: (ResponseTemplate) -> Void
    let onDismiss: () -> Void
    @State private var selectedCategory: ResponseTemplate.TemplateCategory?
    @State private var searchText = ""
    
    var filteredTemplates: [ResponseTemplate] {
        var templates = appState.cannedResponses.isEmpty ? ResponseTemplate.mockList : appState.cannedResponses
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            templates = templates.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                ($0.shortcut?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return templates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.moltPrimary)
                Text("Quick Templates")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.moltTextMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            
            SubtleDivider()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.moltTextMuted)
                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                    .tint(.moltTextPrimary)
            }
            .padding(Spacing.sm)
            .background(Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            
            // Category Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    TemplateCategoryPill(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(ResponseTemplate.TemplateCategory.allCases, id: \.self) { category in
                        TemplateCategoryPill(title: category.rawValue, isSelected: selectedCategory == category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.sm)
            
            SubtleDivider()
            
            // Templates List
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(filteredTemplates) { template in
                        TemplateRow(template: template) {
                            onSelect(template)
                        }
                    }
                }
                .padding(Spacing.md)
            }
        }
        .frame(width: 380, height: 450)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
        .shadow(color: Color.black.opacity(0.2), radius: 20)
    }
}

// MARK: - Template Category Pill (renamed to avoid conflict)
struct TemplateCategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.moltCaption)
                .foregroundColor(isSelected ? .white : .moltTextSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.large)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Row
struct TemplateRow: View {
    let template: ResponseTemplate
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(template.title)
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.moltTextPrimary)
                    
                    if let shortcut = template.shortcut {
                        Text(shortcut)
                            .font(.moltCaption)
                            .foregroundColor(.moltPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.moltPrimaryLight)
                            .cornerRadius(CornerRadius.small)
                    }
                    
                    Spacer()
                    
                    Text(template.category.rawValue)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                
                Text(template.content)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
                    .lineLimit(2)
            }
            .padding(Spacing.md)
            .background(isHovered ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Template Button for MessageInputView
struct TemplateButton: View {
    @Binding var showTemplates: Bool
    
    var body: some View {
        Button(action: { showTemplates.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
                Text("Templates")
                    .font(.moltLabel)
            }
            .foregroundColor(showTemplates ? .white : .moltPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(showTemplates ? Color.moltPrimary : Color.moltPrimaryLight)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}
