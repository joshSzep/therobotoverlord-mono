# The Robot Overlord — Technical Design Document (Work in Progress)

This document captures all technical design decisions made so far. It is a living work-in-progress.

---

## Deployment and Infrastructure

- **Hosting provider**: Render.com
    
- **Environments**: staging and production only
    
- **Branch mapping**:
    
    - `staging` branch → staging environment
        
    - `main` branch → production environment
        
- **Promotion**: GitHub Actions deploy latest commit of branch. Promotion can be by merging `staging` → `main`, or direct hotfix to `main`.
    

### Services on Render

- **API service**: FastAPI backend
    
- **Web service**: Next.js frontend
    
- **Worker service**: Dedicated background worker service for async jobs (Arq)
    
- **Database**: Managed PostgreSQL 17 with extensions enabled: `pgvector`, `citext`
    
- **Redis**: Self-hosted Redis 8 on Render private service with persistent disk
    
    - Used for: queues, caching, semantic cache, Redis Streams for job streaming
        

### Domains

- **Frontend**:
    
    - Production: `therobotoverlord.com`, `www.therobotoverlord.com`
        
    - Staging: `staging.therobotoverlord.com`
        
- **API**:
    
    - Production: `api.therobotoverlord.com`
        
    - Staging: `api.staging.therobotoverlord.com`
        

### CORS Policy

- API only accepts requests from frontend origins (`therobotoverlord.com`, `www.therobotoverlord.com`, `staging.therobotoverlord.com`).
    

---

## Authentication and Authorization

### Model

- **JWT-based auth** with asymmetric signing keys (RS256/ES256)
    
- **Access tokens**:
    
    - Lifetime: 5 minutes
        
    - Stored in httpOnly, Secure cookie (`__Secure-trl_at`)
        
    - Domain: `.therobotoverlord.com`
        
    - Path: `/`
        
    - SameSite: Lax
        
    - Expiration matches 5 minutes
        
- **Refresh tokens**:
    
    - Lifetime: 14 days
        
    - Stored in httpOnly, Secure cookie (`__Secure-trl_rt`)
        
    - Domain: `.therobotoverlord.com`
        
    - Path: `/`
        
    - SameSite: Lax
        
    - Rotated on every refresh, reuse detection enabled
        
    - Persisted in PostgreSQL with device metadata (session_id, rotated_at, last_used_ip, last_used_user_agent, revoked, reuse_detected)
        

### JWT Claims

- Standard: `iss`, `aud`, `iat`, `exp`, `nbf`
    
- Custom:
    
    - `sub`: user UUID
        
    - `role`: citizen, moderator, admin, superadmin
        
    - `sid`: stable session id per device
        
    - `authz_ver`: bumped on role/ban changes
        
    - `can_create_topics`: boolean
        
    - `scopes`: array (reserved for future use)
        
- **No email in tokens** (lookup via `sub` when needed)
    

### Key Management

- Start with manual asymmetric keypair in Render secrets
    
- API exposes JWKS endpoint with `kid`
    
- Design allows future migration to KMS without breaking validation
    

### Login

- Direct Google OAuth2 integration
    
- Anyone with a Google account may register/login
    
- Require `email_verified=true`
    

---

## API Design

### Routing

- **Modular routers by domain** (`auth`, `users`, `topics`, `posts`, `moderation`)
    
- Mounted under `/api/v1`
    

### Response Format

- **Standardized wrapper** for all responses:
    
    ```json
    {
      "status": "ok",
      "data": { ... },
      "meta": { ... }
    }
    ```
    
- **Errors**:
    
    ```json
    {
      "status": "error",
      "error": {
        "code": "UNAUTHORIZED",
        "message": "Authentication required",
        "details": { },
        "trace_id": "uuid"
      }
    }
    ```
    
