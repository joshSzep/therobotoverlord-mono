# RBAC & Permissions System

## RBAC System Tables

### Roles Table (Static Roles)

```sql
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE, -- 'citizen', 'moderator', 'admin', 'superadmin'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Permissions Table (Granular Capabilities)

```sql
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE, -- 'create_topics', 'moderate_posts', 'view_graveyard', etc.
    description TEXT,
    is_dynamic BOOLEAN DEFAULT FALSE, -- true for loyalty-based permissions like 'create_topics'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Role Permissions (Static Assignments)

```sql
CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);
```

### User Permissions (Dynamic Overrides and Loyalty-Based Grants)

```sql
CREATE TABLE user_permissions (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE, -- for temporary permissions
    granted_by_event VARCHAR(50), -- 'loyalty_threshold', 'admin_grant', 'sanction_removal', etc.
    granted_by_user_id UUID REFERENCES users(id), -- admin who granted permission
    is_active BOOLEAN DEFAULT TRUE,
    
    PRIMARY KEY (user_id, permission_id),
    INDEX idx_user_active (user_id, is_active),
    INDEX idx_expires (expires_at)
);
```

## Permission Categories

### Static Role-Based Permissions
- `view_content` - Browse topics and posts
- `create_posts` - Submit posts and replies
- `send_private_messages` - Send direct messages
- `appeal_rejections` - Appeal rejected content
- `flag_content` - Report content for review
- `view_own_graveyard` - View own rejected posts

### Moderator Permissions
- `view_rejected_posts` - See all rejected content
- `apply_sanctions` - Issue posting restrictions
- `adjudicate_appeals` - Review appeals
- `moderate_flags` - Handle flagged content
- `content_preview` - See content previews in queues

### Admin Permissions
- `view_private_messages` - Audit private communications
- `override_tags` - Edit Overlord-assigned tags
- `escalate_sanctions` - Modify existing sanctions
- `admin_dashboard` - Access administrative interface

### Super Admin Permissions
- `change_user_roles` - Promote/demote users
- `delete_accounts` - Remove user accounts
- `system_configuration` - Modify platform settings

### Dynamic Loyalty-Based Permissions
- `create_topics` - Create new debate topics (top 10% loyalty)
- `priority_moderation` - Faster queue processing (high loyalty)
- `extended_appeals` - Additional appeal attempts (high loyalty)

## Permission Resolution Logic

```python
class PermissionService:
    async def user_has_permission(self, user_id: str, permission: str) -> bool:
        # Check user-specific permissions first (overrides)
        user_perm = await self.get_user_permission(user_id, permission)
        if user_perm and user_perm.is_active:
            if not user_perm.expires_at or user_perm.expires_at > datetime.now():
                return True
        
        # Check role-based permissions
        user_role = await self.get_user_role(user_id)
        role_perms = await self.get_role_permissions(user_role)
        
        return permission in role_perms
    
    async def update_dynamic_permissions(self, user_id: str):
        """Update loyalty-based permissions based on current score"""
        loyalty_score = await self.loyalty_service.get_loyalty_score(user_id)
        
        # Topic creation threshold (top 10%)
        if await self.is_in_top_percentile(user_id, 0.1):
            await self.grant_permission(user_id, 'create_topics', 'loyalty_threshold')
        else:
            await self.revoke_permission(user_id, 'create_topics')
```

---

**Related Documentation:**
- [Business: Roles & Capabilities](../business-requirements/02-roles-capabilities.md) - Role definitions and capabilities
- [Authentication](./03-authentication.md) - JWT claims and permissions
- [Loyalty Scoring System](./09-loyalty-scoring.md) - Dynamic permission triggers
