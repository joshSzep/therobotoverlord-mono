# Frontend Web Testing Strategy (`therobotoverlord-web`)

## Overview

Comprehensive testing strategy for the frontend web component, covering component tests, integration tests, visual regression, accessibility, and cross-browser compatibility.

## Testing Architecture

### Test Categories
- **Unit Tests (50%)**: Components, utilities, state management
- **Integration Tests (30%)**: API client, routing, user flows
- **Visual Tests (10%)**: UI consistency, responsive design
- **E2E Tests (10%)**: Critical user workflows

### Technology Stack
- **Test Framework**: Jest + React Testing Library
- **Component Testing**: @testing-library/react
- **E2E Testing**: Playwright
- **Visual Testing**: Chromatic or Percy
- **Accessibility**: @axe-core/react, jest-axe
- **Mocking**: MSW (Mock Service Worker)

## Project Structure
```
therobotoverlord-web/
├── src/
│   ├── components/
│   │   ├── __tests__/
│   │   │   ├── ContentSubmission.test.tsx
│   │   │   ├── QueueStatus.test.tsx
│   │   │   └── OverlordChat.test.tsx
│   │   └── ContentSubmission.tsx
│   ├── pages/
│   │   ├── __tests__/
│   │   │   ├── TopicPage.test.tsx
│   │   │   └── ProfilePage.test.tsx
│   │   └── TopicPage.tsx
│   ├── hooks/
│   │   ├── __tests__/
│   │   │   ├── useAuth.test.ts
│   │   │   └── useQueue.test.ts
│   │   └── useAuth.ts
│   ├── services/
│   │   ├── __tests__/
│   │   │   └── api.test.ts
│   │   └── api.ts
│   └── utils/
│       ├── __tests__/
│       │   └── formatting.test.ts
│       └── formatting.ts
├── tests/
│   ├── e2e/
│   │   ├── content-submission.spec.ts
│   │   ├── moderation-flow.spec.ts
│   │   └── overlord-chat.spec.ts
│   ├── fixtures/
│   │   ├── users.json
│   │   └── content.json
│   ├── helpers/
│   │   ├── test-utils.tsx
│   │   ├── mock-api.ts
│   │   └── test-data.ts
│   └── setup.ts
├── playwright.config.ts
└── jest.config.js
```

## Component Testing

### Test Utilities Setup
```typescript
// tests/helpers/test-utils.tsx
import React, { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '../src/contexts/AuthContext';
import { ThemeProvider } from '../src/contexts/ThemeContext';

interface AllTheProvidersProps {
  children: React.ReactNode;
}

const AllTheProviders = ({ children }: AllTheProvidersProps) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false }
    }
  });

  return (
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <ThemeProvider>
            {children}
          </ThemeProvider>
        </AuthProvider>
      </QueryClientProvider>
    </BrowserRouter>
  );
};

const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTheProviders, ...options });

export * from '@testing-library/react';
export { customRender as render };
```

### Component Unit Tests

