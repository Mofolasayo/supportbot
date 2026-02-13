import Foundation

private enum MockAgentInfo {
    static let name = "Support Agent"
    static let email = "agent@supportbridge.dev"
    static let avatarInitial = "S"
}

// MARK: - Agent
struct Agent: Identifiable, Codable {
    let id: String
    var email: String
    var name: String
    var role: AgentRole
    var status: AgentStatus
    var teamId: String?
    var avatarUrl: String?
    var isActive: Bool
    
    enum AgentRole: String, Codable {
        case admin, supervisor, agent, teamMember = "team_member"
    }
    
    enum AgentStatus: String, Codable {
        case online, away, busy, offline
    }
    
    static let mock = Agent(
        id: "agent-1",
        email: MockAgentInfo.email,
        name: MockAgentInfo.name,
        role: .agent,
        status: .online,
        teamId: "team-1",
        avatarUrl: nil,
        isActive: true
    )

    var avatarInitial: String {
        name.first.map { String($0).uppercased() } ?? "A"
    }
}

// MARK: - Student (Child Info)
struct Student: Identifiable, Codable {
    let id: String
    var name: String
    var grade: String  // e.g., "JSS1", "SS2"
    var classSection: String?  // e.g., "A", "B"
    var admissionNumber: String?
    var dateOfBirth: Date?
    var gender: Gender?
    
    enum Gender: String, Codable {
        case male, female, other
    }
    
    static let mockList: [Student] = [
        Student(id: "student-1", name: "Tunde Adeyemi", grade: "JSS2", classSection: "A", admissionNumber: "ADM/2024/001", dateOfBirth: Date().addingTimeInterval(-378432000), gender: .male),
        Student(id: "student-2", name: "Chinedu Obi", grade: "SS1", classSection: "B", admissionNumber: "ADM/2023/015", dateOfBirth: Date().addingTimeInterval(-441504000), gender: .male),
        Student(id: "student-3", name: "Aisha Ibrahim", grade: "JSS3", classSection: "A", admissionNumber: "ADM/2022/042", dateOfBirth: Date().addingTimeInterval(-410227200), gender: .female)
    ]
}

// MARK: - School
struct School: Identifiable, Codable {
    let id: String
    var name: String
    var address: String?
    var state: String?
    var type: SchoolType
    
    enum SchoolType: String, Codable {
        case primary, secondary, combined
    }
    
    static let mock = School(id: "school-1", name: "Your School", address: "123 Education Lane, Lagos", state: "Lagos", type: .secondary)
}

// MARK: - Parent (Enhanced with full contact info)
struct Parent: Identifiable, Codable {
    let id: String
    var name: String
    var phoneNumber: String
    var email: String?
    var alternatePhone: String?
    var address: String?
    var occupation: String?
    var relationship: ParentRelationship?
    var students: [Student]?
    var studentNames: [String]?  // Kept for backwards compatibility
    var schoolId: String?
    var school: School?
    var avatarUrl: String?
    var isOnline: Bool
    var lastSeen: Date?
    var isStarred: Bool
    var notes: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case phoneNumber
        case email
        case alternatePhone
        case address
        case occupation
        case relationship
        case students
        case studentNames
        case schoolId
        case school
        case avatarUrl
        case isOnline
        case lastSeen
        case isStarred
        case notes
        case createdAt
    }
    
    enum ParentRelationship: String, Codable, CaseIterable {
        case father, mother, guardian, other
        
        var displayName: String {
            rawValue.capitalized
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = (try? container.decode(String.self))?.lowercased() ?? ""
            self = ParentRelationship(rawValue: raw) ?? .other
        }
    }
    
    static let mockList: [Parent] = [
        Parent(id: "parent-1", name: "Parent 01", phoneNumber: "+234 801 234 5678", email: "parent01@email.com", alternatePhone: "+234 802 111 2222", address: "15 Ikoyi Crescent, Lagos", occupation: "Banker", relationship: .mother, students: [Student.mockList[0]], studentNames: ["Tunde Adeyemi"], schoolId: "school-1", isOnline: true, lastSeen: nil, isStarred: true, notes: nil, createdAt: Date().addingTimeInterval(-2592000)),
        Parent(id: "parent-2", name: "Parent 02", phoneNumber: "+234 803 456 7890", email: "parent02@email.com", alternatePhone: nil, address: "42 Lekki Phase 1, Lagos", occupation: "Engineer", relationship: .father, students: [Student.mockList[1]], studentNames: ["Chinedu Obi"], schoolId: "school-1", isOnline: false, lastSeen: Date().addingTimeInterval(-3600), isStarred: false, notes: "Prefers email communication", createdAt: Date().addingTimeInterval(-5184000)),
        Parent(id: "parent-3", name: "Mrs. Ibrahim", phoneNumber: "+234 805 678 9012", email: "ibrahim@email.com", alternatePhone: "+234 806 333 4444", address: "8 Victoria Island, Lagos", occupation: "Doctor", relationship: .mother, students: [Student.mockList[2]], studentNames: ["Aisha Ibrahim"], schoolId: "school-1", isOnline: false, lastSeen: Date().addingTimeInterval(-7200), isStarred: true, notes: nil, createdAt: Date().addingTimeInterval(-7776000)),
        Parent(id: "parent-4", name: "Mr. Eze", phoneNumber: "+234 807 890 1234", email: "eze@email.com", alternatePhone: nil, address: "22 Surulere, Lagos", occupation: "Lawyer", relationship: .father, students: nil, studentNames: ["Emeka Eze"], schoolId: "school-1", isOnline: true, lastSeen: nil, isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-1296000)),
        Parent(id: "parent-5", name: "Mrs. Fadeyi", phoneNumber: "+234 809 012 3456", email: "fadeyi@email.com", alternatePhone: nil, address: "5 Yaba, Lagos", occupation: "Teacher", relationship: .mother, students: nil, studentNames: ["Oluwaseun Fadeyi", "Oluwadamilola Fadeyi"], schoolId: "school-1", isOnline: false, lastSeen: Date().addingTimeInterval(-1800), isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-3888000)),
        Parent(id: "parent-6", name: "Mr. Okoro", phoneNumber: "+234 811 234 5678", email: "okoro@email.com", alternatePhone: nil, address: nil, occupation: "Business Owner", relationship: .father, students: nil, studentNames: ["Chisom Okoro"], schoolId: "school-1", isOnline: false, lastSeen: Date().addingTimeInterval(-86400), isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-6480000)),
        Parent(id: "parent-7", name: "Mrs. Balogun", phoneNumber: "+234 813 456 7890", email: "balogun@email.com", alternatePhone: nil, address: "77 Ikeja GRA, Lagos", occupation: "Architect", relationship: .mother, students: nil, studentNames: ["Adewale Balogun"], schoolId: "school-1", isOnline: true, lastSeen: nil, isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-9072000)),
        Parent(id: "parent-8", name: "Mr. Nnamdi", phoneNumber: "+234 815 678 9012", email: "nnamdi@email.com", alternatePhone: nil, address: nil, occupation: "Pilot", relationship: .father, students: nil, studentNames: ["Kelechi Nnamdi"], schoolId: "school-1", isOnline: false, lastSeen: Date().addingTimeInterval(-172800), isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-11664000)),
        Parent(id: "parent-9", name: "Mrs. Adeleke", phoneNumber: "+234 817 890 1234", email: "adeleke@email.com", alternatePhone: nil, address: "33 Magodo, Lagos", occupation: "Nurse", relationship: .mother, students: nil, studentNames: ["Ayomide Adeleke"], schoolId: "school-1", isOnline: false, lastSeen: Date().addingTimeInterval(-604800), isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-14256000)),
        Parent(id: "parent-10", name: "Mr. Musa", phoneNumber: "+234 819 012 3456", email: "musa@email.com", alternatePhone: nil, address: nil, occupation: "Trader", relationship: .father, students: nil, studentNames: ["Fatima Musa"], schoolId: "school-1", isOnline: false, lastSeen: Date().addingTimeInterval(-259200), isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-16848000)),
        Parent(id: "parent-11", name: "Mrs. Oladipo", phoneNumber: "+234 821 234 5678", email: "oladipo@email.com", alternatePhone: nil, address: nil, occupation: "Consultant", relationship: .mother, students: nil, studentNames: ["Temitope Oladipo"], schoolId: "school-1", isOnline: false, lastSeen: Date().addingTimeInterval(-3600), isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-19440000)),
        Parent(id: "parent-12", name: "Mr. Chukwu", phoneNumber: "+234 823 456 7890", email: "chukwu@email.com", alternatePhone: nil, address: "12 Ajah, Lagos", occupation: "Pharmacist", relationship: .father, students: nil, studentNames: ["Obinna Chukwu"], schoolId: "school-1", isOnline: true, lastSeen: nil, isStarred: false, notes: nil, createdAt: Date().addingTimeInterval(-22032000))
    ]
    
    static let mock = mockList[0]
}

struct ParentCreatePayload: Encodable {
    let whatsappId: String?
    let phoneNumber: String
    let name: String
    let email: String?
    let alternatePhone: String?
    let address: String?
    let occupation: String?
    let relationship: String?
    let notes: String?
    let studentNames: [String]?
}

