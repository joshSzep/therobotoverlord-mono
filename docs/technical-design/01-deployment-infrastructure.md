# Deployment and Infrastructure

## Infrastructure Architecture

```mermaid
graph TB
    subgraph "External Services"
        A[Google OAuth]
        B[Domain DNS]
    end
    
    subgraph "Render.com Infrastructure"
        C[Load Balancer]
        D[Web Service - Next.js]
        E[API Service - FastAPI]
        F[Worker Service - Arq]
        G[PostgreSQL 17]
        H[Redis 8]
    end
    
    subgraph "Environments"
        I[Production - main branch]
        J[Staging - staging branch]
    end
    
    A --> C
    B --> C
    C --> D
    C --> E
    E --> F
    E --> G
    E --> H
    F --> G
    F --> H
    
    I --> D
    I --> E
    I --> F
    J --> D
    J --> E
    J --> F
    
    style C fill:#ff4757,stroke:#fff,color:#fff
    style G fill:#74b9ff,stroke:#fff,color:#fff
    style H fill:#4ecdc4,stroke:#fff,color:#fff
```

## Deployment Pipeline

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant GA as GitHub Actions
    participant R as Render
    participant DB as Database
    
    Dev->>GH: Push to staging branch
    GH->>GA: Trigger CI/CD
    GA->>GA: Run tests
    GA->>R: Deploy to staging
    R->>DB: Run migrations (if any)
    R->>R: Start staging services
    
    Dev->>GH: Merge to main branch
    GH->>GA: Trigger production CI/CD
    GA->>GA: Run full test suite
    GA->>R: Deploy to production
    R->>DB: Run production migrations
    R->>R: Start production services
    R->>R: Health check validation
```

## Hosting Provider

**Render.com**

## Environments

- **Staging**: `staging` branch → staging environment
- **Production**: `main` branch → production environment

## Branch Mapping & Promotion

- GitHub Actions deploy latest commit of branch
- Promotion can be by merging `staging` → `main`, or direct hotfix to `main`

## Services on Render

### API Service
FastAPI backend

### Web Service
Next.js frontend

### Worker Service
Dedicated background worker service for async jobs (Arq)

### Database
Managed PostgreSQL 17 with extensions enabled: `pgvector`, `citext`

### Redis
Self-hosted Redis 8 on Render private service with persistent disk

**Used for:**
- Queues
- Caching
- Semantic cache
- Redis Streams for job streaming

## Domains

### Frontend
- **Production**: `therobotoverlord.com`, `www.therobotoverlord.com`
- **Staging**: `staging.therobotoverlord.com`

### API
- **Production**: `api.therobotoverlord.com`
- **Staging**: `api.staging.therobotoverlord.com`

## CORS Policy

API only accepts requests from frontend origins (`therobotoverlord.com`, `www.therobotoverlord.com`, `staging.therobotoverlord.com`).

---

**Related Documentation:**
- [Background Processing](./11-background-processing.md) - Worker service details
- [Database Schema](./05-database-schema.md) - PostgreSQL configuration
- [Business: Success & Delivery](../business-requirements/19-success-delivery.md) - Deployment phases
