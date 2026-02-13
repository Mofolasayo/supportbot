import SwiftUI

struct ConversationNotesView: View {
    @EnvironmentObject var appState: AppState
    let conversationId: String
    @State private var showAddNote = false
    
    var notes: [ConversationNote] {
        appState.notes(for: conversationId).sorted { note1, note2 in
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            return note1.createdAt > note2.createdAt
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notes")
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                Button(action: { showAddNote = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.moltPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            
            SubtleDivider()
            
            // Notes List
            if notes.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.moltTextMuted)
                    Text("No notes yet")
                        .font(.moltBody)
                        .foregroundColor(.moltTextMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.moltBackground)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(notes) { note in
                            NoteRow(note: note, conversationId: conversationId)
                        }
                    }
                    .padding(Spacing.md)
                }
                .background(Color.moltBackground)
            }
        }
        .frame(width: 320)
        .background(Color.moltSurface)
        .task(id: conversationId) {
            await appState.refreshNotes(for: conversationId)
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(conversationId: conversationId, isPresented: $showAddNote)
        }
    }
}

// MARK: - Note Row
struct NoteRow: View {
    @EnvironmentObject var appState: AppState
    let note: ConversationNote
    let conversationId: String
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(note.createdByName)
                    .font(.moltLabel)
                    .fontWeight(.semibold)
                    .foregroundColor(.moltTextPrimary)
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.moltPrimary)
                }
                
                Spacer()
                
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                
                if isHovering {
                    Menu {
                        Button(action: {
                            _Concurrency.Task {
                                await appState.togglePinNoteRemote(id: note.id, conversationId: conversationId)
                            }
                        }) {
                            Label(note.isPinned ? "Unpin" : "Pin", systemImage: "pin")
                        }
                        Button(action: {
                            _Concurrency.Task {
                                await appState.deleteNoteRemote(id: note.id, conversationId: conversationId)
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.moltTextMuted)
                    }
                    .menuStyle(.borderlessButton)
                }
            }
            
            Text(note.content)
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .background(note.isPinned ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
        .cornerRadius(CornerRadius.small)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
