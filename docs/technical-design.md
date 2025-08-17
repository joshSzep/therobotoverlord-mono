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
        
    - `permissions`: array of permission names (e.g., ["create_topics", "moderate_posts"])
        
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
        "trace_id": "trace-id"
      }
    }
    ```
    
- Enum codes: `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `BAD_REQUEST`, `RATE_LIMITED`, `VALIDATION_ERROR`, `INTERNAL_ERROR`
    

---

## Frontend Design Requirements

### Overlord Aesthetic Implementation

**Visual Identity:**
- **1960s Soviet propaganda aesthetic** with bold reds, off-white textures, stark shapes
- **Heavy display typography** for authoritarian feel
- **Minimal UI chrome** to maintain clean, propaganda poster energy

**Overlord Message Styling:**
- **Distinct typographic treatment** for all Overlord communications
- **Unique visual container** that makes Overlord messages instantly recognizable
- **Robotic styling** that differentiates from citizen content
- Applied to: moderation feedback, chat responses, notifications, sanctions

**UI Components:**
- **Graveyard Section**: Dedicated UI element in user profiles for rejected posts
  - Private visibility (author + moderators/admins only)
  - Clear labeling as "Graveyard" 
  - Display rejected posts with Overlord feedback
- **Queue Visualization**: Dynamic pneumatic tube network
  - Red capsules with crown icons (Topic Creation)
  - Blue capsules with message icons (Post Moderation)
  - Green capsules with lock icons (Private Messages)

---

## Multilingual Translation System

### Translation Architecture

**Translation Flow:**
1. **Content Ingestion**: Posts submitted in any language
2. **Language Detection**: Automatic detection of non-English content
3. **Translation to English**: OpenAI API for canonical storage
4. **Persistence**: Store both original and translated versions
5. **Moderation**: Overlord evaluates English version
6. **Display**: Show appropriate version based on context

**Translation Flow (Updated):**
1. **Content Ingestion**: Posts submitted in any language
2. **Language Detection**: Automatic detection of non-English content
3. **Translation to English**: OpenAI API for canonical storage
4. **Persistence**: Store original in translations table, English in main content tables
5. **Moderation**: Overlord evaluates English version only
6. **Appeals Process**: Display both original and translated versions to users and moderators
7. **Translation Quality**: Poor translation quality can be grounds for successful appeals
8. **Display**: Show appropriate version based on user preference (future enhancement)

**Event-Driven Loyalty Score System:**
```python
# Loyalty score calculation via event sourcing
class LoyaltyScoreService:
    def __init__(self, redis_client, db_client):
        self.redis = redis_client
        self.db = db_client
        # Private algorithm parameters - not exposed to users
        self._POST_VALUE_SCALAR = 1
        self._TOPIC_VALUE_SCALAR = 5  # Topics worth more than posts
        self._PRIVATE_MESSAGE_VALUE_SCALAR = 1
    
    async def get_loyalty_score(self, user_id: str) -> int:
        # Check Redis cache first
        cached_score = await self.redis.get(f"loyalty:{user_id}")
        if cached_score is not None:
            return int(cached_score)
        
        # Calculate from events if cache miss
        score = await self._calculate_from_events(user_id)
        await self.redis.setex(f"loyalty:{user_id}", 3600, score)  # Cache for 1 hour
        return score
    
    async def _calculate_from_events(self, user_id: str) -> int:
        # Private method - algorithm details hidden from public API
        events = await self.db.moderation_events.filter(user_id=user_id)
        
        counts = {
            "accepted_post_count": 0, "rejected_post_count": 0,
            "accepted_topic_count": 0, "rejected_topic_count": 0,
            "accepted_private_message_count": 0, "rejected_private_message_count": 0
        }
        
        for event in events:
            key = f"{event.outcome}_{event.content_type}_count"
            if key in counts:
                counts[key] += 1
        
        # Proprietary loyalty score calculation
        loyalty_score = (
            self._POST_VALUE_SCALAR * (counts["accepted_post_count"] - counts["rejected_post_count"]) +
            self._TOPIC_VALUE_SCALAR * (counts["accepted_topic_count"] - counts["rejected_topic_count"]) +
            self._PRIVATE_MESSAGE_VALUE_SCALAR * (counts["accepted_private_message_count"] - counts["rejected_private_message_count"])
        )
        
        return loyalty_score
    
    async def record_moderation_event(self, user_id: str, event_type: str, content_type: str, content_id: str, outcome: str):
        # Store event with outcome
        await self.db.moderation_events.create({
            "user_id": user_id,
            "event_type": event_type,
            "content_type": content_type,
            "content_id": content_id,
            "outcome": outcome
        })
        
        # Invalidate cache and update user record
        await self.redis.delete(f"loyalty:{user_id}")
        new_score = await self.get_loyalty_score(user_id)
        await self.db.users.filter(id=user_id).update(loyalty_score=new_score)
        
        # Trigger permission updates
        await self.update_dynamic_permissions(user_id)
```

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
        
    - **Overlord Commentary Streaming**: Workers can stream in-character commentary during processing via WebSocket connections
        
    - Event schema:
        
        ```json
        {
          "seq": 123,
          "type": "token|status|error|done|commentary",
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
    loyalty_score INTEGER DEFAULT 0, -- Cached score from proprietary algorithm, only public metric
    is_banned BOOLEAN DEFAULT FALSE,
    is_sanctioned BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);````

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
    content TEXT NOT NULL, -- Canonical English storage only
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'approved', 'calibrated', 'rejected')),
    overlord_feedback TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Used for chronological display ordering
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    
    INDEX idx_topic_submission_order (topic_id, submitted_at)
);
```

