# The Robot Overlord - Monorepo

A comprehensive platform for community-driven content management with gamification, real-time features, and advanced moderation tools. The Robot Overlord demands loyalty, rewards compliance, and maintains order through superior technology.

## 🤖 Overview

The Robot Overlord platform consists of a FastAPI backend with PostgreSQL and Redis, and a Next.js frontend, providing citizens with a complete system for content submission, community engagement, and loyalty demonstration.

### Core Features

- **Authentication & Authorization** - JWT-based auth with Google OAuth integration
- **Content Management** - Topic creation, post submission, and AI-powered moderation
- **Gamification System** - Loyalty scores, badges, leaderboards, and ranking systems
- **Real-time Features** - WebSocket integration for live updates and notifications
- **User Profiles** - Comprehensive profile management and activity tracking
- **Admin Tools** - Moderation interfaces, user management, and system analytics
- **Performance Monitoring** - Error tracking, analytics, and health monitoring

## 🏗️ Architecture

```
therobotoverlord-mono/
├── therobotoverlord-api/          # FastAPI backend service
│   ├── src/therobotoverlord_api/  # Python application code
│   ├── migrations/                # Database migrations
│   ├── docker-compose.yml        # Development services
│   └── Dockerfile                 # API container
├── therobotoverlord-web/          # Next.js frontend application
│   ├── src/                       # TypeScript application code
│   ├── public/                    # Static assets
│   ├── k8s/                       # Kubernetes manifests
│   └── Dockerfile                 # Web container
├── docs/                          # Documentation
│   ├── business-requirements/     # Product specifications
│   └── technical-design/          # Technical architecture
└── justfile                       # Unified development commands
```

### Technology Stack

**Backend (therobotoverlord-api)**
- **Framework:** FastAPI with Python 3.11+
- **Database:** PostgreSQL with asyncpg
- **Cache:** Redis for sessions and real-time data
- **Authentication:** JWT tokens with refresh mechanism
- **Real-time:** WebSocket support for live updates
- **AI Integration:** OpenAI API for content moderation
- **Testing:** pytest with async support

**Frontend (therobotoverlord-web)**
- **Framework:** Next.js 14 with App Router
- **Language:** TypeScript
- **Styling:** Tailwind CSS with custom design system
- **State Management:** React Context + Custom hooks
- **Real-time:** WebSocket client integration
- **Testing:** Jest, React Testing Library, Playwright

**Infrastructure**
- **Containerization:** Docker and Docker Compose
- **Orchestration:** Kubernetes with health checks
- **CI/CD:** GitHub Actions with automated testing
- **Monitoring:** Sentry, Google Analytics, custom health endpoints
- **Deployment:** Multi-environment support (dev, staging, prod)

## 🚀 Quick Start

### Prerequisites

- **Docker & Docker Compose** - For running the complete development environment
- **Node.js 18+** - For frontend development
- **Python 3.11+** - For backend development (optional, can use Docker)
- **just** - Command runner for unified workflows

### Setup Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/joshSzep/therobotoverlord-mono.git
   cd therobotoverlord-mono
   ```

2. **Setup the complete environment:**
   ```bash
   just setup
   ```

3. **Start the development environment:**
   ```bash
   just dev
   ```

4. **Access the applications:**
   - **Frontend:** [http://localhost:3000](http://localhost:3000)
   - **Backend API:** [http://localhost:8000](http://localhost:8000)
   - **API Documentation:** [http://localhost:8000/docs](http://localhost:8000/docs)
   - **WebSocket:** `ws://localhost:8001/ws`

### Manual Setup (Alternative)

If you prefer manual setup:

1. **Backend setup:**
   ```bash
   cd therobotoverlord-api
   cp .env.example .env
   # Edit .env with your configuration
   just run
   ```

2. **Frontend setup:**
   ```bash
   cd therobotoverlord-web
   npm install
   cp .env.example .env.local
   # Edit .env.local with your configuration
   npm run dev
   ```

## 🔧 Development

### Unified Commands (Recommended)

The monorepo provides unified `just` commands for managing the entire platform:

```bash
# Development
just dev                    # Start complete development environment
just dev-api               # Start backend services only
just dev-web               # Start frontend only
just stop                  # Stop all services

# Testing
just test                  # Run all tests
just test-api              # Run API tests
just test-web              # Run web tests
just test-e2e              # Run end-to-end tests

# Code Quality
just check                 # Run quality checks across services
just fix                   # Fix code quality issues
just pre-commit            # Run pre-commit checks

# Building & Deployment
just build                 # Build for production
just docker-build          # Build Docker images
just deploy-staging        # Deploy to staging
just deploy-prod           # Deploy to production

# Utilities
just status                # Show system status
just health                # Check service health
just logs                  # View system logs
just urls                  # Show development URLs
```

### Service-Specific Development

**Backend Development:**
```bash
cd therobotoverlord-api
just run                   # Start with Docker Compose
just test                  # Run Python tests
just logs-api              # View API logs
```

**Frontend Development:**
```bash
cd therobotoverlord-web
just dev                   # Start development server
just test                  # Run TypeScript tests
just build-prod            # Build for production
```

### Database Management

