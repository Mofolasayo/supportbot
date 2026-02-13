---
description: Run the Support Bridge backend server
---

# Run Backend

Start the Go backend server for local development.

## Prerequisites
- PostgreSQL running locally (or configure DATABASE_URL)
- Environment variables configured in `backend/.env`

## Steps

1. Navigate to the backend directory:
```bash
cd /Users/mofolasayo-osikoya/supportbot/backend
```

2. Ensure dependencies are installed:
```bash
go mod tidy
```

// turbo
3. Run the server:
```bash
go run cmd/server/main.go
```

4. Verify the server is running:
```bash
curl http://localhost:8080/api/v1/health
```

Expected response:
```json
{"status":"healthy","service":"support-bridge"}
```

## Environment Variables Required

Copy `.env.example` to `.env` and configure:
- `DATABASE_URL` or individual DB_* variables
- `JWT_SECRET` for authentication
- `WHATSAPP_*` for WhatsApp integration (optional for local dev)
