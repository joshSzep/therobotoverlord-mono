# Visual Queue Requirements

## Concept

Submissions appear as capsules traveling through a dynamic pneumatic tube network. The system features a central hub with branching tubes for different queue types. The visual complexity scales with activity levels.

## Queue Types and Styling

### Topic Creation
Red capsules with crown icons in the main central tube

### Post Moderation
Blue capsules with message icons in topic-specific branch tubes

### Private Messages
Green capsules with lock icons in user-pair branch tubes

## Behavior

The tube network expands and contracts dynamically based on active queues. Citizens can watch submissions flow through different branches. Clicking a capsule reveals its metadata where permitted.

## Visibility Permissions

### All Users (including anonymous)
Can see queue lengths, author names (linked to profiles), and capsule positions

### Moderators with content preview RBAC permission
Can see content previews and additional metadata

### No Content Previews
Are shown to citizens or anonymous users

## Parallel Processing Visualization

Multiple tubes operate simultaneously, showing the parallel nature of the moderation system. This reinforces that debates in different topics can proceed independently.

---

**Related Documentation:**
- [Posts & Moderation](./07-posts-moderation.md) - Queue system overview
- [Look & Feel](./03-look-feel.md) - Visual design principles
- [Technical: Real-time Streaming](../technical-design/06-realtime-streaming.md) - Implementation details
