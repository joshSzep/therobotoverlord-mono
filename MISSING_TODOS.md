# Missing Components Analysis - The Robot Overlord

This document outlines the missing database models, tables, API endpoints, and other critical components identified through comprehensive analysis of the current implementation against the business requirements and technical design documentation.

## Missing Database Tables

### RBAC System Tables (Critical Gap)

The Role-Based Access Control system is completely missing from the current schema:

```sql
-- Missing from schema but required by technical design
CREATE TABLE roles (
    pk UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE permissions (
    pk UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_dynamic BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE role_permissions (
    role_pk UUID NOT NULL REFERENCES roles(pk) ON DELETE CASCADE,
    permission_pk UUID NOT NULL REFERENCES permissions(pk) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (role_pk, permission_pk)
);

CREATE TABLE user_permissions (
    user_pk UUID NOT NULL REFERENCES users(pk) ON DELETE CASCADE,
    permission_pk UUID NOT NULL REFERENCES permissions(pk) ON DELETE CASCADE,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    granted_by_event VARCHAR(50),
    granted_by_user_pk UUID REFERENCES users(pk),
    is_active BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (user_pk, permission_pk)
);
```

## Missing Database Models (Pydantic)

### Badge Models
```python
from datetime import datetime
from uuid import UUID
from therobotoverlord_api.database.models.base import BaseDBModel

class Badge(BaseDBModel):
    name: str
    description: str
    image_url: str

class BadgeCreate(BaseModel):
    name: str
    description: str
    image_url: str

class UserBadge(BaseDBModel):
    user_pk: UUID
    badge_pk: UUID
    awarded_at: datetime
    awarded_for_post_pk: UUID | None = None

class UserBadgeCreate(BaseModel):
    user_pk: UUID
    badge_pk: UUID
    awarded_for_post_pk: UUID | None = None
```

### Flag Models
```python
from enum import Enum

class FlagStatus(str, Enum):
    PENDING = "pending"
    REVIEWED = "reviewed"
    DISMISSED = "dismissed"
    UPHELD = "upheld"

class Flag(BaseDBModel):
    post_pk: UUID | None = None
    topic_pk: UUID | None = None
    flagger_pk: UUID
    reason: str
    status: FlagStatus = FlagStatus.PENDING
    reviewed_by_pk: UUID | None = None
    reviewed_at: datetime | None = None
    review_notes: str | None = None

class FlagCreate(BaseModel):
    post_pk: UUID | None = None
    topic_pk: UUID | None = None
    reason: str

class FlagUpdate(BaseModel):
    status: FlagStatus
    review_notes: str | None = None
```

### Sanction Models
```python
class SanctionType(str, Enum):
    WARNING = "warning"
    TEMPORARY_BAN = "temporary_ban"
    PERMANENT_BAN = "permanent_ban"
    POST_RESTRICTION = "post_restriction"
    TOPIC_RESTRICTION = "topic_restriction"

class Sanction(BaseDBModel):
    user_pk: UUID
    type: SanctionType
    applied_by_pk: UUID
    applied_at: datetime
    expires_at: datetime | None = None
    reason: str
    is_active: bool = True

class SanctionCreate(BaseModel):
    user_pk: UUID
    type: SanctionType
    expires_at: datetime | None = None
    reason: str

class SanctionUpdate(BaseModel):
    is_active: bool
    reason: str | None = None
```

### Tag Models
```python
class Tag(BaseDBModel):
    name: str

class TagCreate(BaseModel):
    name: str

class TopicTag(BaseDBModel):
    topic_pk: UUID
    tag_pk: UUID
    assigned_by_pk: UUID
    assigned_at: datetime

class TopicTagCreate(BaseModel):
    topic_pk: UUID
    tag_pk: UUID
```