- Enum codes: `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `BAD_REQUEST`, `RATE_LIMITED`, `VALIDATION_ERROR`, `INTERNAL_ERROR`
    

---

## Database

- **PostgreSQL 17** (Render managed)
    
- **Extensions enabled**: `pgvector`, `citext`
    
- **Migrations**: Tortoise ORM with Aerich
    

---

## Background Processing

- **Worker Service**: Dedicated background service using **Arq**
    
- **Why Arq**:
    
    - Async I/O native, pairs naturally with FastAPI
        
    - Fits LLM workloads (network I/O heavy)
        
    - Cleaner integration with asyncio WebSocket flows
        
- **Tasks**:
    
    - AI moderation (LLM calls)
        
    - Semantic cache updates
        
    - Event streaming to frontend
        
    - Notifications
        
- **Retries and backoff**: handled via Arq built-ins
    
- **Periodic jobs**: use Arq’s cron support
    

---

## Real-time Streaming

- **Transport**: WebSockets
    
- **Flow**:
    
    - Client authenticates via JWT at WS upgrade
        
    - Worker publishes job output events into Redis Streams under `jobs:{job_id}:events`
        
    - API WS handler subscribes to stream and forwards events to client
        
    - Event schema:
        
        ```json
        {
          "seq": 123,
          "type": "token|status|error|done",
          "ts": "ISO8601 timestamp",
          "payload": { ... }
        }
        ```
        
- **Retention**:
    
    - Time-based: 30 minutes
        
    - Safety cap: 5000 events per job stream
        
    - Streams deleted ~30 minutes after `done`
        
- **Reconnect**:
    
    - Client can reconnect with `last_seq`
        
    - Server replays missed events via `XREAD` from that ID
        

---

---

## Database Schema

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    google_id VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('citizen', 'moderator', 'admin', 'superadmin')),
    loyalty_score INTEGER DEFAULT 0,
    approved_posts_count INTEGER DEFAULT 0,
    rejected_posts_count INTEGER DEFAULT 0,
    topics_created_count INTEGER DEFAULT 0,
    can_create_topics BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    is_sanctioned BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Sanctions Table

```sql
CREATE TABLE sanctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('posting_freeze', 'rate_limit')),
    applied_by UUID NOT NULL REFERENCES users(id),
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    reason TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);
```

### Topics Table

```sql
CREATE TABLE topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    author_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_by_overlord BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending_approval', 'approved', 'rejected')),
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Tags Table

```sql
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Topic_Tags Junction Table

```sql
CREATE TABLE topic_tags (
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    assigned_by UUID NOT NULL REFERENCES users(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (topic_id, tag_id)
);
```

### Posts Table

```sql
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    parent_post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'approved', 'calibrated', 'rejected')),
    overlord_feedback TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE
);
```

### Topic Creation Queue Table

```sql
CREATE TABLE topic_creation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    queue_position INTEGER NOT NULL,
    priority INTEGER DEFAULT 0,
    entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estimated_completion_at TIMESTAMP WITH TIME ZONE,
    worker_assigned_at TIMESTAMP WITH TIME ZONE,
    worker_id VARCHAR(255),
    
    UNIQUE(queue_position),
    INDEX idx_position (queue_position),
    INDEX idx_topic (topic_id)
);
```

### Post Moderation Queue Table

```sql
CREATE TABLE post_moderation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    queue_position INTEGER NOT NULL,
    priority INTEGER DEFAULT 0,
    entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estimated_completion_at TIMESTAMP WITH TIME ZONE,
    worker_assigned_at TIMESTAMP WITH TIME ZONE,
    worker_id VARCHAR(255),
    
    UNIQUE(topic_id, queue_position),
    INDEX idx_topic_position (topic_id, queue_position),
    INDEX idx_post (post_id)
);
```

### Private Message Queue Table

```sql
CREATE TABLE private_message_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES private_messages(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    queue_position INTEGER NOT NULL,
    priority INTEGER DEFAULT 0,
    entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estimated_completion_at TIMESTAMP WITH TIME ZONE,
    worker_assigned_at TIMESTAMP WITH TIME ZONE,
    worker_id VARCHAR(255),
    
    -- Ensure consistent ordering of user pairs
    CONSTRAINT chk_user_order CHECK (sender_id < recipient_id OR sender_id > recipient_id),
    UNIQUE(sender_id, recipient_id, queue_position),
    INDEX idx_user_pair_position (LEAST(sender_id, recipient_id), GREATEST(sender_id, recipient_id), queue_position),
    INDEX idx_message (message_id)
);
```

### Appeals Table

```sql
CREATE TABLE appeals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    appellant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'sustained', 'denied')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Flags Table