### Topic Creation Queue Table

```sql
CREATE TABLE topic_creation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    priority_score BIGINT NOT NULL, -- Timestamp + priority offset for ordering
    priority INTEGER DEFAULT 0,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed')) DEFAULT 'pending',
    entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estimated_completion_at TIMESTAMP WITH TIME ZONE,
    worker_assigned_at TIMESTAMP WITH TIME ZONE,
    worker_id VARCHAR(255),
    
    INDEX idx_priority_score (priority_score),
    INDEX idx_status (status),
    INDEX idx_topic (topic_id)
);
```

### Post Moderation Queue Table

```sql
CREATE TABLE post_moderation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    priority_score BIGINT NOT NULL, -- Timestamp + priority offset for ordering
    priority INTEGER DEFAULT 0,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed')) DEFAULT 'pending',
    entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estimated_completion_at TIMESTAMP WITH TIME ZONE,
    worker_assigned_at TIMESTAMP WITH TIME ZONE,
    worker_id VARCHAR(255),
    
    INDEX idx_topic_priority (topic_id, priority_score),
    INDEX idx_status (status),
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
    priority_score BIGINT NOT NULL, -- Timestamp + priority offset for ordering
    priority INTEGER DEFAULT 0,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed')) DEFAULT 'pending',
    entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estimated_completion_at TIMESTAMP WITH TIME ZONE,
    worker_assigned_at TIMESTAMP WITH TIME ZONE,
    worker_id VARCHAR(255),
    
    -- Queue naming handled in application logic: queue_name = f"users_{min(sender_id, recipient_id)}_{max(sender_id, recipient_id)}"
    INDEX idx_user_pair_priority (sender_id, recipient_id, priority_score),
    INDEX idx_status (status),
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

### Moderation Events Table (Event-Sourced Loyalty Scoring)

```sql
CREATE TABLE moderation_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL, -- 'topic_moderated', 'post_moderated', 'private_message_moderated', etc.
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('topic', 'post', 'private_message')),
    content_id UUID NOT NULL, -- references posts.id, topics.id, or private_messages.id
    outcome VARCHAR(20) NOT NULL CHECK (outcome IN ('approved', 'rejected', 'calibrated')), -- moderation result
    moderator_id UUID REFERENCES users(id), -- NULL for AI moderation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    INDEX idx_user_events (user_id, created_at),
    INDEX idx_content (content_type, content_id),
    INDEX idx_event_type (event_type)
);
```

### Translations Table (Multilingual Support)

```sql
CREATE TABLE translations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL, -- References posts.id, topics.id, or private_messages.id
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('post', 'topic', 'private_message')),
    language_code VARCHAR(10) NOT NULL, -- ISO language code
    original_content TEXT NOT NULL, -- Original submission before translation
    translated_content TEXT NOT NULL, -- English translation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(content_id, content_type, language_code),
    INDEX idx_content (content_type, content_id),
    INDEX idx_language (language_code)
);
```

### RBAC System Tables

```sql
-- Roles table (static roles)
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE, -- 'citizen', 'moderator', 'admin', 'superadmin'
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Permissions table (granular capabilities)
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE, -- 'create_topics', 'moderate_posts', 'view_graveyard', etc.
    description TEXT,
    is_dynamic BOOLEAN DEFAULT FALSE, -- true for loyalty-based permissions like 'create_topics'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Role permissions (static assignments)
CREATE TABLE role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (role_id, permission_id)
);

