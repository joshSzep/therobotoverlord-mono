# API Versioning Strategy

## Overview

The Robot Overlord API uses URL-based versioning with semantic version numbers to ensure backward compatibility and smooth evolution of the platform while maintaining client stability.

## Versioning Scheme

### URL Structure
```
/api/v{major}
```

### Version Examples
- `/api/v1` - Initial major version
- `/api/v2` - Major version with breaking changes
- `/api/v3` - Next major version

## Version Types

### Major Versions (v1, v2, v3...)
**All changes are considered major versions:**
- New endpoints and features
- Removal of endpoints or fields
- Changes to response structure
- Authentication method changes
- Parameter requirement changes
- Data type modifications
- New optional parameters
- Enhanced functionality

**Examples:**
- Adding new queue status endpoints
- Changing user ID from integer to UUID
- Removing deprecated endpoints
- Restructuring response objects
- Including additional metadata in responses
- New Overlord chat capabilities

## Implementation Strategy

### Current Version Support
- **Latest Version**: Always fully supported with new features
- **Previous Major**: Supported for 12 months after new major release
- **Legacy Versions**: 6-month deprecation notice before removal

### Version Lifecycle
```
v1 → v2 → v3
 ↓    ↓    ↓
Active Active Active
     ↓    ↓
  Deprecated Active
     ↓    ↓
  Removed Active
```

### Default Version Behavior
- **No version specified**: Routes to latest stable version (currently v1)
- **Invalid version**: Returns 404 with available versions
- **Deprecated version**: Returns deprecation warning in response headers

## API Structure

### Base URL
```
https://api.therobotoverlord.com/api/v1
```

### Version-Specific Routing
```python
# FastAPI router structure
app.include_router(v1_router, prefix="/api/v1")
app.include_router(v2_router, prefix="/api/v2")
app.include_router(v3_router, prefix="/api/v3")
```

### Shared Components
Common functionality shared across versions:
- Authentication middleware
- Rate limiting
- Error handling
- Logging and monitoring
- Database access layer

## Version-Specific Features

### v1 (Initial Release)
- Core forum functionality
- Basic moderation queues
- User authentication
- Topic and post management
- Overlord chat basic features

### v2 (Planned)
- Enhanced queue status endpoints
- Additional user profile fields
- Improved search capabilities
- Extended Overlord chat features
- Mobile-optimized responses
- Advanced AI moderation features

### v3 (Future)
- Real-time collaboration tools
- Enhanced analytics endpoints
- Improved multilingual support
- Performance optimizations

## Client Communication

### Version Headers
```http
# Request headers
Accept: application/json
API-Version: v1

# Response headers
API-Version: v1
API-Deprecated: false
API-Sunset: null
```

### Deprecation Notices
```http
# Deprecated version response
API-Version: v1
API-Deprecated: true
API-Sunset: 2025-06-01
Deprecation: true
Link: </api/v2>; rel="successor-version"
```

### Error Responses
```json
{
  "error": "version_not_found",
  "message": "API version v4 not found",
  "available_versions": ["v1", "v2", "v3"],
  "latest_version": "v3",
  "documentation": "https://docs.therobotoverlord.com/api"
}
```

## Migration Guidelines

### For Clients
1. **Monitor deprecation headers** in API responses
2. **Test against new versions** before migration
3. **Update gradually** - start with non-critical endpoints
4. **Handle version-specific errors** gracefully

### For Development Team
1. **Maintain backward compatibility** within minor versions
2. **Document all changes** in API changelog
3. **Provide migration guides** for major versions
4. **Test cross-version compatibility** thoroughly

## Documentation Strategy

### Version-Specific Documentation
- Each version maintains separate OpenAPI specifications
- Interactive documentation available at `/docs/v{version}`
- Migration guides for major version changes
- Changelog with detailed version history

### Documentation URLs
```
/docs/v1     - v1 documentation
/docs/v2     - v2 documentation
/docs/v3     - v3 documentation
/docs/latest - Latest stable version
```

## Monitoring & Analytics

### Version Usage Tracking
- Track API version usage by endpoint
- Monitor client adoption of new versions
- Identify deprecated version usage patterns
- Alert on unusual version distribution

### Metrics to Track
- Requests per version
- Error rates by version
- Client migration patterns
- Performance differences between versions

## Security Considerations

### Version-Specific Security
- Security patches applied to all supported versions
- Deprecated versions receive critical security fixes only
- Version-specific rate limiting if needed
- Authentication requirements consistent across versions

### Vulnerability Management
- Coordinate security updates across versions
- Maintain security changelog by version
- Provide security migration paths for deprecated versions

## Implementation Examples

### FastAPI Router Setup
```python
from fastapi import APIRouter, Depends
from .v1 import router as v1_router
from .v1_1 import router as v1_1_router
from .v2 import router as v2_router

# Version-specific routers
app.include_router(
    v1_router, 
    prefix="/api/v1",
    tags=["v1"],
    dependencies=[Depends(version_middleware)]
)

app.include_router(
    v2_router, 
    prefix="/api/v2",
    tags=["v2"],
    dependencies=[Depends(version_middleware)]
)
```

### Version Middleware
```python
async def version_middleware(request: Request):
    version = request.url.path.split('/')[2]  # Extract version from path
    
    # Check if version is deprecated
    if version in DEPRECATED_VERSIONS:
        response.headers["API-Deprecated"] = "true"
        response.headers["API-Sunset"] = SUNSET_DATES[version]
    
    # Add version to response headers
    response.headers["API-Version"] = version
    
    return response
```

### Shared Service Layer
```python
class UserService:
    """Shared service used across API versions"""
    
    async def get_user(self, user_id: str, version: str = "v1"):
        user = await self.user_repository.get_by_id(user_id)
        
        # Version-specific response formatting
        if version == "v1":
            return self._format_user_v1(user)
        elif version == "v2":
            return self._format_user_v2(user)
        elif version == "v3":
            return self._format_user_v3(user)
```

## Testing Strategy

### Cross-Version Testing
- Automated tests for each supported version
- Backward compatibility test suite
- Migration testing between versions
- Performance comparison across versions

### Test Categories
- **Unit Tests**: Version-specific business logic
- **Integration Tests**: Cross-version data consistency
- **Contract Tests**: API contract compliance per version
- **Migration Tests**: Data and functionality migration paths

---

**Related Documentation:**
- [API Design](./04-api-design.md) - Core API structure and patterns
- [Authentication](./03-authentication.md) - Authentication across API versions
- [Testing Strategy](./24-testing-strategy.md) - Overall testing approach
