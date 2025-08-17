# Database Access Layer Architecture

## Overview

Raw SQL database access layer using asyncpg with connection pooling, query organization, and type safety for optimal performance.

## Core Architecture

### Connection Management

```python
# database/connection.py
import asyncpg
import asyncio
from typing import Optional
from contextlib import asynccontextmanager

class DatabasePool:
    def __init__(self):
        self.pool: Optional[asyncpg.Pool] = None
    
    async def initialize(
        self, 
        database_url: str,
        min_size: int = 10,
        max_size: int = 20,
        command_timeout: int = 60
    ):
        """Initialize connection pool"""
        self.pool = await asyncpg.create_pool(
            database_url,
            min_size=min_size,
            max_size=max_size,
            command_timeout=command_timeout,
            server_settings={
                'application_name': 'robot_overlord_api',
                'jit': 'off'  # Disable JIT for consistent performance
            }
        )
    
    async def close(self):
        """Close connection pool"""
        if self.pool:
            await self.pool.close()
    
    @asynccontextmanager
    async def acquire(self):
        """Get connection from pool"""
        async with self.pool.acquire() as connection:
            yield connection
    
    async def execute(self, query: str, *args):
        """Execute query with automatic connection management"""
        async with self.acquire() as conn:
            return await conn.fetch(query, *args)
    
    async def execute_one(self, query: str, *args):
        """Execute query expecting single result"""
        async with self.acquire() as conn:
            return await conn.fetchrow(query, *args)
    
    async def execute_many(self, query: str, args_list):
        """Execute query with multiple parameter sets"""
        async with self.acquire() as conn:
            return await conn.executemany(query, args_list)

# Global database pool instance
db_pool = DatabasePool()
```

### Base Repository Pattern

```python
# database/base_repository.py
from typing import List, Optional, Dict, Any, TypeVar, Generic
from dataclasses import dataclass
import asyncpg
from .connection import db_pool

T = TypeVar('T')

class BaseRepository(Generic[T]):
    def __init__(self, table_name: str, model_class: type):
        self.table_name = table_name
        self.model_class = model_class
    
    def _row_to_model(self, row: asyncpg.Record) -> T:
        """Convert database row to model instance"""
        if row is None:
            return None
        return self.model_class(**dict(row))
    
    def _rows_to_models(self, rows: List[asyncpg.Record]) -> List[T]:
        """Convert database rows to model instances"""
        return [self._row_to_model(row) for row in rows]
    
    async def find_by_id(self, id: str) -> Optional[T]:
        """Find record by ID"""
        query = f"SELECT * FROM {self.table_name} WHERE id = $1"
        row = await db_pool.execute_one(query, id)
        return self._row_to_model(row)
    
    async def find_all(self, limit: int = 100, offset: int = 0) -> List[T]:
        """Find all records with pagination"""
        query = f"SELECT * FROM {self.table_name} ORDER BY created_at DESC LIMIT $1 OFFSET $2"
        rows = await db_pool.execute(query, limit, offset)
        return self._rows_to_models(rows)
    
    async def create(self, **kwargs) -> T:
        """Create new record"""
        columns = ', '.join(kwargs.keys())
        placeholders = ', '.join(f'${i+1}' for i in range(len(kwargs)))
        values = list(kwargs.values())
        
        query = f"""
            INSERT INTO {self.table_name} ({columns})
            VALUES ({placeholders})
            RETURNING *
        """
        row = await db_pool.execute_one(query, *values)
        return self._row_to_model(row)
    
    async def update(self, id: str, **kwargs) -> Optional[T]:
        """Update record by ID"""
        if not kwargs:
            return await self.find_by_id(id)
        
        set_clause = ', '.join(f'{key} = ${i+2}' for i, key in enumerate(kwargs.keys()))
        values = [id] + list(kwargs.values())
        
        query = f"""
            UPDATE {self.table_name}
            SET {set_clause}, updated_at = NOW()
            WHERE id = $1
            RETURNING *
        """
        row = await db_pool.execute_one(query, *values)
        return self._row_to_model(row)
    
    async def delete(self, id: str) -> bool:
        """Delete record by ID"""
        query = f"DELETE FROM {self.table_name} WHERE id = $1"
        result = await db_pool.execute(query, id)
        return len(result) > 0
```

## Domain-Specific Repositories

### User Repository

