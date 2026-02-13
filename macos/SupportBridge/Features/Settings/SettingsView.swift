import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSection: SettingsSection = .profile
    
    var body: some View {
        HStack(spacing: 0) {
            // Settings Sidebar
            VStack(spacing: 0) {
                Text("Settings")
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appHeaderAligned()
                
                SubtleDivider()
    
                
                ScrollView {
                    VStack(spacing: Spacing.xs) {
                        ForEach(SettingsSection.allCases, id: \.self) { section in
                            SettingsSidebarItem(
                                section: section,
                                isSelected: selectedSection == section
                            ) {
                                selectedSection = section
                            }
                        }
                    }
                    .padding(Spacing.sm)
                }
            }
            .frame(width: 220)
            .background(Color.moltSurface)
            
            SubtleVerticalDivider()
            
            // Settings Content
            ScrollView {
                settingsContent
                    .padding(Spacing.xl)
            }
            .frame(maxWidth: .infinity)
            .background(Color.moltBackground)
        }
    }
    
    @ViewBuilder
    var settingsContent: some View {
        switch selectedSection {
        case .profile:
            ProfileSettingsView()
        case .notifications:
            NotificationSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .team:
            TeamSettingsView()
        case .aiSettings:
            AISettingsView()
        case .integrations:
            IntegrationsSettingsView()
        case .security:
            SecuritySettingsView()
        case .about:
            AboutSettingsView()
        }
    }
}

// MARK: - Settings Section
enum SettingsSection: String, CaseIterable {
    case profile = "Profile"
    case notifications = "Notifications"
    case appearance = "Appearance"
    case team = "Team"
    case aiSettings = "AI Settings"
    case integrations = "Integrations"
    case security = "Security"
    case about = "About"
    
    var icon: String {
        switch self {
        case .profile: return "person.circle"
        case .notifications: return "bell"
        case .appearance: return "paintpalette"
        case .team: return "person.3"
        case .aiSettings: return "cpu"
        case .integrations: return "link"
        case .security: return "lock.shield"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Settings Sidebar Item
struct SettingsSidebarItem: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: section.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
                    .frame(width: 24)
                
                Text(section.rawValue)
                    .font(.moltBody)
                    .foregroundColor(isSelected ? .moltTextPrimary : .moltTextSecondary)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.moltPrimaryLight : Color.clear)
            .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Settings
struct ProfileSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var email = ""
    @State private var status: Agent.AgentStatus = .offline

    private var initials: String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        let first = parts.first?.first.map(String.init) ?? "A"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("Profile")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)
            
            // Avatar Section
            HStack(spacing: Spacing.lg) {
                Circle()
                    .fill(Color.moltPrimary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Button("Change Avatar") { }
                        .buttonStyle(.plain)
                        .foregroundColor(.moltPrimary)
                    Button("Remove") { }
                        .buttonStyle(.plain)
                        .foregroundColor(.moltTextMuted)
                }
            }
            .padding(Spacing.lg)
            .background(Color.moltSurface)
            .cornerRadius(CornerRadius.large)
            
            // Form Fields
            SettingsCard(title: "Personal Information") {
                SettingsTextField(label: "Full Name", text: $name)
                SettingsTextField(label: "Email", text: $email)
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Status")
                        .font(.moltLabel)
                        .foregroundColor(.moltTextSecondary)
                    
                    HStack(spacing: Spacing.sm) {
                        StatusButton(title: "Online", color: .priorityLow, isSelected: status == .online) {
                            status = .online
                        }
                        StatusButton(title: "Away", color: .priorityMedium, isSelected: status == .away) {
                            status = .away
                        }
                        StatusButton(title: "Busy", color: .priorityHigh, isSelected: status == .busy) {
                            status = .busy
                        }
                        StatusButton(title: "Offline", color: .moltTextMuted, isSelected: status == .offline) {
                            status = .offline
                        }
                    }
                }
            }
            
            // Save Button
            HStack {
                Spacer()
                Button(action: {}) {
                    Text("Save Changes")
                        .font(.moltBody)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(Color.moltPrimary)
                        .cornerRadius(CornerRadius.medium)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .onAppear { syncFromAgent() }
        .onChange(of: appState.currentAgent?.id) { _ in
            syncFromAgent()
        }
    }

    private func syncFromAgent() {
        guard let agent = appState.currentAgent else { return }
        name = agent.name
        email = agent.email
        status = agent.status
    }
}

