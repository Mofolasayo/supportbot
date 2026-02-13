import SwiftUI

struct KnowledgeBaseView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: KBCategory = .general
    @State private var searchText = ""
    @State private var selectedArticle: KBArticle?
    @State private var isAddingNew = false

    private var articles: [KBArticle] {
        if appState.isAuthenticated {
            return appState.kbArticles
        }
        return KBArticle.mockList
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Categories + Articles List
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Knowledge Base")
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedArticle = nil
                        isAddingNew = true
                    }) {
                        Label("Add Article", systemImage: "plus")
                            .font(.moltLabel)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.moltPrimary)
                            .cornerRadius(CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                }
                .appHeaderAligned()
                .background(Color.moltSurface)
                
                SubtleDivider()
    
                // Search + Categories
                HStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.moltTextMuted)
                        TextField("Search articles...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                    }
                    .padding(Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                    .frame(minWidth: 220)
                    .layoutPriority(1)
                    
                    KBCategorySelector(
                        selectedCategory: $selectedCategory,
                        counts: categoryCounts
                    )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(Color.moltSurface)
                
                SubtleDivider()
    
                
                // Articles List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredArticles) { article in
                            ArticleRow(
                                article: article,
                                isSelected: selectedArticle?.id == article.id
                            )
                            .onTapGesture {
                                selectedArticle = article
                            }
                            
                            SubtleDivider()
                
                        }
                    }
                }
                .background(Color.moltSurface)
            }
            .frame(minWidth: 350)
            
            SubtleVerticalDivider()
            
            // Article Detail
            if let article = selectedArticle {
                ArticleDetailView(article: article)
            } else if isAddingNew {
                NewArticleView(
                    onCancel: {
                        isAddingNew = false
                    },
                    onSave: { newArticle in
                        _Concurrency.Task {
                            do {
                                let created = try await appState.createKnowledgeBaseArticle(
                                    title: newArticle.title,
                                    content: newArticle.content,
                                    category: newArticle.category
                                )
                                await MainActor.run {
                                    selectedArticle = created
                                    selectedCategory = created.category
                                    isAddingNew = false
                                }
                            } catch {
                                print("Failed to create knowledge base article: \(error)")
                            }
                        }
                    }
                )
            } else {
                EmptyKBView()
            }
        }
        .background(Color.moltBackground)
        .task {
            await appState.refreshKnowledgeBase(category: selectedCategory, query: searchText)
        }
        .onChange(of: selectedCategory) { newCategory in
            _Concurrency.Task { await appState.refreshKnowledgeBase(category: newCategory, query: searchText) }
        }
        .onChange(of: searchText) { newQuery in
            _Concurrency.Task { await appState.refreshKnowledgeBase(category: selectedCategory, query: newQuery) }
        }
    }
    
    var filteredArticles: [KBArticle] {
        var filtered = articles.filter { $0.category == selectedCategory }
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        return filtered
    }

    private var categoryCounts: [KBCategory: Int] {
        Dictionary(grouping: articles, by: { $0.category })
            .mapValues { $0.count }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                Text("\(count)")
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.moltTextMuted.opacity(0.2))
                    .cornerRadius(10)
            }
            .font(.moltLabel)
            .foregroundColor(isSelected ? .white : .moltTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.large)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Selector
struct KBCategorySelector: View {
    @Binding var selectedCategory: KBCategory
    let counts: [KBCategory: Int]
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.sm) {
                ForEach(KBCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        label: category.label,
                        count: counts[category] ?? 0,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            
            Menu {
                ForEach(KBCategory.allCases, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        let count = counts[category] ?? 0
                        if selectedCategory == category {
                            Label("\(category.label) (\(count))", systemImage: "checkmark")
                        } else {
                            Text("\(category.label) (\(count))")
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedCategory.label)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.moltTextMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.large)
            }
            .menuStyle(.borderlessButton)
        }
    }
}

// MARK: - Article Row
struct ArticleRow: View {
    let article: KBArticle
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(article.title)
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.moltTextPrimary)
                    
                    if article.isActive {
                        Circle()
                            .fill(Color.priorityLow)
                            .frame(width: 6, height: 6)
                    }
                }
                
                Text(article.content)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
                    .lineLimit(2)
                
                HStack(spacing: Spacing.md) {
                    Label("\(article.usageCount) uses", systemImage: "chart.bar")
                        .font(.moltLabel)
                        .foregroundColor(.moltTextMuted)
                    
                    Text("Updated \(timeAgo(article.lastUpdated))")
                        .font(.moltLabel)
                        .foregroundColor(.moltTextMuted)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.moltTextMuted)
        }
        .padding(Spacing.lg)
        .background(isSelected ? Color.moltPrimaryLight : Color.clear)
        .contentShape(Rectangle())
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Article Detail View
struct ArticleDetailView: View {
    let article: KBArticle
    @State private var isEditing = false
    @State private var editedContent: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    
                    HStack(spacing: Spacing.md) {
                        Label(article.category.label, systemImage: "folder")
                        Label("\(article.usageCount) uses", systemImage: "chart.bar")
                    }
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                }
                
                Spacer()
                
                HStack(spacing: Spacing.sm) {
                    Toggle("", isOn: .constant(article.isActive))
                        .toggleStyle(.switch)
                    
                    Button(action: { isEditing.toggle() }) {
                        Label(isEditing ? "Save" : "Edit", systemImage: isEditing ? "checkmark" : "pencil")
                            .font(.moltLabel)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.moltPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.moltPrimaryLight)
                    .cornerRadius(CornerRadius.medium)
                }
            }
            .appHeaderAligned()
            .background(Color.moltSurface)
            
            SubtleDivider()

            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Content Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Response Content")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        if isEditing {
                            TextEditor(text: $editedContent)
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                                .tint(.moltTextPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 150)
                                .padding(Spacing.md)
                                .background(Color.moltSurfaceSecondary)
                                .cornerRadius(CornerRadius.medium)
                                .onAppear { editedContent = article.content }
                        } else {
                            Text(article.content)
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                                .padding(Spacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.moltSurface)
                                .cornerRadius(CornerRadius.medium)
                        }
                    }
                    
                    // Training Section
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("AI Training Notes")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        Text("SupportBridge AI will use this article when users ask about school resumption, opening dates, or when classes start.")
                            .font(.moltBody)
                            .foregroundColor(.moltTextSecondary)
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.bubbleBot)
                            .cornerRadius(CornerRadius.medium)
                    }
                    
                    // Keywords
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Trigger Keywords")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        FlowLayout(spacing: Spacing.sm) {
                            KeywordTag(text: "resumption")
                            KeywordTag(text: "school open")
                            KeywordTag(text: "start date")
                            KeywordTag(text: "when resume")
                            KeywordTag(text: "+", isAdd: true)
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.moltBackground)
        }
        .frame(minWidth: 400)
    }

}