extension Parent {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown"
        phoneNumber = (try? container.decode(String.self, forKey: .phoneNumber)) ?? ""
        email = try? container.decodeIfPresent(String.self, forKey: .email)
        alternatePhone = try? container.decodeIfPresent(String.self, forKey: .alternatePhone)
        address = try? container.decodeIfPresent(String.self, forKey: .address)
        occupation = try? container.decodeIfPresent(String.self, forKey: .occupation)
        relationship = try? container.decodeIfPresent(ParentRelationship.self, forKey: .relationship)
        students = try? container.decodeIfPresent([Student].self, forKey: .students)
        studentNames = try? container.decodeIfPresent([String].self, forKey: .studentNames)
        schoolId = try? container.decodeIfPresent(String.self, forKey: .schoolId)
        if let decoded = try? container.decodeIfPresent(School.self, forKey: .school) {
            school = decoded
        } else {
            school = nil
        }
        avatarUrl = try? container.decodeIfPresent(String.self, forKey: .avatarUrl)
        isOnline = (try? container.decode(Bool.self, forKey: .isOnline)) ?? false
        lastSeen = try? container.decodeIfPresent(Date.self, forKey: .lastSeen)
        isStarred = (try? container.decode(Bool.self, forKey: .isStarred)) ?? false
        notes = try? container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try? container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(alternatePhone, forKey: .alternatePhone)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(occupation, forKey: .occupation)
        try container.encodeIfPresent(relationship, forKey: .relationship)
        try container.encodeIfPresent(students, forKey: .students)
        try container.encodeIfPresent(studentNames, forKey: .studentNames)
        try container.encodeIfPresent(schoolId, forKey: .schoolId)
        try container.encodeIfPresent(school, forKey: .school)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encodeIfPresent(lastSeen, forKey: .lastSeen)
        try container.encode(isStarred, forKey: .isStarred)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

// MARK: - Conversation (Expanded with more variety)
struct Conversation: Identifiable, Codable {
    let id: String
    var parentId: String
    var parent: Parent?
    var status: ConversationStatus
    var priority: Priority
    var handledBy: ConversationHandler
    var assignedAgentId: String?
    var assignedTeamId: String?
    var unreadCount: Int
    var lastMessagePreview: String?
    var lastMessageAt: Date?
    var createdAt: Date
    var tags: [String]?
    var isAIEnabled: Bool = true  // New: AI toggle per conversation

    enum CodingKeys: String, CodingKey {
        case id
        case parentId
        case parent
        case status
        case priority
        case handledBy
        case assignedAgentId
        case assignedTeamId
        case unreadCount
        case lastMessagePreview
        case lastMessageAt
        case createdAt
        case tags
        case isAIEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        parentId = (try? container.decode(String.self, forKey: .parentId)) ?? ""
        parent = try? container.decodeIfPresent(Parent.self, forKey: .parent)
        status = (try? container.decode(ConversationStatus.self, forKey: .status)) ?? .open
        priority = (try? container.decode(Priority.self, forKey: .priority)) ?? .medium
        handledBy = (try? container.decode(ConversationHandler.self, forKey: .handledBy)) ?? .bot
        assignedAgentId = try? container.decodeIfPresent(String.self, forKey: .assignedAgentId)
        assignedTeamId = try? container.decodeIfPresent(String.self, forKey: .assignedTeamId)
        unreadCount = (try? container.decode(Int.self, forKey: .unreadCount)) ?? 0
        lastMessagePreview = try? container.decodeIfPresent(String.self, forKey: .lastMessagePreview)
        lastMessageAt = try? container.decodeIfPresent(Date.self, forKey: .lastMessageAt)
        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        tags = try? container.decodeIfPresent([String].self, forKey: .tags)
        isAIEnabled = (try? container.decode(Bool.self, forKey: .isAIEnabled)) ?? true
    }

    init(
        id: String,
        parentId: String,
        parent: Parent? = nil,
        status: ConversationStatus,
        priority: Priority,
        handledBy: ConversationHandler,
        assignedAgentId: String? = nil,
        assignedTeamId: String? = nil,
        unreadCount: Int,
        lastMessagePreview: String? = nil,
        lastMessageAt: Date? = nil,
        createdAt: Date,
        tags: [String]? = nil,
        isAIEnabled: Bool = true
    ) {
        self.id = id
        self.parentId = parentId
        self.parent = parent
        self.status = status
        self.priority = priority
        self.handledBy = handledBy
        self.assignedAgentId = assignedAgentId
        self.assignedTeamId = assignedTeamId
        self.unreadCount = unreadCount
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.tags = tags
        self.isAIEnabled = isAIEnabled
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(parentId, forKey: .parentId)
        try container.encodeIfPresent(parent, forKey: .parent)
        try container.encode(status, forKey: .status)
        try container.encode(priority, forKey: .priority)
        try container.encode(handledBy, forKey: .handledBy)
        try container.encodeIfPresent(assignedAgentId, forKey: .assignedAgentId)
        try container.encodeIfPresent(assignedTeamId, forKey: .assignedTeamId)
        try container.encode(unreadCount, forKey: .unreadCount)
        try container.encodeIfPresent(lastMessagePreview, forKey: .lastMessagePreview)
        try container.encodeIfPresent(lastMessageAt, forKey: .lastMessageAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encode(isAIEnabled, forKey: .isAIEnabled)
    }
    
    static let mockList: [Conversation] = [
        Conversation(
            id: "conv-1",
            parentId: "parent-1",
            parent: Parent.mockList[0],
            status: .open,
            priority: .medium,
            handledBy: .bot,
            unreadCount: 2,
            lastMessagePreview: "When does school resume?",
            lastMessageAt: Date(),
            createdAt: Date()
        ),
        Conversation(
            id: "conv-2",
            parentId: "parent-2",
            parent: Parent.mockList[1],
            status: .pending,
            priority: .high,
            handledBy: .agent,
            assignedAgentId: "agent-1",
            unreadCount: 0,
            lastMessagePreview: "I have a question about my son's fees",
            lastMessageAt: Date().addingTimeInterval(-3600),
            createdAt: Date().addingTimeInterval(-86400),
            tags: ["finance", "fees"]
        ),
        Conversation(
            id: "conv-3",
            parentId: "parent-3",
            parent: Parent.mockList[2],
            status: .open,
            priority: .urgent,
            handledBy: .team,
            assignedTeamId: "finance",
            unreadCount: 5,
            lastMessagePreview: "URGENT: Payment issue needs immediate attention",
            lastMessageAt: Date().addingTimeInterval(-1800),
            createdAt: Date().addingTimeInterval(-172800),
            tags: ["finance", "urgent", "payment"]
        ),
        Conversation(
            id: "conv-4",
            parentId: "parent-4",
            parent: Parent.mockList[3],
            status: .resolved,
            priority: .low,
            handledBy: .bot,
            unreadCount: 0,
            lastMessagePreview: "Thank you for the information!",
            lastMessageAt: Date().addingTimeInterval(-7200),
            createdAt: Date().addingTimeInterval(-259200)
        ),
        Conversation(
            id: "conv-5",
            parentId: "parent-5",
            parent: Parent.mockList[4],
            status: .open,
            priority: .medium,
            handledBy: .bot,
            unreadCount: 1,
            lastMessagePreview: "Can I get the school calendar for next term?",
            lastMessageAt: Date().addingTimeInterval(-900),
            createdAt: Date().addingTimeInterval(-1800),
            tags: ["calendar", "general"]
        ),
        Conversation(
            id: "conv-6",
            parentId: "parent-6",
            parent: Parent.mockList[5],
            status: .pending,
            priority: .high,
            handledBy: .agent,
            assignedAgentId: "agent-1",
            unreadCount: 3,
            lastMessagePreview: "My child missed the exam, what can we do?",
            lastMessageAt: Date().addingTimeInterval(-2700),
            createdAt: Date().addingTimeInterval(-10800),
            tags: ["academic", "exam"]
        ),
        Conversation(
            id: "conv-7",
            parentId: "parent-7",
            parent: Parent.mockList[6],
            status: .open,
            priority: .low,
            handledBy: .bot,
            unreadCount: 0,
            lastMessagePreview: "What are the uniform requirements?",
            lastMessageAt: Date().addingTimeInterval(-5400),
            createdAt: Date().addingTimeInterval(-14400)
        ),
        Conversation(
            id: "conv-8",
            parentId: "parent-8",
            parent: Parent.mockList[7],
            status: .open,
            priority: .medium,
            handledBy: .team,
            assignedTeamId: "admissions",
            unreadCount: 2,
            lastMessagePreview: "Is there space for mid-term admission?",
            lastMessageAt: Date().addingTimeInterval(-4200),
            createdAt: Date().addingTimeInterval(-21600),
            tags: ["admissions", "transfer"]
        )
    ]
}

enum ConversationStatus: String, Codable {
    case open, pending, resolved, closed

    init(from decoder: Decoder) throws {
        let value = (try? decoder.singleValueContainer().decode(String.self))?.lowercased() ?? ""
        self = ConversationStatus(rawValue: value) ?? .open
    }
}

enum Priority: String, Codable {
    case low, medium, high, urgent

    init(from decoder: Decoder) throws {
        let value = (try? decoder.singleValueContainer().decode(String.self))?.lowercased() ?? ""
        self = Priority(rawValue: value) ?? .medium
    }
}

enum ConversationHandler: String, Codable {
    case bot, agent, team