// MARK: - Notification Settings
struct NotificationSettingsView: View {
    @State private var enablePush = true
    @State private var enableSound = true
    @State private var enableBadge = true
    @State private var newMessageNotif = true
    @State private var escalationNotif = true
    @State private var assignmentNotif = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("Notifications")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)
            
            SettingsCard(title: "General") {
                SettingsToggle(label: "Enable Push Notifications", isOn: $enablePush)
                SettingsToggle(label: "Enable Sound", isOn: $enableSound)
                SettingsToggle(label: "Show Badge Count", isOn: $enableBadge)
            }
            
            SettingsCard(title: "Notification Types") {
                SettingsToggle(label: "New Messages", isOn: $newMessageNotif)
                SettingsToggle(label: "Escalations", isOn: $escalationNotif)
                SettingsToggle(label: "Assignments", isOn: $assignmentNotif)
            }
            
            Spacer()
        }
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @State private var theme = "System"
    @State private var fontSize = 14.0
    @State private var compactMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("Appearance")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)
            
            SettingsCard(title: "Theme") {
                HStack(spacing: Spacing.sm) {
                    ThemeButton(title: "Light", icon: "sun.max.fill", isSelected: theme == "Light") {
                        theme = "Light"
                    }
                    ThemeButton(title: "Dark", icon: "moon.fill", isSelected: theme == "Dark") {
                        theme = "Dark"
                    }
                    ThemeButton(title: "System", icon: "laptopcomputer", isSelected: theme == "System") {
                        theme = "System"
                    }
                }
            }
            
            SettingsCard(title: "Display") {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Font Size: \(Int(fontSize))pt")
                        .font(.moltLabel)
                        .foregroundColor(.moltTextSecondary)
                    HStack {
                        Text("12")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                        Slider(value: $fontSize, in: 12...18, step: 1)
                            .accentColor(.moltPrimary)
                        Text("18")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                }
                
                SettingsToggle(label: "Compact Mode", isOn: $compactMode)
            }
            
            Spacer()
        }
    }
}

// MARK: - Theme Button
struct ThemeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
                Text(title)
                    .font(.moltCaption)
                    .foregroundColor(isSelected ? .moltPrimary : .moltTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(isSelected ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? Color.moltPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Button
struct StatusButton: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.moltCaption)
                    .foregroundColor(isSelected ? .moltTextPrimary : .moltTextSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.moltPrimaryLight : Color.moltSurfaceSecondary)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? Color.moltPrimary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Team Settings
struct TeamSettingsView: View {
    @EnvironmentObject var appState: AppState

    private var members: [String] {
        var list = ["Michael Obi", "Grace Adeyemi", "Daniel Nwosu", "Chidi Eze"]
        if let name = appState.currentAgent?.name, !name.isEmpty {
            list.insert(name, at: 0)
        } else {
            list.insert("Agent", at: 0)
        }
        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("Team")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)
            
            SettingsCard(title: "Your Team") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Customer Support")
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                        Text("5 members")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                    Spacer()
                    Text("Member")
                        .font(.moltLabel)
                        .foregroundColor(.moltPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.moltPrimaryLight)
                        .cornerRadius(CornerRadius.small)
                }
            }
            
            SettingsCard(title: "Team Members") {
                ForEach(members, id: \.self) { member in
                    HStack {
                        Circle()
                            .fill(Color.moltSurfaceSecondary)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(member.prefix(1))
                                    .font(.moltCaption)
                                    .foregroundColor(.moltTextSecondary)
                            )
                        Text(member)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                        Spacer()
                        Circle()
                            .fill(Color.priorityLow)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - AI Settings
struct AISettingsView: View {
    @State private var enableMoltbot = true
    @State private var autoReply = true
    @State private var confidenceThreshold = 0.75
    @State private var suggestionsEnabled = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("AI Settings")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)
            
            SettingsCard(title: "SupportBridge AI") {
                SettingsToggle(label: "Enable AI Assistant", isOn: $enableMoltbot)
                SettingsToggle(label: "Auto-Reply to Simple Queries", isOn: $autoReply)
                SettingsToggle(label: "Show AI Suggestions", isOn: $suggestionsEnabled)
            }
            
            SettingsCard(title: "Confidence Threshold") {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Auto-reply when confidence is above \(Int(confidenceThreshold * 100))%")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextSecondary)
                    Slider(value: $confidenceThreshold, in: 0.5...0.95, step: 0.05)
                }
            }
            
            SettingsCard(title: "Categories") {
                ForEach(["General Info", "Finance", "Admissions", "Technical", "Academic"], id: \.self) { category in
                    HStack {
                        Text(category)
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(.switch)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Integrations Settings
struct IntegrationsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("Integrations")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)
            
            SettingsCard(title: "Connected Services") {
                IntegrationRow(name: "WhatsApp Business", status: "Connected", icon: "message.fill", color: .priorityLow)
                IntegrationRow(name: "OpenAI", status: "Connected", icon: "cpu", color: .priorityLow)
            }
            
            SettingsCard(title: "Available Integrations") {
                IntegrationRow(name: "Slack", status: "Not Connected", icon: "number", color: .moltTextMuted)
                IntegrationRow(name: "Email", status: "Not Connected", icon: "envelope", color: .moltTextMuted)
            }
            
            Spacer()
        }
    }
}