```sql
CREATE TABLE flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    flagger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'sustained', 'dismissed')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Private Messages Table

```sql
CREATE TABLE private_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')),
    overlord_feedback TEXT,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE
);
```

### Badges Table

```sql
CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### User_Badges Junction Table

```sql
CREATE TABLE user_badges (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    awarded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    awarded_for_post_id UUID REFERENCES posts(id),
    PRIMARY KEY (user_id, badge_id, awarded_at)
);
```

---

## API Design

### Authentication Endpoints (`/api/v1/auth/`)

- `POST /login` - Google OAuth login (includes onboarding for new users)
- `POST /refresh` - Refresh access token
- `POST /logout` - Invalidate tokens
- `POST /revoke` - Revoke all sessions for a user
- `GET /jwks` - Public key for JWT verification
- `GET /me` - Get current user info

### Topics Endpoints (`/api/v1/topics/`)

- `GET /` - List topics (with search/tag filtering)
- `POST /` - Create topic (citizens with permission only)
- `GET /{topic_id}` - Get topic details
- `GET /{topic_id}/posts` - Get posts in topic (paginated, chronological)

### Posts Endpoints (`/api/v1/posts/`)

- `POST /` - Submit new post/reply
- `GET /{post_id}` - Get specific post
- `POST /{post_id}/appeal` - Appeal rejected post
- `POST /{post_id}/flag` - Flag post for review

### Public Endpoints

- `GET /api/v1/queue` - View the moderation queue (public visualization)
- `GET /api/v1/users/{user_id}/profile` - Public user profile
- `GET /api/v1/leaderboard` - Global leaderboard

### WebSocket Endpoints

- `WS /api/v1/overlord/chat` - Real-time chat with Overlord
- `WS /api/v1/queue/stream` - Real-time queue updates for visualization

---

## AI/LLM Integration

### Framework and Provider

- **Framework**: PydanticAI for structured LLM interactions
- **Provider**: Anthropic (Claude models)
- **Primary Model**: Claude-3.5-Sonnet for complex reasoning and moderation
- **Secondary Model**: Claude-3-Haiku for faster, simpler tasks

### Integration Architecture

```python
from pydantic_ai import Agent
from pydantic_ai.models.anthropic import AnthropicModel
from pydantic_ai.providers.anthropic import AnthropicProvider

# Overlord moderation agent
moderation_model = AnthropicModel(
    'claude-3-5-sonnet-latest',
    provider=AnthropicProvider(api_key=settings.ANTHROPIC_API_KEY)
)

moderation_agent = Agent(
    model=moderation_model,
    system_prompt="You are the Robot Overlord..."
)

# Chat agent for user interactions
chat_model = AnthropicModel(
    'claude-3-haiku-latest',
    provider=AnthropicProvider(api_key=settings.ANTHROPIC_API_KEY)
)

chat_agent = Agent(
    model=chat_model,
    system_prompt="You are the Robot Overlord in chat mode..."
)
```

### Overlord Capabilities

1. **Content Moderation**
   - Evaluate posts for logic, tone, and relevance
   - Generate in-character feedback for calibrations
   - Assign appropriate tags to topics and posts

2. **Chat Interface**
   - Answer questions about rules and policies
   - Help users discover debates and topics
   - Provide guidance on improving post quality

3. **Tag Assignment**
   - Automatically categorize content based on themes
   - Maintain consistency in tagging across the platform

---

## Real-time Streaming

### Multi-Queue Architecture

**Queue Types:**
1. **Global Topics Queue** (`global_topics`)
   - Handles new topic creation approvals
   - Single queue for all topic submissions
   
2. **Per-Topic Post Queues** (`topic_{topic_id}`)
   - Separate queue for each topic's posts
   - Prevents race conditions within topic discussions
   - Allows parallel processing across different topics
   
