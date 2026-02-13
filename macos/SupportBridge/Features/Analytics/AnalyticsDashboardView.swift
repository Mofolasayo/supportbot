import SwiftUI

struct AnalyticsDashboardView: View {
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Analytics")
                    .font(.moltTitleMedium)
                    .foregroundColor(.moltTextPrimary)
                
                Spacer()
                
                // Time Range Picker
                HStack(spacing: Spacing.xs) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        TimeRangeButton(
                            label: range.label,
                            isSelected: selectedTimeRange == range
                        ) {
                            selectedTimeRange = range
                        }
                    }
                }
                
                Button(action: {}) {
                    Label("Export", systemImage: "arrow.down.doc")
                        .font(.moltLabel)
                }
                .buttonStyle(.plain)
                .foregroundColor(.moltPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.moltPrimaryLight)
                .cornerRadius(CornerRadius.medium)
            }
            .appHeaderAligned()
            .background(Color.moltSurface)
            
            SubtleDivider()

            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Key Metrics Row
                    HStack(spacing: Spacing.md) {
                        SimpleMetricCard(title: "Total Conversations", value: "1,247", change: "+12%", isPositive: true)
                        SimpleMetricCard(title: "Auto-Resolution", value: "68%", change: "+5%", isPositive: true)
                        SimpleMetricCard(title: "Response Time", value: "2.4 min", change: "-18%", isPositive: true)
                        SimpleMetricCard(title: "Escalations", value: "32%", change: "+3%", isPositive: false)
                    }
                    
                    // Simple Stats Grid
                    HStack(spacing: Spacing.md) {
                        // Volume Trend
                        SimpleChartCard(title: "This Week") {
                            WeeklyVolumeChart()
                        }
                        
                        // Categories
                        SimpleChartCard(title: "Top Categories") {
                            TopCategoriesView()
                        }
                    }
                    
                    // Resolution Overview
                    ResolutionOverviewCard()
                    
                    // Team Performance Section
                    TeamPerformanceSection()
                }
                .padding(Spacing.lg)
            }
            .background(Color.moltBackground)
        }
    }
}

// MARK: - Time Range
enum TimeRange: CaseIterable {
    case today, week, month, quarter
    
    var label: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        }
    }
}

// MARK: - Time Range Button
struct TimeRangeButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.moltLabel)
                .foregroundColor(isSelected ? .white : .moltTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.moltPrimary : Color.clear)
                .cornerRadius(CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Simple Metric Card
struct SimpleMetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.moltCaption)
                .foregroundColor(.moltTextMuted)
            
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(value)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.moltTextPrimary)
                
                Text(change)
                    .font(.moltLabel)
                    .foregroundColor(isPositive ? .priorityLow : .priorityUrgent)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
    }
}

// MARK: - Simple Chart Card
struct SimpleChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.moltLabel)
                .foregroundColor(.moltTextMuted)
            
            content
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
    }
}

// MARK: - Weekly Volume Chart
struct WeeklyVolumeChart: View {
    let data: [(String, Int)] = [
        ("M", 145), ("T", 178), ("W", 165),
        ("T", 198), ("F", 220), ("S", 89), ("S", 67)
    ]
    
    var maxValue: Int { data.map { $0.1 }.max() ?? 1 }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            ForEach(0..<data.count, id: \.self) { index in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.moltPrimary)
                        .frame(height: CGFloat(data[index].1) / CGFloat(maxValue) * 80)
                    
                    Text(data[index].0)
                        .font(.moltCaption)
                        .foregroundColor(.moltTextMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 100)
    }
}

// MARK: - Top Categories View
struct TopCategoriesView: View {
    let categories: [(String, Int)] = [
        ("General Info", 45),
        ("Finance", 28),
        ("Admissions", 18),
        ("Technical", 9)
    ]
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(categories, id: \.0) { category in
                HStack {
                    Text(category.0)
                        .font(.moltBodySmall)
                        .foregroundColor(.moltTextPrimary)
                    
                    Spacer()
                    
                    Text("\(category.1)%")
                        .font(.moltLabel)
                        .foregroundColor(.moltTextMuted)
                }
            }
        }
        .frame(height: 100)
    }
}

// MARK: - Resolution Overview Card
struct ResolutionOverviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Resolution Breakdown")
                .font(.moltLabel)
                .foregroundColor(.moltTextMuted)
            
            HStack(spacing: Spacing.xl) {
                ResolutionItem(label: "Bot Auto-Resolved", value: "68%", color: .priorityLow)
                ResolutionItem(label: "Agent Resolved", value: "24%", color: .moltPrimary)
                ResolutionItem(label: "Team Escalated", value: "8%", color: .priorityMedium)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
    }
}

