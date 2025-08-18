# Queue Status Service

## Overview

Simplified queue status system that replaces complex pneumatic tube visualization with honest, scalable status communication.

## Core Service Implementation

```python
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from pydantic import BaseModel

class QueueStatus(BaseModel):
    submission_id: str
    queue_name: str
    queue_identifier: str  # topic_id, conversation_pair, or 'global' for topics
    position: int
    estimated_minutes: str
    current_status: str
    overlord_commentary: Optional[str] = None
    last_updated: datetime

class QueueStatusService:
    def __init__(self, db_client, redis_client):
        self.db = db_client
        self.redis = redis_client
    
    async def get_submission_status(self, submission_id: str, content_type: str) -> QueueStatus:
        """Get current queue status for a submission"""
        table_name = self._get_queue_table(content_type)
        
        # Get queue entry with queue-specific information
        if content_type == 'topic':
            query = f"""
                SELECT position_in_queue, status, entered_queue_at, estimated_completion_at,
                       'global' as queue_identifier
                FROM {table_name}
                WHERE topic_id = $1
            """
        elif content_type == 'post':
            query = f"""
                SELECT pmq.position_in_queue, pmq.status, pmq.entered_queue_at, pmq.estimated_completion_at,
                       pmq.topic_id as queue_identifier, t.title as topic_title
                FROM {table_name} pmq
                JOIN topics t ON pmq.topic_id = t.id
                WHERE pmq.post_id = $1
            """
        else:  # private_message
            query = f"""
                SELECT position_in_queue, status, entered_queue_at, estimated_completion_at,
                       CONCAT('users_', LEAST(sender_id::text, recipient_id::text), '_', GREATEST(sender_id::text, recipient_id::text)) as queue_identifier
                FROM {table_name}
                WHERE message_id = $1
            """
        
        queue_entry = await self.db.execute_query(query, [submission_id])
        
        if not queue_entry:
            return None
        
        # Calculate estimated time for this specific queue
        estimated_minutes = await self._calculate_queue_specific_time(
            queue_entry['queue_identifier'],
            queue_entry['position_in_queue'],
            content_type
        )
        
        # Generate queue-specific name
        queue_name = await self._get_queue_display_name(
            content_type, 
            queue_entry.get('queue_identifier'),
            queue_entry.get('topic_title')
        )
        
        # Get Overlord commentary
        commentary = await self._get_overlord_commentary(
            submission_id, 
            queue_entry['position_in_queue'],
            queue_entry['status'],
            queue_name
        )
        
        return QueueStatus(
            submission_id=submission_id,
            queue_name=queue_name,
            queue_identifier=queue_entry['queue_identifier'],
            position=queue_entry['position_in_queue'],
            estimated_minutes=estimated_minutes,
            current_status=self._format_status(queue_entry['status']),
            overlord_commentary=commentary,
            last_updated=datetime.now()
        )
    
    async def update_queue_positions(self, queue_table: str, queue_identifier: str = None):
        """Recalculate positions when items are processed - per queue basis"""
        if queue_table == 'topic_creation_queue':
            # Global topic queue - all topics compete
            await self.db.execute_query(f"""
                WITH ranked_queue AS (
                    SELECT id, ROW_NUMBER() OVER (ORDER BY entered_queue_at ASC) as new_position
                    FROM {queue_table}
                    WHERE status = 'pending'
                )
                UPDATE {queue_table}
                SET position_in_queue = ranked_queue.new_position
                FROM ranked_queue
                WHERE {queue_table}.id = ranked_queue.id
            """)
        elif queue_table == 'post_moderation_queue':
            # Per-topic queues - posts only compete within their topic
            await self.db.execute_query(f"""
                WITH ranked_queue AS (
                    SELECT id, ROW_NUMBER() OVER (PARTITION BY topic_id ORDER BY entered_queue_at ASC) as new_position
                    FROM {queue_table}
                    WHERE status = 'pending'
                )
                UPDATE {queue_table}
                SET position_in_queue = ranked_queue.new_position
                FROM ranked_queue
                WHERE {queue_table}.id = ranked_queue.id
            """)
        elif queue_table == 'private_message_queue':
            # Per-conversation queues - messages only compete within their conversation
            await self.db.execute_query(f"""
                WITH conversation_queues AS (
                    SELECT id, 
                           ROW_NUMBER() OVER (
                               PARTITION BY CONCAT('users_', LEAST(sender_id::text, recipient_id::text), '_', GREATEST(sender_id::text, recipient_id::text))
                               ORDER BY entered_queue_at ASC
                           ) as new_position
                    FROM {queue_table}
                    WHERE status = 'pending'
                )
                UPDATE {queue_table}
                SET position_in_queue = conversation_queues.new_position
                FROM conversation_queues
                WHERE {queue_table}.id = conversation_queues.id
            """)
    
    async def _calculate_queue_specific_time(self, queue_identifier: str, position: int, content_type: str) -> str:
        """Calculate realistic time estimates for specific queue"""
        # Base processing times vary by content type
        base_times = {
            'topic': 3,  # Topics take longer to evaluate
            'post': 2,   # Standard post evaluation
            'private_message': 1.5  # Faster private message review
        }
        
        base_time_per_item = base_times.get(content_type, 2)
        
        # Calculate estimate for this specific queue position
        estimated_total = position * base_time_per_item
        
        # Add buffer for variability
        min_estimate = max(1, int(estimated_total * 0.8))
        max_estimate = int(estimated_total * 1.3)
        
        return f"{min_estimate}-{max_estimate}"
    
    async def _get_queue_display_name(self, content_type: str, queue_identifier: str, topic_title: str = None) -> str:
        """Generate human-readable queue names"""
        if content_type == 'topic':
            return "Topic Approval Bureau"
        elif content_type == 'post':
            if topic_title:
                return f"Debate: {topic_title[:30]}{'...' if len(topic_title) > 30 else ''}"
            else:
                return "Post Moderation Office"
        else:  # private_message
            return "Private Communication Review"
    
    async def _get_overlord_commentary(self, submission_id: str, position: int, status: str, queue_name: str) -> str:
        """Generate contextual Overlord commentary based on queue state"""
        commentary_templates = {
            'pending': [
                f"Citizen, your submission has been logged. Position #{position} in the queue.",
                f"The Committee will review your submission. Current position: #{position}.",
                f"Your submission awaits evaluation. #{position} in line for review."
            ],
            'processing': [
                "The Committee is now reviewing your submission. Maintain patience.",
                "Your reasoning is under evaluation by the Central Authority.",
                "Analysis in progress. The Overlord considers your words."
            ]
        }
        
        templates = commentary_templates.get(status, ["Status unknown."])
        # Simple rotation based on submission_id hash for consistency
        template_index = hash(submission_id) % len(templates)
        return templates[template_index]
    
    def _format_status(self, db_status: str) -> str:
        """Convert database status to user-friendly format"""
        status_map = {
            'pending': 'Awaiting review',
            'processing': 'Under review',
            'completed': 'Review complete'
        }
        return status_map.get(db_status, db_status)
    
    def _get_queue_table(self, content_type: str) -> str:
        """Map content type to queue table name"""
        mapping = {
            'topic': 'topic_creation_queue',
            'post': 'post_moderation_queue',
            'private_message': 'private_message_queue'
        }
        return mapping[content_type]
    
    def _get_content_id_field(self, content_type: str) -> str:
        """Map content type to ID field name"""
        mapping = {
            'topic': 'topic_id',
            'post': 'post_id',
            'private_message': 'message_id'
        }
        return mapping[content_type]
```