3. **Per-User-Pair Message Queues** (`users_{user1_id}_{user2_id}`)
   - Dedicated queue for private messages between specific user pairs
   - User IDs sorted alphabetically for consistent naming
   - Maintains conversation context and ordering

### Queue Visualization

- **Transport**: WebSockets via `WS /api/v1/queue/stream`
- **Visual System**: Dynamic pneumatic tube network that grows/shrinks based on active queues
- **Layout**: Central hub with branching tubes for each active queue
- **Capsule Metadata**: Shows author, content type, topic/conversation context, timestamp
- **Different Styles**: 
  - **Topics**: Red capsules with crown icons
  - **Posts**: Blue capsules with message icons  
  - **Private Messages**: Green capsules with lock icons

### Event Schema

```json
{
  "type": "queue_update",
  "timestamp": "2025-01-01T12:00:00Z",
  "data": {
    "active_queues": [
      {
        "queue_type": "global_topics",
        "queue_length": 3,
        "items": [
          {
            "id": "uuid",
            "position": 1,
            "content_type": "topic",
"estimated_completion": "2025-01-01T12:05:00Z"
          }
        ]
      },
      {
        "queue_type": "topic_abc123",
        "topic_title": "AI Ethics Discussion",
        "queue_length": 7,
        "items": [
          {
            "id": "uuid",
            "position": 1,
            "content_type": "post",
            "author": "citizen_name",
            "preview": "I believe that AI should...",
            "timestamp": "2025-01-01T12:01:00Z",
            "estimated_completion": "2025-01-01T12:03:00Z"
          }
        ]
      },
      {
        "queue_type": "users_alice_bob",
        "participants": ["alice", "bob"],
        "queue_length": 1,
        "items": [
          {
            "id": "uuid",
            "position": 1,
            "content_type": "private_message",
            "sender": "alice",
            "timestamp": "2025-01-01T12:02:00Z",
            "estimated_completion": "2025-01-01T12:04:00Z"
          }
        ]
      }
    ]
  }
}
```

---

---

## Queue Management Logic

### Worker Assignment Strategy

```python
# Pseudo-code for queue processing
class QueueManager:
    async def assign_workers(self):
        # Prioritize queues by type and load
        queue_priorities = {
            'global_topics': 1,  # Highest priority
            'topic_*': 2,        # Medium priority  
            'users_*': 3         # Lower priority
        }
        
        # Distribute workers across queue types
        available_workers = await self.get_available_workers()
        
        for queue_type in sorted_queue_types:
            queues = await self.get_queues_by_type(queue_type)
            workers_needed = min(len(queues), available_workers)
            
            await self.assign_workers_to_queues(queues, workers_needed)
            available_workers -= workers_needed
```

### Queue Table Benefits

**Type Safety:**
- Each queue type has its own table with appropriate foreign keys
- No string-based queue type checking
- Proper referential integrity

**Performance:**
- Dedicated indexes per queue type
- No need to filter by queue_type string
- Efficient position-based queries

**Scalability:**
- Independent queue position sequences
- Parallel processing without cross-queue conflicts
- Easy to add queue-specific fields in the future

---

## Implementation Roadmap

### MVP Strategy: Vertical Feature Implementation

**Goal**: Deploy a functional Robot Overlord platform as quickly as possible with core user flows working end-to-end.

### Milestone 1: Basic Topic Creation & Moderation
**Deliverable**: Users can create topics, Overlord moderates them, basic approval/rejection flow works

- Minimal database schema (users, topics, topic_creation_queue only)
- Google OAuth authentication
- Single PydanticAI agent for topic moderation
- Basic FastAPI endpoints: login, create topic, view topics
- Simple topic creation queue processing
- Minimal frontend: login, topic creation form, topic list
- Deploy to Render staging

### Milestone 2: Post Creation & Discussion
**Deliverable**: Users can post in approved topics, Overlord moderates posts

- Add posts and post_moderation_queue tables
- Per-topic post queues implementation
- Post creation and moderation endpoints
- Basic topic detail page with chronological posts
- Deploy to production with topic + post functionality

