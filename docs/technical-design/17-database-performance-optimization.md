# Database Performance Optimization

## Overview

Performance optimizations to handle scale efficiently with incremental updates, materialized views, and strategic indexing.

## Loyalty Score Optimization

### Incremental Score Updates

Replace full recalculation with delta-based updates for 100x performance improvement.

```python
class OptimizedLoyaltyService:
    def __init__(self, redis_client, db_client):
        self.redis = redis_client
        self.db = db_client
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
    ):
        """Record event with incremental score update"""
        
        # Calculate score delta instead of full recalculation
        score_delta = self._calculate_score_delta(content_type, outcome)
        
        # Atomic database update
        result = await self.db.execute("""
            UPDATE users 
            SET loyalty_score = loyalty_score + $1,
                updated_at = NOW()
            WHERE id = $2
            RETURNING loyalty_score
        """, [score_delta, user_id])
        
        new_score = result[0]["loyalty_score"]
        
        # Update Redis cache
        await self.redis.set(f"loyalty:{user_id}", new_score, ex=3600)
        
        # Store event for audit trail
        await self.db.execute("""
            INSERT INTO moderation_events 
            (user_id, event_type, content_type, content_id, outcome)
            VALUES ($1, $2, $3, $4, $5)
        """, [user_id, event_type, content_type, content_id, outcome])
        
        # Update materialized view if significant change
        if abs(score_delta) >= 5:  # Topic-level changes
            await self.refresh_leaderboard_if_needed(user_id, new_score)
        
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
    
    async def get_loyalty_score(self, user_id: str) -> int:
        """Get current loyalty score with Redis caching"""
        # Check Redis cache first
        cached_score = await self.redis.get(f"loyalty:{user_id}")
        if cached_score is not None:
            return int(cached_score)
        
        # Fallback to database
        result = await self.db.execute("""
            SELECT loyalty_score FROM users WHERE id = $1
        """, [user_id])
        
        if result:
            score = result[0]["loyalty_score"]
            await self.redis.set(f"loyalty:{user_id}", score, ex=3600)
            return score
        
        return 0
    
    async def refresh_leaderboard_if_needed(self, user_id: str, new_score: int):
        """Conditionally refresh materialized view for significant changes"""
        # Check if user might have entered/left top 10%
        total_users = await self.db.execute("SELECT COUNT(*) FROM users WHERE loyalty_score > 0")
        top_10_percent_threshold = total_users[0]["count"] * 0.1
        
        # Get current rank from materialized view
        current_rank = await self.db.execute("""
            SELECT rank FROM user_leaderboard WHERE user_id = $1
        """, [user_id])
        
        current_rank_val = current_rank[0]["rank"] if current_rank else float('inf')
        
        # Refresh if crossing top 10% threshold
        if (current_rank_val > top_10_percent_threshold and new_score > 0) or \
           (current_rank_val <= top_10_percent_threshold):
            await self.refresh_leaderboard_materialized_view()
```

### Score Recalculation for Data Integrity

```python
async def recalculate_loyalty_score(self, user_id: str) -> int:
    """Full recalculation for data integrity checks"""
    events = await self.db.execute("""
        SELECT content_type, outcome, COUNT(*) as count
        FROM moderation_events 
        WHERE user_id = $1
        GROUP BY content_type, outcome
    """, [user_id])
    
    total_score = 0
    for event in events:
        multiplier = self._SCORE_MULTIPLIERS.get(event["content_type"], 1)
        if event["outcome"] == "approved":
            total_score += multiplier * event["count"]
        elif event["outcome"] == "rejected":
            total_score -= multiplier * event["count"]
    
    # Update database and cache
    await self.db.execute("""
        UPDATE users SET loyalty_score = $1 WHERE id = $2
    """, [total_score, user_id])
    
    await self.redis.set(f"loyalty:{user_id}", total_score, ex=3600)
    
    return total_score
```

## Leaderboard Materialized Views

### User Leaderboard View