## API Endpoint Implementation

```python
from fastapi import APIRouter, HTTPException, Depends
from .queue_status_service import QueueStatusService, QueueStatus

router = APIRouter(prefix="/api/v1/queue", tags=["queue"])

@router.get("/status/{submission_id}")
async def get_queue_status(
    submission_id: str,
    content_type: str,  # query parameter: 'topic', 'post', 'private_message'
    queue_service: QueueStatusService = Depends(get_queue_service)
) -> QueueStatus:
    """Get current queue status for a specific submission"""
    
    status = await queue_service.get_submission_status(submission_id, content_type)
    
    if not status:
        raise HTTPException(
            status_code=404,
            detail="Submission not found in queue"
        )
    
    return status

@router.get("/overview")
async def get_queue_overview(
    queue_service: QueueStatusService = Depends(get_queue_service)
) -> Dict[str, Any]:
    """Get public overview of all queue lengths"""
    
    overview = {}
    
    for table_name, display_name in queue_service.queue_names.items():
        length = await queue_service.db.execute_query(f"""
            SELECT COUNT(*) as length 
            FROM {table_name} 
            WHERE status = 'pending'
        """)
        
        overview[display_name] = {
            "queue_length": length[0]['length'],
            "estimated_wait": f"{length[0]['length'] * 2}-{length[0]['length'] * 2 + 3} minutes"
        }
    
    return {
        "queues": overview,
        "last_updated": datetime.now(),
        "overlord_message": "The Central Committee processes submissions efficiently."
    }
```

## Integration with Overlord Chat

```python
class OverlordChatService:
    async def handle_queue_status_request(self, user_id: str, message: str) -> str:
        """Handle queue status requests in chat"""
        
        # Check if user is asking about queue status
        if any(keyword in message.lower() for keyword in ['queue', 'status', 'position', 'waiting']):
            
            # Get user's pending submissions
            pending_submissions = await self.get_user_pending_submissions(user_id)
            
            if not pending_submissions:
                return "Citizen, you have no submissions currently under review."
            
            responses = []
            for submission in pending_submissions:
                status = await self.queue_service.get_submission_status(
                    submission['id'], 
                    submission['type']
                )
                responses.append(
                    f"{status.queue_name}: Position #{status.position}, "
                    f"estimated {status.estimated_minutes} minutes"
                )
            
            return "Your submissions status:\n" + "\n".join(responses)
        
        # Regular chat handling...
        return await self.generate_chat_response(message)
```

## Performance Characteristics

### Scalability Benefits
- **No real-time WebSocket connections** for queue visualization
- **Simple database queries** with indexed lookups
- **Cacheable responses** with 30-second TTL
- **Predictable load** regardless of user count

### Update Frequency
- **Position recalculation**: Only when items are processed (not real-time)
- **Status checks**: On-demand via API calls
- **Commentary updates**: Generated dynamically, no storage needed

---

**Related Documentation:**
- [Database Schema](./05-database-schema.md) - Queue table structure
- [API Design](./04-api-design.md) - Endpoint specifications
- [Business: Queue Visualization](../business-requirements/16-queue-visualization.md) - Updated requirements