```python
# database/repositories/user_repository.py
from typing import List, Optional
from dataclasses import dataclass
from datetime import datetime
from ..base_repository import BaseRepository
from ..connection import db_pool

@dataclass
class User:
    id: str
    email: str
    google_id: str
    username: str
    role: str
    loyalty_score: int
    is_banned: bool
    is_sanctioned: bool
    email_verified: bool
    created_at: datetime
    updated_at: datetime

class UserRepository(BaseRepository[User]):
    def __init__(self):
        super().__init__('users', User)
    
    async def find_by_email(self, email: str) -> Optional[User]:
        """Find user by email"""
        query = "SELECT * FROM users WHERE email = $1"
        row = await db_pool.execute_one(query, email)
        return self._row_to_model(row)
    
    async def find_by_google_id(self, google_id: str) -> Optional[User]:
        """Find user by Google ID"""
        query = "SELECT * FROM users WHERE google_id = $1"
        row = await db_pool.execute_one(query, google_id)
        return self._row_to_model(row)
    
    async def get_leaderboard(self, limit: int = 100, offset: int = 0) -> List[User]:
        """Get users from materialized leaderboard view"""
        query = """
            SELECT u.id, u.email, u.google_id, u.username, u.role, 
                   u.loyalty_score, u.is_banned, u.is_sanctioned, 
                   u.email_verified, u.created_at, u.updated_at
            FROM user_leaderboard ul
            JOIN users u ON ul.user_id = u.id
            ORDER BY ul.rank
            LIMIT $1 OFFSET $2
        """
        rows = await db_pool.execute(query, limit, offset)
        return self._rows_to_models(rows)
    
    async def get_top_topic_creators(self) -> List[User]:
        """Get users who can create topics (top 10%)"""
        query = """
            SELECT u.id, u.email, u.google_id, u.username, u.role, 
                   u.loyalty_score, u.is_banned, u.is_sanctioned, 
                   u.email_verified, u.created_at, u.updated_at
            FROM user_leaderboard ul
            JOIN users u ON ul.user_id = u.id
            WHERE ul.can_create_topics = true
            ORDER BY ul.rank
        """
        rows = await db_pool.execute(query)
        return self._rows_to_models(rows)
    
    async def update_loyalty_score(self, user_id: str, score_delta: int) -> int:
        """Atomically update loyalty score and return new score"""
        query = """
            UPDATE users 
            SET loyalty_score = loyalty_score + $1, updated_at = NOW()
            WHERE id = $2
            RETURNING loyalty_score
        """
        row = await db_pool.execute_one(query, score_delta, user_id)
        return row['loyalty_score'] if row else 0
```

### Queue Repository

```python
# database/repositories/queue_repository.py
from typing import List, Optional, Dict
from dataclasses import dataclass
from datetime import datetime
from ..base_repository import BaseRepository
from ..connection import db_pool

@dataclass
class QueueItem:
    id: str
    content_id: str
    priority_score: int
    priority: int
    position_in_queue: int
    status: str
    entered_queue_at: datetime
    estimated_completion_at: Optional[datetime]
    worker_assigned_at: Optional[datetime]
    worker_id: Optional[str]

class QueueRepository:
    async def add_to_topic_queue(self, topic_id: str, priority_score: int = 0) -> QueueItem:
        """Add topic to creation queue"""
        query = """
            WITH next_position AS (
                SELECT COALESCE(MAX(position_in_queue), 0) + 1 as pos
                FROM topic_creation_queue
            )
            INSERT INTO topic_creation_queue 
            (topic_id, position_in_queue, priority_score, entered_queue_at)
            SELECT $1, pos, $2, NOW()
            FROM next_position
            RETURNING *
        """
        row = await db_pool.execute_one(query, topic_id, priority_score)
        return QueueItem(
            id=row['id'],
            content_id=row['topic_id'],
            priority_score=row['priority_score'],
            priority=row['priority'],
            position_in_queue=row['position_in_queue'],
            status=row['status'],
            entered_queue_at=row['entered_queue_at'],
            estimated_completion_at=row['estimated_completion_at'],
            worker_assigned_at=row['worker_assigned_at'],
            worker_id=row['worker_id']
        )
    
    async def add_to_post_queue(self, post_id: str, topic_id: str, priority_score: int = 0) -> QueueItem:
        """Add post to moderation queue for specific topic"""
        query = """
            WITH next_position AS (
                SELECT COALESCE(MAX(position_in_queue), 0) + 1 as pos
                FROM post_moderation_queue 
                WHERE topic_id = $2
            )
            INSERT INTO post_moderation_queue 
            (post_id, topic_id, position_in_queue, priority_score, entered_queue_at)
            SELECT $1, $2, pos, $3, NOW()
            FROM next_position
            RETURNING *
        """
        row = await db_pool.execute_one(query, post_id, topic_id, priority_score)
        return QueueItem(
            id=row['id'],
            content_id=row['post_id'],
            priority_score=row['priority_score'],
            priority=row['priority'],
            position_in_queue=row['position_in_queue'],
            status=row['status'],
            entered_queue_at=row['entered_queue_at'],
            estimated_completion_at=row['estimated_completion_at'],
            worker_assigned_at=row['worker_assigned_at'],
            worker_id=row['worker_id']
        )
    
    async def get_next_in_queue(self, queue_type: str, context: Dict = None) -> Optional[QueueItem]:
        """Get next item from specified queue"""
        if queue_type == "topic_creation_queue":
            query = """
                SELECT * FROM topic_creation_queue
                WHERE status = 'pending'
                ORDER BY priority_score DESC, entered_queue_at ASC
                LIMIT 1
            """
            row = await db_pool.execute_one(query)
        elif queue_type == "post_moderation_queue" and context.get("topic_id"):
            query = """
                SELECT * FROM post_moderation_queue
                WHERE topic_id = $1 AND status = 'pending'
                ORDER BY priority_score DESC, entered_queue_at ASC
                LIMIT 1
            """
            row = await db_pool.execute_one(query, context["topic_id"])
        else:
            return None
        
        if not row:
            return None
        
        return QueueItem(
            id=row['id'],
            content_id=row.get('topic_id') or row.get('post_id'),
            priority_score=row['priority_score'],
            priority=row['priority'],
            position_in_queue=row['position_in_queue'],
            status=row['status'],
            entered_queue_at=row['entered_queue_at'],
            estimated_completion_at=row['estimated_completion_at'],
            worker_assigned_at=row['worker_assigned_at'],
            worker_id=row['worker_id']
        )
    
    async def remove_from_queue(self, content_id: str, queue_type: str):
        """Remove item from queue and update positions"""
        if queue_type == "topic_creation_queue":
            # Remove and get position
            removed_query = """
                DELETE FROM topic_creation_queue 
                WHERE topic_id = $1 
                RETURNING position_in_queue
            """
            removed = await db_pool.execute_one(removed_query, content_id)
            
            if removed:
                # Update positions
                update_query = """
                    UPDATE topic_creation_queue 
                    SET position_in_queue = position_in_queue - 1
                    WHERE position_in_queue > $1
                """
                await db_pool.execute(update_query, removed['position_in_queue'])
        
        elif queue_type == "post_moderation_queue":
            # Remove and get position + topic
            removed_query = """
                DELETE FROM post_moderation_queue 
                WHERE post_id = $1 
                RETURNING position_in_queue, topic_id
            """
            removed = await db_pool.execute_one(removed_query, content_id)
            
            if removed:
                # Update positions within topic
                update_query = """
                    UPDATE post_moderation_queue 
                    SET position_in_queue = position_in_queue - 1
                    WHERE topic_id = $1 AND position_in_queue > $2
                """
                await db_pool.execute(update_query, removed['topic_id'], removed['position_in_queue'])
```

