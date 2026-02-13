---
description: Add a new API endpoint to the Go backend
---

# Add Backend Endpoint

Steps to add a new REST API endpoint to Support Bridge.

## Steps

1. **Create or update handler** in `backend/internal/api/`:
   - For new resource: create `<resource>.go` 
   - For existing resource: add method to existing handler struct

2. **Handler structure** (follow existing pattern):
```go
func (h *ResourceHandler) MethodName(c *gin.Context) {
    // Parse request
    var req RequestStruct
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, errorResponse(err.Error()))
        return
    }
    
    // Business logic with h.db
    
    // Return response
    c.JSON(http.StatusOK, successResponse(data))
}
```

3. **Register route** in `backend/internal/api/routes.go`:
```go
resource := v1.Group("/resource")
{
    resource.GET("", handler.List)
    resource.POST("", handler.Create)
    // etc.
}
```

4. **Update OpenAPI spec** at `shared/api-spec/openapi.yaml`

// turbo
5. **Verify build**:
```bash
cd /Users/mofolasayo-osikoya/supportbot/backend && go build ./...
```

## Key Files
- Handlers: `backend/internal/api/*.go`
- Routes: `backend/internal/api/routes.go`
- Models: `backend/pkg/models/models.go`
- Responses: `backend/internal/api/responses.go` (use successResponse, errorResponse)
