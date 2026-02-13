import SwiftUI
import AppKit

struct MessageInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    var onSendVoice: ((URL, TimeInterval) -> Void)?
    var onSendAttachment: ((URL, MessageType) -> Void)?
    
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showAIAssist = false
    @State private var selectedAttachmentURL: URL?
    @State private var selectedAttachmentType: MessageType?
    @State private var selectedAttachmentPreview: NSImage?
    @State private var showTemplates = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Recording UI Overlay
            if audioRecorder.isRecording {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.red)
                        .pulse(repeating: true)
                    
                    Text(timeString(from: audioRecorder.recordingTime))
                        .font(.monospacedDigit(.body)())
                        .foregroundColor(.moltTextPrimary)
                    
                    Spacer()
                    
                    Text("Recording...")
                        .font(.caption)
                        .foregroundColor(.moltTextMuted)
                    
                    Spacer()
                    
                    Button(action: {
                        audioRecorder.cancelRecording()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.moltTextMuted)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                    
                    Button(action: {
                        audioRecorder.stopRecording()
                        if let url = audioRecorder.audioFilename {
                            onSendVoice?(url, audioRecorder.recordingTime)
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.moltPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(Spacing.md)
                .background(Color.moltSurface)
                .transition(.move(edge: .bottom))
            } else {
                // Templates Picker
                if showTemplates {
                    QuickTemplatesView(
                        onSelect: { template in
                            text = template.content
                            showTemplates = false
                        },
                        onDismiss: {
                            showTemplates = false
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // AI Quick Suggestions
                if showAIAssist {
                    AISuggestionBar(onSelect: { suggestion in
                        text = suggestion
                        showAIAssist = false
                    }, onDismiss: {
                        showAIAssist = false
                    })
                }
                
                // Attachment Preview
                if let preview = selectedAttachmentPreview {
                    AttachmentPreviewBar(
                        image: preview,
                        type: selectedAttachmentType ?? .image,
                        filename: selectedAttachmentURL?.lastPathComponent ?? "File",
                        onRemove: clearAttachment
                    )
                }
                
                // Input Bar Container
                HStack(spacing: Spacing.md) {
                    // Attachment Menu
                    Menu {
                        Button(action: selectImage) {
                            Label("Photos & Videos", systemImage: "photo")
                        }
                        Button(action: selectDocument) {
                            Label("Document", systemImage: "doc.fill")
                        }
                        Button(action: {}) { // Placeholder
                            Label("Contact", systemImage: "person.crop.circle")
                        }
                    } label: {
                        Image(systemName: "paperclip")
                            .font(.system(size: 18))
                            .foregroundColor(selectedAttachmentURL != nil ? .moltPrimary : .moltTextSecondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    
                    // Text Field
                    HStack {
                        TextField("Type a message...", text: $text, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                            .tint(.moltTextPrimary)
                            .accentColor(.moltTextPrimary)
                            .lineLimit(1...4)
                            .onSubmit(handleSend)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.large)
                    .accentColor(.moltTextPrimary)
                    
                    // AI Assist Button
                    if text.isEmpty {
                        Button(action: { showAIAssist.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                Text("AI")
                                    .font(.moltLabel)
                            }
                            .foregroundColor(showAIAssist ? .white : .moltPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(showAIAssist ? Color.moltPrimary : Color.moltPrimaryLight)
                            .cornerRadius(CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Template Button
                    if text.isEmpty {
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
                    
                    // Send or Mic Button
                    if canSend {
                        Button(action: handleSend) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.moltPrimary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            audioRecorder.checkPermissions { allowed in
                                if allowed {
                                    audioRecorder.startRecording()
                                }
                            }
                        }) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.moltTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.md)
                .background(Color.moltSurface)
            }
        }
        .animation(.spring(), value: audioRecorder.isRecording)
    }
    
    var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedAttachmentURL != nil
    }
    
    func handleSend() {
        if let url = selectedAttachmentURL, let type = selectedAttachmentType {
            onSendAttachment?(url, type)
            clearAttachment()
        }
        
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onSend()
        }
    }
    
    func clearAttachment() {
        selectedAttachmentURL = nil
        selectedAttachmentType = nil
        selectedAttachmentPreview = nil
    }
    
    func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .jpeg, .png]
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                selectedAttachmentURL = url
                selectedAttachmentType = .image
                selectedAttachmentPreview = image
            }
        }
    }
    
    func selectDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, .text, .plainText, .data]
        
        if panel.runModal() == .OK, let url = panel.url {
            selectedAttachmentURL = url
            selectedAttachmentType = .document
            selectedAttachmentPreview = NSWorkspace.shared.icon(forFile: url.path)
        }
    }
    
    func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Helper for Pulse Animation
extension View {
    func pulse(repeating: Bool) -> some View {
        self.modifier(PulseModifier(repeating: repeating))
    }
}

struct PulseModifier: ViewModifier {
    let repeating: Bool
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.5 : 1.0)
            .onAppear {
                if repeating {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                        isPulsing = true
                    }
                }
            }
    }
}

// MARK: - Attachment Preview Bar
struct AttachmentPreviewBar: View {
    let image: NSImage
    let type: MessageType
    let filename: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .cornerRadius(CornerRadius.small)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type == .image ? "Photo attached" : "Document attached")
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                Text(filename)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.moltTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(Color.moltSurfaceSecondary)
    }
}

// MARK: - AI Suggestion Bar
struct AISuggestionBar: View {
    let onSelect: (String) -> Void
    let onDismiss: () -> Void
    
    let suggestions = [
        "Thank you for reaching out! Let me help you with that.",
        "I understand your concern. Let me check on this for you.",
        "Our office hours are Monday to Friday, 8 AM to 4 PM."
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.moltPrimary)
                Text("AI Suggestions")
                    .font(.moltLabel)
                    .foregroundColor(.moltTextSecondary)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.moltTextMuted)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: { onSelect(suggestion) }) {
                            Text(suggestion)
                                .font(.moltCaption)
                                .foregroundColor(.moltTextPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .padding(Spacing.sm)
                                .frame(maxWidth: 200, alignment: .leading)
                                .background(Color.bubbleBot)
                                .cornerRadius(CornerRadius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.moltSurfaceSecondary)
    }
}
