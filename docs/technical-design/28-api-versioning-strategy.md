# API Versioning Strategy

## Overview

The Robot Overlord API uses a V1-only evolution strategy where `/api/v1` is the single, continuously evolving API version. The version prefix exists purely for future-proofing in case a complete API redesign is ever needed.

## Versioning Philosophy

### V1 Evolution Approach
- **Single Version**: v1 is the only version that will exist during normal evolution
- **Continuous Evolution**: v1 evolves with backward-compatible changes only
- **Future-Proofing**: Version prefix allows for potential v2 if complete redesign needed
- **No Version Proliferation**: Avoid creating v2, v3, etc. for normal feature additions

### Allowed Changes in V1
**Backward-Compatible Additions:**
- New endpoints
- New optional parameters
- Additional response fields
- Enhanced functionality that doesn't break existing clients
- New features that extend existing capabilities

**Prohibited Changes:**
- Removing endpoints or required fields
- Changing response structure in breaking ways
- Modifying authentication methods
- Changing required parameter types
- Any change that breaks existing client implementations

## Implementation Strategy

### Current Version Support
- **V1**: Continuously supported and evolved
- **Future V2**: Only if complete API redesign becomes necessary
- **No Multiple Versions**: Avoid maintaining multiple API versions simultaneously

### Version Lifecycle
```
v1 (continuous evolution)
 ↓
v1 + new features (backward compatible)
 ↓
v1 + more features (backward compatible)
 ↓
(Only if complete redesign needed: v2)
```

### Default Version Behavior
- **No version specified**: Routes to v1
- **Invalid version**: Returns 404 with available versions
- **V1 specified**: Normal operation

## API Structure

### Base URL
```
https://api.therobotoverlord.com/api/v1
```

### V1-Only Routing
```python
# Single version router with future-proofing
from fastapi import APIRouter, HTTPException

# Main API router
api_router = APIRouter()

# Include all endpoints under v1
app.include_router(api_router, prefix="/api/v1", tags=["v1"])
app.include_router(api_router, prefix="/api", tags=["default"])  # Default to v1

# Version validation middleware
async def version_middleware(request: Request):
    version = extract_version_from_path(request.url.path)
    if version and version != "v1":
        raise HTTPException(
            status_code=404, 
            detail=f"API version {version} not supported. Only v1 is available."
        )
    return "v1"
```

### Shared Components
All functionality uses shared components:
- Authentication middleware
- Rate limiting
- Error handling
- Logging and monitoring
- Database access layer

## V1 Feature Evolution

### Current V1 Features
- Core forum functionality
- Moderation queues with FIFO processing
- JWT-based authentication with activity extension
- Topic and post management
- Overlord chat interface
- Real-time WebSocket updates
- Loyalty scoring system
- Multi-queue architecture

### V1 Evolution Roadmap
**Phase 1 Additions (Backward Compatible):**
- Enhanced queue status endpoints
- Additional user profile fields
- Mobile-optimized response formats
- Extended Overlord chat capabilities

**Phase 2 Additions (Backward Compatible):**
- Advanced search and filtering
- Performance optimizations
- Enhanced analytics endpoints
- Improved multilingual support

**Future Considerations:**
- Only create v2 if fundamental architecture changes are needed
- Maintain backward compatibility within v1 indefinitely

## Client Communication

### Version Headers
```http
# Request headers
Accept: application/json
API-Version: v1

# Response headers
API-Version: v1
API-Deprecated: false
```

### Error Responses
```json
{
  "error": "version_not_supported",
  "message": "API version v2 not supported",
  "available_versions": ["v1"],
  "current_version": "v1",
  "documentation": "https://docs.therobotoverlord.com/api/v1"
}
```

## Development Guidelines

### For Clients
1. **Use v1 endpoints** - the only supported version
2. **Handle new optional fields** gracefully in responses
3. **Test against API changes** in staging environment
4. **Monitor API changelog** for new features

### For Development Team
1. **Maintain backward compatibility** within v1 at all times
2. **Document all changes** in API changelog
3. **Add new features additively** - never remove or break existing functionality
4. **Test backward compatibility** thoroughly before deployment

## Documentation Strategy

### V1 Documentation
- Single OpenAPI specification for v1
- Interactive documentation available at `/docs/v1`
- Comprehensive changelog tracking all v1 evolution
- Feature addition guides for new capabilities

### Documentation URLs
```
/docs/v1     - v1 documentation (primary)
/docs        - Redirects to v1 documentation
```

## Monitoring & Analytics

### V1 Usage Tracking
- Track API endpoint usage patterns
- Monitor new feature adoption
- Identify performance impacts of new features
- Alert on unusual usage patterns

### Metrics to Track
- Requests per endpoint
- Error rates by feature
- New feature adoption rates
- Performance impact of v1 evolution

## Security Considerations

### V1 Security Management
- Security patches applied immediately to v1
- Backward-compatible security enhancements
- Consistent authentication requirements
- Rate limiting applies to all v1 endpoints

### Vulnerability Management
- Immediate security updates for v1
- Security changelog for all v1 changes
- Backward-compatible security improvements only

## Implementation Examples

### FastAPI Router Setup
```python
from fastapi import FastAPI, APIRouter, HTTPException, Request
from .routers import auth, content, queue, overlord

# Main application
app = FastAPI(title="Robot Overlord API", version="1.0")

# Single API router for all endpoints
api_router = APIRouter()

# Include all feature routers
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(content.router, prefix="/content", tags=["content"])
api_router.include_router(queue.router, prefix="/queue", tags=["queue"])
api_router.include_router(overlord.router, prefix="/overlord", tags=["overlord"])

# Mount under v1 and default paths
app.include_router(api_router, prefix="/api/v1")
app.include_router(api_router, prefix="/api")  # Default to v1

# Version validation middleware
@app.middleware("http")
async def version_validation_middleware(request: Request, call_next):
    path_parts = request.url.path.split('/')
    if len(path_parts) > 2 and path_parts[2].startswith('v'):
        version = path_parts[2]
        if version != "v1":
            return JSONResponse(
                status_code=404,
                content={
                    "error": "version_not_supported",
                    "message": f"API version {version} not supported",
                    "available_versions": ["v1"],
                    "current_version": "v1"
                }
            )
    
    response = await call_next(request)
    response.headers["API-Version"] = "v1"
    return response
```

### Service Layer (Version Agnostic)
```python
class UserService:
    """Single service layer - no version-specific formatting needed"""
    
    async def get_user(self, user_id: str):
        """Returns user data in consistent v1 format"""
        user = await self.user_repository.get_by_id(user_id)
        return {
            "id": user.id,
            "username": user.username,
            "role": user.role,
            "loyalty_score": user.loyalty_score,
            "rank": user.rank,
            "created_at": user.created_at.isoformat(),
            # New fields can be added here without breaking existing clients
        }
```

## Testing Strategy

### V1 Evolution Testing
- Automated tests for all v1 endpoints
- Backward compatibility test suite for new features
- Regression testing for existing functionality
- Performance impact testing for v1 changes

### Test Categories
- **Unit Tests**: Business logic for all v1 features
- **Integration Tests**: End-to-end v1 functionality
- **Contract Tests**: API contract compliance for v1
- **Backward Compatibility Tests**: Ensure new features don't break existing clients

---

**Related Documentation:**
- [API Design](./04-api-design.md) - Core API structure and patterns
- [Authentication](./03-authentication.md) - Authentication across API versions
- [Testing Strategy](./24-testing-strategy.md) - Overall testing approach
