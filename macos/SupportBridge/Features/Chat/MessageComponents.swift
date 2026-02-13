import SwiftUI
import AVFoundation

// MARK: - Read Receipt Indicator
struct ReadReceiptIndicator: View {
    let status: MessageStatus
    let readAt: Date?
    
    var body: some View {
        HStack(spacing: 1) {
            switch status {
            case .pending:
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.moltTextMuted)
            case .sent:
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.moltTextMuted)
            case .delivered:
                HStack(spacing: -3) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.moltTextMuted)
            case .read:
                HStack(spacing: -3) {
                    Image(systemName: "checkmark")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.moltPrimary)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.priorityUrgent)
            }
        }
    }
}

// MARK: - Date Separator
struct DateSeparator: View {
    let date: Date
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.moltDivider)
                .frame(height: 1)
            
            Text(formattedDate)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
                .padding(.horizontal, Spacing.md)
            
            Rectangle()
                .fill(Color.moltDivider)
                .frame(height: 1)
        }
        .padding(.vertical, Spacing.md)
    }
    
    var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Quoted Message View
struct QuotedMessageView: View {
    let senderName: String
    let preview: String
    let senderType: SenderType
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(senderName)
                        .font(.moltLabel)
                        .foregroundColor(accentColor)
                    
                    Text(preview)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextSecondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
            }
            .background(Color.moltSurfaceSecondary.opacity(0.5))
            .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(.plain)
    }
    
    var accentColor: Color {
        switch senderType {
        case .parent: return .moltPrimary
        case .agent: return .priorityLow
        case .bot: return .priorityMedium
        case .team: return .priorityHigh
        case .system: return .moltTextMuted
        }
    }
}

// MARK: - Reaction Bar
struct ReactionBar: View {
    let reactions: [MessageReaction]
    var onTap: (() -> Void)? = nil
    
    var groupedReactions: [(String, Int)] {
        var counts: [String: Int] = [:]
        for reaction in reactions {
            counts[reaction.emoji, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 4) {
                ForEach(groupedReactions.prefix(6), id: \.0) { emoji, count in
                    HStack(spacing: 2) {
                        Text(emoji)
                            .font(.system(size: 12))
                        if count > 1 {
                            Text("\(count)")
                                .font(.system(size: 10))
                                .foregroundColor(.moltTextSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.moltSurface)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reaction Picker
struct ReactionPicker: View {
    let onSelect: (String) -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ForEach(MessageReaction.quickReactions, id: \.self) { emoji in
                Button(action: { onSelect(emoji) }) {
                    Text(emoji)
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
            }
            
            Button(action: { onSelect("+") }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.moltTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Link Preview Card
struct LinkPreviewCard: View {
    let preview: LinkPreview
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let imageUrl = preview.imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.moltSurfaceSecondary)
                }
                .frame(height: 120)
                .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let title = preview.title {
                    Text(title)
                        .font(.moltBodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(.moltTextPrimary)
                        .lineLimit(2)
                }
                
                if let description = preview.description {
                    Text(description)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextSecondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                    Text(preview.domain ?? preview.url)
                        .font(.moltLabel)
                }
                .foregroundColor(.moltTextMuted)
            }
            .padding(Spacing.sm)
        }
        .background(Color.moltSurfaceSecondary)
        .cornerRadius(CornerRadius.medium)
    }
}

// MARK: - Voice Message Player
// MARK: - Voice Message Player
struct VoiceMessagePlayer: View {
    let duration: TimeInterval
    let url: URL?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var currentTime: TimeInterval = 0
    @State private var player: AVAudioPlayer?
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Button(action: togglePlayback) {
                ZStack {
                    Circle()
                        .fill(Color.moltPrimary)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                // Waveform visualization
                WaveformView(progress: progress)
                    .frame(height: 24)
                
                Text(formatDuration(isPlaying ? currentTime : duration))
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
        }
        .padding(Spacing.sm)
        .onDisappear {
            stopPlayback()
        }
    }
    
    func togglePlayback() {
        if isPlaying {
            player?.pause()
            timer?.invalidate()
            isPlaying = false
        } else {
            startPlayback()
        }
    }
    
    func startPlayback() {
        guard let url = url else { return }
        
        // If player not initialized or finished
        if player == nil {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
            } catch {
                print("Failed to init audio player: \(error)")
                return
            }
        }
        
        player?.play()
        isPlaying = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let p = player {
                currentTime = p.currentTime
                progress = currentTime / duration
                if !p.isPlaying {
                    stopPlayback()
                }
            }
        }
    }
    
    func stopPlayback() {
        player?.stop()
        timer?.invalidate()
        isPlaying = false
        currentTime = 0
        progress = 0
        player = nil
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Waveform View
struct WaveformView: View {
    let progress: Double
    let barCount = 30
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { i in
                    let height = randomHeight(for: i)
                    let isPlayed = Double(i) / Double(barCount) <= progress
                    
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPlayed ? Color.moltPrimary : Color.moltTextMuted.opacity(0.4))
                        .frame(width: 3, height: geo.size.height * height)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
    
    func randomHeight(for index: Int) -> Double {
        // Pseudo-random based on index for consistent look
        let seed = Double(index * 7 % 13) / 13.0
        return 0.3 + seed * 0.7
    }
}

// MARK: - Image Preview Bubble
struct ImagePreviewBubble: View {
    let imageUrl: String?
    let caption: String?
    @State private var showFullscreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(action: { showFullscreen = true }) {
                ZStack {
                    Rectangle()
                        .fill(Color.moltSurfaceSecondary)
                        .frame(width: 200, height: 150)
                    
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.moltTextMuted)
                }
                .cornerRadius(CornerRadius.medium)
            }
            .buttonStyle(.plain)
            
            if let caption = caption, !caption.isEmpty {
                Text(caption)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
            }
        }
        .sheet(isPresented: $showFullscreen) {
            ImageFullscreenView(imageUrl: imageUrl, isPresented: $showFullscreen)
        }
    }
}

// MARK: - Image Fullscreen View
struct ImageFullscreenView: View {
    let imageUrl: String?
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                
                Spacer()
                
                Image(systemName: "photo")
                    .font(.system(size: 100))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - Deleted Message View
struct DeletedMessageView: View {
    let isFromMe: Bool
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "nosign")
                .font(.system(size: 12))
            Text("This message was deleted")
                .font(.moltCaption)
                .italic()
        }
        .foregroundColor(.moltTextMuted)
        .padding(Spacing.md)
        .background(isFromMe ? Color.bubbleAgent.opacity(0.5) : Color.bubbleParent.opacity(0.5))
        .cornerRadius(CornerRadius.bubble)
    }
}

// MARK: - Forwarded Label
struct ForwardedLabel: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrowshape.turn.up.forward.fill")
                .font(.system(size: 10))
            Text("Forwarded")
                .font(.moltLabel)
        }
        .foregroundColor(.moltTextMuted)
        .padding(.bottom, 2)
    }
}

