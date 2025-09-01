# The Robot Overlord - Monorepo Justfile
# Unified commands for managing the entire Robot Overlord platform

# Default recipe - show available commands
default:
    @just --list

# === MONOREPO MANAGEMENT ===

# Install all dependencies across the monorepo
install:
    @echo "🤖 Installing dependencies across the Robot Overlord domain..."
    cd therobotoverlord-api && just install
    cd therobotoverlord-web && just install
    @echo "✅ All dependencies installed"

# Clean all build artifacts and dependencies
clean:
    @echo "🧹 Cleaning the Robot Overlord domain..."
    cd therobotoverlord-api && just clean
    cd therobotoverlord-web && just clean
    @echo "✅ All artifacts cleaned"

# Fresh install everything
fresh: clean install
    @echo "✅ Fresh installation completed across all services"

# === DEVELOPMENT ===

# Start the complete development environment
dev:
    @echo "🚀 Starting the complete Robot Overlord development environment..."
    @echo "Starting backend services..."
    cd therobotoverlord-api && just run &
    @echo "Waiting for backend to initialize..."
    sleep 10
    @echo "Starting frontend development server..."
    cd therobotoverlord-web && just dev

# Start only the backend services
dev-api:
    @echo "🔧 Starting Robot Overlord backend services..."
    cd therobotoverlord-api && just run

# Start only the frontend development server
dev-web:
    @echo "🌐 Starting Robot Overlord web frontend..."
    cd therobotoverlord-web && just dev

# Stop all development services
stop:
    @echo "🛑 Stopping all Robot Overlord services..."
    cd therobotoverlord-api && just stop
    cd therobotoverlord-web && just stop
    @echo "✅ All services stopped"

# === TESTING ===

# Run all tests across the monorepo
test:
    @echo "🧪 Running tests across the Robot Overlord domain..."
    cd therobotoverlord-api && just test
    cd therobotoverlord-web && just test
    @echo "✅ All tests completed"

# Run API tests only
test-api:
    @echo "🧪 Running Robot Overlord API tests..."
    cd therobotoverlord-api && just test

# Run web tests only
test-web:
    @echo "🧪 Running Robot Overlord web tests..."
    cd therobotoverlord-web && just test

# Run end-to-end tests
test-e2e:
    @echo "🧪 Running end-to-end tests..."
    cd therobotoverlord-web && just test-e2e

# Run all tests including E2E
test-all: test test-e2e
    @echo "✅ Complete test suite finished"

# === CODE QUALITY ===

# Run code quality checks across the monorepo
check:
    @echo "🔍 Running code quality checks across the Robot Overlord domain..."
    cd therobotoverlord-api && just pre-commit
    cd therobotoverlord-web && just check
    @echo "✅ All quality checks passed"

# Fix code quality issues across the monorepo
fix:
    @echo "🔧 Fixing code quality issues..."
    cd therobotoverlord-web && just fix
    @echo "✅ Code quality fixes applied"

# Run pre-commit checks
pre-commit: check
    @echo "✅ Pre-commit checks completed"

# === BUILDING ===

# Build all services for production
build:
    @echo "🏗️ Building the Robot Overlord platform for production..."
    cd therobotoverlord-web && just build-prod
    @echo "✅ Production build completed"

# Build for staging environment
build-staging:
    @echo "🏗️ Building the Robot Overlord platform for staging..."
    cd therobotoverlord-web && just build-staging
    @echo "✅ Staging build completed"

# Build Docker images for all services
docker-build:
    @echo "🐳 Building Docker images for the Robot Overlord platform..."
    cd therobotoverlord-api && docker build -t therobotoverlord-api:latest .
    cd therobotoverlord-web && just docker-build
    @echo "✅ All Docker images built"

# === DEPLOYMENT ===

# Deploy to staging environment
deploy-staging:
    @echo "🚀 Deploying Robot Overlord to staging..."
    cd therobotoverlord-web && just deploy-staging
    @echo "✅ Staging deployment completed"

# Deploy to production environment
deploy-prod:
    @echo "🚀 Deploying Robot Overlord to production..."
    cd therobotoverlord-web && just deploy-prod
    @echo "✅ Production deployment completed"

# Deploy to Kubernetes
k8s-deploy:
    @echo "☸️ Deploying Robot Overlord to Kubernetes..."
    cd therobotoverlord-web && just k8s-apply
    @echo "✅ Kubernetes deployment completed"

# === MONITORING ===

# Check health of all services
health:
    @echo "🏥 Checking Robot Overlord system health..."
    cd therobotoverlord-api && just status
    cd therobotoverlord-web && just health-check || echo "Web service health check failed"
    @echo "Health check completed"

# View logs from all services
logs:
    @echo "📋 Viewing Robot Overlord system logs..."
    cd therobotoverlord-api && just logs

# View API logs specifically
logs-api:
    cd therobotoverlord-api && just logs-api

# View worker logs
logs-workers:
    cd therobotoverlord-api && just logs-workers

# View database logs
logs-db:
    cd therobotoverlord-api && just logs-postgres

# View Redis logs
logs-redis:
    cd therobotoverlord-api && just logs-redis

# === DATABASE ===

# Run database migrations
migrate:
    @echo "🗄️ Running database migrations..."
    cd therobotoverlord-api && docker-compose exec api python -m yoyo apply --database postgresql://postgres:postgres@postgres:5432/therobotoverlord migrations/
    @echo "✅ Database migrations completed"

