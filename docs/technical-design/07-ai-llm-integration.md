# AI/LLM Integration

## Framework and Provider

### Framework
**PydanticAI** for structured LLM interactions

### Primary Provider
**Anthropic (Claude models)**
- **Claude-3.5-Sonnet**: Moderation, Overlord chat, tagging
- **Claude-3-Haiku**: Faster, simpler tasks

### Secondary Provider
**OpenAI**
- **Translation tasks**: Faster and more cost-efficient for multilingual support

## Integration Architecture

```python
from pydantic_ai import Agent
from pydantic_ai.models.anthropic import AnthropicModel
from pydantic_ai.providers.anthropic import AnthropicProvider

# Overlord moderation agent
moderation_model = AnthropicModel(
    'claude-3-5-sonnet-latest',
    provider=AnthropicProvider(api_key=settings.ANTHROPIC_API_KEY)
)

moderation_agent = Agent(
    model=moderation_model,
    system_prompt="You are the Robot Overlord..."
)

# Chat agent for user interactions
chat_model = AnthropicModel(
    'claude-3-haiku-latest',
    provider=AnthropicProvider(api_key=settings.ANTHROPIC_API_KEY)
)

chat_agent = Agent(
    model=chat_model,
    system_prompt="You are the Robot Overlord in chat mode..."
)
```

## Overlord Capabilities

### 1. Content Moderation
- Evaluate posts and topics for logic, tone, and relevance
- Generate in-character feedback for calibrations
- Assign appropriate tags to topics and posts
- Automatic approval/rejection (no manual admin step for MVP)

### 2. Chat Interface
- Session-aware and role-aware responses (knows username, loyalty score, Graveyard count)
- No persistent memory across sessions in MVP
- Answer questions about rules and policies
- Help users discover debates and topics using RAG over indexed content
- Provide guidance on improving post quality
- Role-specific capabilities:
  - Citizens: General guidance and commentary
  - Moderators: Inline moderation actions via chat
  - Admins & Super Admins: Elevated tools and actions
- Communicate sanctions and rate limits as chat messages

### 3. Tag Assignment
- Automatically categorize content based on themes
- Maintain consistency in tagging across the platform
- Admins and Super Admins can override Overlord tag assignments

### 4. Translation Services
- Translate non-English submissions to canonical English storage
- Persist translations to avoid repeat LLM calls

### 5. Private Message Moderation
- Uses identical evaluation criteria as public posts (logic, tone, relevance)
- Same AI agent and prompts as public content moderation
- Moderation outcomes contribute equally to loyalty scores
- Appeals process identical to public posts

---

**Related Documentation:**
- [Business: Overlord Behavior](../business-requirements/09-overlord-behavior.md) - AI personality and evaluation criteria
- [Business: Guidelines & Help](../business-requirements/14-guidelines-help.md) - Chat interface requirements
- [Multilingual System](./10-multilingual.md) - Translation implementation
- [Background Processing](./11-background-processing.md) - AI task execution