    init(from decoder: Decoder) throws {
        let value = (try? decoder.singleValueContainer().decode(String.self))?.lowercased() ?? ""
        self = ConversationHandler(rawValue: value) ?? .bot
    }
}

// MARK: - Link Preview
struct LinkPreview: Codable {
    var url: String
    var title: String?
    var description: String?
    var imageUrl: String?
    var domain: String?
    
    static let mock = LinkPreview(url: "https://schoolable.com/calendar", title: "Academic Calendar 2025/2026", description: "View the complete academic calendar for the current year", imageUrl: nil, domain: "schoolable.com")
}

// MARK: - Message Reaction
struct MessageReaction: Identifiable, Codable {
    let id: String
    var emoji: String
    var userId: String
    var userName: String
    var createdAt: Date = Date()
    
    static let quickReactions = ["👍", "❤️", "😂", "😮", "😢", "🙏"]
}

// MARK: - Message (Enhanced with WhatsApp-like features)
struct Message: Identifiable, Codable {
    let id: String
    var conversationId: String
    var senderId: String?
    var senderType: SenderType
    var content: String
    var messageType: MessageType
    var status: MessageStatus
    var sentAt: Date
    var metadata: [String: String]?
    var imageUrl: String?
    
    // WhatsApp-like features
    var readAt: Date?                    // Read receipt timestamp
    var deliveredAt: Date?               // Delivery timestamp
    var replyToMessageId: String?        // Quote/reply to message
    var replyToPreview: String?          // Preview of quoted message
    var replyToSenderName: String?       // Sender name of quoted message
    var replyToSenderType: SenderType?   // Sender type of quoted message
    var reactions: [MessageReaction]?    // Emoji reactions
    var isStarred: Bool = false          // Starred/saved message
    var isDeleted: Bool = false          // "Deleted for everyone"
    var deletedAt: Date?                 // When deleted
    var isForwarded: Bool = false        // Forwarded message indicator
    var isEdited: Bool = false           // Whether message was edited
    var editedAt: Date?                  // When message was edited
    var linkPreview: LinkPreview?        // URL preview card
    var voiceDuration: TimeInterval?     // Duration for voice messages
    var documentName: String?            // Name for document attachments
    var documentSize: Int?               // Size in bytes
    
    // Messages organized by conversation
    static func messagesFor(conversationId: String) -> [Message] {
        switch conversationId {
        case "conv-1":
            return [
                Message(id: "msg-1-1", conversationId: "conv-1", senderId: "parent-1", senderType: .parent,
                       content: "Hello, when does school resume for the new term?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-300)),
                Message(id: "msg-1-2", conversationId: "conv-1", senderId: nil, senderType: .bot,
                       content: "Hello! Thank you for reaching out. School resumes on January 6th, 2026. Is there anything else I can help you with?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-280)),
                Message(id: "msg-1-3", conversationId: "conv-1", senderId: "parent-1", senderType: .parent,
                       content: "What time should I drop off my child?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-120)),
                Message(id: "msg-1-4", conversationId: "conv-1", senderId: nil, senderType: .bot,
                       content: "Drop-off time is between 7:30 AM and 8:00 AM. The school gates open at 7:15 AM.", messageType: .text, status: .read, sentAt: Date().addingTimeInterval(-60))
            ]
        case "conv-2":
            return [
                Message(id: "msg-2-1", conversationId: "conv-2", senderId: "parent-2", senderType: .parent,
                       content: "Good morning, I have a question about my son Chinedu's school fees.", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-7200)),
                Message(id: "msg-2-2", conversationId: "conv-2", senderId: nil, senderType: .bot,
                       content: "Good morning! I'd be happy to help with fee inquiries. Could you please specify what information you need?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-7100)),
                Message(id: "msg-2-3", conversationId: "conv-2", senderId: "parent-2", senderType: .parent,
                       content: "I made a payment last week but it's not reflecting in my account. Here's the receipt:", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-6000)),
                Message(id: "msg-2-4", conversationId: "conv-2", senderId: "parent-2", senderType: .parent,
                       content: "[Payment Receipt - ₦250,000]", messageType: .image, status: .delivered, sentAt: Date().addingTimeInterval(-5900), imageUrl: "receipt_image"),
                Message(id: "msg-2-5", conversationId: "conv-2", senderId: "agent-1", senderType: .agent,
                       content: "Thank you for sharing the receipt. I'll check with our finance team and get back to you within 24 hours.", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-5000))
            ]
        case "conv-3":
            return [
                Message(id: "msg-3-1", conversationId: "conv-3", senderId: "parent-3", senderType: .parent,
                       content: "URGENT! There's a discrepancy with my payment. I paid ₦500,000 but only ₦300,000 is showing!", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-3600)),
                Message(id: "msg-3-2", conversationId: "conv-3", senderId: nil, senderType: .bot,
                       content: "I understand this is concerning. Let me escalate this to our finance team immediately for urgent review.", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-3500)),
                Message(id: "msg-3-3", conversationId: "conv-3", senderId: nil, senderType: .system,
                       content: "This conversation has been escalated to Finance Team", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-3400)),
                Message(id: "msg-3-4", conversationId: "conv-3", senderId: "parent-3", senderType: .parent,
                       content: "Please resolve this quickly, I don't want Aisha to be sent home", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-2400)),
                Message(id: "msg-3-5", conversationId: "conv-3", senderId: "parent-3", senderType: .parent,
                       content: "Here is my bank statement showing the debit:", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-2300)),
                Message(id: "msg-3-6", conversationId: "conv-3", senderId: "parent-3", senderType: .parent,
                       content: "[Bank Statement Screenshot]", messageType: .image, status: .delivered, sentAt: Date().addingTimeInterval(-2200), imageUrl: "bank_statement")
            ]
        case "conv-4":
            return [
                Message(id: "msg-4-1", conversationId: "conv-4", senderId: "parent-4", senderType: .parent,
                       content: "What are the visiting hours for parents?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-10800)),
                Message(id: "msg-4-2", conversationId: "conv-4", senderId: nil, senderType: .bot,
                       content: "Parent visiting hours are:\n• Monday-Friday: 10:00 AM - 12:00 PM\n• Weekends: 9:00 AM - 4:00 PM\n\nPlease bring a valid ID for registration at the gate.", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-10700)),
                Message(id: "msg-4-3", conversationId: "conv-4", senderId: "parent-4", senderType: .parent,
                       content: "Thank you for the information!", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-10600))
            ]
        case "conv-5":
            return [
                Message(id: "msg-5-1", conversationId: "conv-5", senderId: "parent-5", senderType: .parent,
                       content: "Hi, can I get the school calendar for the next academic term?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-1200)),
                Message(id: "msg-5-2", conversationId: "conv-5", senderId: nil, senderType: .bot,
                       content: "Of course! The academic calendar for 2025/2026 is as follows:\n\n📅 First Term: Sept 9 - Dec 13\n📅 Second Term: Jan 6 - April 10\n📅 Third Term: May 4 - July 25\n\nWould you like me to send you a PDF copy?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-1100)),
                Message(id: "msg-5-3", conversationId: "conv-5", senderId: "parent-5", senderType: .parent,
                       content: "Yes please, that would be helpful!", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-900))
            ]
        case "conv-6":
            return [
                Message(id: "msg-6-1", conversationId: "conv-6", senderId: "parent-6", senderType: .parent,
                       content: "My child Chisom was sick and missed the mid-term exam. What are our options?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-10800)),
                Message(id: "msg-6-2", conversationId: "conv-6", senderId: nil, senderType: .bot,
                       content: "I'm sorry to hear Chisom was unwell. For missed exams due to illness, you'll need to submit a medical certificate to the academic affairs office. Shall I connect you with an academic advisor?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-10700)),
                Message(id: "msg-6-3", conversationId: "conv-6", senderId: "parent-6", senderType: .parent,
                       content: "Yes, please do. Also, here is the hospital's medical report:", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-9000)),
                Message(id: "msg-6-4", conversationId: "conv-6", senderId: "parent-6", senderType: .parent,
                       content: "[Medical Certificate from Lagos General Hospital]", messageType: .image, status: .delivered, sentAt: Date().addingTimeInterval(-8900), imageUrl: "medical_cert"),
                Message(id: "msg-6-5", conversationId: "conv-6", senderId: "agent-1", senderType: .agent,
                       content: "Thank you for sharing the medical certificate. I've forwarded this to our academic coordinator. You'll receive a call within 2 working days to schedule a make-up exam.", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-7200))
            ]
        case "conv-7":
            return [
                Message(id: "msg-7-1", conversationId: "conv-7", senderId: "parent-7", senderType: .parent,
                       content: "What are the uniform requirements for JSS1 students?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-7200)),
                Message(id: "msg-7-2", conversationId: "conv-7", senderId: nil, senderType: .bot,
                       content: "For JSS1 students, the uniform requirements are:\n\n👔 Boys:\n• White short-sleeve shirt\n• Navy blue trousers\n• Black shoes with white socks\n\n👗 Girls:\n• White short-sleeve blouse\n• Navy blue skirt\n• Black shoes with white socks\n\nPE Kit: House-colored t-shirt with blue shorts/skirt\n\nWould you like information about where to purchase these?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-7100))
            ]
        case "conv-8":
            return [
                Message(id: "msg-8-1", conversationId: "conv-8", senderId: "parent-8", senderType: .parent,
                       content: "Hello, we're relocating from Abuja and need to transfer our son to your school. Is there availability for SS1?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-21600)),
                Message(id: "msg-8-2", conversationId: "conv-8", senderId: nil, senderType: .bot,
                       content: "Welcome! We're glad you're considering our school. For mid-term transfers, we have limited spots available. Let me connect you with our admissions team.", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-21500)),
                Message(id: "msg-8-3", conversationId: "conv-8", senderId: nil, senderType: .system,
                       content: "This conversation has been assigned to Admissions Team", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-21400)),
                Message(id: "msg-8-4", conversationId: "conv-8", senderId: "parent-8", senderType: .parent,
                       content: "Thank you! Also, what documents will we need to provide?", messageType: .text, status: .delivered, sentAt: Date().addingTimeInterval(-18000))
            ]
        default:
            return []
        }
    }
    
    static let mockList: [Message] = messagesFor(conversationId: "conv-1")
}

