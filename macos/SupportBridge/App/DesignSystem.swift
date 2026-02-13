import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Color Palette
extension Color {
    // Primary
    static let moltPrimary = Color(hex: "0066CC")
    static let moltPrimaryLight = Color(hex: "E8F4FD")
    
    // Neutral
    static let moltBackground = Color(hex: "F8F9FA")
    static let moltSurface = Color(hex: "FFFFFF")
    static let moltSurfaceSecondary = Color(hex: "F1F3F5")
    static let moltBorder = Color(hex: "E1E5E9")
    static let moltDivider = Color(hex: "F0F2F5")  // Very subtle divider
    static let moltTextPrimary = Color(hex: "1A1D21")
    static let moltTextSecondary = Color(hex: "6B7280")
    static let moltTextMuted = Color(hex: "9CA3AF")
    
    // Priority Colors
    static let priorityUrgent = Color(hex: "DC2626")
    static let priorityHigh = Color(hex: "F59E0B")
    static let priorityMedium = Color(hex: "3B82F6")
    static let priorityLow = Color(hex: "10B981")
    static let priorityResolved = Color(hex: "6B7280")
    
    // Sender Bubble Colors
    static let bubbleBot = Color(hex: "DBEAFE")     // Light blue for bot
    static let bubbleAgent = Color(hex: "BFDBFE")   // Slightly darker blue for agent/you
    static let bubbleParent = Color(hex: "F3F4F6")  // Gray for parent
    static let bubbleTeam = Color(hex: "E0F2FE")    // Sky blue for team
    
    // Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    static let moltTitleLarge = Font.system(size: 24, weight: .semibold)
    static let moltTitleMedium = Font.system(size: 18, weight: .semibold)
    static let moltTitleSmall = Font.system(size: 16, weight: .medium)
    static let moltBody = Font.system(size: 14, weight: .regular)
    static let moltBodySmall = Font.system(size: 13, weight: .regular)
    static let moltCaption = Font.system(size: 12, weight: .regular)
    static let moltLabel = Font.system(size: 11, weight: .medium)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius
enum CornerRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 10
    static let large: CGFloat = 16
    static let bubble: CGFloat = 18
}

// MARK: - Layout
enum AppLayout {
    static let appHeaderHeight: CGFloat = 72
}

// MARK: - Custom Subtle Dividers (for macOS)
// Standard Divider() ignores .background() on macOS, so we use Rectangle instead

struct SubtleDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.moltDivider)
            .frame(height: 1)
    }
}

struct SubtleVerticalDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.moltDivider)
            .frame(width: 1)
    }
}

// MARK: - Shared Layout Helpers
extension View {
    func appHeaderPadding() -> some View {
        padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
    }

    func appHeaderAligned() -> some View {
        appHeaderPadding()
            .frame(height: AppLayout.appHeaderHeight, alignment: .center)
    }
}

// MARK: - Brand Assets
struct SupportBridgeMark: View {
    var size: CGFloat = 28

    var body: some View {
        if let image = NSImage(named: "SupportBridgeMark") {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.moltPrimaryLight)
                    .frame(width: size, height: size)
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: size * 0.55))
                    .foregroundColor(.moltPrimary)
            }
        }
    }
}

struct SupportBridgeLogo: View {
    var height: CGFloat = 48

    var body: some View {
        if let image = NSImage(named: "SupportBridgeLogo") {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        } else {
            HStack(spacing: Spacing.sm) {
                SupportBridgeMark(size: height * 0.8)
                Text("SupportBridge")
                    .font(.moltTitleLarge)
                    .foregroundColor(.moltTextPrimary)
            }
        }
    }
}
