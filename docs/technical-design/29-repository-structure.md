# Repository Structure Strategy

## Overview

The Robot Overlord platform uses a **2-repository approach** optimized for early-stage development velocity while maintaining clear service boundaries for future scaling.

## Repository Structure

### Current Structure (MVP Phase)

```
therobotoverlord-api/     # Backend services (FastAPI + Worker + Shared)
therobotoverlord-web/     # Frontend service (Next.js)
```

### Repository Responsibilities

#### `therobotoverlord-api`
**Consolidated Backend Repository**
- **FastAPI Application**: REST/WebSocket API endpoints
- **Background Worker**: Arq-based async processing
- **Shared Libraries**: Pydantic models, database schemas, utilities
- **Infrastructure**: Deployment configs, migrations, environment setup

#### `therobotoverlord-web` 
**Frontend Repository**
- **Next.js Application**: User interface and admin dashboards
- **Real-time Features**: Queue visualization, WebSocket integration
- **Authentication**: Frontend auth flows and session management

## Internal Module Organization

### API Repository Structure
```
therobotoverlord-api/
├── api/                    # FastAPI application
│   ├── routers/           # API route handlers
│   ├── middleware/        # Authentication, CORS, etc.
│   ├── dependencies/      # Dependency injection
│   └── main.py           # FastAPI app initialization
├── worker/                # Background processing
│   ├── tasks/            # Arq task definitions
│   ├── services/         # Business logic services
│   └── main.py          # Worker initialization
├── shared/               # Common code
│   ├── models/          # Pydantic models
│   ├── database/        # Database schemas & connections
│   ├── utils/           # Utility functions
│   └── config/          # Configuration management
├── infrastructure/       # Deployment & ops
│   ├── migrations/      # Database migrations
│   ├── render/          # Render.com configs
│   └── scripts/         # Deployment scripts
├── tests/               # Test suites
└── requirements.txt     # Python dependencies
```

### Web Repository Structure
```
therobotoverlord-web/
├── src/
│   ├── app/             # Next.js app router
│   ├── components/      # React components
│   ├── hooks/           # Custom React hooks
│   ├── lib/             # Utility libraries
│   ├── types/           # TypeScript type definitions
│   └── styles/          # CSS/styling
├── public/              # Static assets
├── tests/               # Frontend tests
└── package.json         # Node.js dependencies
```

## Deployment Architecture

### Render Services Mapping
- **API Service**: Deploys from `therobotoverlord-api/` (FastAPI app)
- **Worker Service**: Deploys from `therobotoverlord-api/` (Worker main.py)
- **Web Service**: Deploys from `therobotoverlord-web/` (Next.js app)

### Shared Infrastructure
- **PostgreSQL**: Shared database across API and Worker
- **Redis**: Shared cache/queue storage across API and Worker
- **Environment Variables**: Managed via Render secrets

## Development Benefits

### Advantages of 2-Repository Approach

**✅ Development Velocity**
- Fast iteration across tightly coupled services
- Easy debugging across API/Worker boundaries
- Simplified dependency management
- Single deployment pipeline for backend services

**✅ Team Efficiency**
- Reduced coordination overhead for small team
- Easier knowledge sharing across backend components
- Simplified onboarding process
- Fewer repositories to manage and secure

**✅ Operational Simplicity**
- Straightforward CI/CD pipelines
- Unified backend versioning
- Simplified monitoring and logging
- Easier database migration coordination

## Future Migration Strategy

### When to Split Services

**Triggers for Repository Separation:**
- Team grows beyond 5 developers
- Need for independent service ownership
- Different deployment cadences required
- Significant scaling requirements for individual services

### Migration Path

**Phase 1: Current (2 Repositories)**
- `therobotoverlord-api` (consolidated backend)
- `therobotoverlord-web` (frontend)

**Phase 2: Service Separation (5+ Repositories)**
```
therobotoverlord-api/           # FastAPI only
therobotoverlord-worker/        # Background processing
therobotoverlord-shared/        # Common libraries (npm/pip packages)
therobotoverlord-web/           # Next.js frontend
therobotoverlord-infrastructure/ # IaC and deployment configs
```

### Migration Preparation

**Current Design Decisions Supporting Future Split:**
- Clear module boundaries within `api/`, `worker/`, `shared/`
- Separate service entry points (`api/main.py`, `worker/main.py`)
- Isolated business logic in service layers
- Well-defined interfaces between components

**Migration Steps:**
1. Extract `shared/` into separate package repository
2. Split `worker/` into independent repository
3. Move `infrastructure/` to dedicated IaC repository
4. Update CI/CD pipelines for multi-repo coordination

## Best Practices

### Code Organization
- **Clear Boundaries**: Maintain logical separation even within single repository
- **Shared Interfaces**: Define clear contracts between API and Worker
- **Configuration**: Centralized config management in `shared/config/`
- **Testing**: Comprehensive test coverage for all modules

### Development Workflow
- **Feature Branches**: Use feature branches for all changes
- **Code Reviews**: Mandatory reviews for all changes
- **Integration Testing**: Test API/Worker interactions thoroughly
- **Documentation**: Keep module documentation up to date

---

**Related Documentation:**
- [Deployment Infrastructure](./01-deployment-infrastructure.md) - Render service configuration
- [Background Processing](./11-background-processing.md) - Worker service details
- [API Design](./04-api-design.md) - API structure and patterns