// MARK: - API Message (subset for decoding)
struct APIMessage: Decodable {
    let id: String
    let conversationId: String
    let senderId: String?
    let senderType: SenderType
    let content: String?
    let messageType: MessageType
    let mediaUrl: String?
    let mediaMimeType: String?
    let status: MessageStatus
    let sentAt: Date?
    let deliveredAt: Date?
    let readAt: Date?
    let isDeleted: Bool?
    let isEdited: Bool?
    let isStarred: Bool?
    let isForwarded: Bool?
    let reactions: [MessageReaction]?
    let voiceDuration: TimeInterval?
    let documentName: String?
    let documentSize: Int?
}

struct APIUploadMessageData: Decodable {
    let message: APIMessage
    let mediaUrl: String?
}

extension APIMessage {
    func toMessage() -> Message {
        let normalized = normalizeInboundContent()
        let resolvedMediaURL = resolvedMediaURL(from: normalized.mediaURL)
        var extraMetadata: [String: String] = [:]
        if let mime = mediaMimeType, !mime.isEmpty {
            extraMetadata["media_mime_type"] = mime
        }
        let metadata = extraMetadata.isEmpty ? nil : extraMetadata
        return Message(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            senderType: senderType,
            content: normalized.content,
            messageType: normalized.messageType,
            status: status,
            sentAt: sentAt ?? Date(),
            metadata: metadata,
            imageUrl: resolvedMediaURL,
            readAt: readAt,
            deliveredAt: deliveredAt,
            replyToMessageId: nil,
            replyToPreview: nil,
            replyToSenderName: nil,
            replyToSenderType: nil,
            reactions: reactions,
            isStarred: isStarred ?? false,
            isDeleted: isDeleted ?? false,
            deletedAt: nil,
            isForwarded: isForwarded ?? false,
            isEdited: isEdited ?? false,
            editedAt: nil,
            linkPreview: nil,
            voiceDuration: voiceDuration,
            documentName: documentName,
            documentSize: documentSize
        )
    }

    private func normalizeInboundContent() -> (content: String, messageType: MessageType, mediaURL: String?) {
        var body = content ?? ""
        var inferredType = messageType
        var inferredMediaURL = mediaUrl
        var inferredMime = mediaMimeType

        if let inlineMedia = extractInlineMedia(from: body) {
            body = inlineMedia.cleanedBody
            if inferredMediaURL == nil {
                inferredMediaURL = inlineMedia.path
            }
            if inferredMime == nil {
                inferredMime = inlineMedia.mimeType
            }
        }

        body = sanitizeTranscript(body)

        if inferredType == .text, let media = inferredMediaURL {
            inferredType = inferMediaType(from: inferredMime, mediaURL: media)
        }

        if inferredType == .text, let placeholderType = mediaPlaceholderType(for: body) {
            inferredType = placeholderType
            body = ""
        }

        if inferredType != .text {
            let normalizedBody = body.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if normalizedBody == "<media:attachment>" || normalizedBody == "<media:image>" || normalizedBody == "<media:sticker>" || normalizedBody == "<media:video>" || normalizedBody == "<media:audio>" || normalizedBody == "<media:document>" {
                body = ""
            }
            if looksLikeTransportMetadata(body) {
                body = ""
            }
        }

        return (content: body, messageType: inferredType, mediaURL: inferredMediaURL)
    }

    private func resolvedMediaURL(from raw: String?) -> String? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            return value
        }
        if value.hasPrefix("/api/") {
            return apiRootURL() + value
        }
        if value.hasPrefix("/") || value.hasPrefix("local://") || value.hasPrefix("file://") {
            return apiRootURL() + "/api/v1/conversations/\(conversationId)/messages/\(id)/media"
        }
        return value
    }

    private func apiRootURL() -> String {
        let configured = UserDefaults.standard.string(forKey: "apiBaseURL") ?? "http://localhost:8080/api/v1"
        guard let parsed = URL(string: configured),
              let scheme = parsed.scheme,
              let host = parsed.host else {
            return "http://localhost:8080"
        }
        if let port = parsed.port {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }

    private func mediaPlaceholderType(for value: String) -> MessageType? {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "<media:image>", "<media:sticker>":
            return .image
        case "<media:audio>":
            return .audio
        case "<media:video>":
            return .video
        case "<media:document>", "<media:attachment>":
            return .document
        default:
            return nil
        }
    }

    private func looksLikeTransportMetadata(_ value: String) -> Bool {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text.isEmpty {
            return false
        }
        if text.hasPrefix("inbound message +") || text.hasPrefix("outbound message +") {
            return true
        }
        if text.contains("(direct, image/") || text.contains("(group, image/") || text.contains("(direct, video/") {
            return true
        }
        // Ignore single-line phone identifiers that can appear with media-only messages.
        if text.first == "+" && text.count <= 20 {
            let digits = text.dropFirst().allSatisfy { $0.isNumber }
            if digits {
                return true
            }
        }
        return false
    }

    private func sanitizeTranscript(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "" }

        if let range = text.range(of: "To send an image back, prefer the message tool", options: .caseInsensitive) {
            text = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                if line.isEmpty { return false }
                if line == "---" { return false }
                if line == "[Queued messages while agent was busy]" { return false }
                if line.lowercased().hasPrefix("queued #") { return false }
                return true
            }
            .map { line -> String in
                if line.hasPrefix("[WhatsApp "), let closeIdx = line.firstIndex(of: "]") {
                    return String(line[line.index(after: closeIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return line
            }
            .filter { !$0.isEmpty }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractInlineMedia(from text: String) -> (path: String, mimeType: String, cleanedBody: String)? {
        let pattern = #"\[media attached:\s*([^\n\]]+?)\s*\(([^)]+)\)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges >= 3 else {
            return nil
        }

        let path = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
        let mime = ns.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = regex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: ns.length), withTemplate: "")
        return (path: path, mimeType: mime, cleanedBody: cleaned)
    }

    private func inferMediaType(from mimeType: String?, mediaURL: String) -> MessageType {
        if let mimeType = mimeType?.lowercased() {
            if mimeType.hasPrefix("image/") { return .image }
            if mimeType.hasPrefix("audio/") { return .audio }
            if mimeType.hasPrefix("video/") { return .video }
            return .document
        }

        let ext = URL(fileURLWithPath: mediaURL).pathExtension.lowercased()
        switch ext {
        case "png", "jpg", "jpeg", "gif", "webp", "bmp", "heic", "heif":
            return .image
        case "mp3", "aac", "m4a", "wav", "ogg", "opus":
            return .audio
        case "mp4", "mov", "mkv", "webm":
            return .video
        default:
            return .document
        }
    }
}

struct ConversationAssistantInsight: Decodable {
    let aiEnabled: Bool
    let intent: String
    let sentiment: String
    let urgency: String
    let confidence: Double
    let contextSummary: String
    let keywords: [String]
    let suggestedReply: String
    let sources: [ConversationAssistantSource]
    let updatedAt: Date?
}

struct ConversationAssistantSource: Decodable, Identifiable {
    let id: String
    let title: String
    let category: String
}

enum SenderType: String, Codable {
    case parent, agent, bot, team, system

    init(from decoder: Decoder) throws {
        let value = (try? decoder.singleValueContainer().decode(String.self))?.lowercased() ?? ""
        self = SenderType(rawValue: value) ?? .system
    }
}

enum MessageType: String, Codable {
    case text, image, document, audio, template, video, location, system

    init(from decoder: Decoder) throws {
        let value = (try? decoder.singleValueContainer().decode(String.self))?.lowercased() ?? ""
        self = MessageType(rawValue: value) ?? .text
    }
}

enum MessageStatus: String, Codable {
    case pending, sent, delivered, read, failed

    init(from decoder: Decoder) throws {
        let value = (try? decoder.singleValueContainer().decode(String.self))?.lowercased() ?? ""
        self = MessageStatus(rawValue: value) ?? .pending
    }
}

// MARK: - AI Suggestion (Context-aware per conversation)
struct AISuggestion {
    let suggestedReply: String
    let confidence: Double
    let context: String
    let keywords: [String]
    
