# Monorepo End-to-End Testing Strategy (`therobotoverlord-mono`)

## Overview

Comprehensive end-to-end testing strategy for the entire Robot Overlord platform, orchestrating tests across the API backend, web frontend, and their integration points within the monorepo structure.

## Testing Architecture

### Test Categories
- **Full-Stack E2E Tests (40%)**: Complete user workflows across API + Web
- **Integration Tests (30%)**: API-Frontend contract validation
- **System Tests (20%)**: Multi-service orchestration
- **Performance Tests (10%)**: Full-stack load testing

### Technology Stack
- **E2E Framework**: Playwright with Docker Compose
- **API Testing**: pytest + httpx for backend validation
- **Contract Testing**: Pact for API-Frontend contracts
- **Load Testing**: Artillery.js or k6
- **Test Orchestration**: Docker Compose + GitHub Actions
- **Test Data**: Shared fixtures across all test suites

## Monorepo Structure
```
therobotoverlord-mono/
├── therobotoverlord-api/          # Python FastAPI backend
├── therobotoverlord-web/          # React frontend
├── tests/
│   ├── e2e/                       # Full-stack end-to-end tests
│   │   ├── specs/
│   │   │   ├── content-moderation-flow.spec.ts
│   │   │   ├── loyalty-system.spec.ts
│   │   │   ├── overlord-chat.spec.ts
│   │   │   └── admin-moderation.spec.ts
│   │   ├── fixtures/
│   │   │   ├── test-data.json
│   │   │   ├── users.json
│   │   │   └── topics.json
│   │   └── utils/
│   │       ├── test-setup.ts
│   │       ├── api-helpers.ts
│   │       └── db-helpers.ts
│   ├── integration/               # Cross-service integration tests
│   │   ├── api-web-contracts.spec.ts
│   │   ├── auth-flow.spec.ts
│   │   └── real-time-updates.spec.ts
│   ├── performance/               # Load and performance tests
│   │   ├── load-testing.js
│   │   ├── stress-testing.js
│   │   └── performance-benchmarks.js
│   └── shared/
│       ├── fixtures/              # Shared test data
│       ├── helpers/               # Common utilities
│       └── config/                # Test configurations
├── docker-compose.test.yml        # Test environment orchestration
├── playwright.config.ts           # E2E test configuration
└── package.json                   # Monorepo test scripts
```

## Full-Stack End-to-End Tests

