# Roles and Capabilities

## Role Hierarchy Diagram

```mermaid
graph TD
    A[Super Admin] --> B[Admin]
    B --> C[Moderator]
    C --> D[Citizen]
    E[Anonymous Visitor] --> D
    
    A --> F[Full Authority<br/>• Promote/demote roles<br/>• Delete accounts<br/>• Review private messages<br/>• Adjudicate appeals<br/>• Full content visibility]
    
    B --> G[Administrative Powers<br/>• Adjudicate appeals<br/>• View rejected posts<br/>• Review private messages<br/>• Apply sanctions<br/>• Cannot change roles]
    
    C --> H[Anti-spam Role<br/>• View rejected posts<br/>• Apply sanctions<br/>• Cannot view private messages<br/>• Cannot change roles]
    
    D --> I[Debate Participation<br/>• Create posts/topics*<br/>• Send private messages<br/>• Appeal rejections<br/>• Flag content]
    
    E --> J[Browse Only<br/>• View all public content<br/>• Must authenticate to post]
    
    style A fill:#ff4757,stroke:#fff,color:#fff
    style B fill:#ff6b6b,stroke:#fff,color:#fff
    style C fill:#74b9ff,stroke:#fff,color:#fff
    style D fill:#4ecdc4,stroke:#fff,color:#fff
    style E fill:#b0b0b0,stroke:#fff,color:#fff
```

## Permission Flow

```mermaid
flowchart TD
    A[User Action Request] --> B{Authentication Check}
    B -->|Not Authenticated| C[Anonymous Visitor Permissions]
    B -->|Authenticated| D{Role Check}
    
    D -->|Citizen| E[Citizen Permissions]
    D -->|Moderator| F[Moderator + Citizen Permissions]
    D -->|Admin| G[Admin + Moderator + Citizen Permissions]
    D -->|Super Admin| H[All Permissions]
    
    E --> I{Topic Creation?}
    I -->|Yes| J{Top 10% Loyalty?}
    J -->|Yes| K[Allow Topic Creation]
    J -->|No| L[Deny Topic Creation]
    
    C --> M[Browse Content Only]
    E --> N[Standard Citizen Actions]
    F --> O[Moderation Actions]
    G --> P[Administrative Actions]
    H --> Q[Full System Access]
    
    style B fill:#ffd93d,stroke:#000,color:#000
    style J fill:#ff4757,stroke:#fff,color:#fff
```

## Role Hierarchy

### Super Admin
- **Full authority**. Can promote and demote roles. Can delete accounts. Can review private messages. Can adjudicate appeals and flags. Full visibility of all logs and content.

### Admin
- Can adjudicate appeals and flags. Can view rejected posts. Can review private messages. Can apply sanctions. Cannot change user roles. Cannot delete accounts.

### Moderator
- **Anti-spam role**. Can view rejected posts. Can sanction citizens to slow or pause posting. Cannot change roles. Cannot delete accounts. Cannot view private messages. Cannot access citizens' hidden personal information.

### Citizen
- Can view and participate in topics. May be eligible to create topics if high-ranked. Can send private messages. Can appeal rejections. Can flag content.

### Anonymous Visitor
- Can browse the application. Can begin composing posts or topics. Must authenticate before submission enters moderation.

## Permission Matrix

| Capability | Anonymous | Citizen | Moderator | Admin | Super Admin |
|------------|-----------|---------|-----------|-------|-------------|
| Browse content | ✓ | ✓ | ✓ | ✓ | ✓ |
| Create posts | - | ✓ | ✓ | ✓ | ✓ |
| Create topics | - | ✓* | ✓ | ✓ | ✓ |
| Send private messages | - | ✓ | ✓ | ✓ | ✓ |
| Appeal rejections | - | ✓ | ✓ | ✓ | ✓ |
| Flag content | - | ✓ | ✓ | ✓ | ✓ |
| View rejected posts | - | Own only | ✓ | ✓ | ✓ |
| Apply sanctions | - | - | ✓ | ✓ | ✓ |
| Adjudicate appeals | - | - | ✓ | ✓ | ✓ |
| View private messages | - | Own only | - | ✓ | ✓ |
| Change user roles | - | - | - | - | ✓ |
| Delete accounts | - | - | - | - | ✓ |

*Topic creation for citizens requires high loyalty ranking (top 10% by loyalty score)

---

**Related Documentation:**
- [Product Vision](./01-product-vision.md) - Core concepts and terminology
- [Gamification & Reputation](./10-gamification-reputation.md) - Loyalty score requirements
- [Technical: RBAC System](../technical-design/08-rbac-permissions.md) - Implementation details