    static func suggestionsFor(conversationId: String) -> AISuggestion {
        switch conversationId {
        case "conv-1":
            return AISuggestion(
                suggestedReply: "You're welcome! If you have any other questions about the new term, feel free to ask. Have a great day!",
                confidence: 0.92,
                context: "Parent is asking about school resumption dates and timings. The bot has already provided accurate information.",
                keywords: ["resumption", "school calendar", "drop-off times"]
            )
        case "conv-2":
            return AISuggestion(
                suggestedReply: "I've verified with our finance department. Your payment of ₦250,000 made on [date] has been located and will be credited to your account within 24 hours. We apologize for the delay.",
                confidence: 0.78,
                context: "Payment reconciliation issue. Parent provided receipt. Needs manual verification with finance team.",
                keywords: ["payment", "fees", "receipt", "finance"]
            )
        case "conv-3":
            return AISuggestion(
                suggestedReply: "We are actively investigating the ₦200,000 discrepancy. Our finance team is reviewing your bank statement. Please do not worry - Aisha will not be affected while we resolve this.",
                confidence: 0.85,
                context: "URGENT financial dispute. Parent claims ₦200,000 missing from payment. High priority escalation.",
                keywords: ["urgent", "payment dispute", "bank statement", "escalation"]
            )
        case "conv-5":
            return AISuggestion(
                suggestedReply: "I've attached the academic calendar PDF for 2025/2026. You can also access it on our parent portal at portal.schoolable.com. Is there anything else I can help with?",
                confidence: 0.95,
                context: "Simple request for calendar information. Standard response needed.",
                keywords: ["calendar", "academic year", "term dates"]
            )
        case "conv-6":
            return AISuggestion(
                suggestedReply: "Our academic coordinator Dr. Adamu will contact you within 2 working days to schedule Chisom's make-up exam. The medical certificate has been approved.",
                confidence: 0.88,
                context: "Student missed exam due to illness. Medical certificate submitted. Follow-up required.",
                keywords: ["missed exam", "medical", "make-up exam", "academic"]
            )
        case "conv-8":
            return AISuggestion(
                suggestedReply: "For mid-term transfers to SS1, you'll need:\n1. Previous school testimonial\n2. Transfer certificate\n3. Last 2 report cards\n4. Birth certificate\n5. Passport photographs (4)\n\nWould you like to schedule an in-person visit?",
                confidence: 0.91,
                context: "Transfer/admission inquiry. Family relocating from Abuja. Standard admission documents needed.",
                keywords: ["transfer", "admission", "documents", "SS1"]
            )
        default:
            return AISuggestion(
                suggestedReply: "Thank you for your message. How can I assist you further today?",
                confidence: 0.65,
                context: "General inquiry. Standard follow-up response.",
                keywords: ["general"]
            )
        }
    }

    static func simulatedParentReply(for conversationId: String) -> String {
        switch conversationId {
        case "conv-1":
            return "Thanks! Also, does the school provide lunch or should I pack one?"
        case "conv-2":
            return "Great, I have the transaction reference ready. Do you need it now?"
        case "conv-3":
            return "I can send additional bank statements if needed. Please let me know."
        case "conv-5":
            return "Yes please, can you send the calendar PDF?"
        case "conv-6":
            return "Thank you. What documents should we bring for the make-up exam?"
        case "conv-8":
            return "Can we schedule a visit this week? What times are available?"
        default:
            return "Thanks for the update. Is there anything else you need from me?"
        }
    }

    static func followUpSuggestion(for conversationId: String) -> AISuggestion {
        switch conversationId {
        case "conv-1":
            return AISuggestion(
                suggestedReply: "We do not provide lunch at this time, so please pack a meal. We do have a small snack break around 10:30 AM.",
                confidence: 0.86,
                context: "Parent asked about lunch options after resumption and drop-off details.",
                keywords: ["lunch", "snack", "school hours"]
            )
        case "conv-2":
            return AISuggestion(
                suggestedReply: "Yes, please share the transaction reference. I will forward it to finance immediately and update you within 24 hours.",
                confidence: 0.82,
                context: "Parent is ready to share a transaction reference for a payment issue.",
                keywords: ["payment", "reference", "finance"]
            )
        case "conv-3":
            return AISuggestion(
                suggestedReply: "Yes, please send the additional bank statement. It will help us complete the reconciliation faster.",
                confidence: 0.84,
                context: "Urgent payment dispute needs more supporting documents.",
                keywords: ["bank statement", "finance", "urgent"]
            )
        case "conv-5":
            return AISuggestion(
                suggestedReply: "Absolutely. I am sending the PDF now. Let me know if you need the term dates in a different format.",
                confidence: 0.93,
                context: "Parent requested the academic calendar PDF.",
                keywords: ["calendar", "pdf", "term dates"]
            )
        case "conv-6":
            return AISuggestion(
                suggestedReply: "Please bring the original medical certificate and a photocopy. The academic office will also request a parent signature form on arrival.",
                confidence: 0.81,
                context: "Parent asked about required documents for a make-up exam.",
                keywords: ["documents", "medical certificate", "exam"]
            )
        case "conv-8":
            return AISuggestion(
                suggestedReply: "We can schedule visits on weekdays between 10:00 AM and 2:00 PM. Which day works best for you?",
                confidence: 0.9,
                context: "Parent wants to schedule an admissions visit.",
                keywords: ["admissions", "visit", "schedule"]
            )
        default:
            return AISuggestion(
                suggestedReply: "Happy to help. Could you share a bit more detail so I can assist quickly?",
                confidence: 0.7,
                context: "General follow-up after parent response.",
                keywords: ["follow-up"]
            )
        }
    }
}

// MARK: - Escalation
struct Escalation: Identifiable, Codable {
    let id: String
    var conversationId: String
    var conversation: Conversation?
    var reason: String
    var aiSummary: String
    var priority: Priority
    var status: EscalationStatus
    var toTeamId: String?
    var toAgentId: String?
    var createdAt: Date
    var acceptedAt: Date?
    
    enum EscalationStatus: String, Codable {
        case pending, accepted, completed
    }
    
    static let mockList: [Escalation] = [
        Escalation(
            id: "esc-1",
            conversationId: "conv-3",
            reason: "Financial dispute requires human review",
            aiSummary: "Parent is disputing a fee charge. Claims paid ₦500,000 but system shows only ₦300,000. Bank statement provided.",
            priority: .urgent,
            status: .pending,
            toTeamId: "finance",
            createdAt: Date().addingTimeInterval(-600)
        ),
        Escalation(
            id: "esc-2",
            conversationId: "conv-2",
            reason: "Payment not reflecting",
            aiSummary: "Parent made payment last week, submitted receipt, but amount not showing in system.",
            priority: .high,
            status: .accepted,
            toAgentId: "agent-1",
            createdAt: Date().addingTimeInterval(-3600),
            acceptedAt: Date().addingTimeInterval(-3000)
        ),
        Escalation(
            id: "esc-3",
            conversationId: "conv-6",
            reason: "Academic exception request",
            aiSummary: "Student missed mid-term exam due to illness. Medical certificate provided. Needs make-up exam scheduling.",
            priority: .high,
            status: .accepted,
            toTeamId: "team-4",
            createdAt: Date().addingTimeInterval(-9000),
            acceptedAt: Date().addingTimeInterval(-8500)
        )
    ]
}

// MARK: - Team
struct Team: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String?
    var categories: [String]
    var memberCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case categories
        case memberCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? container.decode(String.self, forKey: .name)) ?? "Team"
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        categories = (try? container.decode([String].self, forKey: .categories)) ?? []
        memberCount = (try? container.decode(Int.self, forKey: .memberCount)) ?? 0
    }

    init(
        id: String,
        name: String,
        description: String? = nil,
        categories: [String] = [],
        memberCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.categories = categories
        self.memberCount = memberCount
    }

    static let mockList: [Team] = [
        Team(id: "team-1", name: "Customer Support", description: "General queries", categories: ["general_info"], memberCount: 5),
        Team(id: "team-2", name: "Finance", description: "Billing and payments", categories: ["finance"], memberCount: 3),
        Team(id: "team-3", name: "Admissions", description: "Enrollment", categories: ["admissions"], memberCount: 4),
        Team(id: "team-4", name: "Academic Affairs", description: "Curriculum and grades", categories: ["academic"], memberCount: 3),
        Team(id: "team-5", name: "Technical Support", description: "App and system issues", categories: ["technical"], memberCount: 2),
        Team(id: "team-6", name: "Operations", description: "Day-to-day operations", categories: ["operations"], memberCount: 4)
    ]
}

// MARK: - Agent With Workload (for queue management)
struct AgentWithWorkload: Identifiable {
    let id: String
    var name: String
    var email: String
    var teamId: String
    var status: Agent.AgentStatus
    var activeConversations: Int
    var maxCapacity: Int
    var avatarInitial: String
    
    var workloadPercentage: Double {
        Double(activeConversations) / Double(maxCapacity)
    }
    
    var isAvailable: Bool {
        status == .online && activeConversations < maxCapacity
    }
    