### Content Moderation Flow
```typescript
// tests/e2e/specs/content-moderation-flow.spec.ts
import { test, expect } from '@playwright/test';
import { ApiHelper } from '../utils/api-helpers';
import { TestDataFactory } from '../utils/test-setup';

test.describe('Complete Content Moderation Flow', () => {
  let apiHelper: ApiHelper;
  let testUser: any;

  test.beforeAll(async () => {
    apiHelper = new ApiHelper();
    testUser = await apiHelper.createTestUser({
      role: 'citizen',
      loyaltyScore: 100
    });
  });

  test('should complete full content submission to approval workflow', async ({ page }) => {
    // 1. User Authentication
    await page.goto('/login');
    await page.fill('[data-testid="email"]', testUser.email);
    await page.fill('[data-testid="password"]', 'testpassword123');
    await page.click('[data-testid="login-submit"]');

    // Verify authentication via API
    const userProfile = await apiHelper.getUserProfile(testUser.accessToken);
    expect(userProfile.loyaltyScore).toBe(100);

    // 2. Topic Selection and Content Submission
    await page.waitForSelector('[data-testid="dashboard"]');
    await page.click('[data-testid="browse-topics"]');
    
    // Select climate change topic
    await page.click('[data-testid="topic-climate-change"]');
    
    // Submit well-reasoned content
    const contentText = `According to the IPCC AR6 Working Group I report (2021), 
      human activities have unequivocally warmed the planet by approximately 1.1°C 
      since 1850-1900. The evidence includes: 1) Observed warming patterns consistent 
      with greenhouse gas forcing, 2) Isotopic analysis of atmospheric CO2 showing 
      fossil fuel origins, 3) Sea level rise of 21-24cm since 1880 correlating with 
      thermal expansion and ice melt.`;

    await page.fill('[data-testid="content-input"]', contentText);
    await page.click('[data-testid="submit-content"]');

    // 3. Verify Queue Placement
    await expect(page.locator('[data-testid="submission-success"]')).toBeVisible();
    const queuePosition = await page.textContent('[data-testid="queue-position"]');
    expect(queuePosition).toMatch(/Queue position: \d+/);

    // 4. Backend Processing Simulation
    // Wait for AI moderation to process (or mock it)
    const submittedContent = await apiHelper.getLatestUserContent(testUser.id);
    
    // Simulate AI moderation approval
    await apiHelper.moderateContent(submittedContent.id, {
      decision: 'approved',
      confidence: 0.92,
      feedback: 'Excellent use of scientific evidence and logical reasoning.',
      tags: ['evidence-based', 'well-sourced', 'scientific']
    });

    // 5. User Notification and Loyalty Update
    await page.reload();
    await page.click('[data-testid="queue-status"]');
    
    await expect(page.locator('[data-testid="content-approved"]')).toBeVisible();
    await expect(page.locator('text=Excellent use of scientific evidence')).toBeVisible();

    // Verify loyalty score increase via API
    const updatedProfile = await apiHelper.getUserProfile(testUser.accessToken);
    expect(updatedProfile.loyaltyScore).toBeGreaterThan(100);

    // 6. Content Publication
    await page.goto('/topics/climate-change');
    await expect(page.locator(`[data-testid="content-${submittedContent.id}"]`)).toBeVisible();
    await expect(page.locator('text=human activities have unequivocally warmed')).toBeVisible();
  });

  test('should handle content calibration workflow', async ({ page }) => {
    await page.goto('/login');
    await apiHelper.loginUser(page, testUser);

    // Submit content with logical fallacy
    await page.goto('/topics/climate-change');
    const fallacyContent = `Climate change can't be real because it snowed in Texas last winter. 
      If global warming was happening, we wouldn't have record cold temperatures anywhere.`;

    await page.fill('[data-testid="content-input"]', fallacyContent);
    await page.click('[data-testid="submit-content"]');

    // Backend processing
    const submittedContent = await apiHelper.getLatestUserContent(testUser.id);
    
    await apiHelper.moderateContent(submittedContent.id, {
      decision: 'rejected',
      confidence: 0.85,
      feedback: 'This argument contains a logical fallacy (anecdotal evidence). Local weather events do not disprove global climate trends.',
      tags: ['logical-fallacy', 'anecdotal-evidence'],
      suggestions: [
        'Review NOAA climate vs weather resources',
        'Consider global temperature trends rather than local events',
        'Strengthen argument with peer-reviewed climate data'
      ]
    });

    // Verify calibration feedback
    await page.reload();
    await page.click('[data-testid="queue-status"]');
    
    await expect(page.locator('[data-testid="content-rejected"]')).toBeVisible();
    await expect(page.locator('text=logical fallacy')).toBeVisible();
    await expect(page.locator('text=Local weather events do not disprove')).toBeVisible();

    // Content should not be published
    await page.goto('/topics/climate-change');
    await expect(page.locator(`[data-testid="content-${submittedContent.id}"]`)).not.toBeVisible();
  });
});
```

### Loyalty System Integration
```typescript
// tests/e2e/specs/loyalty-system.spec.ts
import { test, expect } from '@playwright/test';
import { ApiHelper } from '../utils/api-helpers';