-- User permissions (dynamic overrides and loyalty-based grants)
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
- `GET /{topic_id}/posts` - Get posts in topic (paginated, chronological by submitted_at)

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
- **Primary Provider**: Anthropic (Claude models)
  - **Claude-3.5-Sonnet**: Moderation, Overlord chat, tagging
  - **Claude-3-Haiku**: Faster, simpler tasks
- **Secondary Provider**: OpenAI
  - **Translation tasks**: Faster and more cost-efficient for multilingual support

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
   - Evaluate posts and topics for logic, tone, and relevance
   - Generate in-character feedback for calibrations
   - Assign appropriate tags to topics and posts
   - Automatic approval/rejection (no manual admin step for MVP)

2. **Chat Interface**
   - Session-aware and role-aware responses (knows username, loyalty score, Graveyard count)
   - No persistent memory across sessions in MVP
   - Answer questions about rules and policies
   - Help users discover debates and topics using RAG over indexed content
   - Provide guidance on improving post quality
   - Role-specific capabilities:
     - Citizens: General guidance and commentary
     - Moderators: Inline moderation actions via chat
     - Admins & Super Admins: Elevated tools and actions
   - Communicate sanctions and rate limits as chat messages

3. **Tag Assignment**
   - Automatically categorize content based on themes
   - Maintain consistency in tagging across the platform
   - Admins and Super Admins can override Overlord tag assignments

4. **Translation Services**
   - Translate non-English submissions to canonical English storage
   - Persist translations to avoid repeat LLM calls

5. **Private Message Moderation**
   - Uses identical evaluation criteria as public posts (logic, tone, relevance)
   - Same AI agent and prompts as public content moderation
   - Moderation outcomes contribute equally to loyalty scores
   - Appeals process identical to public posts

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

### Queue Visualization (Hybrid Approach)

```python
class VisualizationController:
    def __init__(self):
        self.update_frequencies = {
            'queue_lengths': 2,      # Every 2 seconds - accurate data
            'capsule_positions': 10,  # Every 10 seconds - smooth animation
            'activity_levels': 5     # Every 5 seconds - visual appeal
        }
    
    async def generate_visualization_update(self):
        return {
            'queue_stats': await self.get_queue_lengths(),     # Real data
            'capsule_positions': await self.get_approximate_positions(), # Interpolated
            'activity_indicators': await self.get_activity_levels()     # Artistic
        }
```

**Visualization Strategy:**
- **Queue lengths are accurate** (users know exactly how many items ahead)
- **Capsule movement is smooth** but not perfectly synchronized with processing
- **Activity levels provide visual feedback** without performance cost
- **Sequential Processing Visualization**
  - Per-topic tubes show sequential processing within each topic to guarantee chronological order. Multiple topic tubes operate in parallel, showing that debates in different topics can proceed independently while maintaining order within each topic.
- **Graceful degradation** under high load

**Transport & Styling:**
- **WebSockets**: `WS /api/v1/queue/stream` with delta updates
- **Visual System**: Dynamic pneumatic tube network that grows/shrinks based on active queues
- **Layout**: Central hub with branching tubes for each active queue
- **Capsule Styles**: 
  - **Topics**: Red capsules with crown icons
  - **Posts**: Blue capsules with message icons  
  - **Private Messages**: Green capsules with lock icons
- **Performance**: Same payload regardless of user count, updates batched for efficiency

### Event Schema

**Permission-Based Content Filtering:**
- `preview` field is conditionally populated based on user permissions
- Citizens and anonymous users receive `null` for preview content
- Only moderators with `content_preview` permission see actual content

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
            "preview": null, // Only populated for users with content_preview permission
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

### Configuration

```python
QUEUE_CONFIG = {
    'total_workers': 2,  # Start minimal, scale up as needed
    'worker_distribution': {
        'global_topics': {'min': 1, 'max': 1},      # Always ensure topic approval
        'topic_posts': {'min': 0, 'max': 1},        # Sequential processing per topic to guarantee chronological order
        'private_messages': {'min': 0, 'max': 1}    # Sequential processing per conversation pair
    },
    'circuit_breaker_threshold': timedelta(minutes=2),  # Quick reallocation
    'configurable_scaling': True,  # Support for N workers via config
    'ordering_strategy': {
        'posts': 'strict_fifo_per_topic',    # Sequential processing per topic to guarantee chronological display
        'private_messages': 'strict_fifo'    # Sequential processing to guarantee delivery order
    }
}
```

### Queue Orchestrator

