# Queue Management Logic

## Configuration

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

## Queue Orchestrator

```python
class QueueOrchestrator:
    def __init__(self, total_workers: int = 2):
        self.total_workers = total_workers
        self.worker_pool = WorkerPool(total_workers)
        self.active_queues = {}
        self.circuit_breaker_threshold = timedelta(minutes=2)
    
    async def distribute_workers(self):
        """Smart worker distribution with priority guarantees"""
        # Always ensure topic queue has a worker
        await self.assign_worker_to_queue('global_topics', priority=True)
        
        # Distribute remaining workers based on queue lengths and activity
        remaining_workers = self.total_workers - 1
        active_queues = await self.get_active_queues()
        
        for queue_name in active_queues:
            if remaining_workers > 0 and queue_name != 'global_topics':
                await self.assign_worker_to_queue(queue_name)
                remaining_workers -= 1
    
    async def handle_queue_starvation(self):
        """Circuit breaker for stuck queues"""
        for queue_name, queue_info in self.active_queues.items():
            if queue_info.last_processed < datetime.now() - self.circuit_breaker_threshold:
                await self.reallocate_worker(queue_name)
    
    async def get_queue_priority_score(self, queue_name: str) -> int:
        """Calculate priority score for worker allocation"""
        queue_length = await self.get_queue_length(queue_name)
        avg_wait_time = await self.get_average_wait_time(queue_name)
        
        # Higher score = higher priority
        return queue_length * 10 + int(avg_wait_time.total_seconds() / 60)
```

## Queue Processing Strategies

### Sequential Processing (Posts & Private Messages)

```python
async def process_topic_queue(topic_id: str):
    """Process posts for a specific topic in strict FIFO order"""
    queue_name = f"topic_{topic_id}"
    
    while True:
        # Get next item in queue
        next_item = await redis.lpop(queue_name)
        if not next_item:
            break
        
        # Process item
        await process_post_moderation(next_item)
        
        # Update queue visualization
        await update_queue_visualization(queue_name)

async def process_private_message_queue(user_pair: str):
    """Process private messages between user pair in strict order"""
    queue_name = f"users_{user_pair}"
    
    while True:
        next_message = await redis.lpop(queue_name)
        if not next_message:
            break
        
        await process_private_message_moderation(next_message)
        await update_queue_visualization(queue_name)
```

### Parallel Processing (Topics)

```python
async def process_global_topics_queue():
    """Process topic creation requests - can be parallel"""
    while True:
        # Get multiple items for parallel processing
        items = await redis.lpop('global_topics', count=5)
        if not items:
            break
        
        # Process in parallel
        tasks = [process_topic_moderation(item) for item in items]
        await asyncio.gather(*tasks)
        
        await update_queue_visualization('global_topics')
```

---

**Related Documentation:**
- [Real-time Streaming](./06-realtime-streaming.md) - Queue visualization updates
- [Background Processing](./11-background-processing.md) - Worker implementation
- [Business: Posts & Moderation](../business-requirements/07-posts-moderation.md) - Queue requirements