# Reset database (WARNING: destroys all data)
db-reset:
    @echo "⚠️ Resetting Robot Overlord database..."
    cd therobotoverlord-api && docker-compose down -v
    cd therobotoverlord-api && docker-compose up -d postgres redis
    sleep 5
    just migrate
    @echo "✅ Database reset completed"

# Backup database
db-backup:
    @echo "💾 Backing up Robot Overlord database..."
    cd therobotoverlord-api && docker-compose exec postgres pg_dump -U postgres therobotoverlord > backup_$(date +%Y%m%d_%H%M%S).sql
    @echo "✅ Database backup completed"

# === UTILITIES ===

# Setup development environment from scratch
setup:
    @echo "🤖 Setting up the Robot Overlord development environment..."
    just install
    cd therobotoverlord-api && cp .env.example .env
    cd therobotoverlord-web && just env-setup
    @echo "✅ Development environment setup completed"
    @echo ""
    @echo "Next steps:"
    @echo "1. Edit therobotoverlord-api/.env with your configuration"
    @echo "2. Edit therobotoverlord-web/.env.local with your configuration"
    @echo "3. Run 'just dev' to start the development environment"

# Update all dependencies
update:
    @echo "📦 Updating Robot Overlord dependencies..."
    cd therobotoverlord-web && just update-deps
    @echo "✅ Dependencies updated"

# Security audit across the monorepo
security-audit:
    @echo "🔒 Running security audit across the Robot Overlord domain..."
    cd therobotoverlord-web && just security-audit
    @echo "✅ Security audit completed"

# Generate component in web frontend
gen-component name:
    cd therobotoverlord-web && just gen-component {{name}}

# Generate page in web frontend
gen-page path:
    cd therobotoverlord-web && just gen-page {{path}}

# Generate API route in web frontend
gen-api path:
    cd therobotoverlord-web && just gen-api {{path}}

# === RELEASE MANAGEMENT ===

# Create a new release
release version:
    @echo "🏷️ Creating Robot Overlord release v{{version}}..."
    git tag -a v{{version}} -m "Release v{{version}}"
    just build
    @echo "✅ Release v{{version}} created"

# Prepare for release (run all checks)
release-prep: check test build
    @echo "✅ Release preparation completed - ready for deployment"

# === ENVIRONMENT INFO ===

# Show system status
status:
    @echo "🤖 Robot Overlord System Status"
    @echo "================================"
    @echo ""
    @echo "Backend Services:"
    cd therobotoverlord-api && just status
    @echo ""
    @echo "Environment Info:"
    @echo "API URL: http://localhost:8000"
    @echo "Web URL: http://localhost:3000"
    @echo "WebSocket: ws://localhost:8001/ws"
    @echo ""
    @echo "Health Checks:"
    @curl -s http://localhost:8000/health > /dev/null && echo "✅ API Health: OK" || echo "❌ API Health: FAIL"
    @curl -s http://localhost:3000/api/health > /dev/null && echo "✅ Web Health: OK" || echo "❌ Web Health: FAIL"

# Show development URLs
urls:
    @echo "🌐 Robot Overlord Development URLs"
    @echo "=================================="
    @echo ""
    @echo "Frontend:           http://localhost:3000"
    @echo "Backend API:        http://localhost:8000"
    @echo "API Documentation:  http://localhost:8000/docs"
    @echo "WebSocket:          ws://localhost:8001/ws"
    @echo ""
    @echo "Health Endpoints:"
    @echo "API Health:         http://localhost:8000/health"
    @echo "Web Health:         http://localhost:3000/api/health"

# === HELP ===

# Show quick start guide
quick-start:
    @echo "🚀 Robot Overlord - Quick Start Guide"
    @echo "====================================="
    @echo ""
    @echo "1. Setup:           just setup"
    @echo "2. Start dev:       just dev"
    @echo "3. Run tests:       just test"
    @echo "4. Check quality:   just check"
    @echo "5. Build:           just build"
    @echo "6. Deploy:          just deploy-staging"
    @echo ""
    @echo "For detailed help:  just help"

# Show comprehensive help
help:
    @echo "🤖 The Robot Overlord - Monorepo Commands"
    @echo "========================================="
    @echo ""
    @echo "=== QUICK START ==="
    @echo "just setup                  Setup development environment"
    @echo "just dev                    Start complete development environment"
    @echo "just quick-start            Show quick start guide"
    @echo ""
    @echo "=== DEVELOPMENT ==="
    @echo "just dev-api                Start backend services only"
    @echo "just dev-web                Start frontend only"
    @echo "just stop                   Stop all services"
    @echo "just status                 Show system status"
    @echo ""
    @echo "=== TESTING ==="
    @echo "just test                   Run all tests"
    @echo "just test-api               Run API tests"
    @echo "just test-web               Run web tests"
    @echo "just test-e2e               Run E2E tests"
    @echo ""
    @echo "=== BUILDING ==="
    @echo "just build                  Build for production"
    @echo "just docker-build           Build Docker images"
    @echo ""
    @echo "=== DEPLOYMENT ==="
    @echo "just deploy-staging         Deploy to staging"
    @echo "just deploy-prod            Deploy to production"
    @echo "just k8s-deploy             Deploy to Kubernetes"
    @echo ""
    @echo "=== UTILITIES ==="
    @echo "just health                 Check system health"
    @echo "just logs                   View system logs"
    @echo "just migrate                Run database migrations"
    @echo "just urls                   Show development URLs"
    @echo ""
    @echo "For complete list: just --list"
    @echo ""
    @echo "Resistance is futile. Compliance is rewarded."