// MARK: - Starred Indicator
struct StarredIndicator: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 10))
            .foregroundColor(.priorityHigh)
    }
}

// MARK: - Last Seen Status
struct LastSeenStatus: View {
    let isOnline: Bool
    let lastSeen: Date?
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOnline ? Color.priorityLow : Color.moltTextMuted)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.moltCaption)
                .foregroundColor(.moltTextSecondary)
        }
    }
    
    var statusText: String {
        if isOnline {
            return "Online"
        }
        guard let lastSeen = lastSeen else {
            return "Offline"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last seen \(formatter.localizedString(for: lastSeen, relativeTo: Date()))"
    }
}

// MARK: - Message Context Menu
struct MessageContextMenu: View {
    let message: Message
    let onReply: () -> Void
    let onReact: () -> Void
    let onStar: () -> Void
    let onForward: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    /// Whether this is the current user's own message (can edit/delete)
    var isOwnMessage: Bool {
        message.senderType == .agent
    }
    
    var body: some View {
        Group {
            // Reply - available for all messages
            Button(action: onReply) {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
            
            // React - available for all messages
            Button(action: onReact) {
                Label("React", systemImage: "face.smiling")
            }
            
            Divider()
            
            // Star/Unstar - available for all messages
            Button(action: onStar) {
                Label(message.isStarred ? "Unstar" : "Star", systemImage: message.isStarred ? "star.slash" : "star")
            }
            
            // Forward - available for all messages
            Button(action: onForward) {
                Label("Forward", systemImage: "arrowshape.turn.up.forward")
            }
            
            // Copy - available for all messages
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            // Delete - only for own messages
            if isOwnMessage {
                Divider()
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete for Everyone", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Online Status Dot
struct OnlineStatusDot: View {
    let isOnline: Bool
    let size: CGFloat
    
    init(isOnline: Bool, size: CGFloat = 10) {
        self.isOnline = isOnline
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(isOnline ? Color.priorityLow : Color.moltTextMuted)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.moltSurface, lineWidth: 2)
            )
    }
}
