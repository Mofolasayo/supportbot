---
description: Add a new data model to the backend
---

# Add Data Model

Steps to add a new domain model to the Support Bridge backend.

## Steps

1. **Define the model** in `backend/pkg/models/models.go`:
```go
type NewModel struct {
    BaseModel
    Name        string      `gorm:"size:100;not null" json:"name"`
    Description string      `gorm:"type:text" json:"description,omitempty"`
    Status      StatusEnum  `gorm:"size:20;default:'active'" json:"status"`
    RelatedID   *uuid.UUID  `gorm:"type:uuid" json:"related_id,omitempty"`
    Related     *OtherModel `gorm:"foreignKey:RelatedID" json:"related,omitempty"`
}
```

2. **Define status enums** if needed:
```go
type StatusEnum string

const (
    StatusActive   StatusEnum = "active"
    StatusInactive StatusEnum = "inactive"
)
```

3. **Add to migrations** in `backend/pkg/database/database.go`:
```go
err := db.AutoMigrate(
    // ... existing models
    &models.NewModel{},
)
```

4. **Create handler** following `/add-endpoint` workflow

// turbo
5. **Rebuild and test**:
```bash
cd /Users/mofolasayo-osikoya/supportbot/backend && go build ./...
```

## Field Conventions

| Type | GORM Tag |
|------|----------|
| String (limited) | `gorm:"size:100"` |
| Text (unlimited) | `gorm:"type:text"` |
| UUID foreign key | `gorm:"type:uuid"` |
| Required | `gorm:"not null"` |
| Unique | `gorm:"uniqueIndex"` |
| Default | `gorm:"default:'value'"` |
| Array | `gorm:"type:text[]"` (use StringArray type) |
| JSON | `gorm:"type:jsonb"` (use JSON type) |
