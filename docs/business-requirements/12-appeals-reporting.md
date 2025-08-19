# Appeals and Reporting

## Appeals Process Flow

```mermaid
flowchart TD
    A[Post Rejected] --> B[Citizen Sees Rejection]
    B --> C{Want to Appeal?}
    C -->|No| D[Accept Rejection]
    C -->|Yes| E[Submit Appeal via Overlord Chat]
    
    E --> F[Rate Limit Check]
    F -->|Pass| G[Appeal Enters Queue]
    F -->|Fail| H[Show Rate Limit Message]
    
    G --> I[Human Moderator Review]
    I --> J{Appeal Decision}
    
    J -->|Sustained| K[Post Becomes Visible]
    J -->|Denied| L[Apply Sanction]
    
    K --> M[Update Loyalty Score +]
    L --> N[Update Loyalty Score -]
    
    M --> O[Notify Citizen: Appeal Won]
    N --> P[Notify Citizen: Appeal Lost]
    
    style I fill:#74b9ff,stroke:#fff,color:#fff
    style K fill:#4ecdc4,stroke:#fff,color:#fff
    style L fill:#ff6b6b,stroke:#fff,color:#fff
```

## Reporting & Flagging Flow

```mermaid
sequenceDiagram
    participant C as Citizen
    participant F as Flag System
    participant M as Moderator
    participant O as Overlord
    participant DB as Database
    
    C->>F: Flag Content
    F->>DB: Store Flag Record
    F->>M: Add to Review Queue
    
    M->>F: Review Flag
    M->>M: Evaluate Content
    
    alt Flag Sustained
        M->>DB: Hide Content
        M->>O: Update Loyalty Score
        M->>C: Notify: Flag Upheld
    else Flag Dismissed
        M->>DB: Keep Content Visible
        M->>C: Notify: Flag Dismissed
        Note over M: Check for frivolous flagging
    end
```

## Appeals

### Eligibility
Any rejected public post can be appealed by its author.

### Submission Process
Citizens submit appeals via chat with the Robot Overlord, following proper bureaucratic protocol.

### Confirmation
The Robot Overlord confirms receipt with characteristic bureaucratic precision and enters appeal into the state processing queue.

### Review Process
Appeals reviewed outside of chat in dedicated dashboard (Phase 4).

### Rate Limits
One appeal submission per citizen per five minutes.

### Reviewers
Moderators, admins, and super admins can adjudicate appeals.

### Outcomes
- **If sustained**: The post becomes visible and all stats update.
- **If denied**: A sanction is applied to discourage frivolous appeals.

### Delay Messaging
If queues are backed up: "Your petition has been logged. Await review by the Central Committee."

## Reporting

### Flagging Process
Any citizen can flag a post or topic for review.

### Review Queue
Flags enter dedicated moderation queues and are adjudicated by moderators, admins, and super admins.

### Outcomes
If a flag is sustained, the content is hidden and counted as a rejection with stats updated. Repeated frivolous flagging results in sanctions.

---

**Related Documentation:**
- [Sanctions & Moderation](./13-sanctions-moderation.md) - Sanction system
- [Guidelines & Help](./14-guidelines-help.md) - Appeal submission via Overlord chat
- [Technical: API Design](../technical-design/04-api-design.md) - Appeals endpoints
