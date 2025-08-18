# Backend API Testing Strategy (`therobotoverlord-api`)

## Overview

Comprehensive testing strategy for the Python backend API component, covering unit tests, integration tests, database testing, and service layer validation.

## Testing Architecture

### Test Categories
- **Unit Tests (60%)**: Business logic, services, utilities, validators
- **Integration Tests (30%)**: Database operations, external API calls, message queues
- **Contract Tests (10%)**: API schema validation, request/response contracts

### Technology Stack
- **Test Framework**: pytest
- **API Testing**: pytest + httpx/requests
- **Database Testing**: pytest-postgresql + testcontainers
- **Mocking**: pytest-mock, responses for HTTP mocking
- **Coverage**: pytest-cov
- **Fixtures**: pytest fixtures for test data

## Project Structure
```
therobotoverlord-api/
├── app/
│   ├── services/
│   │   ├── moderation_service.py
│   │   ├── loyalty_service.py
│   │   └── queue_service.py
│   ├── repositories/
│   │   ├── content_repository.py
│   │   └── user_repository.py
│   ├── api/
│   │   ├── routes/
│   │   │   ├── content.py
│   │   │   └── auth.py
│   │   └── dependencies.py
│   ├── models/
│   │   ├── user.py
│   │   ├── content.py
│   │   └── moderation.py
│   └── utils/
│       ├── validators.py
│       └── formatters.py
├── tests/
│   ├── unit/
│   │   ├── services/
│   │   │   ├── test_moderation_service.py
│   │   │   ├── test_loyalty_service.py
│   │   │   └── test_queue_service.py
│   │   ├── repositories/
│   │   │   ├── test_content_repository.py
│   │   │   └── test_user_repository.py
│   │   └── utils/
│   │       └── test_validators.py
│   ├── integration/
│   │   ├── test_content_api.py
│   │   ├── test_auth_api.py
│   │   └── test_moderation_flow.py
│   ├── fixtures/
│   │   ├── users.py
│   │   ├── content.py
│   │   └── database.py
│   ├── conftest.py
│   └── test_config.py
├── pytest.ini
└── requirements-test.txt
```

## Test Data Factories

```python
# tests/fixtures/users.py
import pytest
from datetime import datetime
from typing import Dict, Any, Optional
from app.models.user import User, UserRole

class UserFactory:
    @staticmethod
    def create_user(**overrides) -> Dict[str, Any]:
        """Create test user data with optional overrides."""
        defaults = {
            'id': f'user-{datetime.now().timestamp()}-{hash(str(overrides))}',
            'username': f'test_citizen_{hash(str(overrides)) % 10000}',
            'email': f'test{hash(str(overrides)) % 10000}@overlord.com',
            'password_hash': '$2b$12$hashedpassword',
            'role': UserRole.CITIZEN,
            'loyalty_score': 100,
            'rank': 'Loyal Worker',
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True
        }
        defaults.update(overrides)
        return defaults
    
    @staticmethod
    def create_citizen(**overrides) -> Dict[str, Any]:
        """Create citizen user with default citizen settings."""
        citizen_defaults = {
            'role': UserRole.CITIZEN,
            'loyalty_score': 100,
            'rank': 'Loyal Worker'
        }
        citizen_defaults.update(overrides)
        return UserFactory.create_user(**citizen_defaults)
    
    @staticmethod
    def create_moderator(**overrides) -> Dict[str, Any]:
        """Create moderator user with default moderator settings."""
        moderator_defaults = {
            'role': UserRole.MODERATOR,
            'loyalty_score': 300,
            'rank': 'State Enforcer'
        }
        moderator_defaults.update(overrides)
        return UserFactory.create_user(**moderator_defaults)

# tests/fixtures/content.py
from datetime import datetime
from typing import Dict, Any
from app.models.content import ContentType, ContentStatus

class ContentFactory:
    @staticmethod
    def create_content(**overrides) -> Dict[str, Any]:
        """Create test content data with optional overrides."""
        defaults = {
            'id': f'content-{datetime.now().timestamp()}-{hash(str(overrides))}',
            'type': ContentType.POST,
            'text': 'This is a well-reasoned test argument with supporting evidence from credible sources.',
            'author_id': 'test-user-123',
            'topic_id': 'test-topic-456',
            'status': ContentStatus.PENDING,
            'moderation_result': None,
            'queue_position': 1,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow()
        }
        defaults.update(overrides)
        return defaults
    
    @staticmethod
    def create_moderation_decision(**overrides) -> Dict[str, Any]:
        """Create test moderation decision data."""
        defaults = {
            'id': f'decision-{datetime.now().timestamp()}-{hash(str(overrides))}',
            'content_id': 'test-content-123',
            'decision': 'APPROVED',
            'confidence': 0.85,
            'feedback': 'Well-reasoned argument with credible evidence.',
            'reasoning': 'Content demonstrates logical structure and cites appropriate sources.',
            'tags': ['evidence-based', 'logical', 'well-sourced'],
            'processing_time': 1500,
            'ai_model': 'claude-3-sonnet',
            'prompt_version': 'v1.2',
            'moderator_id': None,
            'created_at': datetime.utcnow()
        }
        defaults.update(overrides)
        return defaults
```

