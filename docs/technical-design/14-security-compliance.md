# Security & Compliance

## Authentication Security

### JWT Security
- **Asymmetric Keys**: RS256/ES256 for token signing
- **Activity-Based Token Lifetime**: 1 hour base, extendable to 8 hours maximum
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
- **Account Deletion**: Automated export and anonymization process
- **Data Retention**: GDPR-compliant tiered retention with anonymization
- **Content Anonymization**: Personal identifiers removed while preserving thread history

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

### GDPR Compliance Features
- **Data Export**: Automated user data export (JSON/CSV formats)
- **Right to Erasure**: Account deletion with content anonymization
- **Data Minimization**: Limited retention periods for personal data
- **Lawful Basis**: Clear legal bases for all data processing
- **User Rights**: Access, rectification, portability, and objection mechanisms
- **Audit Trails**: Immutable logs for all sensitive operations
- **Content Moderation**: AI-first approach with human oversight
- **Anonymization**: Preserve thread history while removing personal identifiers

---

**Related Documentation:**
- [Authentication](./03-authentication.md) - JWT implementation details
- [Business: Data & Policy](../business-requirements/18-data-policy.md) - Privacy and retention policies
- [RBAC & Permissions](./08-rbac-permissions.md) - Access control implementation
