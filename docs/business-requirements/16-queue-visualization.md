# Queue Status System

## Concept

Clear, honest communication about queue position and estimated wait times through status cards and Overlord commentary. Replaces complex visualization with transparent, scalable status updates.

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
