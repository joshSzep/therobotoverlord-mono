# Security & Compliance

## Authentication Security

### JWT Security
- **Asymmetric Keys**: RS256/ES256 for token signing
- **Short Access Token Lifetime**: 5 minutes to minimize exposure
- **Refresh Token Rotation**: Prevents token reuse attacks
- **Reuse Detection**: Automatic session revocation on token reuse

### Cookie Security
- **httpOnly**: Prevents XSS access to tokens
- **Secure**: HTTPS-only transmission
- **SameSite=Lax**: CSRF protection while maintaining usability
- **Domain Scoping**: Restricted to `.therobotoverlord.com`

## Data Protection

### Privacy Controls
- **Private Message Audit**: Limited to admins and super admins
- **Graveyard Privacy**: Rejected posts visible only to author and moderators+
- **Account Deletion**: Automated export and deletion process
- **Data Retention**: Indefinite retention with clear ToS disclosure

### Encryption
- **In Transit**: TLS 1.3 for all communications
- **At Rest**: PostgreSQL encryption for sensitive data
- **Key Management**: Render secrets for JWT keys, future KMS migration

## Input Validation & Sanitization

### Content Security
```python
from bleach import clean
from pydantic import validator

class PostSubmission(BaseModel):
    content: str
    
    @validator('content')
    def sanitize_content(cls, v):
        # Remove potentially harmful HTML/scripts
        cleaned = clean(v, tags=[], attributes={}, strip=True)
        
        # Length validation
        if len(cleaned) > 10000:
            raise ValueError("Content too long")
        
        return cleaned
```

### Rate Limiting
- **Submission Limits**: Per-user rate limits on content creation
- **Appeal Limits**: One appeal per 5 minutes per user
- **API Rate Limiting**: Global and per-user API limits

## Audit & Monitoring

### Security Logging
- **Authentication Events**: Login attempts, token refresh, failures
- **Moderation Actions**: All admin/moderator actions logged
- **Data Access**: Private message audits tracked
- **System Events**: Configuration changes, role modifications

### Compliance Features
- **Data Export**: Automated user data export for GDPR compliance
- **Audit Trails**: Immutable logs for all sensitive operations
- **Content Moderation**: AI-first approach with human oversight
- **Terms Enforcement**: Clear ToS with automated enforcement

---

**Related Documentation:**
- [Authentication](./03-authentication.md) - JWT implementation details
- [Business: Data & Policy](../business-requirements/18-data-policy.md) - Privacy and retention policies
- [RBAC & Permissions](./08-rbac-permissions.md) - Access control implementation