struct IntegrationRow: View {
    let name: String
    let status: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(CornerRadius.small)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                Text(status)
                    .font(.moltCaption)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            if status == "Connected" {
                Button("Disconnect") { }
                    .buttonStyle(.plain)
                    .font(.moltCaption)
                    .foregroundColor(.priorityUrgent)
            } else {
                Button("Connect") { }
                    .buttonStyle(.plain)
                    .font(.moltCaption)
                    .foregroundColor(.moltPrimary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Security Settings
struct SecuritySettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("Security")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)
            
            SettingsCard(title: "Password") {
                Button(action: {}) {
                    HStack {
                        Text("Change Password")
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.moltTextMuted)
                    }
                }
                .buttonStyle(.plain)
            }
            
            SettingsCard(title: "Sessions") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Session")
                            .font(.moltBody)
                            .foregroundColor(.moltTextPrimary)
                        Text("MacBook Pro • Safari")
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                    Spacer()
                    Circle()
                        .fill(Color.priorityLow)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.moltCaption)
                        .foregroundColor(.priorityLow)
                }
                
                Button("Sign Out All Other Sessions") { }
                    .buttonStyle(.plain)
                    .font(.moltCaption)
                    .foregroundColor(.priorityUrgent)
            }

            SettingsCard(title: "Account") {
                Button("Sign Out") {
                    appState.signOut()
                }
                .buttonStyle(.plain)
                .font(.moltBody)
                .foregroundColor(.priorityUrgent)
            }
            
            Spacer()
        }
    }
}

// MARK: - About Settings
struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("About")
                .font(.moltTitleMedium)
                .foregroundColor(.moltTextPrimary)
            
            SettingsCard(title: "App Info") {
                AboutRow(label: "Version", value: "1.0.0")
                AboutRow(label: "Build", value: "2026.02.02")
                AboutRow(label: "Platform", value: "macOS")
            }
            
            SettingsCard(title: "Support") {
                Button(action: {}) {
                    HStack {
                        Text("Contact Support")
                            .font(.moltBody)
                            .foregroundColor(.moltPrimary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    HStack {
                        Text("View Documentation")
                            .font(.moltBody)
                            .foregroundColor(.moltPrimary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Logo
            HStack {
                Spacer()
                VStack(spacing: Spacing.sm) {
                    SupportBridgeMark(size: 32)
                    Text("SupportBridge")
                        .font(.moltTitleSmall)
                        .foregroundColor(.moltTextPrimary)
                    Text("© 2026 SupportBridge")
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                Spacer()
            }
            .padding(.top, Spacing.xl)
            
            Spacer()
        }
    }
}

struct AboutRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.moltBody)
                .foregroundColor(.moltTextSecondary)
            Spacer()
            Text(value)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Reusable Components
struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.moltLabel)
                .foregroundColor(.moltTextMuted)
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                content
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.moltSurface)
            .cornerRadius(CornerRadius.large)
        }
    }
}

struct SettingsTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.moltLabel)
                .foregroundColor(.moltTextSecondary)
            
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
                .tint(.moltTextPrimary)
                .padding(Spacing.md)
                .background(Color.moltSurfaceSecondary)
                .cornerRadius(CornerRadius.medium)
        }
    }
}

struct SettingsToggle: View {
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
    }
}
