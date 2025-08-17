# Multilingual System

## Translation Architecture

### Translation Flow (Updated)

1. **Content Ingestion**: Posts submitted in any language
2. **Language Detection**: Automatic detection of non-English content
3. **Translation to English**: OpenAI API for canonical storage
4. **Persistence**: Store original in translations table, English in main content tables
5. **Moderation**: Overlord evaluates English version only
6. **Appeals Process**: Display both original and translated versions to users and moderators
7. **Translation Quality**: Poor translation quality can be grounds for successful appeals
8. **Display**: Show appropriate version based on user preference (future enhancement)

## Implementation Details

### Language Detection
```python
from langdetect import detect

async def detect_language(content: str) -> str:
    try:
        detected_lang = detect(content)
        return detected_lang if detected_lang != 'en' else None
    except:
        return None  # Assume English if detection fails
```

### Translation Service
```python
from openai import AsyncOpenAI

class TranslationService:
    def __init__(self):
        self.client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    
    async def translate_to_english(self, content: str, source_lang: str) -> str:
        response = await self.client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "Translate the following text to English. Preserve the original meaning and tone as much as possible."},
                {"role": "user", "content": content}
            ]
        )
        return response.choices[0].message.content
    
    async def process_content_translation(self, content_id: str, content_type: str, original_content: str):
        detected_lang = await detect_language(original_content)
        
        if detected_lang and detected_lang != 'en':
            # Translate to English
            translated_content = await self.translate_to_english(original_content, detected_lang)
            
            # Store translation
            await self.db.translations.create({
                "content_id": content_id,
                "content_type": content_type,
                "language_code": detected_lang,
                "original_content": original_content,
                "translated_content": translated_content
            })
            
            return translated_content
        
        return original_content  # Already English
```

### Storage Strategy

#### Main Content Tables
Store canonical English version for:
- Consistent moderation
- Search indexing
- Performance optimization

#### Translations Table
Store original language versions for:
- Appeals process transparency
- Future display localization
- Translation quality assessment

### Appeals Integration

```python
async def get_content_for_appeal(content_id: str, content_type: str):
    # Get English version from main table
    english_content = await get_main_content(content_id, content_type)
    
    # Check for original translation
    translation = await self.db.translations.filter(
        content_id=content_id,
        content_type=content_type
    ).first()
    
    return {
        "english_version": english_content,
        "original_version": translation.original_content if translation else None,
        "source_language": translation.language_code if translation else "en"
    }
```

## Future Enhancements

### Display Localization
- Automatic translation of posts into user's preferred language
- Cached localized variants for performance
- User language preference settings

### Translation Quality Metrics
- Track successful appeals due to translation issues
- Implement translation confidence scoring
- A/B test different translation providers

---

**Related Documentation:**
- [Business: Multilingual Support](../business-requirements/15-multilingual.md) - Requirements and user experience
- [AI/LLM Integration](./07-ai-llm-integration.md) - OpenAI integration for translations
- [Database Schema](./05-database-schema.md) - Translations table structure