test.describe('Loyalty System Integration', () => {
  test('should track loyalty progression through multiple interactions', async ({ page }) => {
    const apiHelper = new ApiHelper();
    const citizen = await apiHelper.createTestUser({
      role: 'citizen',
      loyaltyScore: 50,
      rank: 'Probationary Worker'
    });

    await apiHelper.loginUser(page, citizen);

    // Initial state verification
    await page.goto('/profile');
    await expect(page.locator('[data-testid="loyalty-score"]')).toContainText('50');
    await expect(page.locator('[data-testid="user-rank"]')).toContainText('Probationary Worker');

    // Submit high-quality content
    const qualityContent = `Meta-analysis of 97 climate studies shows 97% consensus on anthropogenic warming (Cook et al., 2013). 
      This consensus is supported by multiple lines of evidence including paleoclimate data, isotopic analysis, 
      and observed warming patterns consistent with greenhouse gas theory.`;

    await page.goto('/topics/climate-change');
    await page.fill('[data-testid="content-input"]', qualityContent);
    await page.click('[data-testid="submit-content"]');

    // Backend processes content
    const content = await apiHelper.getLatestUserContent(citizen.id);
    await apiHelper.moderateContent(content.id, {
      decision: 'approved',
      confidence: 0.95,
      feedback: 'Outstanding scientific rigor and evidence quality.',
      tags: ['evidence-based', 'scientific', 'high-quality']
    });

    // Verify loyalty increase
    await page.reload();
    await page.goto('/profile');
    
    const updatedScore = await apiHelper.getUserProfile(citizen.accessToken);
    expect(updatedScore.loyaltyScore).toBeGreaterThan(50);
    
    // Check for rank progression
    if (updatedScore.loyaltyScore >= 100) {
      await expect(page.locator('[data-testid="user-rank"]')).toContainText('Loyal Worker');
    }

    // Test privilege unlock - check if user is in top 10%
    const isTopTenPercent = await apiHelper.isInTopPercentile(citizen.id, 0.1);
    if (isTopTenPercent) {
      await page.goto('/topics');
      await expect(page.locator('[data-testid="create-topic-button"]')).toBeVisible();
    }
  });
});
```

### Overlord Chat System
```typescript
// tests/e2e/specs/overlord-chat.spec.ts
import { test, expect } from '@playwright/test';
import { ApiHelper } from '../utils/api-helpers';

test.describe('Overlord Chat Integration', () => {
  test('should handle citizen queries and commands', async ({ page }) => {
    const apiHelper = new ApiHelper();
    const citizen = await apiHelper.createTestUser({ role: 'citizen' });
    
    await apiHelper.loginUser(page, citizen);
    await page.goto('/chat');

    // Test loyalty score query
    await page.fill('[data-testid="chat-input"]', 'What is my loyalty score?');
    await page.click('[data-testid="send-message"]');

    await expect(page.locator('[data-testid="overlord-response"]')).toContainText('loyalty score');
    await expect(page.locator('[data-testid="overlord-response"]')).toContainText(citizen.loyaltyScore.toString());

    // Test topic creation request
    await page.fill('[data-testid="chat-input"]', 'Can I create a new topic about renewable energy?');
    await page.click('[data-testid="send-message"]');

    const response = await page.locator('[data-testid="overlord-response"]').last();
    const isTopTenPercent = await apiHelper.isInTopPercentile(citizen.id, 0.1);
    if (isTopTenPercent) {
      await expect(response).toContainText('You may create topics');
      await expect(page.locator('[data-testid="create-topic-link"]')).toBeVisible();
    } else {
      await expect(response).toContainText('insufficient loyalty score');
    }
  });

  test('should handle moderator commands', async ({ page }) => {
    const apiHelper = new ApiHelper();
    const moderator = await apiHelper.createTestUser({ 
      role: 'moderator',
      loyaltyScore: 300 
    });

    // Create content to moderate
    const citizen = await apiHelper.createTestUser({ role: 'citizen' });
    const content = await apiHelper.createContent({
      authorId: citizen.id,
      text: 'Test content for moderation',
      status: 'pending'
    });

    await apiHelper.loginUser(page, moderator);
    await page.goto('/chat');

    // Test moderation command
    await page.fill('[data-testid="chat-input"]', `approve content ${content.id}`);
    await page.click('[data-testid="send-message"]');

    await expect(page.locator('[data-testid="overlord-response"]')).toContainText('Content approved');
    
    // Verify content status changed in backend
    const updatedContent = await apiHelper.getContent(content.id);
    expect(updatedContent.status).toBe('approved');
  });
});
```

## Integration Testing

### API-Frontend Contract Tests
```typescript
// tests/integration/api-web-contracts.spec.ts
import { test, expect } from '@playwright/test';
import { ApiHelper } from '../utils/api-helpers';

