# Guidelines and Help

## Code of Conduct

Clear, accessible rules that reflect the moderation criteria and site culture.

## Ask the Overlord

### Conversational Interface
A conversational interface for user guidance, discovery, rules explanation, and navigation.

### RAG Integration
Uses RAG (Retrieval-Augmented Generation) over indexed public content for contextual responses.

### Discovery Capabilities
Can help find topics, posts, or citizens (e.g., "show debates on X").

### Response Features
Responses may include links to relevant debates or profiles.

### Session Awareness
Role-aware and session-aware (knows username, loyalty score, Graveyard count).

### Memory Limitations
No persistent memory across sessions in MVP.

## Role-Specific Capabilities

### Citizens
General guidance and Overlord commentary

### Moderators
Inline moderation actions (approve, reject, sanction) via chat

### Admins & Super Admins
Same as moderators, plus elevated tools (role/tag adjustments)

## Proactive Notifications

Proactive notifications delivered as messages from the Overlord (rate limits, sanctions).

---

**Related Documentation:**
- [Appeals & Reporting](./12-appeals-reporting.md) - Appeal submission via chat
- [Overlord Behavior](./09-overlord-behavior.md) - AI personality and responses
- [Technical: AI/LLM Integration](../technical-design/07-ai-llm-integration.md) - Chat implementation
