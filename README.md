# Support Bridge

A multi-platform customer support application suite for Schoolable that bridges WhatsApp parent communications with the internal support team.

## Project Structure

```
supportbot/
├── backend/           # Go backend server
├── ios/              # iOS application (SwiftUI)
├── android/          # Android application (Jetpack Compose)
├── macos/            # macOS application (SwiftUI)
├── shared/           # Shared specifications (OpenAPI)
└── docs/             # Documentation
```

## Quick Start

### Backend

```bash
cd backend

# Copy environment variables
cp .env.example .env

# Edit .env with your credentials
# - Database connection
# - WhatsApp Business API credentials
# - JWT secret

# Install dependencies
go mod tidy

# Run the server
go run cmd/server/main.go
```

### Prerequisites

- Go 1.21+
- PostgreSQL 15+
- Redis (optional, for caching)
- WhatsApp Business API access

## Features

- **WhatsApp Bridge**: Real-time message sync with WhatsApp Business API
- **Unified Inbox**: All parent conversations in one place
- **Agent Assignment**: Manual or automatic conversation routing
- **Task Management**: Create and track support tasks
- **Real-time Updates**: WebSocket-powered live messaging
- **Cross-Platform**: Native apps for macOS, iOS, and Android

## API Documentation

API specification is available at `shared/api-spec/openapi.yaml`.

Run the server and visit `/api/v1/health` to verify it's running.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Secret key for JWT tokens |
| `WHATSAPP_PHONE_ID` | WhatsApp Business phone number ID |
| `WHATSAPP_ACCESS_TOKEN` | WhatsApp API access token |

## Development

### Backend

```bash
cd backend
go run cmd/server/main.go
```

### Native Apps

- **macOS/iOS**: Open in Xcode and run
- **Android**: Open in Android Studio and run

## License

Proprietary - Schoolable
