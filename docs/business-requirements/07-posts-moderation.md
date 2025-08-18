# Posts and Replies

## Post Moderation Flow

```mermaid
flowchart TD
    A[Citizen Submits Post] --> B[Enter Post Moderation Queue]
    B --> C[Queue Position Assigned]
    C --> D[WebSocket: Position Update]
    D --> E[Overlord AI Processing]
    E --> F{Evaluation Result}
    
    F -->|Approved| G[Post Published]
    F -->|Rejected| H[Post to Graveyard]
    
    G --> I[Update Loyalty Score +]
    H --> J[Update Loyalty Score -]
    
    I --> K[Notify User: Approved]
    J --> L[Notify User: Rejected]
    
    style E fill:#74b9ff,stroke:#fff,color:#fff
    style G fill:#4ecdc4,stroke:#fff,color:#fff
    style H fill:#ff6b6b,stroke:#fff,color:#fff
    style I fill:#ffd93d,stroke:#000,color:#000
```

## Moderation Decision Tree

```mermaid
graph TD
    A[Post Content] --> B{Logic Check}
    B -->|Pass| C{Tone Check}
    B -->|Fail| D[Reject: Poor Logic]
    
    C -->|Pass| E{Relevance Check}
    C -->|Fail| F[Calibrate: Improve Tone]
    
    E -->|Pass| G[Approve Post]
    E -->|Fail| H[Calibrate: Stay On Topic]
    
    D --> I[Send to Graveyard]
    F --> J[Return with Feedback]
    H --> J
    G --> K[Publish to Topic]
    
    style G fill:#4ecdc4,stroke:#fff,color:#fff
    style D fill:#ff6b6b,stroke:#fff,color:#fff
    style F fill:#ffd93d,stroke:#000,color:#000
    style H fill:#ffd93d,stroke:#000,color:#000
```

## Submission

- Citizens can reply in any topic.
- Posts are displayed in **chronological order by submission time**. There are no upvotes or downvotes.
- Posts may be processed out of submission order for performance optimization, but final display always uses submission timestamp ordering.

## Evaluation

### Specialized Evaluation Queues

Submissions enter specialized evaluation queues based on content type:

- **Topic Creation Queue**: Global queue for all new topic proposals
- **Post Moderation Queues**: Per-topic queues for posts within specific debates
- **Private Message Queues**: Per-conversation queues for private communications (processed sequentially to guarantee delivery order)

### Queue System Visualization

The queue system is rendered as a dynamic pneumatic tube network with branching paths. Each queue type has distinct visual styling and capsule colors.

Queue updates are live and show real-time movement through the tube system, representing processing activity rather than final display order.

### In-Character Commentary

While content is waiting, the Overlord can stream in-character commentary to the author.

## Evaluation Outcomes

### Approved
The post appears in the topic. The Overlord may attach a visible commentary block.

### Rejected
The post does not appear publicly. It is stored in the author's private **Graveyard** and visible to the author, moderators, admins, and super admins.

---

**Related Documentation:**
- [Queue Visualization](./16-queue-visualization.md) - Detailed queue requirements
- [Overlord Behavior](./09-overlord-behavior.md) - Evaluation criteria
- [Appeals & Reporting](./12-appeals-reporting.md) - Appeal process for rejections
- [Technical: Real-time Streaming](../technical-design/06-realtime-streaming.md) - Implementation details
