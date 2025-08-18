# Queue Status System

## Concept

Clear, honest communication about queue position and estimated wait times through status cards and Overlord commentary. Replaces complex visualization with transparent, scalable status updates.

## Queue System Architecture

```mermaid
graph TB
    subgraph "Content Submission"
        A[User Submits Content] --> B{Content Type?}
        B -->|Topic| C[Topic Creation Queue]
        B -->|Post| D[Post Moderation Queue]
        B -->|Private Message| E[Private Message Queue]
    end
    
    subgraph "Queue Processing"
        C --> F[Topic Approval Bureau]
        D --> G[Debate Moderation Office]
        E --> H[Private Communication Review]
    end
    
    subgraph "Overlord Processing"
        F --> I[AI Evaluation Engine]
        G --> I
        H --> I
        I --> J{Evaluation Result}
        J -->|Approved| K[Content Published]
        J -->|Rejected| L[Content to Graveyard]
        J -->|Calibrated| M[Feedback to User]
    end
    
    subgraph "Real-time Updates"
        N[WebSocket Server] --> O[Queue Position Updates]
        N --> P[Overlord Commentary]
        N --> Q[Status Changes]
    end
    
    style C fill:#ff4757,stroke:#fff,color:#fff
    style D fill:#ff4757,stroke:#fff,color:#fff
    style E fill:#ff4757,stroke:#fff,color:#fff
    style I fill:#74b9ff,stroke:#fff,color:#fff
```

## Queue Flow Visualization

```mermaid
sequenceDiagram
    participant U as User
    participant Q as Queue System
    participant O as Overlord AI
    participant W as WebSocket
    participant DB as Database
    
    U->>Q: Submit Content
    Q->>DB: Store in Queue Table
    Q->>W: Send Position Update
    W->>U: "Position #3 in queue"
    
    loop Queue Processing
        Q->>O: Next Item for Review
        O->>O: Evaluate Content
        O->>Q: Return Decision
        Q->>DB: Update Status
        Q->>W: Send Progress Update
        W->>U: "Under review..."
    end
    
    O->>Q: Final Decision
    Q->>DB: Update Content Status
    Q->>W: Send Final Result
    W->>U: "Approved/Rejected"
```

## Queue Status Cards

Each queue item displays:
- **Position in queue** (e.g., "Position 3 of 12") - reflects true FIFO processing order
- **Estimated wait time** based on historical processing rates
- **Current status** (Pending, In Review, Processing)
- **Overlord commentary** providing context or encouragement
- **Fair processing guarantee** - "All submissions processed in order received"

### Topic Approval Bureau
```
┌─────────────────────────────────┐
│ 🏛️ TOPIC APPROVAL BUREAU        │
│ Your submission: Position #3     │
│ Estimated review: 2-4 minutes   │
│ Current status: Under review     │
└─────────────────────────────────┘
```

### Debate Moderation Office
```
┌─────────────────────────────────┐
│ 📝 CLIMATE CHANGE DEBATE        │
│ Your post: Position #7          │
│ Estimated review: 5-8 minutes   │
│ Current status: Awaiting review │
└─────────────────────────────────┘
```

### Private Communication Review
```
┌─────────────────────────────────┐
│ 🔒 PRIVATE MESSAGE REVIEW       │
│ Your message: Position #2       │
│ Estimated review: 1-3 minutes   │
│ Current status: Under review     │
└─────────────────────────────────┘
```

## Overlord Commentary System

### Progressive Status Updates
- **Initial**: "Citizen, your submission has been logged. Position #3 in the queue."
- **Processing**: "The Committee is now reviewing your proposal. Maintain patience."
- **Near completion**: "Your reasoning shows promise. Final evaluation in progress..."

### Context-Aware Messages
Commentary varies based on queue position, wait time, and submission type while maintaining authoritarian character.

## The Overlord's Commentary:
"Citizen, your submission awaits my divine attention. The queue moves in perfect order - first submitted, first reviewed. No favoritism, no shortcuts, no hidden priorities. Your patience demonstrates loyalty to the fair system I have decreed."
- **Processing**: "The Committee is now reviewing your proposal. Maintain patience."
- **Near completion**: "Your reasoning shows promise. Final evaluation in progress..."

### Context-Aware Messages
Commentary varies based on queue position, wait time, and submission type while maintaining authoritarian character.

## Public Queue Overview

### Aggregate Statistics
- Total items in each queue
- Estimated wait times for new submissions
- General processing status without individual details

### Anonymous Visibility
All users can see queue lengths and general activity without accessing individual submission details.

---

**Related Documentation:**
- [Posts & Moderation](./07-posts-moderation.md) - Queue system overview
- [Look & Feel](./03-look-feel.md) - Visual design principles
- [Technical: Real-time Streaming](../technical-design/06-realtime-streaming.md) - Implementation details
