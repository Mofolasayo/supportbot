---
description: Configure and work with Moltbot AI assistant
---

# Moltbot AI Integration

Working with the Moltbot AI triage system in Support Bridge.

## How Moltbot Works

```
Parent Message → Moltbot Analyzes → Decision
                                      │
                ┌─────────────────────┴─────────────────────┐
                ▼                                           ▼
        HIGH CONFIDENCE                              LOW CONFIDENCE
        (Simple question)                           (Complex/Sensitive)
                │                                           │
                ▼                                           ▼
        Auto-Reply                                   Escalate to Human
        via WhatsApp                                 + AI Summary
```

## Configuration

Environment variables in `.env`:
```bash
# AI Provider
OPENAI_API_KEY=your-api-key
OPENAI_BASE_URL=https://api.openai.com/v1  # or compatible endpoint
OPENAI_MODEL=gpt-4o-mini

# Moltbot Settings
MOLTBOT_CONFIDENCE_THRESHOLD=0.8  # 80% confidence for auto-reply
```

## Message Categories

| Category | Description | Team |
|----------|-------------|------|
| `general_info` | School hours, location | Customer Support |
| `admissions` | Enrollment, registration | Admissions |
| `finance` | Fees, payments | Finance |
| `academic` | Grades, curriculum | Academic Affairs |
| `technical` | App issues, passwords | Technical Support |
| `complaint` | Dissatisfaction | Management |
| `emergency` | Urgent safety/health | Management |

## Using Moltbot in Code

```go
import "github.com/schoolable/supportbridge/internal/moltbot"

// Initialize
provider := moltbot.NewOpenAIProvider()
bot := moltbot.NewBot(db, provider)

// Process incoming message
result, err := bot.ProcessMessage(ctx, conversation, message)

if result.Action == moltbot.ActionAutoReply {
    // Bot handled it - send result.Reply via WhatsApp
} else {
    // Escalated - conversation updated, note added for agents
    // Optionally route to result.TargetTeam
}
```

## Analytics

Get bot performance stats:
```go
stats, _ := bot.GetBotStats(ctx)
// stats.TotalProcessed - messages analyzed
// stats.AutoReplied - handled by bot
// stats.Escalated - sent to humans
// stats.ByCategory - breakdown by category
```

## Customizing the AI Prompt

Edit the prompt in `backend/internal/moltbot/providers.go`:
- Add school-specific information
- Customize categories for your needs
- Adjust confidence thresholds per category
