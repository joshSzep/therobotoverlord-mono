# Real-time Streaming

## Transport

**WebSockets**

## Flow

- Client authenticates via JWT at WS upgrade
- Worker publishes job output events into Redis Streams under `jobs:{job_id}:events`
- API WS handler subscribes to stream and forwards events to client
- **Overlord Commentary Streaming**: Workers can stream in-character commentary during processing via WebSocket connections

## Pydantic Event Models

```python
from pydantic import BaseModel
from typing import Any, Dict, Literal
from datetime import datetime

class EventType(str, Enum):
    TOKEN = "token"
    STATUS = "status"
    ERROR = "error"
    DONE = "done"
    COMMENTARY = "commentary"
    TOS_SCREENING = "tos_screening"
    TOS_VIOLATION = "tos_violation"

class StreamEvent(BaseModel):
    seq: int
    type: EventType
    ts: datetime
    payload: Dict[str, Any]
```

## Multi-Queue Architecture

### Queue Types

1. **Global Topics Queue** (`global_topics`)
   - Single queue for all topic creation requests
   - Strict FIFO processing order globally
   - One dedicated worker processes topics sequentially
   
2. **Per-Topic Posts Queues** (`posts_topic_{topic_id}`)
   - One queue per topic for posts and replies
   - Strict FIFO processing within each topic
   - Parallel processing across different topics
   - Maintains chronological order within topic discussions
   
3. **Per-Conversation Message Queues** (`messages_conv_{conversation_id}`)
   - One queue per conversation for private messages
   - Strict FIFO processing within each conversation
   - Parallel processing across different conversations
   - Ensures message delivery order within conversations
   - Maintains conversation context and ordering

## Queue Visualization (Hybrid Approach)

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

### Visualization Strategy

- **Queue lengths are accurate** (users know exactly how many items ahead)
- **Capsule movement is smooth** but not perfectly synchronized with processing
- **Activity levels provide visual feedback** without performance cost
- **Sequential Processing Visualization**
  - Per-topic tubes show sequential processing within each topic to guarantee chronological order. Multiple topic tubes operate in parallel, showing that debates in different topics can proceed independently while maintaining order within each topic.
- **Graceful degradation** under high load

### Transport & Styling

- **WebSockets**: `WS /api/v1/queue/stream` with delta updates
- **Visual System**: Dynamic pneumatic tube network that grows/shrinks based on active queues
- **Layout**: Central hub with branching tubes for each active queue
- **Capsule Styles**: 
  - **Topics**: Red capsules with crown icons
  - **Posts**: Blue capsules with message icons  
  - **Private Messages**: Green capsules with lock icons
- **Performance**: Same payload regardless of user count, updates batched for efficiency

## Queue Event Models

### Pydantic Models for Queue WebSocket Events

```python
from pydantic import BaseModel
from typing import List, Optional, Literal
from datetime import datetime
from uuid import UUID

class ContentType(str, Enum):
    TOPIC = "topic"
    POST = "post"
    PRIVATE_MESSAGE = "private_message"

class QueueItem(BaseModel):
    id: UUID
    position: int
    content_type: ContentType
    author: Optional[str] = None
    sender: Optional[str] = None  # For private messages
    preview: Optional[str] = None  # Only populated for users with content_preview permission
    timestamp: datetime
    estimated_completion: datetime

class QueueInfo(BaseModel):
    queue_type: str
    queue_length: int
    topic_title: Optional[str] = None  # For topic-specific queues
    participants: Optional[List[str]] = None  # For private message queues
    items: List[QueueItem]

class QueueUpdateEvent(BaseModel):
    type: Literal["queue_update"]
    timestamp: datetime
    data: "QueueUpdateData"

class QueueUpdateData(BaseModel):
    active_queues: List[QueueInfo]
```

### Permission-Based Content Filtering

- `preview` field is conditionally populated based on user permissions
- Citizens and anonymous users receive `null` for preview content
- Only moderators with `content_preview` permission see actual content

## Retention

- **Time-based**: 30 minutes
- **Safety cap**: 5000 events per job stream
- **Streams deleted**: ~30 minutes after `done`

## Reconnect

- Client can reconnect with `last_seq`
- Server replays missed events via `XREAD` from that ID

---

**Related Documentation:**
- [Business: Queue Visualization](../business-requirements/16-queue-visualization.md) - Visual requirements
- [Queue Management](./12-queue-management.md) - Queue orchestration logic
- [API Design](./04-api-design.md) - WebSocket endpoints
