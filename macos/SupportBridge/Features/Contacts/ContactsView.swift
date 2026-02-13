import SwiftUI

// MARK: - Contacts View
struct ContactsView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedContact: Parent?
    @State private var selectedFilter: ContactFilter = .all

    private var contactsSource: [Parent] {
        if appState.isAuthenticated {
            return appState.parents
        }
        return Parent.mockList
    }
    
    var filteredContacts: [Parent] {
        var result = contactsSource
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .recent:
            result = result.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
            result = Array(result.prefix(5))
        case .starred:
            result = result.filter { $0.isStarred }
        }
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.phoneNumber.contains(searchText) ||
                $0.email?.localizedCaseInsensitiveContains(searchText) ?? false ||
                $0.studentNames?.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return result
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Contact List
            VStack(spacing: 0) {
                // Header
                VStack(spacing: Spacing.md) {
                    HStack {
                        Text("Contacts")
                            .font(.moltTitleMedium)
                            .foregroundColor(.moltTextPrimary)
                        
                        Spacer()
                        
                        Text("\(contactsSource.count) total")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                        
                        AddContactButton()
                    }
                    
                    // Search
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.moltTextMuted)
                        TextField("Search contacts...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.moltBody)
                    }
                    .padding(Spacing.sm)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                    
                    // Filter Pills
                    HStack(spacing: Spacing.sm) {
                        ForEach(ContactFilter.allCases, id: \.self) { filter in
                            ContactFilterPill(
                                label: filter.label,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                        Spacer()
                    }
                }
                .padding(Spacing.lg)
                .background(Color.moltSurface)
                
                SubtleDivider()
                
                // Contact List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredContacts) { contact in
                            ContactRow(
                                contact: contact,
                                isSelected: selectedContact?.id == contact.id
                            ) {
                                selectedContact = contact
                            }
                            
                            SubtleDivider()
                                .padding(.leading, 64)
                        }
                    }
                }
                .background(Color.moltSurface)
            }
            .frame(minWidth: 320, idealWidth: 360, maxWidth: 400)
            
            SubtleVerticalDivider()
            
            // Contact Detail
            if let contact = selectedContact {
                ContactDetailView(contact: contact)
            } else {
                EmptyContactView()
            }
        }
        .background(Color.moltBackground)
        .task {
            await appState.refreshParents()
        }
    }
}

// MARK: - Contact Filter
enum ContactFilter: CaseIterable {
    case all, recent, starred
    
    var label: String {
        switch self {
        case .all: return "All"
        case .recent: return "Recent"
        case .starred: return "Starred"
        }
    }
}

// MARK: - Contact Filter Pill
struct ContactFilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.moltCaption)
                .foregroundColor(isSelected ? .white : .moltTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.moltPrimary : Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.large)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    let contact: Parent
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.moltPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Text(contact.name.prefix(1).uppercased())
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.moltPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.moltTextPrimary)
                    
                    if let students = contact.studentNames, !students.isEmpty {
                        Text("Parent of: \(students.joined(separator: ", "))")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Quick actions
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.moltPrimary)
                    
                    Image(systemName: "phone.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.moltTextMuted)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(isSelected ? Color.moltPrimaryLight : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact Detail View
struct ContactDetailView: View {
    let contact: Parent
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Header Card
                VStack(spacing: Spacing.lg) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.moltPrimary)
                            .frame(width: 80, height: 80)
                        
                        Text(contact.name.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text(contact.name)
                        .font(.moltTitleMedium)
                        .foregroundColor(.moltTextPrimary)
                    
                    // Quick Actions
                    HStack(spacing: Spacing.lg) {
                        ContactActionButton(icon: "message.fill", label: "Message") {}
                        ContactActionButton(icon: "phone.fill", label: "Call") {}
                        ContactActionButton(icon: "envelope.fill", label: "Email") {}
                    }
                }
                .padding(Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(Color.moltSurface)
                .cornerRadius(CornerRadius.large)
                
                // Contact Info Card
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Contact Information")
                        .font(.moltLabel)
                        .foregroundColor(.moltTextMuted)
                    
                    ContactInfoRow(icon: "phone.fill", label: "Phone", value: contact.phoneNumber)
                    
                    if let email = contact.email {
                        ContactInfoRow(icon: "envelope.fill", label: "Email", value: email)
                    }
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.moltSurface)
                .cornerRadius(CornerRadius.large)
                
                // Students Card
                if let students = contact.studentNames, !students.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Enrolled Students")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        ForEach(students, id: \.self) { student in
                            HStack(spacing: Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(Color.priorityLow.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.priorityLow)
                                }
                                
                                Text(student)
                                    .font(.moltBody)
                                    .foregroundColor(.moltTextPrimary)
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("View Profile")
                                        .font(.moltCaption)
                                        .foregroundColor(.moltPrimary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.moltSurface)
                    .cornerRadius(CornerRadius.large)
                }
                
                // Recent Conversations
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text("Recent Conversations")
                            .font(.moltLabel)
                            .foregroundColor(.moltTextMuted)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("View All")
                                .font(.moltCaption)
                                .foregroundColor(.moltPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Mock recent conversation
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.moltTextMuted)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Last conversation 2 days ago")
                                .font(.moltBody)
                                .foregroundColor(.moltTextPrimary)
                            Text("Topic: Fee inquiry")
                                .font(.moltCaption)
                                .foregroundColor(.moltTextSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(Spacing.md)
                    .background(Color.moltSurfaceSecondary)
                    .cornerRadius(CornerRadius.medium)
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.moltSurface)
                .cornerRadius(CornerRadius.large)
                
                Spacer()
            }
            .padding(Spacing.lg)
        }
        .background(Color.moltBackground)
    }
}

// MARK: - Contact Action Button
struct ContactActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(Color.moltPrimaryLight)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.moltPrimary)
                }
                
                Text(label)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contact Info Row
struct ContactInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.moltPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
                Text(value)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundColor(.moltTextMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Empty Contact View
struct EmptyContactView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 56))
                .foregroundColor(.moltTextMuted)
            
            Text("Select a Contact")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextSecondary)
            
            Text("Choose a contact from the list to view details")
                .font(.moltBody)
                .foregroundColor(.moltTextMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.moltBackground)
    }
}
