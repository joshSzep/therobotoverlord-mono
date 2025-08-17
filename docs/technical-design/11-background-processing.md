# Background Processing

## Worker Service

**Dedicated background service using Arq**

## Why Arq

- **Async I/O native**, pairs naturally with FastAPI
- **Fits LLM workloads** (network I/O heavy)
- **Cleaner integration** with asyncio WebSocket flows

## Tasks

- **AI moderation** (LLM calls)
- **Semantic cache updates**
- **Event streaming** to frontend
- **Notifications**

## Configuration

- **Retries and backoff**: handled via Arq built-ins
- **Periodic jobs**: use Arq's cron support

## Worker Implementation

```python
from arq import create_pool
from arq.connections import RedisSettings

async def startup(ctx):
    ctx['db'] = await get_database_connection()
    ctx['llm_service'] = LLMService()
    ctx['notification_service'] = NotificationService()

async def shutdown(ctx):
    await ctx['db'].close()

async def moderate_content(ctx, content_id: str, content_type: str):
    """Main moderation task"""
    db = ctx['db']
    llm_service = ctx['llm_service']
    
    # Get content from database
    content = await get_content(db, content_id, content_type)
    
    # Stream commentary during processing
    await stream_overlord_commentary(content_id, "Analyzing your submission...")
    
    # Perform AI moderation
    result = await llm_service.moderate_content(content)
    
    # Update database with result
    await update_moderation_result(db, content_id, result)
    
    # Stream final result
    await stream_final_result(content_id, result)

class WorkerSettings:
    functions = [moderate_content]
    on_startup = startup
    on_shutdown = shutdown
    redis_settings = RedisSettings.from_dsn('redis://localhost:6379')
    job_timeout = 300  # 5 minutes for LLM calls
    keep_result = 3600  # Keep results for 1 hour
```

---

**Related Documentation:**
- [AI/LLM Integration](./07-ai-llm-integration.md) - LLM service implementation
- [Real-time Streaming](./06-realtime-streaming.md) - Event streaming to frontend
- [Deployment & Infrastructure](./01-deployment-infrastructure.md) - Worker service deployment
