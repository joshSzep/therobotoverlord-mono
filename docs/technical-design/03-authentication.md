# Authentication

## Authentication System Architecture

```mermaid
graph TD
    subgraph "Client Layer"
        A[Web Browser]
        B[Mobile App]
    end
    
    subgraph "Authentication Flow"
        C[Google OAuth 2.0]
        D[JWT Token Service]
        E[Session Management]
    end
    
    subgraph "Token Storage"
        F[Access Token Cookie]
        G[Refresh Token Cookie]
        H[Session Database]
    end
    
    subgraph "API Protection"
        I[Authentication Middleware]
        J[Role-Based Access Control]
        K[Permission Validation]
    end
    
    A --> C
    B --> C
    C --> D
    D --> E
    E --> F
    E --> G
    E --> H
    
    F --> I
    I --> J
    J --> K
    
    style C fill:#ff4757,stroke:#fff,color:#fff
    style D fill:#74b9ff,stroke:#fff,color:#fff
    style I fill:#4ecdc4,stroke:#fff,color:#fff
```

## Token Lifecycle Management

```mermaid
sequenceDiagram
    participant U as User
    participant C as Client
    participant A as Auth Service
    participant G as Google OAuth
    participant DB as Database
    
    U->>C: Login Request
    C->>A: Initiate OAuth
    A->>G: Redirect to Google
    G->>U: Google Login
    U->>G: Provide Credentials
    G->>A: OAuth Callback + Code
    A->>G: Exchange Code for Tokens
    G->>A: User Info + Access Token
    A->>DB: Store/Update User
    A->>A: Generate JWT Tokens
    A->>C: Set Secure Cookies
    C->>U: Login Success
    
    loop Active Session
        U->>C: API Request
        C->>A: Validate Access Token
        A->>A: Check Token Expiry
        alt Token Valid
            A->>A: Extend Token (if activity)
            A->>C: Authorized Response
        else Token Expired
            A->>A: Use Refresh Token
            A->>C: New Access Token
        end
    end
```

## JWT-Based Authentication

### Token Lifetimes
- **Access Token**: 1 hour base lifetime, extendable to 8 hours maximum
- **Refresh Token**: 14 days

### Activity-Based Token Extension Strategy
- Access tokens extend by 30 minutes per user activity
- Maximum token lifetime: 8 hours from initial issue
- Extension triggers: API calls, WebSocket activity, page navigation
- Refresh token rotation on each use
- Secure httpOnly cookies for token storage

## Access Tokens

- **Storage**: httpOnly, Secure cookie (`__Secure-trl_at`)
- **Domain**: `.therobotoverlord.com`
- **Path**: `/`
- **SameSite**: Lax
- **Base Expiration**: 1 hour from issue
- **Activity Extension**: +30 minutes per activity, max 8 hours total
- **Extension Triggers**: API requests, WebSocket messages, page navigation

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
