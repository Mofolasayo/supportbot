# Support Bridge - Complete System Flow

## The Full Picture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PARENT                                                                      │
│  Sends WhatsApp message                                                      │
└────────────────────────────────────────────┬────────────────────────────────┘
                                             │
                                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  WHATSAPP BUSINESS API                                                       │
│  Forwards message via webhook                                                │
└────────────────────────────────────────────┬────────────────────────────────┘
                                             │
                                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  SUPPORT BRIDGE BACKEND                                                      │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  1. WEBHOOK HANDLER                                                    │  │
│  │     • Receives message                                                 │  │
│  │     • Creates/finds parent record                                      │  │
│  │     • Creates/updates conversation                                     │  │
│  │     • Stores message in database                                       │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                      │                                       │
│                                      ▼                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  2. MOLTBOT AI TRIAGE                                                  │  │
│  │     • Reads message + conversation history                             │  │
│  │     • Analyzes with AI (category, sentiment, confidence)               │  │
│  │     • Stores analysis in database                                      │  │
│  │     • Makes decision: auto-reply OR escalate                           │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                            │                            │                    │
│              ┌─────────────┘                            └─────────────┐      │
│              ▼                                                        ▼      │
│  ┌──────────────────────┐                            ┌──────────────────────┐│
│  │ CONFIDENCE >= 80%    │                            │ CONFIDENCE < 80%     ││
│  │ Simple question      │                            │ Complex/Sensitive    ││
│  │                      │                            │                      ││
│  │ → Generate reply     │                            │ → Create AI summary  ││
│  │ → Send via WhatsApp  │                            │ → Tag & prioritize   ││
│  │ → Track as resolved  │                            │ → Route to team      ││
│  │                      │                            │ → Alert agents       ││
│  └──────────────────────┘                            └──────────────────────┘│
│              │                                                        │      │
│              │                                                        ▼      │
│              │                            ┌──────────────────────────────────┐
│              │                            │  3. HUMAN AGENT DASHBOARD       │
│              │                            │     • Sees new conversation     │
│              │                            │     • Reads Moltbot's summary   │
│              │                            │     • Responds or forwards      │
│              │                            └──────────────────────────────────┘
│              │                                                        │      │
│              │                            ┌───────────────────────────┘      │
│              │                            ▼                                  │
│              │                 ┌─────────────────────────┐                   │
│              │                 │  4. SPECIALIZED TEAMS   │                   │
│              │                 │  • Finance              │                   │
│              │                 │  • Admissions           │                   │
│              │                 │  • Academic Affairs     │                   │
│              │                 │  • Technical Support    │                   │
│              │                 │  • Management           │                   │
│              │                 └─────────────────────────┘                   │
│              │                            │                                  │
│              └────────────────────────────┼──────────────────────────────────┤
│                                           │                                  │
│                                           ▼                                  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  5. ANALYTICS ENGINE                                                   │  │
│  │     • Response times                                                   │  │
│  │     • Resolution times                                                 │  │
│  │     • Bot efficiency (auto-reply %)                                    │  │
│  │     • Common issues by category                                        │  │
│  │     • Agent performance                                                │  │
│  │     • Team workload                                                    │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                             │
                                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  MANAGEMENT VISIBILITY                                                       │
│  Full dashboard with metrics, trends, and insights                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Message Categories

| Category | Example Questions | Handled By | Auto-Reply? |
|----------|-------------------|------------|-------------|
| `general_info` | School hours, address, holidays | Moltbot/Support | ✅ Usually |
| `admissions` | How to enroll, requirements | Admissions | ⚠️ Sometimes |
| `finance` | Fee structure, payment issues | Finance | ❌ Escalate |
| `academic` | Grades, results, curriculum | Academic | ❌ Escalate |
| `technical` | App problems, login issues | Tech Support | ⚠️ Sometimes |
| `complaint` | Dissatisfaction, issues | Management | ❌ Always escalate |
| `emergency` | Safety, health concerns | Management | ❌ Immediate escalate |

## Key Metrics Tracked

- **Response Time**: How fast agents reply
- **Resolution Time**: Time to close conversation  
- **Bot Efficiency**: % of queries handled automatically
- **Category Breakdown**: What parents ask about most
- **Agent Performance**: Per-agent metrics
- **Escalation Patterns**: What gets escalated and why
