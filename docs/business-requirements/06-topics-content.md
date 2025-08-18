# Topics

## Topic Creation Flow

```mermaid
flowchart TD
    A[User Wants to Create Topic] --> B{User Role Check}
    B -->|Overlord| C[Create Topic Directly]
    B -->|Citizen| D{Top 10% Loyalty Score?}
    B -->|Other Roles| E[Create with Privileges]
    
    D -->|Yes| F[Allow Topic Creation]
    D -->|No| G[Deny Topic Creation]
    
    F --> H[Submit Topic to Queue]
    E --> H
    C --> I[Publish Immediately]
    
    H --> J[Topic Approval Bureau]
    J --> K[Overlord AI Evaluation]
    K --> L{Evaluation Result}
    
    L -->|Approved| M[Topic Goes Live]
    L -->|Rejected| N[Topic Rejected]
    L -->|Calibrated| O[Return with Feedback]
    
    style D fill:#ff4757,stroke:#fff,color:#fff
    style K fill:#74b9ff,stroke:#fff,color:#fff
    style M fill:#4ecdc4,stroke:#fff,color:#fff
    style N fill:#ff6b6b,stroke:#fff,color:#fff
```

## Topic Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Draft: User Creates Topic
    Draft --> Pending: Submit for Approval
    Pending --> UnderReview: Enter Queue
    UnderReview --> Approved: Pass Evaluation
    UnderReview --> Rejected: Fail Evaluation
    UnderReview --> Calibrated: Needs Improvement
    Calibrated --> Draft: User Edits
    Approved --> Live: Published
    Live --> [*]: Topic Active
    Rejected --> [*]: Sent to Graveyard
```

## Who Can Create Topics

### The Overlord
The Overlord can create topics at will.

### Citizens
Citizens can create topics only if they are among the most loyal, as determined by the leaderboard. The exact threshold is the **top 10% of citizens by loyalty score**, calculated in real-time.

## Approval Process

- **Fully automatic via Overlord (LLM)**. No manual admin approval required for MVP.
- Uses same evaluation criteria as posts: logic, tone, relevance.

## Topic Fields

- **Title**
- **Description** 
- **Author**
- **Overlord-assigned tags**

## Behavior

Topics list appears in a simple feed. Sorting and filtering use search and tags. **No score voting**.

---

**Related Documentation:**
- [Roles & Capabilities](./02-roles-capabilities.md) - Topic creation permissions
- [Gamification & Reputation](./10-gamification-reputation.md) - Loyalty score thresholds
- [Overlord Behavior](./09-overlord-behavior.md) - Evaluation criteria
- [Technical: Database Schema](../technical-design/05-database-schema.md) - Topics table structure