#### Content Submission Component
```typescript
// src/components/__tests__/ContentSubmission.test.tsx
import { render, screen, fireEvent, waitFor } from '../../tests/helpers/test-utils';
import { ContentSubmission } from '../ContentSubmission';
import { server } from '../../tests/helpers/mock-api';
import { rest } from 'msw';

describe('ContentSubmission', () => {
  const mockTopic = {
    id: 'topic-123',
    title: 'Climate Change Policy Debate',
    description: 'Debate on climate policy approaches'
  };

  beforeEach(() => {
    server.resetHandlers();
  });

  it('should render content submission form', () => {
    render(<ContentSubmission topic={mockTopic} />);
    
    expect(screen.getByRole('textbox', { name: /your argument/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /submit for review/i })).toBeInTheDocument();
    expect(screen.getByText(/character count/i)).toBeInTheDocument();
  });

  it('should validate content length requirements', async () => {
    render(<ContentSubmission topic={mockTopic} />);
    
    const textArea = screen.getByRole('textbox', { name: /your argument/i });
    const submitButton = screen.getByRole('button', { name: /submit for review/i });
    
    // Test minimum length
    fireEvent.change(textArea, { target: { value: 'Too short' } });
    fireEvent.click(submitButton);
    
    await waitFor(() => {
      expect(screen.getByText(/minimum 50 characters required/i)).toBeInTheDocument();
    });
  });

  it('should submit content successfully', async () => {
    server.use(
      rest.post('/api/content', (req, res, ctx) => {
        return res(ctx.json({
          id: 'content-456',
          status: 'pending',
          queuePosition: 5,
          estimatedProcessingTime: '15 minutes'
        }));
      })
    );

    render(<ContentSubmission topic={mockTopic} />);
    
    const textArea = screen.getByRole('textbox', { name: /your argument/i });
    const submitButton = screen.getByRole('button', { name: /submit for review/i });
    
    fireEvent.change(textArea, { 
      target: { 
        value: 'According to NASA data, global temperatures have increased by 1.1°C since pre-industrial times.' 
      } 
    });
    
    fireEvent.click(submitButton);
    
    await waitFor(() => {
      expect(screen.getByText(/submitted successfully/i)).toBeInTheDocument();
      expect(screen.getByText(/queue position: 5/i)).toBeInTheDocument();
    });
  });
});
```

#### Queue Status Component
```typescript
// src/components/__tests__/QueueStatus.test.tsx
import { render, screen, waitFor } from '../../tests/helpers/test-utils';
import { QueueStatus } from '../QueueStatus';
import { server } from '../../tests/helpers/mock-api';
import { rest } from 'msw';

describe('QueueStatus', () => {
  beforeEach(() => {
    server.resetHandlers();
  });

  it('should display user queue information', async () => {
    server.use(
      rest.get('/api/queue/status', (req, res, ctx) => {
        return res(ctx.json({
          userSubmissions: [
            {
              id: 'content-1',
              status: 'pending',
              queuePosition: 3,
              estimatedWaitTime: '10 minutes',
              text: 'Climate change evidence...'
            }
          ],
          totalQueueLength: 25,
          averageProcessingTime: '12 minutes'
        }));
      })
    );

    render(<QueueStatus />);
    
    await waitFor(() => {
      expect(screen.getByText(/queue position: 3/i)).toBeInTheDocument();
      expect(screen.getByText(/estimated wait: 10 minutes/i)).toBeInTheDocument();
    });
  });

  it('should handle loading and error states', async () => {
    server.use(
      rest.get('/api/queue/status', (req, res, ctx) => {
        return res(ctx.status(500), ctx.json({ error: 'Server error' }));
      })
    );

    render(<QueueStatus />);
    
    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
    
    await waitFor(() => {
      expect(screen.getByText(/failed to load queue status/i)).toBeInTheDocument();
    });
  });
});
```

### Custom Hooks Testing

#### useAuth Hook
```typescript
// src/hooks/__tests__/useAuth.test.ts
import { renderHook, act } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAuth } from '../useAuth';
import { server } from '../../tests/helpers/mock-api';
import { rest } from 'msw';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } }
  });
  
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
};

describe('useAuth', () => {
  beforeEach(() => {
    server.resetHandlers();
    localStorage.clear();
  });

  it('should handle successful login', async () => {
    server.use(
      rest.post('/api/auth/login', (req, res, ctx) => {
        return res(ctx.json({
          user: { id: 'user-123', username: 'test_citizen', role: 'citizen' },
          accessToken: 'mock-jwt-token'
        }));
      })
    );

    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() });

    await act(async () => {
      await result.current.login('test@example.com', 'password123');
    });

    expect(result.current.user).toEqual({
      id: 'user-123',
      username: 'test_citizen',
      role: 'citizen'
    });
    expect(result.current.isAuthenticated).toBe(true);
  });

  it('should handle logout', async () => {
    localStorage.setItem('accessToken', 'existing-token');
    
    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() });

    act(() => {
      result.current.logout();
    });

    expect(result.current.user).toBeNull();
    expect(result.current.isAuthenticated).toBe(false);
  });
});
```

## End-to-End Testing with Playwright