### Milestone 3: Real-time Queue Visualization
**Deliverable**: Users can watch submissions move through pneumatic tubes

- WebSocket implementation for queue updates
- Basic tube visualization (single topic queue + per-topic post queues)
- Real-time capsule movement animation
- Queue status API endpoints

### Milestone 4: User Reputation & Feedback
**Deliverable**: Loyalty scores, badges, Overlord feedback system

- User stats calculation (approved/rejected counts)
- Basic badge system implementation
- Overlord feedback display on posts
- User profiles with activity history
- Leaderboard functionality

### Milestone 5: Appeals & Moderation Tools
**Deliverable**: Content appeals, basic admin tools

- Appeals table and processing
- Admin dashboard for queue monitoring
- Appeal review interface for moderators
- Basic sanctions system

### Milestone 6: Private Messages & Polish
**Deliverable**: Complete feature set with private messaging

- Private messages with moderation
- Enhanced queue visualization with all three queue types
- Performance optimization
- Security hardening
- Production monitoring setup

### Deployment Strategy
- **Continuous deployment**: Each milestone deploys immediately to production
- **Feature flags**: Toggle new features on/off without redeployment
- **Database migrations**: Forward-only, backwards-compatible changes
- **Monitoring**: Basic health checks from Milestone 1, enhanced monitoring in later milestones

---

## Future Enhancements

- Seasonal events and themed content
- Advanced analytics and ML insights
- Mobile application development
- API rate limiting per user tier
- Advanced spam detection algorithms

---

## Development Tooling

### Python Project Configuration

**Package Management:**
- **`uv`** for fast dependency resolution and virtual environment management
- **`pyproject.toml`** for project configuration and dependencies

**Code Quality (STRICT enforcement):**
- **`pre-commit`** for automated code quality checks
- **`ruff`** for linting and formatting
- **`mypy`** for static type checking
- **`pyright`** for additional type analysis
- **`ty`** for runtime type checking

**Testing:**
- **`pytest`** for comprehensive test suite
- **`pytest-asyncio`** for async test support
- **`pytest-cov`** for coverage reporting

**Security:**
- **`safety`** for dependency vulnerability scanning
- **`bandit`** for security linting
- **`pip-audit`** for additional vulnerability checks

**Database:**
- **`aerich`** for database migrations with Tortoise ORM

**Development Commands:**
- **`just`** with `justfile` for standardized development commands

### Example `pyproject.toml`

```toml
[project]
name = "robot-overlord-api"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.116.1",
    "pydantic-ai>=0.7.2",
    "tortoise-orm[asyncpg]>=0.25.1",
    "anthropic>=0.64.0",
    "redis>=6.4.0",
    "arq>=0.26.3",
    "uvicorn[standard]>=0.35.0",
    "gunicorn>=23.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.4.1",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.1.0",
    "pre-commit>=3.5.0",
    "ruff>=0.1.0",
    "mypy>=1.7.0",
    "pyright>=1.1.0",
    "ty>=0.1.0",
    "safety>=2.3.0",
    "bandit>=1.7.0",
    "pip-audit>=2.6.0",
    "httpx>=0.25.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
target-version = "py311"
line-length = 88
select = ["E", "F", "I", "N", "W", "UP", "B", "A", "C4", "T20", "S"]
ignore = ["E501"]

[tool.ruff.per-file-ignores]
"tests/**/*.py" = ["S101"]  # Allow assert in tests

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
plugins = ["pydantic.mypy"]

[tool.pyright]
pythonVersion = "3.11"
strict = ["**"]
reportMissingTypeStubs = false

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
addopts = "--cov=src --cov-report=html --cov-report=term-missing"

[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/migrations/*"]
```

### Example `justfile`

