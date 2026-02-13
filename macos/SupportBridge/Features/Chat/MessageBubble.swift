import SwiftUI
import ImageIO

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    var onReply: ((Message) -> Void)?
    var onReact: ((Message) -> Void)?
    var onStar: ((Message) -> Void)?
    var onForward: ((Message) -> Void)?
    var onDelete: ((Message) -> Void)?
    
    @State private var isHovering = false
    
    var isFromParent: Bool {
        message.senderType == .parent
    }
    
    var isSystemMessage: Bool {
        message.senderType == .system
    }

    private var isImageLikeMessage: Bool {
        if message.messageType == .image { return true }
        if message.messageType == .document, let imageURL = message.imageUrl?.lowercased() {
            let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".heic", ".heif"]
            if imageExtensions.contains(where: { imageURL.hasSuffix($0) }) {
                return true
            }
        }
        if message.content.lowercased().contains("<media:sticker>") { return true }
        return message.content.lowercased().contains("[media attached:")
    }
    
    var body: some View {
        if isSystemMessage {
            SystemMessageView(message: message)
        } else if message.isDeleted {
            // Deleted message placeholder
            HStack {
                if !isFromParent { Spacer(minLength: 60) }
                DeletedMessageView(isFromMe: !isFromParent)
                if isFromParent { Spacer(minLength: 60) }
            }
        } else {
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                if !isFromParent {
                    Spacer(minLength: 60)
                }
                
                VStack(alignment: isFromParent ? .leading : .trailing, spacing: 4) {
                    // Sender Label
                    HStack(spacing: 4) {
                        if message.senderType == .bot {
                            Image(systemName: "cpu")
                                .font(.system(size: 10))
                        }
                        Text(senderLabel)
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        if message.isStarred {
                            StarredIndicator()
                        }
                    }
                    
                    // Bubble Content
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        // Forwarded indicator
                        if message.isForwarded {
                            ForwardedLabel()
                        }
                        
                        // Quoted/Reply message
                        if let replyPreview = message.replyToPreview {
                            QuotedMessageView(
                                senderName: message.replyToSenderName ?? "Original message",
                                preview: replyPreview,
                                senderType: message.replyToSenderType ?? .parent
                            )
                        }
                        
                        // Voice message
                        if message.messageType == .audio, let duration = message.voiceDuration {
                            VoiceMessagePlayer(duration: duration, url: URL(fileURLWithPath: message.content))
                        }
                        // Image message
                        else if isImageLikeMessage {
                            ImageMessageView(message: message)
                        }
                        // Link preview
                        else if let linkPreview = message.linkPreview {
                            LinkPreviewCard(preview: linkPreview)
                        }
                        
                        // Text content
                        let displayText = cleanedDisplayText()
                        if !displayText.isEmpty && !isImageLikeMessage && message.messageType != .audio {
                            HStack(alignment: .bottom, spacing: Spacing.sm) {
                                if message.senderType == .bot {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundColor(.moltPrimary.opacity(0.7))
                                }
                                
                                Text(displayText)
                                    .font(.moltBody)
                                    .foregroundColor(.moltTextPrimary)
                            }
                        } else if isImageLikeMessage && !displayText.isEmpty {
                            Text(displayText)
                                .font(.moltCaption)
                                .foregroundColor(.moltTextSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(bubbleColor)
                    .cornerRadius(CornerRadius.bubble, corners: corners)
                    .contextMenu {
                        MessageContextMenu(
                            message: message,
                            onReply: { onReply?(message) },
                            onReact: { onReact?(message) },
                            onStar: { onStar?(message) },
                            onForward: { onForward?(message) },
                            onCopy: { copyMessage() },
                            onDelete: { onDelete?(message) }
                        )
                    }
                    .overlay(alignment: isFromParent ? .bottomLeading : .bottomTrailing) {
                        // Reaction bar
                        if let reactions = message.reactions, !reactions.isEmpty {
                            ReactionBar(reactions: reactions)
                                .offset(y: 12)
                        }
                    }
                    
                    // Timestamp + Edited + Read Receipts
                    HStack(spacing: 4) {
                        if message.isEdited {
                            Text("edited")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextMuted)
                                .italic()
                        }
                        
                        Text(formatTime(message.sentAt))
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                        
                        if !isFromParent {
                            ReadReceiptIndicator(status: message.status, readAt: message.readAt)
                        }
                    }
                    .padding(.top, message.reactions?.isEmpty == false ? 8 : 0)
                }
                
                if isFromParent {
                    Spacer(minLength: 60)
                }
            }
            .onHover { hovering in
                isHovering = hovering
            }
            
            // Hover Reply Button
            if isHovering {
                Button(action: { onReply?(message) }) {
                    Image(systemName: "arrowshape.turn.up.left.none") // Reply icon
                        .font(.system(size: 14))
                        .foregroundColor(.moltTextMuted)
                        .padding(6)
                        .background(Color.moltSurfaceSecondary)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .padding(.horizontal, 4)
            }
        }
    }
    
    var senderLabel: String {
        switch message.senderType {
        case .parent: return "Parent"
        case .agent: return "You"
        case .bot: return "SupportBridge AI"
        case .team: return "Team"
        case .system: return "System"
        }
    }
    
    var bubbleColor: Color {
        switch message.senderType {
        case .parent: return .bubbleParent
        case .agent, .bot, .team, .system: return .bubbleBot
        }
    }
    
    var corners: UIRectCorner {
        if isFromParent {
            return [.topLeft, .topRight, .bottomRight]
        } else {
            return [.topLeft, .topRight, .bottomLeft]
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func copyMessage() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cleanedDisplayText(), forType: .string)
    }

    private func cleanedDisplayText() -> String {
        var text = message.content
        if let range = text.range(of: "To send an image back, prefer the message tool", options: .caseInsensitive) {
            text = String(text[..<range.lowerBound])
        }
        text = text.replacingOccurrences(of: "[Queued messages while agent was busy]", with: "")
        text = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                if line.isEmpty { return false }
                if line == "---" { return false }
                if line.lowercased().hasPrefix("queued #") { return false }
                if line.lowercased().hasPrefix("[whatsapp "), let idx = line.firstIndex(of: "]") {
                    let remainder = line[line.index(after: idx)...].trimmingCharacters(in: .whitespacesAndNewlines)
                    return !remainder.isEmpty
                }
                return !line.lowercased().hasPrefix("[media attached:")
            }
            .map { line -> String in
                if line.lowercased().hasPrefix("[whatsapp "), let idx = line.firstIndex(of: "]") {
                    return String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return line
            }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text
    }
}

