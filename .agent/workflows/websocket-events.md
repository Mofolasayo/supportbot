---
description: Add real-time WebSocket events for live updates
---

# WebSocket Events

Adding real-time functionality to Support Bridge.

## Backend - Broadcasting Events

Use the WebSocket hub in `backend/internal/messaging/hub.go`:

```go
// Broadcast to all connected agents
hub.BroadcastMessage("new_message", messageData)

// Send to specific agent
hub.SendToAgent(agentID, "assignment", assignmentData)
```

## Event Types

| Event | Payload | Trigger |
|-------|---------|---------|
| `new_message` | Message object | New message received |
| `message_status` | {id, status} | Delivery status change |
| `conversation_update` | Conversation object | Assignment, status change |
| `task_update` | Task object | Task created/updated |
| `agent_status` | {agent_id, status} | Agent goes online/offline |

## Client - Connecting

### Swift (iOS/macOS)
```swift
import Starscream

class WebSocketService: WebSocketDelegate {
    var socket: WebSocket!
    
    func connect(token: String) {
        var request = URLRequest(url: URL(string: "ws://api/ws")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        if case .text(let text) = event {
            handleMessage(text)
        }
    }
}
```

### Kotlin (Android)
```kotlin
val client = OkHttpClient()
val request = Request.Builder()
    .url("ws://api/ws")
    .header("Authorization", "Bearer $token")
    .build()

val webSocket = client.newWebSocket(request, object : WebSocketListener() {
    override fun onMessage(ws: WebSocket, text: String) {
        handleMessage(text)
    }
})
```

## Message Format

```json
{
  "type": "new_message",
  "payload": {
    "id": "uuid",
    "conversation_id": "uuid",
    "content": "Hello!",
    "sender_type": "parent"
  }
}
```