    static let mockList: [AgentWithWorkload] = [
        AgentWithWorkload(id: "agent-1", name: MockAgentInfo.name, email: MockAgentInfo.email, teamId: "team-1", status: .online, activeConversations: 4, maxCapacity: 8, avatarInitial: MockAgentInfo.avatarInitial),
        AgentWithWorkload(id: "agent-2", name: "Michael Obi", email: "michael@schoolable.com", teamId: "team-1", status: .online, activeConversations: 2, maxCapacity: 8, avatarInitial: "M"),
        AgentWithWorkload(id: "agent-3", name: "Grace Adeyemi", email: "grace@schoolable.com", teamId: "team-3", status: .busy, activeConversations: 7, maxCapacity: 8, avatarInitial: "G"),
        AgentWithWorkload(id: "agent-4", name: "Daniel Nwosu", email: "daniel@schoolable.com", teamId: "team-5", status: .online, activeConversations: 1, maxCapacity: 8, avatarInitial: "D"),
        AgentWithWorkload(id: "agent-5", name: "Chidi Eze", email: "chidi@schoolable.com", teamId: "team-6", status: .away, activeConversations: 3, maxCapacity: 8, avatarInitial: "C")
    ]
    
    static func leastBusyAgent() -> AgentWithWorkload? {
        mockList.filter { $0.isAvailable }.min { $0.activeConversations < $1.activeConversations }
    }

    static func members(of teamId: String) -> [AgentWithWorkload] {
        mockList.filter { $0.teamId == teamId }
    }
}

// MARK: - API Canned Response
struct APICannedResponse: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let category: String?
    let shortcut: String?
}

// MARK: - Quick Reply Template
struct ResponseTemplate: Identifiable {
    let id: String
    var title: String
    var content: String
    var category: TemplateCategory
    var shortcut: String?
    
    enum TemplateCategory: String, CaseIterable {
        case greeting = "Greeting"
        case general = "General"
        case fees = "Fees"
        case academic = "Academic"
        case closing = "Closing"
    }

    static func fromAPI(_ apiCategory: String?) -> TemplateCategory {
        guard let value = apiCategory?.lowercased() else { return .general }
        switch value {
        case "greeting", "greetings":
            return .greeting
        case "fees", "finance", "billing":
            return .fees
        case "academic", "academics":
            return .academic
        case "closing", "farewell":
            return .closing
        default:
            return .general
        }
    }

    static func fromAPI(_ api: APICannedResponse) -> ResponseTemplate {
        let category = fromAPI(api.category)
        return ResponseTemplate(
            id: api.id,
            title: api.title,
            content: api.content,
            category: category,
            shortcut: api.shortcut
        )
    }
    
    static let mockList: [ResponseTemplate] = [
        // Greetings
        ResponseTemplate(id: "t1", title: "Welcome", content: "Hello! Thank you for reaching out. How can I assist you today?", category: .greeting, shortcut: "/hello"),
        ResponseTemplate(id: "t2", title: "Good Morning", content: "Good morning! I hope you're having a great day. How may I help you?", category: .greeting, shortcut: "/gm"),
        
        // General
        ResponseTemplate(id: "t3", title: "Office Hours", content: "Our office hours are Monday to Friday, 8:00 AM to 4:00 PM. We're closed on weekends and public holidays.", category: .general, shortcut: "/hours"),
        ResponseTemplate(id: "t4", title: "Please Hold", content: "Thank you for your patience. I'm looking into this for you and will get back to you shortly.", category: .general, shortcut: "/hold"),
        ResponseTemplate(id: "t5", title: "Checking Status", content: "Let me check on the status of that for you. One moment please.", category: .general, shortcut: "/check"),
        
        // Fees
        ResponseTemplate(id: "t6", title: "Payment Confirmation", content: "I can confirm that your payment has been received and processed. Thank you!", category: .fees, shortcut: "/paid"),
        ResponseTemplate(id: "t7", title: "Fee Breakdown", content: "Here's the fee breakdown for this term:\n• Tuition: ₦XXX,XXX\n• Development Levy: ₦XX,XXX\n• Total: ₦XXX,XXX", category: .fees, shortcut: "/fees"),
        ResponseTemplate(id: "t8", title: "Payment Options", content: "You can make payments via:\n• Bank Transfer to the school account\n• Online payment portal\n• Cash at the bursary office", category: .fees, shortcut: "/pay"),
        
        // Academic
        ResponseTemplate(id: "t9", title: "Term Dates", content: "The academic calendar for 2025/2026:\n• First Term: Sept 9 - Dec 13\n• Second Term: Jan 6 - April 10\n• Third Term: May 4 - July 25", category: .academic, shortcut: "/dates"),
        ResponseTemplate(id: "t10", title: "Report Card", content: "Report cards will be available on the parent portal within 2 weeks after the term ends. You'll receive a notification when it's ready.", category: .academic, shortcut: "/report"),
        
        // Closing
        ResponseTemplate(id: "t11", title: "Thank You", content: "Thank you for contacting us! Is there anything else I can help you with?", category: .closing, shortcut: "/thanks"),
        ResponseTemplate(id: "t12", title: "Goodbye", content: "It was my pleasure helping you today. Have a wonderful day!", category: .closing, shortcut: "/bye"),
        ResponseTemplate(id: "t13", title: "Follow Up", content: "I'll follow up on this and get back to you within 24 hours. Thank you for your patience.", category: .closing, shortcut: "/followup")
    ]
}

// MARK: - Team Chat Message (Internal)
struct TeamChatMessage: Identifiable, Codable {
    let id: String
    var senderId: String?
    var senderName: String
    var content: String
    var channelId: String?  // nil for direct messages
    var recipientId: String?  // for direct messages
    var sentAt: Date
    var isRead: Bool

    init(
        id: String,
        senderId: String?,
        senderName: String,
        content: String,
        channelId: String?,
        recipientId: String?,
        sentAt: Date,
        isRead: Bool
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.channelId = channelId
        self.recipientId = recipientId
        self.sentAt = sentAt
        self.isRead = isRead
    }
    
    static func messagesForDM(_ agentId: String) -> [TeamChatMessage] {
        switch agentId {
        case "agent-2":
            return [
                TeamChatMessage(id: "tcm-dm-2-1", senderId: "agent-2", senderName: "Michael Obi", content: "Hey Sarah, can you help with the Ibrahim case? It's getting complicated.", channelId: nil, recipientId: "agent-1", sentAt: Date().addingTimeInterval(-5400), isRead: true),
                TeamChatMessage(id: "tcm-dm-2-2", senderId: "agent-1", senderName: MockAgentInfo.name, content: "Sure. Is it the payment dispute with the bank statement?", channelId: nil, recipientId: "agent-2", sentAt: Date().addingTimeInterval(-5100), isRead: true),
                TeamChatMessage(id: "tcm-dm-2-3", senderId: "agent-2", senderName: "Michael Obi", content: "Yes. Parent says 200k is missing. I escalated to Finance, but they need more proof.", channelId: nil, recipientId: "agent-1", sentAt: Date().addingTimeInterval(-4800), isRead: true),
                TeamChatMessage(id: "tcm-dm-2-4", senderId: "agent-1", senderName: MockAgentInfo.name, content: "Got it. I will review the receipts and update you within the hour.", channelId: nil, recipientId: "agent-2", sentAt: Date().addingTimeInterval(-4500), isRead: false)
            ]
        case "agent-3":
            return [
                TeamChatMessage(id: "tcm-dm-3-1", senderId: "agent-3", senderName: "Grace Adeyemi", content: "Can you review the new admission script? I drafted a first pass.", channelId: nil, recipientId: "agent-1", sentAt: Date().addingTimeInterval(-3200), isRead: true),
                TeamChatMessage(id: "tcm-dm-3-2", senderId: "agent-1", senderName: MockAgentInfo.name, content: "Share it here and I will comment.", channelId: nil, recipientId: "agent-3", sentAt: Date().addingTimeInterval(-3000), isRead: true),
                TeamChatMessage(id: "tcm-dm-3-3", senderId: "agent-3", senderName: "Grace Adeyemi", content: "Posting a shortened version for now. Waiting on final dates from admin.", channelId: nil, recipientId: "agent-1", sentAt: Date().addingTimeInterval(-2700), isRead: false)
            ]
        case "agent-4":
            return [
                TeamChatMessage(id: "tcm-dm-4-1", senderId: "agent-4", senderName: "Daniel Nwosu", content: "FYI: system latency spikes at noon. We might need to stagger broadcast sends.", channelId: nil, recipientId: "agent-1", sentAt: Date().addingTimeInterval(-2600), isRead: true),
                TeamChatMessage(id: "tcm-dm-4-2", senderId: "agent-1", senderName: MockAgentInfo.name, content: "Thanks. Can you share a quick graph or timeslot range?", channelId: nil, recipientId: "agent-4", sentAt: Date().addingTimeInterval(-2400), isRead: true),
                TeamChatMessage(id: "tcm-dm-4-3", senderId: "agent-4", senderName: "Daniel Nwosu", content: "Will do. It is usually 11:45am to 12:30pm.", channelId: nil, recipientId: "agent-1", sentAt: Date().addingTimeInterval(-2200), isRead: false)
            ]
        case "agent-5":
            return [
                TeamChatMessage(id: "tcm-dm-5-1", senderId: "agent-5", senderName: "Chidi Eze", content: "We have three parents asking about scholarship payments today.", channelId: nil, recipientId: "agent-1", sentAt: Date().addingTimeInterval(-4000), isRead: true),
                TeamChatMessage(id: "tcm-dm-5-2", senderId: "agent-1", senderName: MockAgentInfo.name, content: "Please tag them as finance + scholarship and forward to Finance team.", channelId: nil, recipientId: "agent-5", sentAt: Date().addingTimeInterval(-3700), isRead: true),
                TeamChatMessage(id: "tcm-dm-5-3", senderId: "agent-5", senderName: "Chidi Eze", content: "Done. I also added notes about the deadlines they mentioned.", channelId: nil, recipientId: "agent-1", sentAt: Date().addingTimeInterval(-3400), isRead: false)
            ]
        default:
            return []
        }
    }