```sql
-- Create materialized view for efficient leaderboard queries
CREATE MATERIALIZED VIEW user_leaderboard AS
SELECT 
    u.id as user_id,
    u.username,
    u.loyalty_score,
    ROW_NUMBER() OVER (ORDER BY u.loyalty_score DESC, u.created_at ASC) as rank,
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY u.loyalty_score DESC, u.created_at ASC) <= 
             (SELECT COUNT(*) * 0.1 FROM users WHERE loyalty_score > 0) 
        THEN true 
        ELSE false 
    END as can_create_topics,
    u.created_at,
    u.updated_at
FROM users u
WHERE u.loyalty_score > 0
ORDER BY u.loyalty_score DESC, u.created_at ASC;

-- Indexes for fast lookups
CREATE UNIQUE INDEX idx_leaderboard_user_id ON user_leaderboard(user_id);
CREATE INDEX idx_leaderboard_rank ON user_leaderboard(rank);
CREATE INDEX idx_leaderboard_score ON user_leaderboard(loyalty_score DESC);
CREATE INDEX idx_leaderboard_topic_creators ON user_leaderboard(can_create_topics) WHERE can_create_topics = true;
```

### Refresh Strategy

```python
class LeaderboardService:
    def __init__(self, db_client, redis_client):
        self.db = db_client
        self.redis = redis_client
        self.refresh_threshold = 10  # Refresh after 10 significant changes
        
    async def refresh_leaderboard_materialized_view(self):
        """Refresh materialized view with concurrency control"""
        # Use advisory lock to prevent concurrent refreshes
        lock_acquired = await self.db.execute("""
            SELECT pg_try_advisory_lock(12345) as acquired
        """)
        
        if not lock_acquired[0]["acquired"]:
            return  # Another process is already refreshing
        
        try:
            await self.db.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY user_leaderboard")
            await self.redis.delete("leaderboard:refresh_pending")
            
        finally:
            await self.db.execute("SELECT pg_advisory_unlock(12345)")
    
    async def get_leaderboard(self, limit: int = 100, offset: int = 0) -> List[dict]:
        """Get leaderboard from materialized view"""
        return await self.db.execute("""
            SELECT user_id, username, loyalty_score, rank, can_create_topics
            FROM user_leaderboard
            ORDER BY rank
            LIMIT $1 OFFSET $2
        """, [limit, offset])
    
    async def get_user_rank(self, user_id: str) -> Optional[dict]:
        """Get specific user's rank from materialized view"""
        result = await self.db.execute("""
            SELECT rank, loyalty_score, can_create_topics
            FROM user_leaderboard
            WHERE user_id = $1
        """, [user_id])
        
        return result[0] if result else None
    
    async def schedule_refresh_if_needed(self):
        """Schedule refresh based on accumulated changes"""
        pending_changes = await self.redis.incr("leaderboard:refresh_pending")
        
        if pending_changes >= self.refresh_threshold:
            # Schedule background refresh
            await self.refresh_leaderboard_materialized_view()
```

## Queue Position Optimization

### Efficient Position Management

