---
description: Design guidelines for Moltbot UI across all platforms
---

# Moltbot Design System

Professional UI design guidelines for the AI-powered WhatsApp customer support platform.

## Design Goals

- **Clean** - Minimal visual noise
- **Calm** - Neutral, non-distracting palette
- **Trustworthy** - Enterprise-ready aesthetic
- **Accessible** - Easy for non-technical staff
- **WhatsApp-inspired** - Familiar but NOT a clone

## Target Users

| Role | Needs |
|------|-------|
| Support Agents | Quick access to conversations, AI suggestions |
| Team Members | Category-filtered inbox, internal notes |
| Managers | Analytics, team workload, performance metrics |

---

## Color Palette

```swift
// Primary
static let primary = Color(hex: "0066CC")        // Trust blue
static let primaryLight = Color(hex: "E8F4FD")   // Light blue bg

// Neutral
static let background = Color(hex: "F8F9FA")     // Page background
static let surface = Color(hex: "FFFFFF")        // Cards
static let surfaceSecondary = Color(hex: "F1F3F5") // Secondary surfaces
static let border = Color(hex: "E1E5E9")         // Borders
static let textPrimary = Color(hex: "1A1D21")    // Main text
static let textSecondary = Color(hex: "6B7280")  // Secondary text
static let textMuted = Color(hex: "9CA3AF")      // Muted text

// Priority/Status
static let urgent = Color(hex: "DC2626")         // Red
static let high = Color(hex: "F59E0B")           // Amber
static let medium = Color(hex: "3B82F6")         // Blue
static let low = Color(hex: "10B981")            // Green
static let resolved = Color(hex: "6B7280")       // Gray

// Sender Types
static let botBubble = Color(hex: "EEF2FF")      // Moltbot - light indigo
static let agentBubble = Color(hex: "DCFCE7")    // Agent - light green
static let parentBubble = Color(hex: "F3F4F6")   // Parent - light gray
static let teamBubble = Color(hex: "FEF3C7")     // Team - light amber
```

---

## Typography

```swift
// macOS/iOS System Fonts
static let titleLarge = Font.system(size: 24, weight: .semibold)
static let titleMedium = Font.system(size: 18, weight: .semibold)
static let titleSmall = Font.system(size: 16, weight: .medium)
static let body = Font.system(size: 14, weight: .regular)
static let bodySmall = Font.system(size: 13, weight: .regular)
static let caption = Font.system(size: 12, weight: .regular)
static let label = Font.system(size: 11, weight: .medium)
```

---

## Component Patterns

### Conversation List Item
- Parent name (bold)
- Message preview (1 line, gray)
- Time (right aligned, muted)
- Priority dot (color-coded, left edge)
- Status badge: "Bot" / "Agent" / "Team"
- Unread count badge (if applicable)

### Chat Bubbles
- Rounded corners (16pt)
- Max width 70% of container
- Clear sender label above bubble
- Timestamp below bubble
- Status icons for sent/delivered/read

### AI Panel
- Card-based sections
- Subtle background
- Collapsible sections
- Clear "Edit" and "Send" actions
- Confidence displayed as percentage

### Priority Indicators
- Dot or tag style
- Color + optional text
- Never rely on color alone (add icon/text)

---

## Layout Patterns

### Three-Column (Desktop)
```
[Sidebar 250px] [Conversation List 320px] [Chat + AI Panel flex]
```

### Two-Column (Tablet)
```
[Conversation List 320px] [Chat + AI Panel flex]
```

### Single Column (Mobile)
```
[Full width - navigate between views]
```

---

## UX Principles

1. **One conversation = one owner** at a time
2. **Clear visual indicators** for Bot/Human/Team handling
3. **No hidden actions** - important actions always visible
4. **AI actions clearly labeled** - no deception
5. **Familiar patterns** - use standard macOS conventions

---

## Screen Inventory

| Screen | Purpose |
|--------|---------|
| Login | Authentication + role selection |
| Inbox | Main conversation list with filters |
| Chat | Active conversation with messages |
| AI Panel | Suggestions, intent, escalation |
| Escalation Queue | Tier 2 pending items |
| Team Inbox | Category-filtered view |
| Analytics | Management dashboard |
| Settings | Profile, notifications, preferences |

---

## Do's and Don'ts

✅ **DO**
- Use system fonts
- Maintain consistent spacing (8pt grid)
- Show loading states
- Provide keyboard shortcuts (macOS)
- Use subtle animations

❌ **DON'T**
- Overuse emojis
- Make it look like a chatbot toy
- Hide critical information
- Use bright colors excessively
- Complicate navigation