    static func messagesForChannel(_ channelId: String) -> [TeamChatMessage] {
        switch channelId {
        case "general":
            return [
                TeamChatMessage(id: "tcm-ch-1", senderId: "agent-3", senderName: "Grace Adeyemi", content: "Reminder: team meeting at 2 PM today.", channelId: "general", recipientId: nil, sentAt: Date().addingTimeInterval(-7200), isRead: true),
                TeamChatMessage(id: "tcm-ch-2", senderId: "agent-4", senderName: "Daniel Nwosu", content: "We are seeing an increase in admission queries this week.", channelId: "general", recipientId: nil, sentAt: Date().addingTimeInterval(-6600), isRead: true),
                TeamChatMessage(id: "tcm-ch-3", senderId: "agent-1", senderName: MockAgentInfo.name, content: "I will draft a quick template response by end of day.", channelId: "general", recipientId: nil, sentAt: Date().addingTimeInterval(-6000), isRead: true),
                TeamChatMessage(id: "tcm-ch-4", senderId: "agent-2", senderName: "Michael Obi", content: "Any updates on the payment dispute? Parent is waiting.", channelId: "general", recipientId: nil, sentAt: Date().addingTimeInterval(-5400), isRead: false)
            ]
        case "announcements":
            return [
                TeamChatMessage(id: "tcm-ch-5", senderId: "agent-1", senderName: MockAgentInfo.name, content: "Please note: broadcast approvals now require supervisor sign-off.", channelId: "announcements", recipientId: nil, sentAt: Date().addingTimeInterval(-10800), isRead: true),
                TeamChatMessage(id: "tcm-ch-6", senderId: "agent-3", senderName: "Grace Adeyemi", content: "Updated the knowledge base with resumption dates and term calendar.", channelId: "announcements", recipientId: nil, sentAt: Date().addingTimeInterval(-9000), isRead: true),
                TeamChatMessage(id: "tcm-ch-7", senderId: "agent-4", senderName: "Daniel Nwosu", content: "System maintenance scheduled for Friday 9 PM - 10 PM.", channelId: "announcements", recipientId: nil, sentAt: Date().addingTimeInterval(-7800), isRead: true)
            ]
        case "urgent":
            return [
                TeamChatMessage(id: "tcm-ch-8", senderId: "agent-2", senderName: "Michael Obi", content: "Escalation alert: parent reporting safety issue near school gate.", channelId: "urgent", recipientId: nil, sentAt: Date().addingTimeInterval(-3600), isRead: true),
                TeamChatMessage(id: "tcm-ch-9", senderId: "agent-1", senderName: MockAgentInfo.name, content: "Looping in management and security. Please do not reply publicly.", channelId: "urgent", recipientId: nil, sentAt: Date().addingTimeInterval(-3300), isRead: true),
                TeamChatMessage(id: "tcm-ch-10", senderId: "agent-5", senderName: "Chidi Eze", content: "I have the parent on hold and am collecting details.", channelId: "urgent", recipientId: nil, sentAt: Date().addingTimeInterval(-3000), isRead: false)
            ]
        default:
            return []
        }
    }
}

// MARK: - Team Chat Channel
struct TeamChatChannel: Identifiable, Codable {
    let id: String
    var name: String
    var icon: String
    var unreadCount: Int
    
    static let mockList: [TeamChatChannel] = [
        TeamChatChannel(id: "general", name: "General", icon: "number", unreadCount: 0),
        TeamChatChannel(id: "announcements", name: "Announcements", icon: "megaphone", unreadCount: 1),
        TeamChatChannel(id: "urgent", name: "Urgent Issues", icon: "exclamationmark.triangle", unreadCount: 2)
    ]
}

// MARK: - Broadcast Message
struct BroadcastMessage: Identifiable {
    let id: String
    var title: String
    var content: String
    var recipientFilter: RecipientFilter
    var scheduledAt: Date?
    var sentAt: Date?
    var status: BroadcastStatus
    var recipientCount: Int
    var deliveredCount: Int
    var readCount: Int
    
    enum RecipientFilter: String {
        case all = "All Parents"
        case byClass = "By Class"
        case byGrade = "By Grade"
        case custom = "Custom Selection"
    }
    
    enum BroadcastStatus: String {
        case draft, scheduled, sending, sent, failed
    }

    static func fromAPI(_ api: APIBroadcast) -> BroadcastMessage {
        let status = BroadcastStatus(rawValue: api.status.lowercased()) ?? .draft
        let filter = RecipientFilter.fromAPI(api.recipientFilter)
        return BroadcastMessage(
            id: api.id,
            title: api.title,
            content: api.content,
            recipientFilter: filter,
            scheduledAt: api.scheduledAt,
            sentAt: api.sentAt,
            status: status,
            recipientCount: api.recipientCount,
            deliveredCount: api.deliveredCount,
            readCount: api.readCount
        )
    }
    
    static let mockList: [BroadcastMessage] = [
        BroadcastMessage(id: "bc-1", title: "School Resumption Notice", content: "Dear Parents, this is to remind you that school resumes on January 6th, 2026...", recipientFilter: .all, scheduledAt: nil, sentAt: Date().addingTimeInterval(-86400), status: .sent, recipientCount: 450, deliveredCount: 448, readCount: 320),
        BroadcastMessage(id: "bc-2", title: "Fee Payment Reminder", content: "Kindly note that school fees are due by January 15th...", recipientFilter: .all, scheduledAt: Date().addingTimeInterval(86400), sentAt: nil, status: .scheduled, recipientCount: 450, deliveredCount: 0, readCount: 0),
        BroadcastMessage(id: "bc-3", title: "PTA Meeting", content: "You are invited to the PTA meeting on...", recipientFilter: .all, scheduledAt: nil, sentAt: nil, status: .draft, recipientCount: 450, deliveredCount: 0, readCount: 0)
    ]
}

struct APIBroadcast: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let recipientFilter: String
    let scheduledAt: Date?
    let sentAt: Date?
    let status: String
    let recipientCount: Int
    let deliveredCount: Int
    let readCount: Int
}

extension BroadcastMessage.RecipientFilter {
    static func fromAPI(_ value: String) -> BroadcastMessage.RecipientFilter {
        switch value.lowercased() {
        case "all", "all_parents", "all parents":
            return .all
        case "by_class", "class", "by class":
            return .byClass
        case "by_grade", "grade", "by grade":
            return .byGrade
        default:
            return .custom
        }
    }
}

// MARK: - Knowledge Base
enum KBCategory: String, CaseIterable, Codable {
    case general, finance, admissions, technical, academic

    var label: String {
        rawValue.capitalized
    }

    static func from(_ value: String) -> KBCategory {
        switch value.lowercased() {
        case "finance":
            return .finance
        case "admissions":
            return .admissions
        case "technical":
            return .technical
        case "academic":
            return .academic
        default:
            return .general
        }
    }
}

struct KBArticle: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let category: KBCategory
    let lastUpdated: Date
    let usageCount: Int
    let isActive: Bool

    static func fromAPI(_ api: APIKnowledgeArticle) -> KBArticle {
        KBArticle(
            id: api.id,
            title: api.title,
            content: api.content,
            category: KBCategory.from(api.category),
            lastUpdated: api.lastUpdated,
            usageCount: api.usageCount,
            isActive: api.isActive
        )
    }

    static let mockList: [KBArticle] = [
        KBArticle(id: "1", title: "School Resumption Dates", content: "Classes resume on January 6th, 2026. All students are expected to arrive by 7:30 AM. The first week will focus on orientation and schedule distribution.", category: .general, lastUpdated: Date().addingTimeInterval(-86400), usageCount: 145, isActive: true),
        KBArticle(id: "2", title: "School Hours", content: "School hours are from 8:00 AM to 3:00 PM, Monday through Friday. Extended care is available until 5:30 PM for an additional fee.", category: .general, lastUpdated: Date().addingTimeInterval(-172800), usageCount: 89, isActive: true),
        KBArticle(id: "3", title: "Fee Payment Methods", content: "Fees can be paid via bank transfer, online payment portal, or in person at the bursar's office. Payment plans are available upon request.", category: .finance, lastUpdated: Date().addingTimeInterval(-259200), usageCount: 234, isActive: true),
        KBArticle(id: "4", title: "Admission Requirements", content: "Required documents include birth certificate, previous school records, passport photographs, and completed application form.", category: .admissions, lastUpdated: Date().addingTimeInterval(-345600), usageCount: 178, isActive: true),
        KBArticle(id: "5", title: "App Login Issues", content: "If you're having trouble logging in, try resetting your password using the 'Forgot Password' link. Clear your app cache if issues persist.", category: .technical, lastUpdated: Date().addingTimeInterval(-432000), usageCount: 67, isActive: true),
    ]
}

