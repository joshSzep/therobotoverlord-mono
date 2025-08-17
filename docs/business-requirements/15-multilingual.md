# Multilingual Support

## Canonical Storage

All posts are ultimately stored in English for consistency and moderation.

## Translation Flow

### Automatic Translation
Posts submitted in other languages are automatically translated to English on ingestion.

### Translation Persistence
Translations are persisted in the database to avoid repeat LLM calls.

### Cached Variants
Cached localized variants may also be stored for display optimization.

## Appeals and Moderation

Users see both original and translated versions in appeals. Moderation decisions are based solely on English translation. Translation quality issues can be grounds for successful appeals.

## Future Enhancement

- Automatic translation of posts into user's preferred language for display.
- For MVP, only one translation per language is persisted.

---

**Related Documentation:**
- [Appeals & Reporting](./12-appeals-reporting.md) - Translation quality in appeals
- [Technical: Multilingual System](../technical-design/10-multilingual.md) - Implementation details