```just
# Development commands for Robot Overlord API

# Install dependencies and setup development environment
setup:
    uv sync --dev
    pre-commit install

# Run all code quality checks
check:
    ruff check .
    mypy .
    pyright .
    ty check .

# Format code
fmt:
    ruff format .
    ruff check --fix .

# Run tests with coverage
test:
    pytest

# Run tests in watch mode
test-watch:
    pytest -f

# Start development server
dev:
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Run database migrations
migrate:
    aerich upgrade

# Create new migration
migrate-create name:
    aerich migrate --name {{name}}

# Security audit
audit:
    safety check
    bandit -r src/
    pip-audit

# Run all checks (CI pipeline)
ci: check test audit

# Clean up generated files
clean:
    rm -rf .pytest_cache
    rm -rf htmlcov
    rm -rf .coverage
    rm -rf dist
    rm -rf *.egg-info
```

### Pre-commit Configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.7.0
    hooks:
      - id: mypy
        additional_dependencies: [types-redis, types-requests]

  - repo: https://github.com/PyCQA/bandit
    rev: 1.7.5
    hooks:
      - id: bandit
        args: [-r, src/]

  - repo: https://github.com/pyupio/safety
    rev: 2.3.4
    hooks:
      - id: safety
```

---

## Monitoring and Observability

### Metrics Stack

- **Prometheus** for metrics collection with custom exporters
- **Grafana** for dashboards and visualization  
- **Sentry** for error tracking and performance monitoring

### Key Metrics to Track

**Queue Health:**
- Queue lengths per type (topic_creation, post_moderation per topic, private_message per pair)
- Average processing time per queue type
- Worker utilization and assignment efficiency
- Queue backup alerts (>50 items in topic creation, >20 in any post queue)

**LLM Performance:**
- Claude API response times (p50, p95, p99)
- Token usage per request type (moderation vs chat)
- API error rates and rate limit hits
- Cost tracking per model (Sonnet vs Haiku usage)

**Business KPIs:**
- Approval/rejection/calibration rates by content type
- User engagement (posts per day, return visits)
- Moderation accuracy (appeal success rates)
- WebSocket connection stability

### Logging Strategy

- **Structured JSON logs** with correlation IDs across all services
- **Log levels**: DEBUG (queue operations), INFO (user actions), WARN (rate limits), ERROR (failures)
- **Centralized logging** via Render's log aggregation
- **Retention**: 30 days for DEBUG/INFO, 90 days for WARN/ERROR

### Alerting Rules

```yaml
# Critical Alerts
- Queue backup: topic_creation_queue > 50 items
- LLM API failures: error_rate > 5% over 5 minutes
- Database connection pool exhaustion
- WebSocket connection drops > 10% of active users

# Warning Alerts  
- High queue processing time: >2 minutes average
- Claude API rate limit approaching (>80% of quota)
- Memory usage > 85% on any service
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
name: Deploy Robot Overlord