// MARK: - Flow Layout for Keywords
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(subviews: subviews, width: proposal.width ?? 0)
        return CGSize(width: result.width, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
    
    private func arrange(subviews: Subviews, width: CGFloat) -> (width: CGFloat, height: CGFloat) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
            rowHeight = max(rowHeight, size.height)
        }
        
        return (maxWidth, y + rowHeight)
    }
}

// MARK: - Keyword Tag
struct KeywordTag: View {
    let text: String
    var isAdd: Bool = false
    
    var body: some View {
        Text(text)
            .font(.moltLabel)
            .foregroundColor(isAdd ? .moltPrimary : .moltTextSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isAdd ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.large)
    }
}

// MARK: - New Article View
struct NewArticleView: View {
    let onCancel: () -> Void
    let onSave: (KBArticle) -> Void
    @State private var title = ""
    @State private var content = ""
    @State private var category: KBCategory = .general
    @State private var attachedFiles: [String] = []
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Article")
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button("Cancel") { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.moltTextSecondary)
                
                Button(action: onSaveTapped) {
                    HStack(spacing: Spacing.xs) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .moltPrimary))
                                .scaleEffect(0.8)
                        }
                        Text("Save Article")
                            .font(.moltLabel)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(canSave ? Color.moltPrimary : Color.moltTextMuted)
                    .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(!canSave || isSaving)
            }
            .appHeaderAligned()
            .background(Color.moltSurface)
            
            SubtleDivider()

            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Title
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Title")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        TextField("Article title", text: $title)
                            .textFieldStyle(.plain)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .padding(Spacing.md)
                            .background(Color.moltSurfaceSecondary)
                            .cornerRadius(CornerRadius.medium)
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Category")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        HStack(spacing: Spacing.sm) {
                            ForEach(KBCategory.allCases, id: \.self) { cat in
                                CategoryButton(
                                    label: cat.label,
                                    isSelected: category == cat
                                ) {
                                    category = cat
                                }
                            }
                        }
                    }
                    
                    // Response Content
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Response Content")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Enter the response that SupportBridge AI should use...")
                                    .font(.moltBody)
                                    .foregroundColor(.moltTextMuted)
                                    .padding(Spacing.md)
                            }
                            
                            TextEditor(text: $content)
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                                .tint(.moltTextPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 150)
                                .padding(Spacing.sm)
                        }
                        .background(Color.moltSurfaceSecondary)
                        .cornerRadius(CornerRadius.medium)
                    }
                    
                    // File Attachments
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Attachments (Optional)")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        // Attached files list
                        if !attachedFiles.isEmpty {
                            VStack(spacing: Spacing.xs) {
                                ForEach(attachedFiles, id: \.self) { file in
                                    HStack {
                                        Image(systemName: "doc.fill")
                                            .foregroundColor(.moltPrimary)
                                        Text(file)
                                            .font(.moltBodySmall)
                                            .foregroundColor(.moltTextPrimary)
                                        Spacer()
                                        Button(action: { attachedFiles.removeAll { $0 == file } }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.moltTextMuted)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(Spacing.sm)
                                    .background(Color.moltSurface)
                                    .cornerRadius(CornerRadius.small)
                                }
                            }
                        }
                        
                        // Add file button
                        Button(action: {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = true
                            panel.canChooseFiles = true
                            panel.canChooseDirectories = false
                            panel.allowedContentTypes = [.pdf, .plainText, .rtf]
                            if panel.runModal() == .OK {
                                for url in panel.urls {
                                    attachedFiles.append(url.lastPathComponent)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Files (PDF, TXT, RTF)")
                            }
                            .font(.moltBody)
                            .foregroundColor(.moltPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.md)
                            .background(Color.moltPrimaryLight)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.moltBackground)
        }
        .frame(minWidth: 400)
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func onSaveTapped() {
        guard canSave else { return }
        isSaving = true
        let newArticle = KBArticle(
            id: UUID().uuidString,
            title: title,
            content: content,
            category: category,
            lastUpdated: Date(),
            usageCount: 0,
            isActive: true
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            onSave(newArticle)
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.moltLabel)
                .foregroundColor(isSelected ? .white : .moltTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State
struct EmptyKBView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.moltTextMuted)
            
            Text("Select an Article")
                .font(.moltTitleSmall)
                .foregroundColor(.moltTextPrimary)
            
            Text("Choose an article to view or edit its content")
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
}
