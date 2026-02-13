# Support Bridge - Project Guide

## How This Project Works

### System Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                           PARENT SENDS MESSAGE                          │
│                          (WhatsApp on their phone)                      │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         WHATSAPP CLOUD API                              │
│                    (Meta's servers forward to us)                       │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ Webhook POST
                                     ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         GO BACKEND SERVER                               │
│  ┌─────────────┐   ┌──────────────┐   ┌─────────────────┐             │
│  │  Webhook    │──▶│  Process &   │──▶│  Store in       │             │
│  │  Handler    │   │  Create Conv │   │  PostgreSQL     │             │
│  └─────────────┘   └──────────────┘   └────────┬────────┘             │
│                                                 │                       │
│                                                 ▼                       │
│                                        ┌─────────────────┐             │
│                                        │  Broadcast via  │             │
│                                        │  WebSocket Hub  │             │
│                                        └────────┬────────┘             │
└─────────────────────────────────────────────────┼──────────────────────┘
                                                  │
                    ┌─────────────────────────────┼─────────────────────────────┐
                    │                             │                             │
                    ▼                             ▼                             ▼
          ┌─────────────────┐           ┌─────────────────┐           ┌─────────────────┐
          │   macOS App     │           │    iOS App      │           │  Android App    │
          │   (Agent at     │           │  (Agent on      │           │  (Agent on      │
          │    desk)        │           │   the go)       │           │   the go)       │
          └────────┬────────┘           └────────┬────────┘           └────────┬────────┘
                   │                             │                             │
                   └─────────────────────────────┴─────────────────────────────┘
                                                 │
                                                 │ Agent types reply
                                                 ▼
                                    ┌─────────────────────────┐
                                    │  REST API → Backend →   │
                                    │  WhatsApp API → Parent  │
                                    └─────────────────────────┘
```

## Key Concepts

### 1. Conversations
- Each parent gets a **Conversation** when they first message
- Conversations can be **assigned** to agents
- Status: `open` → `pending` → `resolved` → `closed`

### 2. Messages
- All messages stored in our database
- **Incoming**: Parent → WhatsApp → Webhook → Database → Apps
- **Outgoing**: Agent → API → Database → WhatsApp → Parent

### 3. Real-Time Updates
- WebSocket connection keeps all agent apps synchronized
- When a message arrives, ALL connected agents see it instantly
- No polling required - true push notifications

### 4. Task Management
- Agents can create **Tasks** from conversations
- Tasks can be assigned to team members
- Helps track follow-ups and action items

## Development Workflow

### Adding Features

1. **Backend first**: Models → API → WebSocket events
2. **Then clients**: Update all platforms together
3. **Test end-to-end**: Webhook → Storage → Broadcast → Display

### Available Slash Commands

| Command | Purpose |
|---------|---------|
| `/run-backend` | Start the Go server |
| `/add-endpoint` | Create new API endpoint |
| `/add-model` | Add database model |
| `/add-swiftui-view` | Add iOS/macOS screen |
| `/add-compose-screen` | Add Android screen |
| `/whatsapp-integration` | WhatsApp-related tasks |
| `/websocket-events` | Real-time updates |

## File Locations

| What | Where |
|------|-------|
| API handlers | `backend/internal/api/` |
| Data models | `backend/pkg/models/` |
| WhatsApp client | `backend/internal/whatsapp/` |
| WebSocket hub | `backend/internal/messaging/` |
| macOS views | `macos/SupportBridge/Features/` |
| iOS views | `ios/SupportBridge/Features/` |
| Android screens | `android/app/src/main/java/.../ui/` |