test.describe('API-Frontend Contracts', () => {
  test('should maintain consistent data models between API and UI', async ({ page }) => {
    const apiHelper = new ApiHelper();
    
    // Get user data from API
    const apiUser = await apiHelper.getUser('test-user-123');
    
    // Login and check UI representation
    await apiHelper.loginUser(page, apiUser);
    await page.goto('/profile');
    
    // Verify UI displays match API data
    await expect(page.locator('[data-testid="username"]')).toContainText(apiUser.username);
    await expect(page.locator('[data-testid="loyalty-score"]')).toContainText(apiUser.loyaltyScore.toString());
    await expect(page.locator('[data-testid="user-rank"]')).toContainText(apiUser.rank);
    await expect(page.locator('[data-testid="join-date"]')).toContainText(
      new Date(apiUser.createdAt).toLocaleDateString()
    );
  });

  test('should handle API error responses consistently', async ({ page }) => {
    const apiHelper = new ApiHelper();
    
    // Mock API error
    await page.route('/api/content', route => {
      route.fulfill({
        status: 429,
        contentType: 'application/json',
        body: JSON.stringify({
          error: 'Rate limit exceeded',
          message: 'Please wait 60 seconds before submitting again',
          retryAfter: 60
        })
      });
    });

    await page.goto('/topics/climate-change');
    await page.fill('[data-testid="content-input"]', 'Test content');
    await page.click('[data-testid="submit-content"]');

    // Verify UI handles error appropriately
    await expect(page.locator('[data-testid="error-message"]')).toContainText('Rate limit exceeded');
    await expect(page.locator('[data-testid="retry-countdown"]')).toBeVisible();
  });
});
```

## Test Environment Orchestration

### Docker Compose Test Setup
```yaml
# docker-compose.test.yml
version: '3.8'

services:
  postgres-test:
    image: postgres:15
    environment:
      POSTGRES_DB: overlord_test
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports:
      - "5433:5432"
    volumes:
      - postgres_test_data:/var/lib/postgresql/data

  redis-test:
    image: redis:7-alpine
    ports:
      - "6380:6379"

  api-test:
    build:
      context: ./therobotoverlord-api
      dockerfile: Dockerfile.test
    environment:
      DATABASE_URL: postgresql://test:test@postgres-test:5432/overlord_test
      REDIS_URL: redis://redis-test:6379
      ENVIRONMENT: test
      AI_SERVICE_URL: http://mock-ai:8080
    ports:
      - "8001:8000"
    depends_on:
      - postgres-test
      - redis-test
      - mock-ai
    volumes:
      - ./therobotoverlord-api:/app
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

  web-test:
    build:
      context: ./therobotoverlord-web
      dockerfile: Dockerfile.test
    environment:
      REACT_APP_API_URL: http://api-test:8000
      REACT_APP_ENVIRONMENT: test
    ports:
      - "3001:3000"
    depends_on:
      - api-test
    volumes:
      - ./therobotoverlord-web:/app
      - /app/node_modules
    command: npm start

  mock-ai:
    image: wiremock/wiremock:latest
    ports:
      - "8080:8080"
    volumes:
      - ./tests/mocks/ai-service:/home/wiremock
    command: --global-response-templating

volumes:
  postgres_test_data:
```

### Test Setup Utilities
```typescript
// tests/utils/test-setup.ts
import { execSync } from 'child_process';
import { ApiHelper } from './api-helpers';

export class TestEnvironment {
  private apiHelper: ApiHelper;

  constructor() {
    this.apiHelper = new ApiHelper();
  }

  async setup(): Promise<void> {
    // Start test services
    execSync('docker-compose -f docker-compose.test.yml up -d', { stdio: 'inherit' });
    
    // Wait for services to be ready
    await this.waitForServices();
    
    // Run database migrations
    await this.runMigrations();
    
    // Seed test data
    await this.seedTestData();
  }

  async teardown(): Promise<void> {
    // Clean up test data
    await this.cleanupTestData();
    
    // Stop test services
    execSync('docker-compose -f docker-compose.test.yml down -v', { stdio: 'inherit' });
  }