### Session Models
```python
class UserSession(BaseDBModel):
    session_id: str
    user_pk: UUID
    refresh_token_hash: str
    expires_at: datetime
    last_used_at: datetime
    last_used_ip: str | None = None
    last_used_user_agent: str | None = None
    is_revoked: bool = False
    reuse_detected: bool = False

class UserSessionCreate(BaseModel):
    session_id: str
    user_pk: UUID
    refresh_token_hash: str
    expires_at: datetime
    last_used_ip: str | None = None
    last_used_user_agent: str | None = None
```

### RBAC Models
```python
class Role(BaseDBModel):
    name: str
    description: str | None = None

class RoleCreate(BaseModel):
    name: str
    description: str | None = None

class Permission(BaseDBModel):
    name: str
    description: str | None = None
    is_dynamic: bool = False

class PermissionCreate(BaseModel):
    name: str
    description: str | None = None
    is_dynamic: bool = False

class UserPermission(BaseDBModel):
    user_pk: UUID
    permission_pk: UUID
    granted_at: datetime
    expires_at: datetime | None = None
    granted_by_event: str | None = None
    granted_by_user_pk: UUID | None = None
    is_active: bool = True
```

## Missing API Endpoints

### User Management & Profiles
```python
# Missing: /api/v1/users/ router
@router.get("/users/{user_id}/profile")          # Public user profiles
@router.get("/users/{user_id}/graveyard")        # User's rejected posts (private)
@router.get("/users/registry")                   # Public citizen registry
@router.put("/users/{user_id}")                  # Update user profile
@router.get("/users/{user_id}/badges")           # User's badges
@router.get("/users/{user_id}/activity")         # User's activity feed
@router.delete("/users/{user_id}")               # Delete user account (GDPR)
```

### Content Flagging & Reporting
```python
# Missing: /api/v1/flags/ router
@router.post("/flags")                           # Flag content for review
@router.get("/flags")                            # List flags (moderators only)
@router.put("/flags/{flag_id}")                  # Review flag (moderators only)
@router.get("/flags/{flag_id}")                  # Get flag details
@router.delete("/flags/{flag_id}")               # Delete flag
```

### Sanctions & Moderation
```python
# Missing: /api/v1/sanctions/ router
@router.post("/sanctions")                       # Apply sanction (moderators only)
@router.get("/sanctions")                        # List sanctions (moderators only)
@router.put("/sanctions/{sanction_id}")          # Update/remove sanction
@router.get("/users/{user_id}/sanctions")        # User's active sanctions
@router.delete("/sanctions/{sanction_id}")       # Remove sanction
```

### Tags & Content Organization
```python
# Missing: /api/v1/tags/ router
@router.get("/tags")                             # List all tags
@router.post("/tags")                            # Create tag (admins only)
@router.get("/tags/{tag_name}/topics")           # Topics by tag
@router.put("/topics/{topic_id}/tags")           # Assign/update topic tags
@router.delete("/tags/{tag_id}")                 # Delete tag (admins only)
```

### Badges & Achievements
```python
# Missing: /api/v1/badges/ router
@router.get("/badges")                           # List all badges
@router.post("/badges")                          # Create badge (admins only)
@router.get("/users/{user_id}/badges")           # User's badges
@router.post("/users/{user_id}/badges/{badge_id}")  # Award badge
@router.delete("/badges/{badge_id}")             # Delete badge (admins only)
```

### WebSocket Endpoints
```python
# Missing: Real-time endpoints
@app.websocket("/api/v1/queue/stream")           # Queue visualization updates
@app.websocket("/api/v1/overlord/chat")          # Overlord chat interface
@app.websocket("/api/v1/notifications")          # Real-time notifications
@app.websocket("/api/v1/moderation/live")        # Live moderation updates
```

### Admin & Moderation Dashboard
```python
# Missing: /api/v1/admin/ router
@router.get("/admin/dashboard")                  # Admin dashboard stats
@router.get("/admin/moderation-queue")           # Pending moderation items
@router.get("/admin/users")                      # User management
@router.put("/admin/users/{user_id}/role")       # Change user role
@router.get("/admin/system-health")              # System monitoring
@router.get("/admin/analytics")                  # Platform analytics
@router.post("/admin/announcements")             # System announcements
```