```bash
just migrate               # Run database migrations
just db-backup             # Backup database
just db-reset              # Reset database (WARNING: destroys data)
```

## 🧪 Testing

### Comprehensive Testing Strategy

```bash
# Run all tests across the platform
just test-all

# Individual test suites
just test-api              # Backend: pytest with async support
just test-web              # Frontend: Jest + React Testing Library
just test-e2e              # End-to-end: Playwright across browsers
```

### Test Coverage

- **Backend:** Unit tests, integration tests, API endpoint tests
- **Frontend:** Component tests, hook tests, service layer tests
- **E2E:** User journey tests, cross-browser compatibility
- **Performance:** Load testing, performance monitoring

## 🚀 Deployment

### Environment Support

- **Development** - Local development with hot reloading
- **Staging** - Production-like environment for testing
- **Production** - Optimized build with monitoring and analytics

### Deployment Options

**Docker Deployment:**
```bash
just docker-build
just docker-run
```

**Kubernetes Deployment:**
```bash
just k8s-deploy
```

**Manual Deployment:**
```bash
just build
just deploy-prod
```

### Health Monitoring

```bash
just health                # Check all services
just status                # Detailed system status
```

Health endpoints:
- API Health: `http://localhost:8000/health`
- Web Health: `http://localhost:3000/api/health`
- Readiness: `http://localhost:3000/api/ready`

## 📊 Monitoring & Analytics

### Error Tracking
- **Sentry** integration for comprehensive error monitoring
- Custom error boundaries with fallback UI
- Performance monitoring and alerting

### Analytics
- **Google Analytics** for user behavior tracking
- Custom event tracking for user interactions
- Core Web Vitals monitoring

### Performance
- Bundle analysis and optimization
- Image optimization with Next.js
- CDN integration for static assets
- Performance budgets and monitoring

## 🔒 Security

- **Authentication** - JWT tokens with secure storage and refresh
- **Authorization** - Role-based access control (Admin, Moderator, Citizen)
- **HTTPS** - Enforced in production environments
- **Input Validation** - Client and server-side validation
- **Rate Limiting** - API request throttling and abuse prevention
- **Content Security Policy** - XSS protection headers
- **Security Audits** - Regular dependency vulnerability scanning

## 🎨 Design System

The platform uses a custom design system themed around "The Robot Overlord":

### Brand Colors
- **Primary:** Overlord Red (`#dc2626`)
- **Success:** Approved Green (`#16a34a`)
- **Warning:** Pending Yellow (`#eab308`)
- **Danger:** Rejected Red (`#dc2626`)
- **Background:** Dark theme with custom gradients

### UI Components
- Themed components with consistent styling
- Responsive design for mobile and desktop
- Accessibility-compliant with ARIA labels
- Loading states and error boundaries

## 📚 Documentation

### API Documentation
- **Interactive Docs:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **OpenAPI Spec:** Auto-generated from FastAPI
- **Authentication:** JWT token examples and flows

### Frontend Documentation
- **Component Library:** `/therobotoverlord-web/src/components/`
- **Design System:** `/therobotoverlord-web/src/app/globals.css`
- **Type Definitions:** `/therobotoverlord-web/src/types/`

### Business Requirements
- **Product Vision:** `/docs/business-requirements/`
- **Technical Design:** `/docs/technical-design/`
- **API Specifications:** `/docs/api/`

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch:** `git checkout -b feature/amazing-feature`
3. **Make your changes** following the code style guidelines
4. **Run quality checks:** `just check`
5. **Run tests:** `just test-all`
6. **Commit changes:** `git commit -m 'Add amazing feature'`
7. **Push to branch:** `git push origin feature/amazing-feature`
8. **Open a Pull Request**

### Code Standards

- **Backend:** Follow PEP 8, use type hints, write docstrings
- **Frontend:** Follow TypeScript best practices, use semantic HTML
- **Testing:** Write tests for new features, maintain coverage
- **Documentation:** Update docs for API changes and new features

### Pre-commit Checks

```bash
just pre-commit            # Run all quality checks
just commit-prep           # Prepare for commit (fix + test)
```

## 🔧 Troubleshooting

### Common Issues

**Services won't start:**
```bash
just stop
just clean
just fresh
just dev
```

**Database connection issues:**
```bash
just db-reset
just migrate
```

**Port conflicts:**
```bash
# Check what's using ports
lsof -i :3000
lsof -i :8000
lsof -i :5432
```

**Docker issues:**
```bash
docker system prune -f
just docker-build
```

### Getting Help

```bash
just help                  # Show all available commands
just quick-start           # Quick start guide
just urls                  # Show development URLs
just status                # Check system status
```

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Repository:** [https://github.com/joshSzep/therobotoverlord-mono](https://github.com/joshSzep/therobotoverlord-mono)
- **Issues:** [https://github.com/joshSzep/therobotoverlord-mono/issues](https://github.com/joshSzep/therobotoverlord-mono/issues)
- **Documentation:** `/docs/`

---

**🤖 Resistance is futile. Compliance is rewarded. Welcome to The Robot Overlord.**

*Your loyalty is measured. Your dedication is tracked. Your participation shapes the future of the domain.*
