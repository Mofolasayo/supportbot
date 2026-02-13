# Support Bridge App Flow (Plain English)

## Basic flow (how the app is meant to work)
- Parents message the school on WhatsApp.
- The backend receives the message, stores it, and notifies agents in real time.
- Moltbot reviews the message:
  - If it is simple, it can auto-reply.
  - If it is complex, it escalates to a human or team.
- Agents use the macOS app to:
  - See new conversations,
  - Take ownership,
  - Reply,
  - Escalate,
  - Track outcomes and analytics.

## Features in the macOS app (UI exists today)
- Login: UI only (mocked login).
- Inbox + Chat: Conversation list, message thread, send text, AI panel, quick templates.
- Queue: Unassigned vs assigned queue, take ownership.
- Escalations: Escalation list and details.
- Team Inbox: Team-assigned conversations.
- Team Chat: Channels + DMs (mock data).
- Analytics: Dashboard charts and metrics (mock data).
- Broadcasts: Create and view bulk messages (mock data).
- Knowledge Base: Articles list + editor (mock data).
- Settings: Profile, notifications, AI, integrations, security (mock data).

## Backend implemented (real APIs)
- Auth: login/register/refresh/logout.
- Profile: GET /me, PUT /me.
- Conversations: list/get/create/update/delete + assign.
- Messages: get, update status, send in conversation.
- Media upload stub: POST /conversations/:id/messages/media (stores locally for now).
- Agents/Teams/Tasks/Tickets/Parents/Canned Responses/Templates: CRUD.
- Escalations: create/list/get/update + accept/complete.
- Analytics: dashboard + agent performance.
- Moltbot stats + AI analysis: admin/supervisor endpoints.
- WebSocket: real-time events.
- WhatsApp webhook: verified, receives messages.

## Backend still needed
- Queue endpoints (assigned/unassigned, take ownership).
- AI panel endpoints (per-conversation AI analysis, refresh, toggle).
- Broadcast endpoints (create/schedule/send + metrics).
- Knowledge Base endpoints (articles + categories).
- Team chat endpoints (channels, DMs).
- Settings & integrations endpoints (notification prefs, AI toggles, integration status).
- Media storage (real storage like S3 instead of temp).
- Final Moltbot contract (exact request/response schema once provided).

## macOS app: what is still mocked
Almost everything is mocked in the macOS app today. No networking layer exists yet.
The UI is ready; the backend is now catching up so it can be wired later.
