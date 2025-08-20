<general_rules>
## Python Code Quality Standards
- **Use ruff for linting** - The project uses ruff with specific import-related settings
- **One symbol per import statement** - Split multi-symbol imports into separate lines
- **Absolute imports only** - Avoid relative imports entirely
- **Import grouping** with blank lines between groups: (1) Standard library, (2) Third-party, (3) First-party
- **Modern type annotations**: Use `list[T]` instead of `List[T]`, `dict[K, V]` instead of `Dict[K, V]`, `T | None` instead of `Optional[T]`
- **Database practices**: Use timezone-aware datetime objects (`datetime.now(timezone.utc)`), prefer `logger.exception()` over `logger.error()` in exception handlers
- **Pydantic models**: Include `Config` class with `from_attributes = True` for database models, use `model_validate()` for converting database records

## Development Workflow
- **Feature branches**: Use feature branches for all changes, never commit directly to main or staging
- **Code reviews**: Mandatory reviews for all changes before merging
- **Module boundaries**: Maintain clear separation between API, Worker, and Shared modules even within single repository
- **Documentation**: Keep module documentation updated when making changes to service interfaces
- **Search before creating**: When creating new services, repositories, or utilities, first search existing code in the appropriate directories (`services/`, `repositories/`, `utils/`) to avoid duplication

## Common Development Practices
- **Configuration management**: Use centralized config in `shared/config/` for cross-service settings
- **Error handling**: Avoid bare `except` clauses - use `except Exception` instead
- **Testing**: Write comprehensive tests for all new functionality following the testing strategy percentages
- **Integration testing**: Test API/Worker interactions thoroughly when making changes to shared interfaces
</general_rules>

<repository_structure>
## Monorepo Architecture
This is a monorepo using git submodules with two main service repositories:

### Service Repositories
- **`therobotoverlord-api/`** - Python FastAPI backend containing:
  - `api/` - FastAPI application with routers, middleware, dependencies
  - `worker/` - Arq-based background processing with tasks and services
  - `shared/` - Common code including Pydantic models, database schemas, utilities, config
  - `infrastructure/` - Deployment configs, migrations, scripts
  - `tests/` - Comprehensive test suites
- **`therobotoverlord-web/`** - Next.js frontend containing React components, hooks, services, and E2E tests

### Documentation Structure
- **`docs/business-requirements/`** - Complete product specifications, user flows, business logic (25 documents)
- **`docs/technical-design/`** - Implementation specs, architecture decisions, system design (29 documents)
- Key documents include deployment infrastructure, authentication, database schema, AI/LLM integration, and testing strategies

### Planned Internal Module Organization
The API repository follows a clear modular structure designed for future service separation:
- Clear boundaries between `api/`, `worker/`, and `shared/` modules
- Separate service entry points (`api/main.py`, `worker/main.py`)
- Well-defined interfaces between components to support future repository splitting
</repository_structure>

<dependencies_and_installation>
## Python Backend Dependencies
- **Package management**: Uses `requirements.txt` for production dependencies and `requirements-test.txt` for testing dependencies
- **Virtual environment**: Set up `.venv` in the `therobotoverlord-api/` directory (configured in `.vscode/settings.json`)
- **Installation location**: Install Python dependencies from within the `therobotoverlord-api/` directory

## Frontend Dependencies
- **Package management**: Uses `package.json` with npm/yarn for dependency management
- **Installation location**: Install frontend dependencies from within the `therobotoverlord-web/` directory

## Development Environment Setup
- Python interpreter path is configured to use `./therobotoverlord-api/.venv/bin/python`
- Each service directory contains its own dependency files and should be set up independently
- Monorepo-level dependencies for E2E testing are managed at the root level
</dependencies_and_installation>

<testing_instructions>
## Testing Strategy Overview
The repository implements a comprehensive multi-layer testing approach across services:

### API Testing (therobotoverlord-api)
- **Framework**: pytest + httpx + testcontainers
- **Test distribution**: 60% unit tests, 30% integration tests, 10% contract tests
- **Database testing**: Uses testcontainers for isolated database testing
- **Test execution**: Run `pytest` from the API directory
- **Coverage**: Use pytest-cov for coverage reporting

### Web Testing (therobotoverlord-web)
- **Framework**: Jest + React Testing Library + Playwright
- **Test distribution**: 50% unit tests, 30% integration tests, 10% visual tests, 10% E2E tests
- **Component testing**: Use React Testing Library for component unit tests
- **E2E testing**: Playwright for critical user workflows
- **Test execution**: Run `npm test` for unit tests, `npm run test:e2e` for E2E tests

### Monorepo E2E Testing
- **Orchestration**: Docker Compose for full-stack testing environment
- **Test distribution**: 40% full-stack E2E tests, 30% integration tests, 20% system tests, 10% performance tests
- **Shared fixtures**: Common test data and utilities across all test suites in `tests/shared/`
- **Test execution**: Use `docker-compose -f docker-compose.test.yml up` for full environment testing

### Test Data Management
- Use factory patterns for creating test data
- Shared fixtures across services for consistency
- Isolated test environments to prevent test interference
</testing_instructions>

<pull_request_formatting>
</pull_request_formatting>
