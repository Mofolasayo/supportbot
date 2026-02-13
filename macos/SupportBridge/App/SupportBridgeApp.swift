import SwiftUI
import AppKit

@main
struct SupportBridgeApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .accentColor(.moltPrimary)  // Global accent color for cursor
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
    }
    
    init() {
        // Configure appearance
        NSWindow.allowsAutomaticWindowTabbing = false
        // Ensure a consistent caret color across TextField/TextEditor on macOS.
        NotificationCenter.default.addObserver(
            forName: NSText.didBeginEditingNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let textView = notification.object as? NSTextView else { return }
            textView.insertionPointColor = NSColor(Color.moltTextPrimary)
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentAgent: Agent?
    @Published var authToken: String?
    @Published var selectedConversation: Conversation?
    @Published var conversations: [Conversation] = []
    @Published var queueAssigned: [Conversation] = []
    @Published var queueUnassigned: [Conversation] = []
    @Published var isLoadingQueue = false
    @Published var queueLoadError: String?
    @Published var cannedResponses: [ResponseTemplate] = []
    @Published var cannedResponsesError: String?
    @Published var selectedTab: SidebarTab = .inbox
    @Published var isAIPanelVisible = true
    @Published var conversationMessages: [String: [Message]] = [:]
    @Published var isLoadingConversations = false
    @Published var conversationLoadError: String?
    @Published var conversationPagination: Pagination?
    @Published var isLoadingMoreConversations = false
    @Published var messageLoadErrors: [String: String] = [:]
    @Published var parents: [Parent] = []
    @Published var parentsLoadError: String?
    @Published var teams: [Team] = []
    @Published var teamLoadError: String?
    @Published var agents: [Agent] = []
    @Published var agentsLoadError: String?
    @Published var teamChannels: [TeamChatChannel] = []
    @Published var channelMessages: [String: [TeamChatMessage]] = [:]
    @Published var dmMessages: [String: [TeamChatMessage]] = [:]
    @Published var teamChatError: String?
    @Published var broadcasts: [BroadcastMessage] = []
    @Published var broadcastLoadError: String?
    @Published var notifications: [AppNotification] = []
    @Published var notificationLoadError: String?
    @Published var escalations: [Escalation] = []
    @Published var escalationLoadError: String?
    @Published var kbArticles: [KBArticle] = []
    @Published var kbLoadError: String?
    @Published var scheduledMessages: [ScheduledMessageData] = []
    @Published var scheduledMessagesError: String?
    @Published var isRealtimeConnected = false
    @Published var assistantInsights: [String: ConversationAssistantInsight] = [:]
    
    private let authService = AuthService()
    private var conversationsPage = 1
    private let conversationsPageSize = 20
    private var pollingTask: _Concurrency.Task<Void, Never>?
    private let pollingInterval: UInt64 = 12_000_000_000
    private let realtimeService = RealtimeService()

    var hasMoreConversations: Bool {
        guard let pagination = conversationPagination else { return false }
        return pagination.page < pagination.totalPages
    }
    
    init() {
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            authToken = token
            APIClient.shared.token = token
        }
        realtimeService.onEvent = { [weak self] event in
            guard let self else { return }
            _Concurrency.Task { @MainActor in
                self.handleRealtimeEvent(event)
            }
        }
        realtimeService.onConnectionChange = { [weak self] connected in
            guard let self else { return }
            _Concurrency.Task { @MainActor in
                self.isRealtimeConnected = connected
                if connected {
                    self.stopPolling()
                } else if self.authToken != nil {
                    await self.startPolling()
                }
            }
        }
    }
    
    // Mock data for development
    func loadMockData() {
        conversations = Conversation.mockList
        isAuthenticated = true
        currentAgent = Agent.mock
        loadMockTasks()
        loadMockNotes()
        load() // Load persisted data
    }

    @MainActor
    func applyAuth(token: String, agent: Agent) {
        authToken = token
        APIClient.shared.token = token
        currentAgent = agent
        isAuthenticated = true
        conversationsPage = 1
        conversationPagination = nil
        _Concurrency.Task { [weak self] in
            await self?.refreshConversations()
            await self?.refreshQueue()
            await self?.refreshTasks()
            await self?.refreshCannedResponses()
            await self?.refreshParents()
            await self?.refreshTeams()
            await self?.refreshAgents()
            await self?.refreshTeamChannels()
            await self?.refreshBroadcasts()
            await self?.refreshNotifications()
            await self?.refreshEscalations()
            await self?.refreshKnowledgeBase(category: .general, query: "")
            await self?.refreshScheduledMessages()
            self?.startRealtime()
            await self?.startPolling()
        }
    }

    @MainActor
    func signOut() {
        authToken = nil
        APIClient.shared.token = nil
        currentAgent = nil
        isAuthenticated = false
        conversations = []
        conversationPagination = nil
        isLoadingMoreConversations = false
        queueAssigned = []
        queueUnassigned = []
        cannedResponses = []
        parents = []
        teams = []
        agents = []
        teamChannels = []
        channelMessages = [:]
        dmMessages = [:]
        broadcasts = []
        notifications = []
        escalations = []
        kbArticles = []
        scheduledMessages = []
        assistantInsights = [:]
        conversationMessages = [:]
        selectedConversation = nil
        isRealtimeConnected = false
        stopRealtime()
        stopPolling()
    }

    func login(email: String, password: String) async throws {
        let response = try await authService.login(email: email, password: password)
        await MainActor.run {
            applyAuth(token: response.token, agent: response.agent)
        }
    }

    func signup(name: String, email: String, password: String) async throws -> SignupResponse {
        return try await authService.signup(name: name, email: email, password: password)
    }

    func verifyEmail(email: String, token: String) async throws {
        let response = try await authService.verifyEmail(email: email, token: token)
        await MainActor.run {
            applyAuth(token: response.token, agent: response.agent)
        }
    }

    func resendVerification(email: String) async throws -> ForgotPasswordResponse {
        return try await authService.resendVerification(email: email)
    }

    @MainActor
    func refreshConversations(page: Int = 1, append: Bool = false, showLoading: Bool = true) async {
        guard authToken != nil else { return }
        let isInitialPage = page <= 1
        if isInitialPage {
            if showLoading {
                isLoadingConversations = true
            }
        } else {
            isLoadingMoreConversations = true
        }
        defer {
            if isInitialPage {
                if showLoading {
                    isLoadingConversations = false
                }
            } else {
                isLoadingMoreConversations = false
            }
        }

        do {
            let response: PaginatedResponse<[Conversation]> = try await APIClient.shared.request(
                "conversations",
                method: .get,
                query: [
                    URLQueryItem(name: "page", value: "\(page)"),
                    URLQueryItem(name: "limit", value: "\(conversationsPageSize)")
                ]
            )
            conversationPagination = response.pagination
            conversationsPage = response.pagination?.page ?? page
            if append {
                var merged = conversations
                let existing = Set(merged.map { $0.id })
                for conversation in response.items where !existing.contains(conversation.id) {
                    merged.append(conversation)
                }
                conversations = merged.sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
            } else {
                conversations = response.items
            }
            conversationLoadError = nil
            if selectedConversation == nil {
                selectedConversation = conversations.first
            }
            if let selectedID = selectedConversation?.id {
                _Concurrency.Task { await self.fetchAssistantInsight(for: selectedID) }
            }
        } catch {
            conversationLoadError = error.localizedDescription
            print("Failed to load conversations: \(error)")
        }
    }

    @MainActor
    func loadMoreConversations() async {
        guard !isLoadingMoreConversations else { return }
        guard let pagination = conversationPagination else { return }
        guard pagination.page < pagination.totalPages else { return }
        await refreshConversations(page: pagination.page + 1, append: true)
    }

    @MainActor
    func refreshQueue() async {
        guard authToken != nil else { return }
        isLoadingQueue = true
        defer { isLoadingQueue = false }

        do {
            let assigned: PaginatedResponse<[Conversation]> = try await APIClient.shared.request(
                "queue/assigned",
                method: .get
            )
            let unassigned: PaginatedResponse<[Conversation]> = try await APIClient.shared.request(
                "queue/unassigned",
                method: .get
            )
            queueAssigned = assigned.items
            queueUnassigned = unassigned.items
            queueLoadError = nil
        } catch {
            queueLoadError = error.localizedDescription
            print("Failed to load queue: \(error)")
        }
    }

    @MainActor
    func takeQueueOwnership(conversationId: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            "queue/\(conversationId)/take",
            method: .post
        )
        await refreshQueue()
        await refreshConversations()
    }

    @MainActor
    func refreshCannedResponses() async {
        guard authToken != nil else { return }

        do {
            let response: APIResponse<[APICannedResponse]> = try await APIClient.shared.request(
                "canned-responses",
                method: .get
            )
            let items = response.data ?? []
            cannedResponses = items.map { ResponseTemplate.fromAPI($0) }
            cannedResponsesError = nil
        } catch {
            cannedResponsesError = error.localizedDescription
            print("Failed to load canned responses: \(error)")
        }
    }

    @MainActor
    func createCannedResponse(
        title: String,
        content: String,
        category: ResponseTemplate.TemplateCategory,
        shortcut: String?
    ) async throws -> ResponseTemplate {
        struct Body: Encodable {
            let title: String
            let content: String
            let category: String
            let shortcut: String?
            let isGlobal: Bool
        }

        let payload = Body(
            title: title,
            content: content,
            category: category.rawValue.lowercased(),
            shortcut: shortcut,
            isGlobal: true
        )

        let response: APIResponse<APICannedResponse> = try await APIClient.shared.request(
            "canned-responses",
            method: .post,
            body: payload
        )

        guard let api = response.data else {
            throw APIError(message: "Failed to create template")
        }

        let created = ResponseTemplate.fromAPI(api)
        await refreshCannedResponses()
        return created
    }

    @MainActor
    func updateCannedResponse(
        id: String,
        title: String,
        content: String,
        category: ResponseTemplate.TemplateCategory,
        shortcut: String?
    ) async throws {
        struct Body: Encodable {
            let title: String
            let content: String
            let category: String
            let shortcut: String?
        }

        let payload = Body(
            title: title,
            content: content,
            category: category.rawValue.lowercased(),
            shortcut: shortcut
        )

        let _: EmptyResponse = try await APIClient.shared.request(
            "canned-responses/\(id)",
            method: .put,
            body: payload
        )
        await refreshCannedResponses()
    }

    @MainActor
    func deleteCannedResponse(id: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            "canned-responses/\(id)",
            method: .delete
        )
        await refreshCannedResponses()
    }

    @MainActor
    func refreshParents() async {
        guard authToken != nil else { return }
        do {
            let response: APIResponse<[Parent]> = try await APIClient.shared.request(
                "parents",
                method: .get
            )
            parents = response.data ?? []
            parentsLoadError = nil
        } catch {
            parentsLoadError = error.localizedDescription
            print("Failed to load parents: \(error)")
        }
    }

    func createParent(_ payload: ParentCreatePayload) async throws -> Parent {
        let response: APIResponse<Parent> = try await APIClient.shared.request(
            "parents",
            method: .post,
            body: payload
        )
        if let parent = response.data {
            await refreshParents()
            return parent
        }
        throw APIError(message: "Failed to create parent")
    }

    @MainActor
    func refreshTeams() async {
        guard authToken != nil else { return }
        do {
            let response: APIResponse<[Team]> = try await APIClient.shared.request(
                "teams",
                method: .get
            )
            teams = response.data ?? []
            teamLoadError = nil
        } catch {
            teamLoadError = error.localizedDescription
            print("Failed to load teams: \(error)")
        }
    }

    @MainActor
    func refreshAgents() async {
        guard authToken != nil else { return }
        do {
            let response: APIResponse<[Agent]> = try await APIClient.shared.request(
                "agents",
                method: .get
            )
            agents = response.data ?? []
            agentsLoadError = nil
        } catch {
            agentsLoadError = error.localizedDescription
            print("Failed to load agents: \(error)")
        }
    }

    @MainActor
    func refreshTeamChannels() async {
        guard authToken != nil else { return }
        do {
            let response: APIResponse<[TeamChatChannel]> = try await APIClient.shared.request(
                "team/channels",
                method: .get
            )
            teamChannels = response.data ?? []
            teamChatError = nil
        } catch {
            teamChatError = error.localizedDescription
            print("Failed to load team channels: \(error)")
        }
    }

    @MainActor
    func loadChannelMessages(channelId: String) async {
        guard authToken != nil else { return }
        do {
            let response: PaginatedResponse<[TeamChatMessage]> = try await APIClient.shared.request(
                "team/channels/\(channelId)/messages",
                method: .get
            )
            channelMessages[channelId] = response.items
            teamChatError = nil
        } catch {
            teamChatError = error.localizedDescription
            print("Failed to load channel messages: \(error)")
        }
    }

    @MainActor
    func sendChannelMessage(channelId: String, content: String) async throws {
        struct Body: Encodable {
            let content: String
            let senderName: String
        }

        let payload = Body(content: content, senderName: currentAgent?.name ?? "Agent")
        let response: APIResponse<TeamChatMessage> = try await APIClient.shared.request(
            "team/channels/\(channelId)/messages",
            method: .post,
            body: payload
        )
        if let message = response.data {
            channelMessages[channelId, default: []].append(message)
        }
    }

    @MainActor
    func loadDMMessages(agentId: String) async {
        guard authToken != nil else { return }
        do {
            let response: PaginatedResponse<[TeamChatMessage]> = try await APIClient.shared.request(
                "team/dms/\(agentId)/messages",
                method: .get
            )
            dmMessages[agentId] = response.items
            teamChatError = nil
        } catch {
            teamChatError = error.localizedDescription
            print("Failed to load DM messages: \(error)")
        }
    }

    @MainActor
    func sendDM(agentId: String, content: String) async throws {
        struct Body: Encodable {
            let content: String
            let senderName: String
        }

        let payload = Body(content: content, senderName: currentAgent?.name ?? "Agent")
        let response: APIResponse<TeamChatMessage> = try await APIClient.shared.request(
            "team/dms/\(agentId)/messages",
            method: .post,
            body: payload
        )
        if let message = response.data {
            dmMessages[agentId, default: []].append(message)
        }
    }

    @MainActor
    func refreshBroadcasts() async {
        guard authToken != nil else { return }
        do {
            let response: PaginatedResponse<[APIBroadcast]> = try await APIClient.shared.request(
                "broadcasts",
                method: .get
            )
            broadcasts = response.items.map { BroadcastMessage.fromAPI($0) }
            broadcastLoadError = nil
        } catch {
            broadcastLoadError = error.localizedDescription
            print("Failed to load broadcasts: \(error)")
        }
    }

    @MainActor
    func createBroadcast(
        title: String,
        content: String,
        recipientFilter: BroadcastMessage.RecipientFilter,
        scheduledAt: Date?
    ) async throws -> BroadcastMessage {
        struct Body: Encodable {
            let title: String
            let content: String
            let recipientFilter: String
            let scheduledAt: Date?
        }

        let payload = Body(
            title: title,
            content: content,
            recipientFilter: recipientFilter.rawValue,
            scheduledAt: scheduledAt
        )

        let response: APIResponse<APIBroadcast> = try await APIClient.shared.request(
            "broadcasts",
            method: .post,
            body: payload
        )

        guard let api = response.data else {
            throw APIError(message: "Broadcast creation failed")
        }

        let created = BroadcastMessage.fromAPI(api)
        await refreshBroadcasts()
        return created
    }

    @MainActor
    func sendBroadcast(id: String) async throws {
        let _: APIResponse<APIBroadcast> = try await APIClient.shared.request(
            "broadcasts/\(id)/send",
            method: .post
        )
        await refreshBroadcasts()
    }

    @MainActor
    func refreshNotifications() async {
        guard authToken != nil else { return }
        do {
            let response: PaginatedResponse<[APINotification]> = try await APIClient.shared.request(
                "notifications",
                method: .get
            )
            notifications = response.items.map { AppNotification.fromAPI($0) }
            notificationLoadError = nil
        } catch {
            notificationLoadError = error.localizedDescription
            print("Failed to load notifications: \(error)")
        }
    }

    @MainActor
    func markAllNotificationsRead() async {
        guard authToken != nil else { return }
        do {
            let _: EmptyResponse = try await APIClient.shared.request(
                "notifications/read-all",
                method: .post
            )
            await refreshNotifications()
        } catch {
            print("Failed to mark notifications read: \(error)")
        }
    }

    @MainActor
    func markNotificationRead(id: String) async {
        guard authToken != nil else { return }
        do {
            let _: APIResponse<APINotification> = try await APIClient.shared.request(
                "notifications/\(id)/read",
                method: .post
            )
            await refreshNotifications()
        } catch {
            print("Failed to mark notification read: \(error)")
        }
    }

    @MainActor
    func refreshEscalations() async {
        guard authToken != nil else { return }
        do {
            let response: APIResponse<[Escalation]> = try await APIClient.shared.request(
                "escalations",
                method: .get
            )
            escalations = response.data ?? []
            escalationLoadError = nil
        } catch {
            escalationLoadError = error.localizedDescription
            print("Failed to load escalations: \(error)")
        }
    }

    @MainActor
    func acceptEscalation(id: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            "escalations/\(id)/accept",
            method: .post
        )
        await refreshEscalations()
    }

    @MainActor
    func updateEscalation(id: String, updates: [String: String]) async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            "escalations/\(id)",
            method: .put,
            body: updates
        )
        await refreshEscalations()
    }

    @MainActor
    func refreshKnowledgeBase(category: KBCategory, query: String) async {
        guard authToken != nil else { return }
        var queryItems: [URLQueryItem] = []
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        // Fetch all categories and filter locally for accurate counts.
        do {
            let response: PaginatedResponse<[APIKnowledgeArticle]> = try await APIClient.shared.request(
                "kb/articles",
                method: .get,
                query: queryItems
            )
            kbArticles = response.items.map { KBArticle.fromAPI($0) }
            kbLoadError = nil
        } catch {
            kbLoadError = error.localizedDescription
            print("Failed to load knowledge base: \(error)")
        }
    }

    @MainActor
    func createKnowledgeBaseArticle(title: String, content: String, category: KBCategory) async throws -> KBArticle {
        struct Body: Encodable {
            let title: String
            let content: String
            let category: String
        }

        let response: APIResponse<APIKnowledgeArticle> = try await APIClient.shared.request(
            "kb/articles",
            method: .post,
            body: Body(title: title, content: content, category: category.rawValue)
        )

        guard let api = response.data else {
            throw APIError(message: "Knowledge base article creation failed")
        }

        let created = KBArticle.fromAPI(api)
        await refreshKnowledgeBase(category: category, query: "")
        return created
    }

    @MainActor
    func refreshScheduledMessages() async {
        guard authToken != nil else { return }
        do {
            let response: PaginatedResponse<[APIScheduledMessage]> = try await APIClient.shared.request(
                "scheduled-messages",
                method: .get
            )
            scheduledMessages = response.items.map {
                ScheduledMessageData(
                    id: $0.id,
                    conversationId: $0.conversationId,
                    content: $0.content,
                    scheduledFor: $0.scheduledFor,
                    createdBy: $0.createdBy?.name ?? "Agent"
                )
            }
            scheduledMessagesError = nil
        } catch {
            scheduledMessagesError = error.localizedDescription
            print("Failed to load scheduled messages: \(error)")
        }
    }

    func requestPasswordReset(email: String) async throws -> ForgotPasswordResponse {
        return try await authService.forgotPassword(email: email)
    }

    func resetPassword(email: String, token: String, newPassword: String) async throws {
        _ = try await authService.resetPassword(email: email, token: token, newPassword: newPassword)
    }

    func ensureMessagesLoaded(for conversationId: String) {
        if conversationMessages[conversationId] == nil {
            _Concurrency.Task {
                await loadMessages(for: conversationId)
            }
        }
    }

    @MainActor
    func refreshMessages(for conversationId: String) async {
        await loadMessages(for: conversationId)
    }

    @MainActor
    func fetchAssistantInsight(for conversationId: String) async {
        guard authToken != nil else { return }
        do {
            let response: APIResponse<ConversationAssistantInsight> = try await APIClient.shared.request(
                "conversations/\(conversationId)/assistant",
                method: .get
            )
            if let insight = response.data {
                assistantInsights[conversationId] = insight
            }
        } catch {
            print("Failed to fetch assistant insight: \(error)")
        }
    }

    @MainActor
    func setConversationAIEnabled(conversationId: String, enabled: Bool) async throws {
        struct Body: Encodable { let enabled: Bool }
        let response: APIResponse<Conversation> = try await APIClient.shared.request(
            "conversations/\(conversationId)/ai",
            method: .post,
            body: Body(enabled: enabled)
        )
        if let updated = response.data {
            applyConversationUpdate(updated)
        } else {
            await refreshConversations(showLoading: false)
        }
        await fetchAssistantInsight(for: conversationId)
    }

    @MainActor
    func startPolling() async {
        stopPolling()
        guard authToken != nil else { return }
        pollingTask = _Concurrency.Task { [weak self] in
            while let self, !_Concurrency.Task.isCancelled {
                await self.refreshConversations(showLoading: false)
                await self.refreshTasks()
                if let selected = await MainActor.run(resultType: String?.self, body: { self.selectedConversation?.id }) {
                    await self.refreshMessages(for: selected)
                }
                try? await _Concurrency.Task.sleep(nanoseconds: pollingInterval)
            }
        }
    }

    @MainActor
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    @MainActor
    func startRealtime() {
        guard let token = authToken else { return }
        realtimeService.connect(token: token, baseURL: APIClient.shared.baseURL)
    }

    @MainActor
    func stopRealtime() {
        realtimeService.disconnect()
    }

    @MainActor
    private func handleRealtimeEvent(_ event: RealtimeService.Event) {
        switch event {
        case .message(let apiMessage):
            let message = apiMessage.toMessage()
            if !conversations.contains(where: { $0.id == message.conversationId }) {
                _Concurrency.Task { await refreshConversations(showLoading: false) }
            }
            appendMessage(message, to: message.conversationId)
            _Concurrency.Task { await fetchAssistantInsight(for: message.conversationId) }
        case .conversation(let conversation):
            applyConversationUpdate(conversation)
            _Concurrency.Task { await fetchAssistantInsight(for: conversation.id) }
        case .task(let apiTask):
            upsertTask(apiTask.toTask())
        case .taskStatus(let payload):
            applyTaskStatusRealtime(id: payload.id, status: payload.status)
        }
    }

    @MainActor
    private func applyConversationUpdate(_ conversation: Conversation) {
        let existingParent = conversations.first(where: { $0.id == conversation.id })?.parent
        var next = conversation
        if next.parent == nil {
            next.parent = existingParent
        }
        if let index = conversations.firstIndex(where: { $0.id == next.id }) {
            conversations[index] = next
        } else {
            conversations.append(next)
        }
        conversations.sort { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
        if selectedConversation?.id == next.id {
            selectedConversation = next
        }
    }

    @MainActor
    func sendMessage(conversationId: String, content: String, messageType: MessageType = .text) async {
        guard authToken != nil else { return }

        struct Body: Encodable {
            let content: String
            let messageType: String
        }

        do {
            let response: APIResponse<APIMessage> = try await APIClient.shared.request(
                "conversations/\(conversationId)/messages",
                method: .post,
                body: Body(content: content, messageType: messageType.rawValue)
            )
            if let apiMessage = response.data {
                let message = apiMessage.toMessage()
                appendMessage(message, to: conversationId)
            }
            await refreshConversations()
            await fetchAssistantInsight(for: conversationId)
            messageLoadErrors[conversationId] = nil
        } catch {
            messageLoadErrors[conversationId] = error.localizedDescription
            print("Failed to send message: \(error)")
        }
    }

    @MainActor
    func uploadAttachmentMessage(
        conversationId: String,
        fileURL: URL,
        fallbackType: MessageType
    ) async {
        guard authToken != nil else {
            // Keep local behavior for offline/mock mode.
            let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            let local = Message(
                id: UUID().uuidString,
                conversationId: conversationId,
                senderId: currentAgent?.id,
                senderType: .agent,
                content: fileURL.path,
                messageType: fallbackType,
                status: .sent,
                sentAt: Date(),
                documentName: fileURL.lastPathComponent,
                documentSize: Int(fileSize)
            )
            appendMessage(local, to: conversationId)
            return
        }

        do {
            let response: APIResponse<APIUploadMessageData> = try await APIClient.shared.uploadMultipart(
                "conversations/\(conversationId)/messages/media",
                fileURL: fileURL
            )
            if let payload = response.data {
                appendMessage(payload.message.toMessage(), to: conversationId)
                await refreshConversations(showLoading: false)
            } else {
                await refreshMessages(for: conversationId)
            }
            messageLoadErrors[conversationId] = nil
        } catch {
            messageLoadErrors[conversationId] = error.localizedDescription
        }
    }

    @MainActor
    private func loadMessages(for conversationId: String) async {
        guard authToken != nil else {
            let messages = Message.messagesFor(conversationId: conversationId)
            conversationMessages[conversationId] = messages
            if let lastMessage = messages.last {
                updateConversationSummary(for: conversationId, with: lastMessage, shouldIncrementUnread: false)
            }
            return
        }
        do {
            let response: APIResponse<[APIMessage]> = try await APIClient.shared.request(
                "conversations/\(conversationId)/messages",
                method: .get
            )
            let messages = (response.data ?? []).map { $0.toMessage() }
            let ordered = messages.sorted { $0.sentAt < $1.sentAt }
            conversationMessages[conversationId] = ordered
            if let lastMessage = ordered.last {
                updateConversationSummary(for: conversationId, with: lastMessage, shouldIncrementUnread: false)
            }
            messageLoadErrors[conversationId] = nil
            _Concurrency.Task { await fetchAssistantInsight(for: conversationId) }
        } catch {
            print("Failed to load messages: \(error)")
            conversationMessages[conversationId] = []
            messageLoadErrors[conversationId] = error.localizedDescription
        }
    }

    func messages(for conversationId: String) -> [Message] {
        return conversationMessages[conversationId] ?? []
    }

    func appendMessage(_ message: Message, to conversationId: String) {
        ensureMessagesLoaded(for: conversationId)
        var list = conversationMessages[conversationId] ?? []
        if let existingIndex = list.firstIndex(where: { $0.id == message.id }) {
            list[existingIndex] = message
        } else {
            list.append(message)
        }
        list.sort { $0.sentAt < $1.sentAt }
        conversationMessages[conversationId] = list
        updateConversationSummary(for: conversationId, with: message)
        save()
    }

    private func upsertTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.insert(task, at: 0)
        }
    }

    private func applyTaskStatusRealtime(id: String, status: String) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let mapped = Task.TaskStatus.fromAPI(status)
        tasks[index].status = mapped
        tasks[index].completedAt = mapped == .completed ? Date() : nil
    }

    func conversationPreview(for conversation: Conversation) -> String {
        if let preview = conversation.lastMessagePreview, !preview.isEmpty {
            return preview
        }
        if let lastMessage = conversationMessages[conversation.id]?.last {
            return messagePreview(for: lastMessage)
        }
        return "No messages yet"
    }

    func messagePreview(for message: Message) -> String {
        if message.isDeleted { return "Message deleted" }
        switch message.messageType {
        case .text:
            return message.content.isEmpty ? "Message" : message.content
        case .image:
            return "📷 Photo"
        case .document:
            return "📎 \(message.documentName ?? "Document")"
        case .audio:
            return "🎤 Voice message"
        case .video:
            return "🎬 Video"
        case .location:
            return "📍 Location"
        case .template:
            return message.content.isEmpty ? "Template message" : message.content
        case .system:
            return message.content.isEmpty ? "System update" : message.content
        }
    }

    private func updateConversationSummary(
        for conversationId: String,
        with message: Message,
        shouldIncrementUnread: Bool = true
    ) {
        let preview = messagePreview(for: message)
        updateConversationInLists(conversationId: conversationId) { conversation in
            conversation.lastMessagePreview = preview
            conversation.lastMessageAt = message.sentAt
            if shouldIncrementUnread && message.senderType == .parent {
                if selectedConversation?.id == conversationId {
                    conversation.unreadCount = 0
                } else {
                    conversation.unreadCount = max(1, conversation.unreadCount + 1)
                }
            }
        }
    }

    @MainActor
    func markConversationRead(_ conversationId: String) {
        updateConversationInLists(conversationId: conversationId) { conversation in
            conversation.unreadCount = 0
        }
        guard authToken != nil else { return }
        _Concurrency.Task {
            do {
                let _: EmptyResponse = try await APIClient.shared.request(
                    "conversations/\(conversationId)/read",
                    method: .post
                )
                await refreshConversations()
            } catch {
                print("Failed to mark conversation read: \(error)")
            }
        }
    }

    @MainActor
    func markConversationUnread(_ conversationId: String) {
        updateConversationInLists(conversationId: conversationId) { conversation in
            conversation.unreadCount = max(1, conversation.unreadCount)
        }
        guard authToken != nil else { return }
        _Concurrency.Task {
            do {
                let _: EmptyResponse = try await APIClient.shared.request(
                    "conversations/\(conversationId)/unread",
                    method: .post
                )
                await refreshConversations()
            } catch {
                print("Failed to mark conversation unread: \(error)")
            }
        }
    }

    @MainActor
    func assignConversation(conversationId: String, agentId: String?) {
        updateConversationInLists(conversationId: conversationId) { conversation in
            conversation.assignedAgentId = agentId
            if let agentId = agentId, !agentId.isEmpty {
                conversation.handledBy = .agent
            } else if conversation.assignedTeamId != nil {
                conversation.handledBy = .team
            } else {
                conversation.handledBy = .bot
            }
        }
        guard authToken != nil else { return }
        _Concurrency.Task {
            do {
                if let agentId = agentId, !agentId.isEmpty {
                    if agentId == currentAgent?.id {
                        let _: EmptyResponse = try await APIClient.shared.request(
                            "queue/\(conversationId)/take",
                            method: .post
                        )
                    } else {
                        struct Body: Encodable { let agentId: String }
                        let _: EmptyResponse = try await APIClient.shared.request(
                            "conversations/\(conversationId)/assign",
                            method: .post,
                            body: Body(agentId: agentId)
                        )
                    }
                } else {
                    let _: EmptyResponse = try await APIClient.shared.request(
                        "conversations/\(conversationId)/unassign",
                        method: .post
                    )
                }
                await refreshConversations()
                await refreshQueue()
            } catch {
                print("Failed to assign conversation: \(error)")
            }
        }
    }

    @MainActor
    func forwardConversation(
        conversationId: String,
        teamId: String?,
        agentId: String?
    ) async throws {
        struct Body: Encodable {
            let teamId: String?
            let agentId: String?
        }

        let response: APIResponse<Conversation> = try await APIClient.shared.request(
            "conversations/\(conversationId)/forward",
            method: .post,
            body: Body(teamId: teamId, agentId: agentId)
        )

        if let updated = response.data {
            applyConversationUpdate(updated)
        } else {
            await refreshConversations(showLoading: false)
        }
        await refreshQueue()
    }

    @MainActor
    func createEscalation(
        conversationId: String,
        reason: String,
        aiSummary: String,
        priority: Priority,
        toTeamId: String?,
        toAgentId: String?
    ) async throws {
        struct Body: Encodable {
            let conversationId: String
            let reason: String
            let aiSummary: String
            let priority: String
            let status: String
            let toTeamId: String?
            let toAgentId: String?
        }

        let payload = Body(
            conversationId: conversationId,
            reason: reason,
            aiSummary: aiSummary,
            priority: priority.rawValue,
            status: "pending",
            toTeamId: toTeamId,
            toAgentId: toAgentId
        )

        let response: APIResponse<Escalation> = try await APIClient.shared.request(
            "escalations",
            method: .post,
            body: payload
        )
        if let escalation = response.data {
            escalations.insert(escalation, at: 0)
        } else {
            await refreshEscalations()
        }
    }

    @MainActor
    func updateConversationTags(conversationId: String, tags: [String]) {
        updateConversationInLists(conversationId: conversationId) { conversation in
            conversation.tags = tags
        }
        guard authToken != nil else { return }
        _Concurrency.Task {
            do {
                struct Body: Encodable { let tags: [String] }
                let _: EmptyResponse = try await APIClient.shared.request(
                    "conversations/\(conversationId)",
                    method: .put,
                    body: Body(tags: tags)
                )
                await refreshConversations()
            } catch {
                print("Failed to update conversation tags: \(error)")
            }
        }
    }

    @MainActor
    func updateParentNotes(parentId: String, notes: String) {
        if let index = parents.firstIndex(where: { $0.id == parentId }) {
            parents[index].notes = notes
        }
        for idx in conversations.indices {
            if conversations[idx].parent?.id == parentId {
                conversations[idx].parent?.notes = notes
            }
        }
        if selectedConversation?.parent?.id == parentId {
            selectedConversation?.parent?.notes = notes
        }
        guard authToken != nil else { return }
        _Concurrency.Task {
            do {
                struct Body: Encodable { let notes: String }
                let _: EmptyResponse = try await APIClient.shared.request(
                    "parents/\(parentId)",
                    method: .put,
                    body: Body(notes: notes)
                )
                await refreshParents()
            } catch {
                print("Failed to update parent notes: \(error)")
            }
        }
    }

    private func updateConversationInLists(
        conversationId: String,
        update: (inout Conversation) -> Void
    ) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            var conversation = conversations[index]
            update(&conversation)
            conversations[index] = conversation
        }
        if let index = queueAssigned.firstIndex(where: { $0.id == conversationId }) {
            var conversation = queueAssigned[index]
            update(&conversation)
            queueAssigned[index] = conversation
        }
        if let index = queueUnassigned.firstIndex(where: { $0.id == conversationId }) {
            var conversation = queueUnassigned[index]
            update(&conversation)
            queueUnassigned[index] = conversation
        }
        if selectedConversation?.id == conversationId {
            if var selected = selectedConversation {
                update(&selected)
                selectedConversation = selected
            }
        }
    }
    
    // MARK: - Persistence
    private var dataFileURL: URL? {
        guard let documents = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let path = documents.appendingPathComponent("SupportBridge")
        if !FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        }
        return path.appendingPathComponent("messages.json")
    }
    
    func save() {
        guard let url = dataFileURL else { return }
        do {
            let data = try JSONEncoder().encode(conversationMessages)
            try data.write(to: url)
        } catch {
            print("Failed to save messages: \(error)")
        }
    }
    
    func load() {
        guard let url = dataFileURL, let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode([String: [Message]].self, from: data) {
            conversationMessages = decoded
        }
    }
    
    // MARK: - Message Actions (Reactive)
    
    /// Toggle star status on a message
    func toggleStarMessage(messageId: String, conversationId: String) {
        guard var messages = conversationMessages[conversationId],
              let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[index].isStarred.toggle()
        conversationMessages[conversationId] = messages
        save()
    }

    @MainActor
    func toggleStarMessageRemote(messageId: String, conversationId: String) async {
        if authToken == nil {
            toggleStarMessage(messageId: messageId, conversationId: conversationId)
            return
        }

        guard let message = getMessage(id: messageId, conversationId: conversationId) else { return }
        let shouldStar = !message.isStarred

        // Optimistic update for responsive UI.
        toggleStarMessage(messageId: messageId, conversationId: conversationId)

        do {
            if shouldStar {
                let _: MessageResponse = try await APIClient.shared.request(
                    "messages/\(messageId)/star",
                    method: .post
                )
            } else {
                let _: MessageResponse = try await APIClient.shared.request(
                    "messages/\(messageId)/star",
                    method: .delete
                )
            }

            let refreshed: APIResponse<APIMessage> = try await APIClient.shared.request(
                "messages/\(messageId)",
                method: .get
            )
            if let api = refreshed.data {
                applyMessageUpdate(api.toMessage(), conversationId: conversationId)
            }
            messageLoadErrors[conversationId] = nil
        } catch {
            // Revert optimistic change if remote call failed.
            toggleStarMessage(messageId: messageId, conversationId: conversationId)
            messageLoadErrors[conversationId] = error.localizedDescription
        }
    }
    
    /// Delete a message (soft delete - shows "This message was deleted")
    func deleteMessage(messageId: String, conversationId: String) {
        guard var messages = conversationMessages[conversationId],
              let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[index].isDeleted = true
        messages[index].deletedAt = Date()
        conversationMessages[conversationId] = messages
        save()
    }
    
    /// Add a reaction to a message
    func addReaction(emoji: String, to messageId: String, conversationId: String) {
        guard var messages = conversationMessages[conversationId],
              let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        let reaction = MessageReaction(
            id: UUID().uuidString,
            emoji: emoji,
            userId: currentAgent?.id ?? "agent-1",
            userName: currentAgent?.name ?? "Agent"
        )
        
        var currentReactions = messages[index].reactions ?? []
        // Check if user already reacted with this emoji
        if let existingIndex = currentReactions.firstIndex(where: { $0.userId == reaction.userId && $0.emoji == emoji }) {
            // Remove the reaction (toggle off)
            currentReactions.remove(at: existingIndex)
        } else {
            // Add the reaction
            currentReactions.append(reaction)
        }
        messages[index].reactions = currentReactions
        conversationMessages[conversationId] = messages
        save()
    }

    @MainActor
    func addReactionRemote(emoji: String, to messageId: String, conversationId: String) async {
        if authToken == nil {
            addReaction(emoji: emoji, to: messageId, conversationId: conversationId)
            return
        }

        struct Body: Encodable {
            let emoji: String
            let userId: String
            let userName: String
        }

        let payload = Body(
            emoji: emoji,
            userId: currentAgent?.id ?? "agent",
            userName: currentAgent?.name ?? "Agent"
        )

        do {
            let response: APIResponse<APIMessage> = try await APIClient.shared.request(
                "messages/\(messageId)/reactions",
                method: .post,
                body: payload
            )
            if let updated = response.data {
                applyMessageUpdate(updated.toMessage(), conversationId: conversationId)
            } else {
                await refreshMessages(for: conversationId)
            }
            messageLoadErrors[conversationId] = nil
        } catch {
            messageLoadErrors[conversationId] = error.localizedDescription
        }
    }
    
    /// Edit a message (only your own)
    func editMessage(messageId: String, newContent: String, conversationId: String) {
        guard var messages = conversationMessages[conversationId],
              let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        // Only allow editing your own messages
        guard messages[index].senderType == .agent else { return }
        messages[index].content = newContent
        messages[index].isEdited = true
        messages[index].editedAt = Date()
        conversationMessages[conversationId] = messages
        save()
    }

    @MainActor
    func deleteMessageRemote(messageId: String, conversationId: String) async {
        if authToken == nil {
            deleteMessage(messageId: messageId, conversationId: conversationId)
            return
        }

        // Optimistic local deletion.
        deleteMessage(messageId: messageId, conversationId: conversationId)

        do {
            let _: MessageResponse = try await APIClient.shared.request(
                "messages/\(messageId)",
                method: .delete
            )
            messageLoadErrors[conversationId] = nil
        } catch {
            messageLoadErrors[conversationId] = error.localizedDescription
            await refreshMessages(for: conversationId)
        }
    }

    @MainActor
    func forwardMessage(
        messageId: String,
        toConversationIDs: [String],
        note: String?
    ) async throws {
        guard authToken != nil else {
            throw APIError(message: "Sign in to forward messages")
        }
        struct Body: Encodable {
            let conversationIds: [String]
            let note: String?
        }

        let response: APIResponse<[APIMessage]> = try await APIClient.shared.request(
            "messages/\(messageId)/forward",
            method: .post,
            body: Body(conversationIds: toConversationIDs, note: note)
        )

        // Insert forwarded messages into any loaded conversation currently in memory.
        for api in response.data ?? [] {
            applyMessageUpdate(api.toMessage(), conversationId: api.conversationId)
        }
        await refreshConversations(showLoading: false)
    }
    
    func getMessage(id: String, conversationId: String) -> Message? {
        return conversationMessages[conversationId]?.first(where: { $0.id == id })
    }
    
    /// Update message with link preview
    func updateMessageLinkPreview(messageId: String, conversationId: String, preview: LinkPreview) {
        guard var messages = conversationMessages[conversationId],
              let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        messages[index].linkPreview = preview
        conversationMessages[conversationId] = messages
        save()
    }

    private func applyMessageUpdate(_ message: Message, conversationId: String) {
        var messages = conversationMessages[conversationId] ?? []
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
            messages.sort { $0.sentAt < $1.sentAt }
        }
        conversationMessages[conversationId] = messages
        if let latest = messages.last {
            updateConversationSummary(for: conversationId, with: latest, shouldIncrementUnread: false)
        }
        save()
    }
    
    // MARK: - Conversation Actions
    
    @MainActor
    func toggleResolve(conversationId: String) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        let nextStatus: ConversationStatus = conversations[index].status == .resolved ? .open : .resolved
        await updateConversation(conversationId: conversationId, status: nextStatus)
    }
    
    @MainActor
    func toggleEscalate(conversationId: String) async {
        await updateConversation(conversationId: conversationId, status: .pending)
    }

    @MainActor
    private func updateConversation(conversationId: String, status: ConversationStatus) async {
        struct Body: Encodable { let status: String }
        do {
            let response: APIResponse<Conversation> = try await APIClient.shared.request(
                "conversations/\(conversationId)",
                method: .put,
                body: Body(status: status.rawValue)
            )
            if let updated = response.data,
               let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index] = updated
                if selectedConversation?.id == conversationId {
                    selectedConversation = updated
                }
            } else {
                await refreshConversations()
            }
        } catch {
            print("Failed to update conversation: \(error)")
        }
    }
    
    // MARK: - Task Management
    @Published var tasks: [Task] = []
    @Published var isLoadingTasks = false
    @Published var taskLoadError: String?
    
    func loadMockTasks() {
        tasks = Task.mockTasks
    }

    @MainActor
    func refreshTasks() async {
        guard authToken != nil else { return }
        isLoadingTasks = true
        defer { isLoadingTasks = false }
        do {
            let response: PaginatedResponse<[APITask]> = try await APIClient.shared.request(
                "tasks",
                method: .get
            )
            tasks = response.items.map { $0.toTask() }
            taskLoadError = nil
        } catch {
            taskLoadError = error.localizedDescription
            print("Failed to load tasks: \(error)")
        }
    }

    @MainActor
    func createTask(
        title: String,
        description: String?,
        assignedToId: String?,
        conversationId: String?,
        priority: Priority,
        dueDate: Date?,
        tags: [String]?
    ) async {
        struct Body: Encodable {
            let title: String
            let description: String?
            let assignedToId: String?
            let conversationId: String?
            let priority: String
            let dueDate: Date?
            let tags: [String]?
        }
        do {
            let response: APIResponse<APITask> = try await APIClient.shared.request(
                "tasks",
                method: .post,
                body: Body(
                    title: title,
                    description: description,
                    assignedToId: assignedToId,
                    conversationId: conversationId,
                    priority: priority.rawValue,
                    dueDate: dueDate,
                    tags: tags
                )
            )
            if let apiTask = response.data {
                tasks.insert(apiTask.toTask(), at: 0)
            } else {
                await refreshTasks()
            }
        } catch {
            print("Failed to create task: \(error)")
        }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        save()
    }
    
    func updateTask(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        save()
    }

    @MainActor
    func updateTaskRemote(_ task: Task) async {
        struct Body: Encodable {
            let title: String
            let description: String?
            let assignedToId: String?
            let priority: String
            let dueDate: Date?
            let tags: [String]?
        }
        do {
            let response: APIResponse<APITask> = try await APIClient.shared.request(
                "tasks/\(task.id)",
                method: .put,
                body: Body(
                    title: task.title,
                    description: task.description,
                    assignedToId: task.assignedTo,
                    priority: task.priority.rawValue,
                    dueDate: task.dueDate,
                    tags: task.tags
                )
            )
            if let apiTask = response.data,
               let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = apiTask.toTask()
            } else {
                await refreshTasks()
            }
        } catch {
            print("Failed to update task: \(error)")
        }
    }
    
    func deleteTask(id: String) {
        tasks.removeAll { $0.id == id }
        save()
    }
    
    @MainActor
    func toggleTaskStatus(taskId: String) async {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let currentStatus = tasks[index].status
        let nextStatus: Task.TaskStatus = currentStatus == .completed ? .todo : .completed

        struct Body: Encodable { let status: String }
        do {
            _ = try await APIClient.shared.request(
                "tasks/\(taskId)/status",
                method: .put,
                body: Body(status: nextStatus.apiValue)
            ) as MessageResponse
            tasks[index].status = nextStatus
            tasks[index].completedAt = nextStatus == .completed ? Date() : nil
        } catch {
            print("Failed to update task status: \(error)")
        }
    }
    
    // MARK: - Conversation Notes
    @Published var conversationNotes: [String: [ConversationNote]] = [:] // conversationId -> notes
    
    func loadMockNotes() {
        conversationNotes = Dictionary(grouping: ConversationNote.mockNotes, by: { $0.conversationId })
    }
    
    func notes(for conversationId: String) -> [ConversationNote] {
        return conversationNotes[conversationId] ?? []
    }

    @MainActor
    func refreshNotes(for conversationId: String) async {
        guard authToken != nil else { return }
        do {
            let response: APIResponse<[ConversationNote]> = try await APIClient.shared.request(
                "conversations/\(conversationId)/notes",
                method: .get
            )
            conversationNotes[conversationId] = response.data ?? []
        } catch {
            print("Failed to load notes: \(error)")
        }
    }

    @MainActor
    func createNote(conversationId: String, content: String, isPinned: Bool, mentions: [String]) async {
        struct Body: Encodable {
            let content: String
            let isPinned: Bool
            let mentions: [String]
        }
        do {
            let response: APIResponse<ConversationNote> = try await APIClient.shared.request(
                "conversations/\(conversationId)/notes",
                method: .post,
                body: Body(content: content, isPinned: isPinned, mentions: mentions)
            )
            if let note = response.data {
                var notes = conversationNotes[conversationId] ?? []
                notes.append(note)
                conversationNotes[conversationId] = notes
            } else {
                await refreshNotes(for: conversationId)
            }
        } catch {
            print("Failed to create note: \(error)")
        }
    }

    @MainActor
    func deleteNoteRemote(id: String, conversationId: String) async {
        do {
            _ = try await APIClient.shared.request(
                "conversations/\(conversationId)/notes/\(id)",
                method: .delete
            ) as MessageResponse
            conversationNotes[conversationId]?.removeAll { $0.id == id }
        } catch {
            print("Failed to delete note: \(error)")
        }
    }

    @MainActor
    func togglePinNoteRemote(id: String, conversationId: String) async {
        do {
            let response: APIResponse<ConversationNote> = try await APIClient.shared.request(
                "conversations/\(conversationId)/notes/\(id)/pin",
                method: .post
            )
            if let note = response.data,
               var notes = conversationNotes[conversationId],
               let index = notes.firstIndex(where: { $0.id == id }) {
                notes[index] = note
                conversationNotes[conversationId] = notes
            } else {
                await refreshNotes(for: conversationId)
            }
        } catch {
            print("Failed to toggle pin: \(error)")
        }
    }
    
    func addNote(_ note: ConversationNote) {
        var notes = conversationNotes[note.conversationId] ?? []
        notes.append(note)
        conversationNotes[note.conversationId] = notes
        save()
    }
    
    func updateNote(_ note: ConversationNote) {
        guard var notes = conversationNotes[note.conversationId],
              let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index] = note
        conversationNotes[note.conversationId] = notes
        save()
    }
    
    func deleteNote(id: String, conversationId: String) {
        guard var notes = conversationNotes[conversationId] else { return }
        notes.removeAll { $0.id == id }
        conversationNotes[conversationId] = notes
        save()
    }
    
    func togglePinNote(id: String, conversationId: String) {
        guard var notes = conversationNotes[conversationId],
              let index = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[index].isPinned.toggle()
        conversationNotes[conversationId] = notes
        save()
    }
}

enum SidebarTab: String, CaseIterable {
    case inbox = "Inbox"
    case escalations = "Escalations"
    case team = "My Team"
    case analytics = "Analytics"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .inbox: return "tray.fill"
        case .escalations: return "arrow.up.circle.fill"
        case .team: return "person.3.fill"
        case .analytics: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