  private async waitForServices(): Promise<void> {
    const maxAttempts = 30;
    let attempts = 0;

    while (attempts < maxAttempts) {
      try {
        await this.apiHelper.healthCheck();
        console.log('Services are ready');
        return;
      } catch (error) {
        attempts++;
        console.log(`Waiting for services... (${attempts}/${maxAttempts})`);
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }

    throw new Error('Services failed to start within timeout');
  }

  private async runMigrations(): Promise<void> {
    execSync('docker-compose -f docker-compose.test.yml exec api-test alembic upgrade head', 
      { stdio: 'inherit' });
  }

  private async seedTestData(): Promise<void> {
    // Create test topics
    await this.apiHelper.createTopic({
      id: 'topic-climate-change',
      title: 'Climate Change Policy',
      description: 'Debate on climate change policies and solutions'
    });

    await this.apiHelper.createTopic({
      id: 'topic-renewable-energy',
      title: 'Renewable Energy Transition',
      description: 'Discussion on renewable energy adoption strategies'
    });
  }

  private async cleanupTestData(): Promise<void> {
    await this.apiHelper.clearTestData();
  }

  // Add helper method for top percentile checking
  async isInTopPercentile(userId: string, percentile: number): Promise<boolean> {
    const totalUsers = await this.apiHelper.getTotalActiveUsers();
    const userRank = await this.apiHelper.getUserRank(userId);
    const threshold = Math.ceil(totalUsers * percentile);
    return userRank <= threshold;
  }
}

export class TestDataFactory {
  static createUser(overrides: any = {}) {
    return {
      username: `test_user_${Date.now()}`,
      email: `test${Date.now()}@overlord.com`,
      password: 'testpassword123',
      role: 'citizen',
      loyaltyScore: 100,
      rank: 'Loyal Worker',
      ...overrides
    };
  }

  static createContent(overrides: any = {}) {
    return {
      type: 'post',
      text: 'This is a test argument with sufficient length and reasoning.',
      topicId: 'topic-climate-change',
      status: 'pending',
      ...overrides
    };
  }
}
```

## Performance Testing

### Load Testing Configuration
```javascript
// tests/performance/load-testing.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '2m', target: 10 },   // Ramp up
    { duration: '5m', target: 50 },   // Stay at 50 users
    { duration: '2m', target: 100 },  // Ramp to 100 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests under 2s
    errors: ['rate<0.1'],              // Error rate under 10%
  },
};

export default function () {
  // Test content submission endpoint
  const contentPayload = JSON.stringify({
    type: 'post',
    text: 'Load test content submission with sufficient length for validation requirements.',
    topicId: 'topic-climate-change'
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer test-token'
    },
  };

  const response = http.post('http://localhost:8001/api/content', contentPayload, params);
  
  const success = check(response, {
    'status is 201': (r) => r.status === 201,
    'response time < 2000ms': (r) => r.timings.duration < 2000,
  });

  errorRate.add(!success);
  sleep(1);
}
```

## CI/CD Integration

### GitHub Actions Workflow
```yaml
# .github/workflows/e2e-tests.yml
name: End-to-End Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.12'
      
      - name: Install dependencies
        run: |
          npm ci
          pip install -r therobotoverlord-api/requirements.txt
      
      - name: Start test environment
        run: docker-compose -f docker-compose.test.yml up -d
      
      - name: Wait for services
        run: |
          npm run test:wait-for-services
      
      - name: Run E2E tests
        run: |
          npm run test:e2e
      
      - name: Run performance tests
        run: |
          npm run test:performance
      
      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: |
            test-results/
            playwright-report/
      
      - name: Cleanup
        if: always()
        run: docker-compose -f docker-compose.test.yml down -v
```

## Test Scripts

### Package.json Scripts
```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug",
    "test:integration": "playwright test tests/integration",
    "test:performance": "k6 run tests/performance/load-testing.js",
    "test:contracts": "pact-broker can-i-deploy --pacticipant web --version $VERSION",
    "test:setup": "node tests/utils/test-setup.js",
    "test:teardown": "node tests/utils/test-teardown.js",
    "test:wait-for-services": "wait-on http://localhost:8001/health && wait-on http://localhost:3001",
    "test:full-suite": "npm run test:setup && npm run test:e2e && npm run test:performance && npm run test:teardown"
  }
}
```

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
- [ ] Set up Docker Compose test environment
- [ ] Create basic E2E test framework with Playwright
- [ ] Implement test data factories and utilities
- [ ] Set up CI/CD pipeline

### Phase 2: Core E2E Tests (Week 2)
- [ ] Implement content moderation flow tests
- [ ] Add loyalty system integration tests
- [ ] Create Overlord chat system tests
- [ ] Add API-Frontend contract validation

### Phase 3: Advanced Testing (Week 3)
- [ ] Implement performance and load testing
- [ ] Add cross-browser compatibility tests
- [ ] Create test reporting and monitoring
- [ ] Optimize test execution speed

---

**Related Documentation:**
- [API Testing Strategy](./25-api-testing-strategy.md) - Backend testing details
- [Web Testing Strategy](./26-web-testing-strategy.md) - Frontend testing details
- [Deployment Infrastructure](./01-deployment-infrastructure.md) - Environment setup