## Service Layer Integration

```python
# services/loyalty_service.py
from database.repositories.user_repository import UserRepository
from database.connection import db_pool
import redis.asyncio as redis

class LoyaltyService:
    def __init__(self, redis_client: redis.Redis):
        self.user_repo = UserRepository()
        self.redis = redis_client
        self._SCORE_MULTIPLIERS = {
            "post": 1,
            "topic": 5,
            "private_message": 1
        }
    
    async def record_moderation_event(
        self, 
        user_id: str, 
        event_type: str,
        content_type: str, 
        content_id: str, 
        outcome: str
    ) -> int:
        """Record moderation event with incremental score update"""
        score_delta = self._calculate_score_delta(content_type, outcome)
        
        # Atomic score update
        new_score = await self.user_repo.update_loyalty_score(user_id, score_delta)
        
        # Update Redis cache
        await self.redis.set(f"loyalty:{user_id}", new_score, ex=3600)
        
        # Store event for audit trail
        await db_pool.execute("""
            INSERT INTO moderation_events 
            (user_id, event_type, content_type, content_id, outcome)
            VALUES ($1, $2, $3, $4, $5)
        """, user_id, event_type, content_type, content_id, outcome)
        
        return new_score
    
    def _calculate_score_delta(self, content_type: str, outcome: str) -> int:
        """Calculate incremental score change"""
        base_score = self._SCORE_MULTIPLIERS.get(content_type, 1)
        
        if outcome == "approved":
            return base_score
        elif outcome == "rejected":
            return -base_score
        else:  # calibrated
            return 0
```

## Usage Example

```python
# main.py
from database.connection import db_pool
from database.repositories.user_repository import UserRepository
from services.loyalty_service import LoyaltyService
import redis.asyncio as redis

async def main():
    # Initialize database pool
    await db_pool.initialize("postgresql://user:pass@localhost/robotoverlord")
    
    # Initialize Redis
    redis_client = redis.from_url("redis://localhost:6379")
    
    # Initialize services
    user_repo = UserRepository()
    loyalty_service = LoyaltyService(redis_client)
    
    # Example usage
    user = await user_repo.find_by_email("user@example.com")
    if user:
        new_score = await loyalty_service.record_moderation_event(
            user.id, "post_moderated", "post", "post_123", "approved"
        )
        print(f"User {user.username} new loyalty score: {new_score}")
    
    # Cleanup
    await db_pool.close()
    await redis_client.close()
```

---

**Related Documentation:**
- [Database Schema](./05-database-schema.md) - Core database structure
- [Database Migration System](./19-database-migrations.md) - Migration strategy
- [Performance Optimization](./17-database-performance-optimization.md) - Performance patterns