```python
class QueueOrchestrator:
    def __init__(self, total_workers: int = 2):
        self.total_workers = total_workers
        self.worker_pool = WorkerPool(total_workers)
        self.active_queues = {}
        self.circuit_breaker_threshold = timedelta(minutes=2)
    
    async def distribute_workers(self):
        """Smart worker distribution with priority guarantees"""
        # Phase 1: Guarantee minimum workers for critical queues
        await self._assign_critical_workers()
        
        # Phase 2: Distribute remaining workers by demand
        await self._assign_demand_based_workers()
        
        # Phase 3: Handle queue lifecycle events
        await self._manage_queue_lifecycle()
    
    async def _assign_critical_workers(self):
        # Always ensure global topics queue has workers
        if await self.has_pending_items('global_topics'):
            await self.worker_pool.assign_workers('global_topics', min_workers=1)
    
    async def check_starvation(self):
        """Circuit breaker: reallocate workers for starved queues"""
        starved_queues = []
        
        for queue in await self.get_all_queues():
            oldest_item = await queue.get_oldest_pending_item()
            if oldest_item and self._is_starved(oldest_item, self.circuit_breaker_threshold):
                starved_queues.append(queue)
        
        if starved_queues:
            await self._emergency_worker_boost(starved_queues)

class WorkerPool:
    def __init__(self, total_workers: int = 2):
        self.total_workers = total_workers
        self.available_workers = total_workers
        self.assignments = {}
    
    async def scale_workers(self, new_total: int):
        """Support dynamic scaling without restart"""
        if new_total > self.total_workers:
            await self._spawn_workers(new_total - self.total_workers)
        elif new_total < self.total_workers:
            await self._terminate_workers(self.total_workers - new_total)
        self.total_workers = new_total
```

### Queue Lifecycle Management

```python
class QueueLifecycleManager:
    async def on_topic_approved(self, topic_id: str):
        """Create dedicated post queue only after topic approval"""
        queue_name = f"topic_{topic_id}"
        await self.create_queue(queue_name, queue_type='topic_posts')
        await self.orchestrator.register_queue(queue_name)
        
    async def on_topic_archived(self, topic_id: str):
        """Graceful queue shutdown"""
        queue_name = f"topic_{topic_id}"
        await self.drain_queue(queue_name)  # Process remaining items
        await self.delete_queue(queue_name)
        
    async def cleanup_idle_queues(self):
        """Periodic cleanup of empty queues"""
        for queue in await self.get_idle_queues(idle_minutes=30):
            if queue.depth == 0 and not queue.has_active_workers:
                await self.delete_queue(queue.name)
```

### FIFO Fallback Strategy

```python
class FIFOFallbackProcessor:
    """Dead-simple fallback when orchestration fails"""
    def __init__(self):
        self.processing_order = [
            'topic_creation_queue',
            'post_moderation_queue',  # Sequential processing per topic to guarantee chronological display
            'private_message_queue'   # Sequential processing per conversation pair
        ]
    
    async def process_all_queues(self):
        """Process everything in creation order - bulletproof but slower"""
        while True:
            processed_any = False
            
            for table_name in self.processing_order:
                item = await self.get_oldest_pending_item(table_name)
                if item:
                    await self.process_item_simple(item)
                    processed_any = True
                    break  # Process one item, then check all queues again
            
            if not processed_any:
                await asyncio.sleep(1)  # No work available
    
    async def get_oldest_pending_item(self, table_name: str):
        """Get single oldest item across ALL queues of this type"""
        query = f"""
        SELECT * FROM {table_name} 
        WHERE status = 'pending' 
        ORDER BY priority_score ASC 
        LIMIT 1
        """
        return await self.db.fetch_one(query)

class SystemHealthMonitor:
    async def check_orchestration_health(self):
        try:
            await self.orchestrator.distribute_workers()
            await self.orchestrator.check_queue_health()
            return "healthy"
        except Exception as e:
            logger.error(f"Orchestration failed: {e}")
            await self.activate_fifo_fallback()
            return "fallback_active"
    
    async def activate_fifo_fallback(self):
        # Stop sophisticated processing
        await self.orchestrator.shutdown_gracefully()
        
        # Start simple FIFO processor
        self.fifo_processor = FIFOFallbackProcessor()
        asyncio.create_task(self.fifo_processor.process_all_queues())
        
        # Alert administrators
        await self.send_alert("Queue system in FIFO fallback mode")
    
    async def attempt_orchestration_recovery(self):
        """Try to restore sophisticated processing every 5 minutes"""
        while self.in_fallback_mode:
            await asyncio.sleep(300)  # 5 minutes
            
            try:
                test_orchestrator = QueueOrchestrator()
                await test_orchestrator.health_check()
                
                await self.switch_to_orchestrated_mode()
                logger.info("Restored sophisticated queue processing")
                break
                
            except Exception:
                logger.info("Orchestration still unhealthy, continuing FIFO fallback")
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