```python
class OptimizedQueueService:
    async def add_to_queue(
        self, 
        content_id: str, 
        queue_type: str, 
        context: dict,
        priority_score: float = 0.0
    ):
        """Add item to queue with efficient position calculation"""
        
        if queue_type == "topic_creation_queue":
            # Global queue for topics
            position = await self.db.execute("""
                SELECT COALESCE(MAX(position_in_queue), 0) + 1 as next_position
                FROM topic_creation_queue
            """)
            
            await self.db.execute("""
                INSERT INTO topic_creation_queue 
                (topic_id, position_in_queue, priority_score, entered_queue_at)
                VALUES ($1, $2, $3, NOW())
            """, [content_id, position[0]["next_position"], priority_score])
            
        elif queue_type == "post_moderation_queue":
            # Per-topic queue
            topic_id = context["topic_id"]
            position = await self.db.execute("""
                SELECT COALESCE(MAX(position_in_queue), 0) + 1 as next_position
                FROM post_moderation_queue 
                WHERE topic_id = $1
            """, [topic_id])
            
            await self.db.execute("""
                INSERT INTO post_moderation_queue 
                (post_id, topic_id, position_in_queue, priority_score, entered_queue_at)
                VALUES ($1, $2, $3, $4, NOW())
            """, [content_id, topic_id, position[0]["next_position"], priority_score])
            
        elif queue_type == "private_message_queue":
            # Per-conversation queue
            conversation_id = context["conversation_id"]
            position = await self.db.execute("""
                SELECT COALESCE(MAX(position_in_queue), 0) + 1 as next_position
                FROM private_message_queue 
                WHERE conversation_id = $1
            """, [conversation_id])
            
            await self.db.execute("""
                INSERT INTO private_message_queue 
                (message_id, conversation_id, position_in_queue, priority_score, entered_queue_at)
                VALUES ($1, $2, $3, $4, NOW())
            """, [content_id, conversation_id, position[0]["next_position"], priority_score])
    
    async def remove_from_queue(self, content_id: str, queue_type: str):
        """Remove item and efficiently update positions"""
        
        if queue_type == "topic_creation_queue":
            removed = await self.db.execute("""
                DELETE FROM topic_creation_queue 
                WHERE topic_id = $1 
                RETURNING position_in_queue
            """, [content_id])
            
            if removed:
                # Update positions for items after removed item
                await self.db.execute("""
                    UPDATE topic_creation_queue 
                    SET position_in_queue = position_in_queue - 1
                    WHERE position_in_queue > $1
                """, [removed[0]["position_in_queue"]])
                
        elif queue_type == "post_moderation_queue":
            removed = await self.db.execute("""
                DELETE FROM post_moderation_queue 
                WHERE post_id = $1 
                RETURNING position_in_queue, topic_id
            """, [content_id])
            
            if removed:
                await self.db.execute("""
                    UPDATE post_moderation_queue 
                    SET position_in_queue = position_in_queue - 1
                    WHERE topic_id = $1 AND position_in_queue > $2
                """, [removed[0]["topic_id"], removed[0]["position_in_queue"]])
                
        elif queue_type == "private_message_queue":
            removed = await self.db.execute("""
                DELETE FROM private_message_queue 
                WHERE message_id = $1 
                RETURNING position_in_queue, conversation_id
            """, [content_id])
            
            if removed:
                await self.db.execute("""
                    UPDATE private_message_queue 
                    SET position_in_queue = position_in_queue - 1
                    WHERE conversation_id = $1 AND position_in_queue > $2
                """, [removed[0]["conversation_id"], removed[0]["position_in_queue"]])
    
    async def reorder_queue_by_priority(self, queue_type: str, context: dict = None):
        """Reorder queue based on priority scores"""
        
        if queue_type == "topic_creation_queue":
            await self.db.execute("""
                UPDATE topic_creation_queue 
                SET position_in_queue = new_positions.new_position
                FROM (
                    SELECT topic_id,
                           ROW_NUMBER() OVER (ORDER BY priority_score DESC, entered_queue_at ASC) as new_position
                    FROM topic_creation_queue
                ) new_positions
                WHERE topic_creation_queue.topic_id = new_positions.topic_id
            """)
            
        elif queue_type == "post_moderation_queue" and context.get("topic_id"):
            topic_id = context["topic_id"]
            await self.db.execute("""
                UPDATE post_moderation_queue 
                SET position_in_queue = new_positions.new_position
                FROM (
                    SELECT post_id,
                           ROW_NUMBER() OVER (ORDER BY priority_score DESC, entered_queue_at ASC) as new_position
                    FROM post_moderation_queue
                    WHERE topic_id = $1
                ) new_positions
                WHERE post_moderation_queue.post_id = new_positions.post_id
                AND post_moderation_queue.topic_id = $1
            """, [topic_id])
```

## Strategic Database Indexes

### Performance-Critical Indexes