## Service Layer Testing

### Moderation Service Tests
```python
# tests/unit/services/test_moderation_service.py
import pytest
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime
from app.services.moderation_service import ModerationService
from app.models.content import Content, ContentStatus
from app.models.moderation import ModerationDecision, ModerationOutcome
from tests.fixtures.content import ContentFactory

class TestModerationService:
    @pytest.fixture
    def moderation_service(self):
        return ModerationService()
    
    @pytest.fixture
    def mock_ai_service(self):
        return Mock()
    
    @pytest.fixture
    def sample_content(self):
        return ContentFactory.create_content(
            text="Climate change is supported by overwhelming scientific evidence from NASA and NOAA."
        )
    
    @pytest.mark.asyncio
    async def test_moderate_content_approves_well_reasoned_content(
        self, moderation_service, mock_ai_service, sample_content
    ):
        """Test that well-reasoned content with evidence gets approved."""
        # Arrange
        mock_ai_service.moderate_content.return_value = {
            'decision': ModerationOutcome.APPROVED,
            'confidence': 0.92,
            'reasoning': 'Well-sourced argument with credible evidence',
            'tags': ['evidence-based', 'scientific'],
            'processing_time': 1200
        }
        moderation_service.ai_service = mock_ai_service
        
        # Act
        result = await moderation_service.moderate_content(sample_content)
        
        # Assert
        assert result.decision == ModerationOutcome.APPROVED
        assert result.confidence > 0.8
        assert 'evidence-based' in result.tags
        mock_ai_service.moderate_content.assert_called_once_with(
            sample_content['text'],
            prompt_version='v1.2',
            context_data={
                'author_id': sample_content['author_id'],
                'topic_id': sample_content['topic_id'],
                'content_type': sample_content['type']
            }
        )
    
    @pytest.mark.asyncio
    async def test_moderate_content_rejects_logical_fallacies(
        self, moderation_service, mock_ai_service
    ):
        """Test that content with logical fallacies gets rejected."""
        # Arrange
        fallacy_content = ContentFactory.create_content(
            text="Climate change is fake because it snowed yesterday in my city."
        )
        
        mock_ai_service.moderate_content.return_value = {
            'decision': ModerationOutcome.REJECTED,
            'confidence': 0.88,
            'reasoning': 'Contains logical fallacy (anecdotal evidence)',
            'feedback': 'Weather events in a single location do not disprove global climate trends.',
            'tags': ['logical-fallacy', 'anecdotal-evidence'],
            'processing_time': 1100
        }
        moderation_service.ai_service = mock_ai_service
        
        # Act
        result = await moderation_service.moderate_content(fallacy_content)
        
        # Assert
        assert result.decision == ModerationOutcome.REJECTED
        assert 'Weather events in a single location' in result.feedback
        assert 'logical-fallacy' in result.tags
    
    @pytest.mark.asyncio
    async def test_moderate_content_handles_ai_service_errors(
        self, moderation_service, mock_ai_service
    ):
        """Test graceful handling of AI service errors."""
        # Arrange
        test_content = ContentFactory.create_content()
        mock_ai_service.moderate_content.side_effect = Exception(
            "AI service temporarily unavailable"
        )
        moderation_service.ai_service = mock_ai_service
        
        # Act & Assert
        with pytest.raises(Exception) as exc_info:
            await moderation_service.moderate_content(test_content)
        
        assert "Moderation service error" in str(exc_info.value)
    
    @pytest.mark.asyncio
    async def test_moderate_content_validates_length(
        self, moderation_service, mock_ai_service
    ):
        """Test content length validation before moderation."""
        # Arrange
        short_content = ContentFactory.create_content(text="Too short")
        moderation_service.ai_service = mock_ai_service
        
        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await moderation_service.moderate_content(short_content)
        
        assert "Content must be at least 50 characters" in str(exc_info.value)
        mock_ai_service.moderate_content.assert_not_called()
```

## Database Testing

