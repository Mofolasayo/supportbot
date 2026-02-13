---
description: Handle WhatsApp webhook events and send messages
---

# WhatsApp Integration

Working with WhatsApp Business API in Support Bridge.

## Architecture

```
Parent (WhatsApp) ──webhook──▶ Backend ──broadcast──▶ Agent Apps
Agent Apps ──REST API──▶ Backend ──Cloud API──▶ Parent (WhatsApp)
```

## Handle Incoming Messages

Webhooks are processed in `backend/internal/whatsapp/client.go`:

1. **Webhook verification** (GET request):
```go
// Verify token matches WHATSAPP_VERIFY_TOKEN env var
if token == os.Getenv("WHATSAPP_VERIFY_TOKEN") {
    return challenge
}
```

2. **Message processing** (POST request):
```go
func (c *Client) HandleWebhook(payload WebhookPayload) error {
    // Extracts messages from payload
    // Creates/finds parent record
    // Creates/updates conversation
    // Stores message
    // Broadcasts to WebSocket clients
}
```

## Send Messages

Use the WhatsApp client to send:

```go
// Text message
resp, err := waClient.SendTextMessage(phoneNumber, "Hello!")

// Template message (for first contact or after 24h)
resp, err := waClient.SendTemplate(phoneNumber, "template_name", "en", []string{"param1"})

// With conversation context
err := waClient.SendMessageAndSave(conversationID, agentID, content)
```

## Webhook Payload Types

| Event | Description |
|-------|-------------|
| `messages` | Incoming message from parent |
| `statuses` | Delivery status update (sent/delivered/read) |

## Configuration

Required environment variables:
```
WHATSAPP_PHONE_ID=your-phone-number-id
WHATSAPP_ACCESS_TOKEN=your-access-token
WHATSAPP_VERIFY_TOKEN=your-webhook-verify-token
```

## Testing Locally

Use ngrok to expose local server for webhook testing:
```bash
ngrok http 8080
```
Then configure webhook URL in Meta Developer Console.