struct APIKnowledgeArticle: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let category: String
    let lastUpdated: Date
    let usageCount: Int
    let isActive: Bool
    let createdAt: Date?
    let updatedAt: Date?
}

// MARK: - App Notification
struct AppNotification: Identifiable, Codable {
    let id: String
    let type: String
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: Date

    static func fromAPI(_ api: APINotification) -> AppNotification {
        AppNotification(
            id: api.id,
            type: api.type ?? "general",
            title: api.title,
            message: api.message ?? "",
            isRead: api.isRead,
            createdAt: api.createdAt
        )
    }
}

struct APINotification: Identifiable, Codable {
    let id: String
    let type: String?
    let title: String
    let message: String?
    let isRead: Bool
    let createdAt: Date
}

struct APIScheduledMessage: Identifiable, Codable {
    let id: String
    let conversationId: String
    let content: String
    let scheduledFor: Date
    let createdBy: Agent?
    let createdById: String?
    let status: String
    let sentAt: Date?
}

struct ScheduledMessageData: Identifiable, Codable {
    let id: String
    let conversationId: String
    let content: String
    let scheduledFor: Date
    let createdBy: String
}

// MARK: - Agent Queue Item
struct QueueItem: Identifiable {
    let id: String
    var conversationId: String
    var parentName: String
    var preview: String
    var priority: Priority
    var waitingTime: TimeInterval
    var assignedToId: String?
    
    var waitingTimeFormatted: String {
        let minutes = Int(waitingTime / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }

    init(
        id: String,
        conversationId: String,
        parentName: String,
        preview: String,
        priority: Priority,
        waitingTime: TimeInterval,
        assignedToId: String?
    ) {
        self.id = id
        self.conversationId = conversationId
        self.parentName = parentName
        self.preview = preview
        self.priority = priority
        self.waitingTime = waitingTime
        self.assignedToId = assignedToId
    }

    init(conversation: Conversation) {
        id = conversation.id
        conversationId = conversation.id
        parentName = conversation.parent?.name ?? "Unknown Parent"
        preview = conversation.lastMessagePreview ?? "No messages yet"
        priority = conversation.priority
        let anchor = conversation.lastMessageAt ?? conversation.createdAt
        waitingTime = max(0, Date().timeIntervalSince(anchor))
        assignedToId = conversation.assignedAgentId
    }
    
    static let mockQueue: [QueueItem] = [
        QueueItem(id: "q-1", conversationId: "conv-2", parentName: "Parent 02", preview: "Fee payment query", priority: .high, waitingTime: 1800, assignedToId: "agent-1"),
        QueueItem(id: "q-2", conversationId: "conv-3", parentName: "Mrs. Ibrahim", preview: "Payment dispute - URGENT", priority: .urgent, waitingTime: 3600, assignedToId: "agent-1"),
        QueueItem(id: "q-3", conversationId: "conv-6", parentName: "Mr. Okoro", preview: "Missed exam inquiry", priority: .high, waitingTime: 2700, assignedToId: "agent-1"),
        QueueItem(id: "q-4", conversationId: "conv-8", parentName: "Mr. Nnamdi", preview: "Transfer admission", priority: .medium, waitingTime: 4200, assignedToId: nil)  // Unassigned
    ]
    
    static func queueForAgent(_ agentId: String) -> [QueueItem] {
        mockQueue.filter { $0.assignedToId == agentId }
    }
    
    static var unassignedQueue: [QueueItem] {
        mockQueue.filter { $0.assignedToId == nil }
    }
}

// MARK: - Task
struct Task: Identifiable, Codable {
    let id: String
    var title: String
    var description: String?
    var conversationId: String?
    var assignedTo: String? // Agent ID
    var createdBy: String // Agent ID
    var createdByName: String?
    var dueDate: Date?
    var status: TaskStatus
    var priority: Priority
    var createdAt: Date
    var completedAt: Date?
    var tags: [String]?
    
    enum TaskStatus: String, Codable, CaseIterable {
        case todo = "To Do"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
        
        var icon: String {
            switch self {
            case .todo: return "circle"
            case .inProgress: return "circle.hexagongrid.fill"
            case .completed: return "checkmark.circle.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .todo: return "priorityMedium"
            case .inProgress: return "moltPrimary"
            case .completed: return "priorityLow"
            case .cancelled: return "priorityResolved"
            }
        }

        var apiValue: String {
            switch self {
            case .todo: return "todo"
            case .inProgress: return "in_progress"
            case .completed: return "done"
            case .cancelled: return "cancelled"
            }
        }

        static func fromAPI(_ value: String) -> TaskStatus {
            switch value.lowercased() {
            case "todo", "to do": return .todo
            case "in_progress", "in progress": return .inProgress
            case "done", "completed": return .completed
            case "cancelled", "canceled": return .cancelled
            case "blocked": return .inProgress
            default: return .todo
            }
        }

        init(from decoder: Decoder) throws {
            let raw = (try? decoder.singleValueContainer().decode(String.self)) ?? ""
            self = TaskStatus.fromAPI(raw)
        }
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .completed && status != .cancelled
    }
    
    static let mockTasks: [Task] = [
        Task(
            id: "task-1",
            title: "Follow up on payment dispute",
            description: "Mrs. Ibrahim claims double charge, verify with finance team",
            conversationId: "conv-3",
            assignedTo: "agent-1",
            createdBy: "agent-1",
            createdByName: MockAgentInfo.name,
            dueDate: Date().addingTimeInterval(86400),
            status: .inProgress,
            priority: .high,
            createdAt: Date().addingTimeInterval(-7200),
            tags: ["finance", "urgent"]
        ),
        Task(
            id: "task-2",
            title: "Send admission requirements",
            description: "Compile document checklist for mid-term admission",
            conversationId: "conv-7",
            assignedTo: "agent-2",
            createdBy: "agent-1",
            createdByName: MockAgentInfo.name,
            dueDate: Date().addingTimeInterval(172800),
            status: .todo,
            priority: .medium,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        Task(
            id: "task-3",
            title: "Update school hours in KB",
            description: nil,
            conversationId: nil,
            assignedTo: "agent-1",
            createdBy: "agent-3",
            createdByName: "Mike Chen",
            dueDate: Date().addingTimeInterval(-3600),
            status: .todo,
            priority: .low,
            createdAt: Date().addingTimeInterval(-86400)
        ),
        Task(
            id: "task-4",
            title: "Verify exam reschedule policy",
            description: "Check with academic affairs about makeup exam",
            conversationId: "conv-6",
            assignedTo: "agent-1",
            createdBy: "agent-1",
            createdByName: MockAgentInfo.name,
            dueDate: nil,
            status: .completed,
            priority: .medium,
            createdAt: Date().addingTimeInterval(-172800),
            completedAt: Date().addingTimeInterval(-86400)
        )
    ]
}

struct APITask: Decodable {
    let id: String
    let title: String
    let description: String?
    let assignedToId: String?
    let assignedTo: Agent?
    let createdById: String
    let createdBy: Agent?
    let conversationId: String?
    let status: String
    let priority: String
    let dueDate: Date?
    let completedAt: Date?
    let tags: [String]?
    let createdAt: Date
}

extension APITask {
    func toTask() -> Task {
        Task(
            id: id,
            title: title,
            description: description,
            conversationId: conversationId,
            assignedTo: assignedToId,
            createdBy: createdById,
            createdByName: createdBy?.name,
            dueDate: dueDate,
            status: Task.TaskStatus.fromAPI(status),
            priority: Priority(rawValue: priority.lowercased()) ?? .medium,
            createdAt: createdAt,
            completedAt: completedAt,
            tags: tags
        )
    }
}

// MARK: - Conversation Note
struct ConversationNote: Identifiable, Codable {
    let id: String
    var conversationId: String
    var content: String
    var createdBy: String // Agent ID
    var createdByName: String
    var createdAt: Date
    var isPinned: Bool
    var mentions: [String] // Agent IDs mentioned with @
    var editedAt: Date?
    
    static let mockNotes: [ConversationNote] = [
        ConversationNote(
            id: "note-1",
            conversationId: "conv-3",
            content: "Verified with finance - there WAS a double charge. Refund initiated. @agent-2 please follow up tomorrow.",
            createdBy: "agent-1",
            createdByName: MockAgentInfo.name,
            createdAt: Date().addingTimeInterval(-3600),
            isPinned: true,
            mentions: ["agent-2"]
        ),
        ConversationNote(
            id: "note-2",
            conversationId: "conv-3",
            content: "Parent seems frustrated but understanding. Maintain empathetic tone.",
            createdBy: "agent-1",
            createdByName: MockAgentInfo.name,
            createdAt: Date().addingTimeInterval(-7200),
            isPinned: false,
            mentions: []
        ),
        ConversationNote(
            id: "note-3",
            conversationId: "conv-6",
            content: "Academic affairs confirmed no makeup exam policy. Will need to escalate to principal.",
            createdBy: "agent-3",
            createdByName: "Mike Chen",
            createdAt: Date().addingTimeInterval(-1800),
            isPinned: false,
            mentions: []
        )
    ]
}