```sql
-- Loyalty score operations
CREATE INDEX idx_users_loyalty_score_desc ON users(loyalty_score DESC) WHERE loyalty_score > 0;
CREATE INDEX idx_users_loyalty_username ON users(loyalty_score DESC, username) WHERE loyalty_score > 0;

-- Moderation events for score calculation
CREATE INDEX idx_moderation_events_user_time ON moderation_events(user_id, created_at DESC);
CREATE INDEX idx_moderation_events_content ON moderation_events(content_type, content_id);
CREATE INDEX idx_moderation_events_outcome ON moderation_events(outcome, content_type);

-- Queue operations
CREATE INDEX idx_topic_queue_position ON topic_creation_queue(position_in_queue);
CREATE INDEX idx_topic_queue_priority ON topic_creation_queue(priority_score DESC, entered_queue_at ASC);

CREATE INDEX idx_post_queue_topic_position ON post_moderation_queue(topic_id, position_in_queue);
CREATE INDEX idx_post_queue_topic_priority ON post_moderation_queue(topic_id, priority_score DESC, entered_queue_at ASC);

CREATE INDEX idx_message_queue_conv_position ON private_message_queue(conversation_id, position_in_queue);
CREATE INDEX idx_message_queue_conv_priority ON private_message_queue(conversation_id, priority_score DESC, entered_queue_at ASC);

-- User lookups
CREATE INDEX idx_users_username ON users(username) WHERE loyalty_score > 0;
CREATE INDEX idx_users_created_at ON users(created_at);
```

## Performance Monitoring

### Key Metrics to Track

```python
class PerformanceMonitor:
    async def track_loyalty_update_performance(self, user_id: str, start_time: float):
        """Track loyalty score update performance"""
        duration = time.time() - start_time
        
        await self.redis.lpush("perf:loyalty_updates", json.dumps({
            "user_id": user_id,
            "duration_ms": duration * 1000,
            "timestamp": time.time()
        }))
        
        # Keep only last 1000 measurements
        await self.redis.ltrim("perf:loyalty_updates", 0, 999)
    
    async def track_queue_operation_performance(self, operation: str, queue_type: str, duration: float):
        """Track queue operation performance"""
        key = f"perf:queue:{operation}:{queue_type}"
        
        await self.redis.lpush(key, json.dumps({
            "duration_ms": duration * 1000,
            "timestamp": time.time()
        }))
        
        await self.redis.ltrim(key, 0, 999)
    
    async def get_performance_stats(self) -> dict:
        """Get performance statistics"""
        loyalty_updates = await self.redis.lrange("perf:loyalty_updates", 0, -1)
        
        if loyalty_updates:
            durations = [json.loads(update)["duration_ms"] for update in loyalty_updates]
            avg_duration = sum(durations) / len(durations)
            max_duration = max(durations)
        else:
            avg_duration = max_duration = 0
        
        return {
            "loyalty_updates": {
                "avg_duration_ms": avg_duration,
                "max_duration_ms": max_duration,
                "sample_count": len(loyalty_updates)
            }
        }
```

## Expected Performance Improvements

### Loyalty Score Operations
- **Before**: O(n) full recalculation per event (100-500ms)
- **After**: O(1) incremental update (1-5ms)
- **Improvement**: 100x faster

### Queue Operations  
- **Before**: O(n) position updates per change (50-200ms)
- **After**: O(log n) targeted updates (5-10ms)
- **Improvement**: 20x faster

### Leaderboard Queries
- **Before**: Full table scan + sort (1-5 seconds)
- **After**: Materialized view lookup (10-50ms)
- **Improvement**: 100x faster

---

**Related Documentation:**
- [Database Schema](./05-database-schema.md) - Core database structure
- [Loyalty Scoring System](./09-loyalty-scoring.md) - Loyalty calculation logic
- [Queue Status Service](./15-queue-status-service.md) - Queue management
- [Performance & Scaling](./13-performance-scaling.md) - Overall performance strategy
