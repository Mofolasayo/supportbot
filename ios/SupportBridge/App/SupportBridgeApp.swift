import SwiftUI

@main
struct SupportBridgeApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentAgent: Agent?
    @Published var selectedConversation: Conversation?
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ConversationsTab()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
            
            TasksTab()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            
            TeamTab()
                .tabItem {
                    Label("Team", systemImage: "person.3")
                }
            
            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct ConversationsTab: View {
    @State private var conversations: [Conversation] = []
    
    var body: some View {
        NavigationStack {
            List(conversations) { conversation in
                NavigationLink(destination: ChatView(conversation: conversation)) {
                    ConversationRow(conversation: conversation)
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All") {}
                        Button("Open") {}
                        Button("Pending") {}
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(conversation.parent?.name ?? "Unknown")
                    .font(.headline)
                Spacer()
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            Text(conversation.subject ?? "No subject")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

struct ChatView: View {
    let conversation: Conversation
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation.parent?.name ?? "Chat")
    }
    
    func sendMessage() {
        // TODO: Send message via API
        newMessage = ""
    }
}

struct MessageBubble: View {
    let message: Message
    
    var isFromAgent: Bool {
        message.senderType == .agent
    }
    
    var body: some View {
        HStack {
            if isFromAgent { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isFromAgent ? Color.blue : Color(.systemGray5))
                .foregroundColor(isFromAgent ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            if !isFromAgent { Spacer() }
        }
    }
}

struct TasksTab: View {
    var body: some View {
        NavigationStack {
            Text("Tasks")
                .navigationTitle("Tasks")
        }
    }
}

struct TeamTab: View {
    var body: some View {
        NavigationStack {
            Text("Team")
                .navigationTitle("Team")
        }
    }
}

struct SettingsTab: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Text(appState.currentAgent?.name ?? "Agent")
                    Text(appState.currentAgent?.email ?? "")
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        appState.isAuthenticated = false
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Support Bridge")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            Button("Sign In") {
                appState.isAuthenticated = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}
