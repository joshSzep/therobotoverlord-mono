# Loyalty Scoring System

## Event-Driven Loyalty Score System

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
        # Calculate score delta for incremental update
        score_delta = self._calculate_score_delta(content_type, outcome)
        
        # Atomic database update with incremental score change
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
        
        # Trigger permission updates
        await self.update_dynamic_permissions(user_id)
        
        return new_score
    
    def _calculate_score_delta(self, content_type: str, outcome: str) -> int:
        """Calculate incremental score change"""
        multipliers = {"post": 1, "topic": 5, "private_message": 1}
        base_score = multipliers.get(content_type, 1)
        
        if outcome == "approved":
            return base_score
        elif outcome == "rejected":
            return -base_score
```

## Algorithm Properties

### Proprietary Calculation
- General factors disclosed to users (approved/rejected post ratios)
- Specific weights and calculations remain proprietary
- Real-time calculation with Redis caching
- Event-sourced for auditability and recalculation

### Content Type Weighting
- **Posts**: Base value (1x multiplier)
- **Topics**: Higher value (5x multiplier) - reflects greater effort and impact
- **Private Messages**: Base value (1x multiplier)

### Score Updates
- Real-time recalculation on each moderation outcome
- Cache invalidation triggers fresh calculation
- User record updated with new score
- Dynamic permissions updated based on new score

## Integration Points

### Moderation Pipeline
Every moderation outcome triggers:
1. Event recording in `moderation_events` table
2. Cache invalidation for affected user
3. Score recalculation and user record update
4. Dynamic permission evaluation and updates

### Permission System Integration
- Topic creation privilege: Top 10% by loyalty score
- Queue priority: Higher loyalty users get faster processing
- Appeal limits: Higher loyalty users get additional appeals

---

**Related Documentation:**
- [Business: Gamification & Reputation](../business-requirements/10-gamification-reputation.md) - Loyalty score requirements
- [Database Schema](./05-database-schema.md) - Moderation events table
- [RBAC & Permissions](./08-rbac-permissions.md) - Dynamic permission updates
