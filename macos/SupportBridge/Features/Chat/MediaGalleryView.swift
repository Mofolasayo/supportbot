import SwiftUI

// MARK: - Media Gallery View
struct MediaGalleryView: View {
    let conversationId: String
    @Binding var isPresented: Bool
    @State private var selectedFilter: MediaFilter = .all
    @State private var selectedMedia: MediaItem? = nil
    
    // Mock media items for the conversation
    var mediaItems: [MediaItem] {
        MediaItem.mockItems(for: conversationId).filter { item in
            switch selectedFilter {
            case .all: return true
            case .images: return item.type == .image
            case .videos: return item.type == .video
            case .documents: return item.type == .document
            case .links: return item.type == .link
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { isPresented = false }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.moltTextSecondary)
                }
                .buttonStyle(.plain)
                
                Text("Media & Links")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Text("\(mediaItems.count) items")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            .padding(Spacing.lg)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Filter tabs
            HStack(spacing: 0) {
                ForEach(MediaFilter.allCases, id: \.self) { filter in
                    MediaFilterTab(
                        label: filter.label,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.moltSurface)
            
            SubtleDivider()
            
            // Content
            if mediaItems.isEmpty {
                EmptyMediaView(filter: selectedFilter)
            } else {
                ScrollView {
                    if selectedFilter == .links {
                        // Links layout
                        LazyVStack(spacing: Spacing.sm) {
                            ForEach(mediaItems) { item in
                                LinkItemRow(item: item)
                            }
                        }
                        .padding(Spacing.md)
                    } else {
                        // Grid layout for images, videos, documents
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                            ForEach(mediaItems) { item in
                                MediaGridItem(item: item) {
                                    selectedMedia = item
                                }
                            }
                        }
                        .padding(2)
                    }
                }
                .background(Color.moltBackground)
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .background(Color.moltBackground)
        .sheet(item: $selectedMedia) { item in
            MediaDetailView(item: item, isPresented: .constant(true))
        }
    }
}

// MARK: - Media Filter
enum MediaFilter: String, CaseIterable {
    case all, images, videos, documents, links
    
    var label: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .images: return "photo"
        case .videos: return "video"
        case .documents: return "doc"
        case .links: return "link"
        }
    }
}