struct ResolutionItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.moltTitleSmall)
                    .foregroundColor(.moltTextPrimary)
                Text(label)
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
        }
    }
}

// MARK: - Team Performance Section
struct TeamPerformanceSection: View {
    @EnvironmentObject var appState: AppState

    // Mock team member data
    var teamMembers: [TeamMemberStats] {
        let name = appState.currentAgent?.name ?? "Agent"
        let status: TeamMemberStats.MemberStatus
        switch appState.currentAgent?.status ?? .offline {
        case .online: status = .online
        case .away: status = .away
        case .busy: status = .away
        case .offline: status = .offline
        }

        return [
            TeamMemberStats(name: name, conversations: 156, ownershipTaken: 42, escalationsHandled: 8, avgResponseTime: "1.8 min", status: status),
            TeamMemberStats(name: "Michael Obi", conversations: 134, ownershipTaken: 38, escalationsHandled: 12, avgResponseTime: "2.1 min", status: .online),
            TeamMemberStats(name: "Grace Adeyemi", conversations: 98, ownershipTaken: 28, escalationsHandled: 5, avgResponseTime: "2.5 min", status: .away),
            TeamMemberStats(name: "Daniel Nwosu", conversations: 88, ownershipTaken: 22, escalationsHandled: 4, avgResponseTime: "3.0 min", status: .online),
            TeamMemberStats(name: "Chidi Eze", conversations: 67, ownershipTaken: 15, escalationsHandled: 3, avgResponseTime: "2.8 min", status: .offline)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Team Performance This Week")
                    .font(.moltLabel)
                    .foregroundColor(.moltTextMuted)
                
                Spacer()
                
                Text("\(teamMembers.count) members")
                    .font(.moltCaption)
                    .foregroundColor(.moltTextMuted)
            }
            
            // Header Row
            HStack(spacing: 0) {
                Text("Member")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Conversations")
                    .frame(width: 110, alignment: .center)
                Text("Ownership")
                    .frame(width: 100, alignment: .center)
                Text("Escalations")
                    .frame(width: 100, alignment: .center)
                Text("Avg Response")
                    .frame(width: 100, alignment: .center)
            }
            .font(.moltCaption)
            .foregroundColor(.moltTextMuted)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            
            SubtleDivider()

            
            // Member Rows
            ForEach(teamMembers) { member in
                TeamMemberRow(member: member)
                
                if member.id != teamMembers.last?.id {
                    SubtleDivider()
        
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.moltSurface)
        .cornerRadius(CornerRadius.large)
    }
}

struct TeamMemberStats: Identifiable {
    let id = UUID()
    let name: String
    let conversations: Int
    let ownershipTaken: Int
    let escalationsHandled: Int
    let avgResponseTime: String
    let status: MemberStatus
    
    enum MemberStatus {
        case online, away, offline
        
        var color: Color {
            switch self {
            case .online: return .priorityLow
            case .away: return .priorityMedium
            case .offline: return .moltTextMuted
            }
        }
    }
}

struct TeamMemberRow: View {
    let member: TeamMemberStats
    
    var body: some View {
        HStack(spacing: 0) {
            // Member info
            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.moltSurfaceSecondary)
                        .frame(width: 32, height: 32)
                    Text(member.name.prefix(1))
                        .font(.moltLabel)
                        .foregroundColor(.moltTextSecondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.moltBody)
                        .foregroundColor(.moltTextPrimary)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(member.status.color)
                            .frame(width: 6, height: 6)
                        Text(String(describing: member.status).capitalized)
                            .font(.moltCaption)
                            .foregroundColor(.moltTextMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Conversations
            Text("\(member.conversations)")
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
                .frame(width: 110, alignment: .center)
            
            // Ownership Taken
            HStack(spacing: 4) {
                Text("\(member.ownershipTaken)")
                    .font(.moltBody)
                    .foregroundColor(.moltTextPrimary)
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.moltPrimary)
            }
            .frame(width: 100, alignment: .center)
            
            // Escalations Handled
            Text("\(member.escalationsHandled)")
                .font(.moltBody)
                .foregroundColor(.moltTextPrimary)
                .frame(width: 100, alignment: .center)
            
            // Avg Response Time
            Text(member.avgResponseTime)
                .font(.moltBody)
                .foregroundColor(responseTimeColor)
                .frame(width: 100, alignment: .center)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
    }
    
    var responseTimeColor: Color {
        if member.avgResponseTime.contains("1.") { return .priorityLow }
        if member.avgResponseTime.contains("2.") { return .moltTextPrimary }
        return .priorityMedium
    }
}