// MARK: - System Message View
struct SystemMessageView: View {
    let message: Message
    
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: Spacing.sm) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.moltTextMuted)
                Text(message.content)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
            Spacer()
        }
    }
}

// MARK: - Image Message View
struct ImageMessageView: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let image = resolvedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .fill(Color.moltSurfaceSecondary)
                        .frame(width: 200, height: 150)
                    
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: imageIcon)
                            .font(.system(size: 32))
                            .foregroundColor(.moltPrimary)
                        
                        Text(imageLabel)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextSecondary)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(Color.moltBorder, lineWidth: 1)
                )
            }
        }
    }
    
    var imageIcon: String {
        if message.imageUrl?.contains("receipt") == true {
            return "doc.text.image"
        } else if message.imageUrl?.contains("bank") == true {
            return "building.columns"
        } else if message.imageUrl?.contains("medical") == true {
            return "cross.case"
        }
        return "photo"
    }
    
    var imageLabel: String {
        if message.content.lowercased().contains("<media:sticker>") ||
            message.metadata?["media_mime_type"]?.lowercased().contains("webp") == true {
            return "Sticker"
        }
        if message.imageUrl?.contains("receipt") == true {
            return "Payment Receipt"
        } else if message.imageUrl?.contains("bank") == true {
            return "Bank Statement"
        } else if message.imageUrl?.contains("medical") == true {
            return "Medical Certificate"
        }
        return "Image Attachment"
    }

    private var resolvedImage: NSImage? {
        if let imageURL = message.imageUrl, let image = loadImage(from: imageURL) {
            return image
        }
        if let inline = inlineMediaPath(from: message.content), let image = loadImage(from: inline) {
            return image
        }
        return nil
    }

    private func loadImage(from rawValue: String) -> NSImage? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return nil }

        if value.hasPrefix("local://uploads/") {
            let filename = String(value.dropFirst("local://uploads/".count))
            let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("supportbridge_uploads/\(filename)")
            return decodeImage(fromFile: tempPath)
        }

        if value.hasPrefix("http://") || value.hasPrefix("https://"), let url = URL(string: value), let data = try? Data(contentsOf: url) {
            return decodeImage(fromData: data)
        }

        if value.hasPrefix("file://"), let url = URL(string: value) {
            return decodeImage(fromFile: url.path)
        }

        return decodeImage(fromFile: value)
    }

    private func inlineMediaPath(from text: String) -> String? {
        let pattern = #"\[media attached:\s*([^\n\]]+?)\s*\(([^)]+)\)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges >= 2 else {
            return nil
        }
        return ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeImage(fromFile path: String) -> NSImage? {
        if let image = NSImage(contentsOfFile: path) {
            return image
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return decodeImage(fromData: data)
    }

    private func decodeImage(fromData data: Data) -> NSImage? {
        if let image = NSImage(data: data) {
            return image
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: .zero)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: radius,
            yRadius: radius
        )
        return Path(path.cgPath)
    }
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
}

// UIRectCorner for macOS
struct UIRectCorner: OptionSet {
    let rawValue: Int
    static let topLeft = UIRectCorner(rawValue: 1 << 0)
    static let topRight = UIRectCorner(rawValue: 1 << 1)
    static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}