### RBAC Management
```python
# Missing: /api/v1/rbac/ router
@router.get("/rbac/roles")                       # List roles
@router.post("/rbac/roles")                      # Create role
@router.get("/rbac/permissions")                 # List permissions
@router.post("/rbac/permissions")                # Create permission
@router.put("/users/{user_id}/roles")            # Assign user roles
@router.get("/users/{user_id}/permissions")      # Get user permissions
```

## Missing Repository Files

The following repository files need to be created:

- `badge.py` - Badge and user badge operations
- `flag.py` - Content flagging operations
- `sanction.py` - User sanction management
- `tag.py` - Tag and topic tag operations
- `user_session.py` - Session management operations
- `rbac.py` - Role and permission management

## Missing Service Files

The following service files need to be created:

- `badge_service.py` - Badge awarding logic and validation
- `flag_service.py` - Content flagging and review workflows
- `sanction_service.py` - Sanction application and enforcement
- `tag_service.py` - Tag management and assignment
- `rbac_service.py` - Permission resolution and role management
- `websocket_service.py` - Real-time connection management
- `overlord_chat_service.py` - AI chat interface
- `notification_service.py` - Real-time notification delivery

## Missing Worker Files

The following background worker files need to be created:

- `tos_screening_worker.py` - ToS violation detection using AI
- `overlord_chat_worker.py` - Generate Overlord chat responses
- `notification_worker.py` - Process and send real-time notifications
- `badge_award_worker.py` - Automatic badge awarding based on events
- `sanction_enforcement_worker.py` - Apply and enforce sanctions
- `content_moderation_worker.py` - Enhanced AI content moderation

## Missing Database Migrations

The following migrations need to be created:

- `006_add_rbac_system.sql` - Create RBAC tables and seed data
- `007_add_badge_system.sql` - Create badge and user_badge tables
- `008_add_flag_system.sql` - Create flags table
- `009_add_sanction_system.sql` - Create sanctions table
- `010_add_tag_system.sql` - Create tags and topic_tags tables

## Priority Implementation Order

### Phase 1: Critical Foundation (High Priority)
1. **RBAC System** - Essential for security and permissions
2. **User Management API** - Core user operations and profiles
3. **Content Flagging** - Community moderation capabilities
4. **Session Management** - Complete authentication system

### Phase 2: Core Features (Medium Priority)
1. **Badges System** - Gamification and achievements
2. **Tags System** - Content organization
3. **Sanctions System** - Moderation enforcement
4. **WebSocket Infrastructure** - Real-time updates

### Phase 3: Advanced Features (Lower Priority)
1. **Admin Dashboard** - Administrative interface
2. **Advanced Moderation** - Enhanced AI moderation
3. **Analytics & Monitoring** - System observability
4. **Performance Optimization** - Scalability improvements

## Implementation Notes

- All new models should follow the existing patterns in `therobotoverlord_api.database.models.base`
- API endpoints should include proper authentication, authorization, and validation
- Repository classes should extend the base repository pattern
- Services should handle business logic and coordinate between repositories
- Workers should be implemented using the existing Arq framework
- All endpoints should include proper OpenAPI documentation
- Consider rate limiting for user-facing endpoints
- Implement proper error handling and logging throughout

## Estimated Development Effort

- **Phase 1**: ~3-4 weeks (40-50 hours)
- **Phase 2**: ~2-3 weeks (25-35 hours)  
- **Phase 3**: ~2-3 weeks (25-35 hours)

**Total Estimated Effort**: 8-10 weeks (90-120 hours)

This analysis provides a comprehensive roadmap for completing The Robot Overlord implementation according to the specified requirements and technical design.