// MARK: - Media Filter Tab
struct MediaFilterTab: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                    Text(label)
                        .font(.moltLabel)
                }
                .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
                
                Rectangle()
                    .fill(isSelected ? Color.moltPrimary : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Media Item Model
struct MediaItem: Identifiable {
    let id: String
    var type: MediaType
    var url: String
    var thumbnailUrl: String?
    var title: String?
    var description: String?
    var size: Int?  // bytes
    var duration: TimeInterval?  // for videos
    var createdAt: Date
    var messageId: String
    
    enum MediaType: String {
        case image, video, document, link
    }
    
    static func mockItems(for conversationId: String) -> [MediaItem] {
        [
            MediaItem(id: "media-1", type: .image, url: "receipt.jpg", thumbnailUrl: nil, title: "Payment Receipt", description: nil, size: 245000, duration: nil, createdAt: Date().addingTimeInterval(-86400), messageId: "msg-1"),
            MediaItem(id: "media-2", type: .image, url: "bank_statement.jpg", thumbnailUrl: nil, title: "Bank Statement", description: nil, size: 312000, duration: nil, createdAt: Date().addingTimeInterval(-172800), messageId: "msg-2"),
            MediaItem(id: "media-3", type: .document, url: "medical_cert.pdf", thumbnailUrl: nil, title: "Medical Certificate", description: "Lagos General Hospital", size: 156000, duration: nil, createdAt: Date().addingTimeInterval(-259200), messageId: "msg-3"),
            MediaItem(id: "media-4", type: .link, url: "https://schoolable.com/calendar", thumbnailUrl: nil, title: "Academic Calendar 2025/2026", description: "View the complete academic calendar", size: nil, duration: nil, createdAt: Date().addingTimeInterval(-345600), messageId: "msg-4"),
            MediaItem(id: "media-5", type: .image, url: "school_photo.jpg", thumbnailUrl: nil, title: nil, description: nil, size: 425000, duration: nil, createdAt: Date().addingTimeInterval(-432000), messageId: "msg-5"),
            MediaItem(id: "media-6", type: .video, url: "event_video.mp4", thumbnailUrl: nil, title: "School Event", description: nil, size: 15600000, duration: 45, createdAt: Date().addingTimeInterval(-518400), messageId: "msg-6")
        ]
    }
}

// MARK: - Media Grid Item
struct MediaGridItem: View {
    let item: MediaItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(Color.moltSurfaceSecondary)
                    .aspectRatio(1, contentMode: .fill)
                
                Group {
                    switch item.type {
                    case .image:
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.moltTextMuted)
                    case .video:
                        ZStack {
                            Image(systemName: "video.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.moltTextMuted)
                            
                            if let duration = item.duration {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text(formatDuration(duration))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(4)
                                            .padding(4)
                                    }
                                }
                            }
                        }
                    case .document:
                        VStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.moltPrimary)
                            if let title = item.title {
                                Text(title)
                                    .font(.system(size: 9))
                                    .foregroundColor(.moltTextSecondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(4)
                    case .link:
                        Image(systemName: "link")
                            .font(.system(size: 24))
                            .foregroundColor(.moltPrimary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Link Item Row
struct LinkItemRow: View {
    let item: MediaItem
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(Color.moltPrimaryLight)
                    .frame(width: 48, height: 48)
                
                Image(systemName: "link")
                    .font(.system(size: 20))
                    .foregroundColor(.moltPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let title = item.title {
                    Text(title)
                        .font(.moltBody)
                        .foregroundColor(.moltTextPrimary)
                        .lineLimit(1)
                }
                
                Text(item.url)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                    .lineLimit(1)
                
                Text(formatDate(item.createdAt))
                    .font(.moltLabel)
                    .foregroundColor(.moltTextMuted)
            }
            
            Spacer()
            
            Button(action: { openLink(item.url) }) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16))
                    .foregroundColor(.moltTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.medium)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    func openLink(_ url: String) {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Empty Media View
struct EmptyMediaView: View {
    let filter: MediaFilter
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: filter.icon)
                .font(.system(size: 48))
                .foregroundColor(.moltTextMuted)
            
            Text("No \(filter.label.lowercased()) yet")
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
            
            Text("Media shared in this conversation will appear here")
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
}

// MARK: - Media Detail View
struct MediaDetailView: View {
    let item: MediaItem
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.title ?? "Media")
                            .font(.moltBody)
                            .foregroundColor(.white)
                        Text(formatDate(item.createdAt))
                            .font(.moltCaption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: Spacing.lg) {
                        Button(action: shareMedia) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: downloadMedia) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                
                Spacer()
                
                // Content placeholder
                Group {
                    switch item.type {
                    case .image:
                        Image(systemName: "photo")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                    case .video:
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.8))
                            if let duration = item.duration {
                                Text(formatDuration(duration))
                                    .font(.moltBody)
                                    .foregroundColor(.white)
                            }
                        }
                    case .document:
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.5))
                            Text(item.title ?? "Document")
                                .font(.moltBody)
                                .foregroundColor(.white)
                            if let size = item.size {
                                Text(formatSize(size))
                                    .font(.moltCaption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    case .link:
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "link")
                                .font(.system(size: 80))
                                .foregroundColor(.moltPrimary)
                            Text(item.url)
                                .font(.moltCaption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
    
    func shareMedia() {
        // Share functionality
    }
    
    func downloadMedia() {
        // Download functionality
    }
}

// MARK: - Media Gallery Button (for ChatDetailView)
struct MediaGalleryButton: View {
    let conversationId: String
    @State private var showGallery = false
    
    var body: some View {
        Button(action: { showGallery = true }) {
            Image(systemName: "photo.stack")
                .font(.system(size: 16))
                .foregroundColor(.moltTextSecondary)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showGallery) {
            MediaGalleryView(conversationId: conversationId, isPresented: $showGallery)
        }
    }
}
