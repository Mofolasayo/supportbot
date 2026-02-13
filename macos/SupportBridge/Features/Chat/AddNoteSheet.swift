import SwiftUI

struct AddNoteSheet: View {
    @EnvironmentObject var appState: AppState
    let conversationId: String
    @Binding var isPresented: Bool
    
    @State private var content = ""
    @State private var isPinned = false
    
    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                
                Text("Add Note")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button("Save") {
                    saveNote()
                }
                .buttonStyle(.plain)
                .foregroundColor(canSave ? .moltPrimary : .moltTextMuted)
                .disabled(!canSave)
            }
            .padding(Spacing.lg)
            
            SubtleDivider()
            
            // Form
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Note Content")
                        .font(.moltLabel)
                        .foregroundColor(.moltTextSecondary)
                    
                    TextEditor(text: $content)
                        .font(.moltBody)
                        .frame(height: 150)
                        .padding(Spacing.sm)
                        .background(Color.moltSurfaceSecondary)
                        .cornerRadius(CornerRadius.medium)
                }
                
                Toggle("Pin this note", isOn: $isPinned)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                
                Text("Use @agent-id to mention team members")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            .padding(Spacing.lg)
            
            Spacer()
        }
        .frame(width: 400, height: 350)
        .background(Color.moltBackground)
    }
    
    func saveNote() {
        let mentions = extractMentions(from: content)
        _Concurrency.Task {
            await appState.createNote(
                conversationId: conversationId,
                content: content,
                isPinned: isPinned,
                mentions: mentions
            )
            await MainActor.run {
                isPresented = false
            }
        }
    }
    
    func extractMentions(from text: String) -> [String] {
        let pattern = "@([a-zA-Z0-9\\-]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
    }
}