### Test Database Setup
```python
# tests/fixtures/database.py
import pytest
import asyncio
from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from testcontainers.postgres import PostgresContainer
from app.database.base import Base
from app.database.session import get_db

@pytest.fixture(scope="session")
def postgres_container():
    """Start PostgreSQL test container for the session."""
    with PostgresContainer("postgres:15") as postgres:
        postgres.with_env("POSTGRES_DB", "overlord_test")
        postgres.with_env("POSTGRES_USER", "test")
        postgres.with_env("POSTGRES_PASSWORD", "test")
        yield postgres

@pytest.fixture(scope="session")
def database_url(postgres_container):
    """Get database URL from container."""
    return postgres_container.get_connection_url()

@pytest.fixture(scope="session")
def async_database_url(postgres_container):
    """Get async database URL from container."""
    return postgres_container.get_connection_url().replace(
        "postgresql://", "postgresql+asyncpg://"
    )

@pytest.fixture(scope="session")
def engine(async_database_url):
    """Create async database engine."""
    return create_async_engine(async_database_url, echo=False)

@pytest.fixture(scope="session")
async def setup_database(engine):
    """Create all tables."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
async def db_session(engine, setup_database):
    """Create a database session for testing."""
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session() as session:
        yield session
        await session.rollback()

@pytest.fixture
def override_get_db(db_session):
    """Override the get_db dependency for testing."""
    async def _override_get_db():
        yield db_session
    return _override_get_db

## API Integration Testing

### Controller Tests
```typescript
// src/controllers/__tests__/content.controller.integration.test.ts
describe('Content Controller Integration', () => {
  let app: Application;
  let testDb: TestDatabase;
  let citizenToken: string;
  let moderatorToken: string;
  
  beforeAll(async () => {
    testDb = new TestDatabase();
    await testDb.setup();
    app = createTestApp({ database: testDb.connection });
  });
  
  describe('POST /api/content', () => {
    it('should accept valid content submission', async () => {
      const response = await request(app)
        .post('/api/content')
        .set('Authorization', `Bearer ${citizenToken}`)
        .send({
          type: 'post',
          text: 'According to IPCC AR6 report, immediate action is critical.',
          topicId: 'topic-123'
        });
      
      expect(response.status).toBe(201);
      expect(response.body).toMatchObject({
        status: 'pending',
        queuePosition: expect.any(Number)
      });
    });
    
    it('should reject unauthenticated requests', async () => {
      const response = await request(app)
        .post('/api/content')
        .send({ type: 'post', text: 'Unauthorized content' });
      
      expect(response.status).toBe(401);
    });
  });
});

## Pytest Configuration

```ini
# pytest.ini
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    --strict-markers
    --strict-config
    --verbose
    --tb=short
    --cov=app
    --cov-report=term-missing
    --cov-report=html
    --cov-fail-under=80
markers = 
    asyncio: marks tests as async
    unit: marks tests as unit tests
    integration: marks tests as integration tests
    slow: marks tests as slow running
asyncio_mode = auto
```

```python
# tests/conftest.py
import pytest
import asyncio
from typing import Generator
from httpx import AsyncClient
from fastapi.testclient import TestClient
from app.main import app
from tests.fixtures.database import *
from tests.fixtures.users import *
from tests.fixtures.content import *

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def client():
    """Create test client for FastAPI app."""
    return TestClient(app)

@pytest.fixture
async def async_client():
    """Create async test client for FastAPI app."""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
```

## Test Requirements

```txt
# requirements-test.txt
pytest>=7.4.0
pytest-asyncio>=0.21.0
pytest-cov>=4.1.0
pytest-mock>=3.11.0
pytest-postgresql>=5.0.0
testcontainers>=3.7.0
httpx>=0.24.0
responses>=0.23.0
factory-boy>=3.3.0
faker>=19.0.0
```

## Test Scripts

```python
# Makefile or scripts
test:
	pytest

test-unit:
	pytest tests/unit/ -m "not slow"

test-integration:
	pytest tests/integration/ -m "not slow"

test-coverage:
	pytest --cov=app --cov-report=html --cov-report=term

test-watch:
	pytest-watch

test-performance:
	pytest tests/ -m slow --durations=10
```

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
- [ ] Set up pytest with async support
- [ ] Create test database infrastructure with testcontainers
- [ ] Build test data factories
- [ ] Implement basic service tests

### Phase 2: Core Testing (Week 2)
- [ ] Complete service layer tests
- [ ] Add repository/database tests
- [ ] Implement FastAPI integration tests
- [ ] Set up CI pipeline with GitHub Actions

### Phase 3: Advanced Testing (Week 3)
- [ ] Add performance tests with pytest-benchmark
- [ ] Implement contract tests with Pact
- [ ] Create load testing scenarios
- [ ] Add security testing with safety/bandit

---

**Related Documentation:**
- [Database Schema](./05-database-schema.md) - Entity relationships to test
- [API Design](./04-api-design.md) - Endpoints to test
- [AI/LLM Integration](./07-ai-llm-integration.md) - AI services to mock