### E2E Test Configuration
```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure'
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    }
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

### Content Submission E2E Test
```typescript
// tests/e2e/content-submission.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Content Submission Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.route('/api/auth/login', async route => {
      await route.fulfill({
        json: {
          user: { id: 'user-123', username: 'test_citizen', role: 'citizen' },
          accessToken: 'mock-token'
        }
      });
    });
  });

  test('should complete full content submission workflow', async ({ page }) => {
    await page.goto('/');

    // Login
    await page.click('[data-testid="login-button"]');
    await page.fill('[data-testid="email-input"]', 'citizen@overlord.com');
    await page.fill('[data-testid="password-input"]', 'secure123');
    await page.click('[data-testid="submit-login"]');

    // Submit content
    await page.waitForSelector('[data-testid="content-input"]');
    await page.fill('[data-testid="content-input"]', 
      'According to IPCC AR6, immediate climate action is essential for limiting warming to 1.5°C.');
    
    await page.route('/api/content', async route => {
      await route.fulfill({
        json: {
          id: 'content-456',
          status: 'pending',
          queuePosition: 3,
          estimatedProcessingTime: '12 minutes'
        }
      });
    });

    await page.click('[data-testid="submit-content"]');

    // Verify success message
    await expect(page.locator('[data-testid="submission-success"]')).toBeVisible();
    await expect(page.locator('text=Queue position: 3')).toBeVisible();
  });

  test('should handle validation errors', async ({ page }) => {
    await page.goto('/topics/climate-change');
    
    await page.fill('[data-testid="content-input"]', 'Too short');
    await page.click('[data-testid="submit-content"]');

    await expect(page.locator('text=minimum 50 characters required')).toBeVisible();
  });
});
```

## Visual Regression Testing

### Storybook Configuration
```typescript
// .storybook/main.ts
import type { StorybookConfig } from '@storybook/react-vite';

const config: StorybookConfig = {
  stories: ['../src/**/*.stories.@(js|jsx|ts|tsx|mdx)'],
  addons: [
    '@storybook/addon-essentials',
    '@storybook/addon-a11y',
    '@chromatic-com/storybook'
  ],
  framework: {
    name: '@storybook/react-vite',
    options: {},
  },
};

export default config;
```

## Accessibility Testing

### Automated A11y Tests
```typescript
// src/components/__tests__/ContentSubmission.a11y.test.tsx
import { render } from '../../tests/helpers/test-utils';
import { axe, toHaveNoViolations } from 'jest-axe';
import { ContentSubmission } from '../ContentSubmission';

expect.extend(toHaveNoViolations);

describe('ContentSubmission Accessibility', () => {
  it('should not have accessibility violations', async () => {
    const { container } = render(
      <ContentSubmission topic={{ id: 'topic-1', title: 'Test Topic' }} />
    );
    
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should have proper ARIA labels', () => {
    render(<ContentSubmission topic={{ id: 'topic-1', title: 'Test Topic' }} />);
    
    expect(screen.getByRole('textbox')).toHaveAttribute('aria-label');
    expect(screen.getByRole('button')).toHaveAttribute('aria-describedby');
  });
});
```

## Test Configuration

### Jest Configuration
```javascript
// jest.config.js
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy'
  },
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{ts,tsx}'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

### Test Scripts
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:visual": "chromatic --exit-zero-on-changes"
  }
}
```

## Implementation Roadmap

### Phase 1: Foundation (Week 1)
- [ ] Set up Jest + React Testing Library
- [ ] Create test utilities and providers
- [ ] Implement basic component tests
- [ ] Set up MSW for API mocking

### Phase 2: Core Testing (Week 2)
- [ ] Complete component test suite
- [ ] Add custom hook tests
- [ ] Implement integration tests
- [ ] Set up Playwright for E2E

### Phase 3: Advanced Testing (Week 3)
- [ ] Add visual regression testing
- [ ] Implement accessibility tests
- [ ] Create performance tests
- [ ] Set up CI/CD pipeline

---

**Related Documentation:**
- [API Testing Strategy](./25-api-testing-strategy.md) - Backend testing approach
- [Component Library](./02-frontend-design.md) - Components to test
- [User Experience](./03-look-feel.md) - UX patterns to validate