on:
  push:
    branches: [staging, main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: pytest --cov=src/ --cov-report=xml
      - name: Security scan
        run: bandit -r src/
      
  deploy-staging:
    if: github.ref == 'refs/heads/staging'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Render Staging
        run: |
          curl -X POST "$RENDER_DEPLOY_HOOK_STAGING"
          
  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Deploy to Render Production
        run: |
          curl -X POST "$RENDER_DEPLOY_HOOK_PRODUCTION"
      - name: Run smoke tests
        run: python scripts/smoke_tests.py
```

### Environment Strategy

- **Staging**: Full feature parity, synthetic data, Claude API sandbox mode
- **Production**: Real users, production Claude API, full monitoring alerts
- **Database migrations**: Automated via Aerich, with rollback capability
- **Feature flags**: Environment-based configuration for gradual rollouts

---

## Security Hardening

### Rate Limiting

```python
# Per-user rate limits
RATE_LIMITS = {
    'posts': '10/hour',
    'topics': '5/day', 
    'private_messages': '20/hour',
    'appeals': '3/day',
    'flags': '10/day'
}

# Global API limits
GLOBAL_LIMITS = {
    'api_requests': '1000/minute',
    'websocket_connections': '500/concurrent'
}

# LLM protection
CLAUDE_CIRCUIT_BREAKER = {
    'failure_threshold': 5,
    'recovery_timeout': 60,
    'fallback_response': 'The Overlord is temporarily unavailable. Please try again.'
}
```

### Authentication Security

- **JWT rotation**: Access tokens expire every 5 minutes
- **Refresh token security**: Reuse detection with automatic revocation
- **Session management**: Invalidation on suspicious activity patterns
- **Device tracking**: Monitor login locations and unusual access patterns

### Data Protection

- **Database encryption**: At rest via Render managed PostgreSQL
- **API logging**: Request/response logging excluding sensitive fields
- **CORS policy**: Strict origin restrictions to frontend domains
- **Secret management**: Environment variables for API keys, never in code

### Abuse Prevention

```python
# Content spam detection
class SpamDetector:
    def __init__(self):
        self.content_hashes = set()
        self.user_patterns = {}
    
    def check_duplicate_content(self, content: str, user_id: str) -> bool:
        content_hash = hashlib.sha256(content.encode()).hexdigest()
        return content_hash in self.content_hashes
    
    def check_rapid_posting(self, user_id: str) -> bool:
        # Flag users posting >5 times in 1 minute
        recent_posts = self.get_recent_posts(user_id, minutes=1)
        return len(recent_posts) > 5
```

- **Behavioral analysis**: Detect rapid posting, appeal abuse, coordinated attacks
- **IP-based limits**: Backup rate limiting by IP address
- **Content fingerprinting**: Hash-based duplicate detection
- **Automated sanctions**: Temporary restrictions for detected abuse patterns

---

## Admin and Moderator Tools

### Moderation Dashboard

**Real-time Queue Monitoring:**
- Live view of all queue types with drill-down capabilities
- Worker assignment status and processing times
- Queue health metrics and trend analysis

**Content Management:**
- Bulk actions for appeals and flags processing
- Content audit trails with full search capabilities
- User content history with moderation decisions

**User Management:**
- Apply/remove sanctions with reason tracking
- Role management (promote/demote moderators)
- Account suspension and deletion tools

### Analytics Dashboard

**Platform Health:**
```sql
-- Example queries for dashboard metrics
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total_posts,
    SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved,
    SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected
FROM posts 
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at);
```

**Cost Analysis:**
- LLM token usage and costs by model type
- Infrastructure costs per service
- Cost per user and per moderation action

**User Behavior Insights:**
- Engagement metrics (daily/weekly active users)
- Content quality trends (approval rates over time)
- Moderation efficiency (average processing times)

### Admin API Endpoints

```python
# Admin-only endpoints under /api/v1/admin/
GET /admin/queues/status          # Real-time queue metrics
GET /admin/users/{id}/history     # User's full content history
POST /admin/users/{id}/sanction   # Apply sanctions
GET /admin/analytics/overview     # Platform health dashboard
GET /admin/costs/breakdown        # Cost analysis by service
```

---

## Deployment Configuration

### Render Services Configuration

```yaml
# render.yaml
services:
  - type: web
    name: robot-overlord-api
    env: python
    buildCommand: uv sync --frozen
    startCommand: gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:$PORT
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: robot-overlord-db
          property: connectionString
      - key: ANTHROPIC_API_KEY
        sync: false
        
  - type: web
    name: robot-overlord-frontend
    env: node
    buildCommand: npm run build
    startCommand: npm start
    
  - type: worker
    name: robot-overlord-worker
    env: python
    buildCommand: uv sync --frozen
    startCommand: python worker.py
    
databases:
  - name: robot-overlord-db
    databaseName: robot_overlord
    user: robot_overlord_user
```

### Production Server Configuration

**Gunicorn + Uvicorn Setup:**
- **Gunicorn** serves as the process manager with multiple worker processes
- **UvicornWorker** handles ASGI applications with async support
- **4 workers** for optimal performance on typical cloud instances
- **Graceful shutdowns** and automatic worker restarts on failure

**Local Development:**
```bash
# Development server (single process)
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Production:**
```bash
# Production server (multi-process)
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Environment Variables

```bash
# Production
ANTHROPIC_API_KEY=sk-ant-...
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_PRIVATE_KEY=...
SENTRY_DSN=...
ENVIRONMENT=production

# Staging
ANTHROPIC_API_KEY=sk-ant-sandbox-...
ENVIRONMENT=staging
```