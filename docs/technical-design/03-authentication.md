# Authentication and Authorization

## Model

**JWT-based auth** with asymmetric signing keys (RS256/ES256)

## Access Tokens

- **Lifetime**: 15 minutes (optimized for user experience)
- **Storage**: httpOnly, Secure cookie (`__Secure-trl_at`)
- **Domain**: `.therobotoverlord.com`
- **Path**: `/`
- **SameSite**: Lax
- **Expiration**: matches 15 minutes
- **Activity Extension**: Automatically refreshed on user activity within 5 minutes of expiry

## Refresh Tokens

- **Lifetime**: 14 days
- **Storage**: httpOnly, Secure cookie (`__Secure-trl_rt`)
- **Domain**: `.therobotoverlord.com`
- **Path**: `/`
- **SameSite**: Lax
- **Rotation**: Rotated on every refresh, reuse detection enabled
- **Persistence**: Stored in PostgreSQL with device metadata (session_id, rotated_at, last_used_ip, last_used_user_agent, revoked, reuse_detected)

## JWT Claims

### Standard Claims
`iss`, `aud`, `iat`, `exp`, `nbf`

### Custom Claims
- `sub`: user UUID
- `role`: citizen, moderator, admin, superadmin
- `sid`: stable session id per device
- `authz_ver`: bumped on role/ban changes
- `permissions`: array of permission names (e.g., ["create_topics", "moderate_posts"])
- `scopes`: array (reserved for future use)

**No email in tokens** (lookup via `sub` when needed)

## Key Management

- Start with manual asymmetric keypair in Render secrets
- API exposes JWKS endpoint with `kid`
- Design allows future migration to KMS without breaking validation

## Login

- Direct Google OAuth2 integration
- Anyone with a Google account may register/login
- Require `email_verified=true`

---

**Related Documentation:**
- [Business: Authentication & Onboarding](../business-requirements/05-auth-onboarding.md) - User experience flow
- [RBAC & Permissions](./08-rbac-permissions.md) - Permission system details
- [API Design](./04-api-design.md) - Authentication endpoints
