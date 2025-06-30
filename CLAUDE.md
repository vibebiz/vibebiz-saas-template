# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Root-level Commands (Monorepo Orchestration)

```bash
# Development
pnpm dev                    # Start all services in development mode via Turborepo
pnpm build                  # Build all packages and services
pnpm clean                  # Clean all build artifacts and node_modules

# Testing
pnpm test                   # Run all tests across the monorepo
pnpm test:coverage          # Run tests with coverage reporting
pnpm test:unit              # Run only unit tests

# Code Quality
pnpm lint                   # Run linting across all packages
pnpm type-check             # Run TypeScript type checking
pnpm format                # Format code with Prettier
pnpm all-checks            # Run comprehensive quality checks (./scripts/run-all-checks.sh)
pnpm validate              # Run lint, type-check, and test together
```

### Service-Specific Commands

#### Next.js Applications (apps/public-web)

```bash
cd apps/public-web
pnpm dev                   # Start Next.js development server
pnpm build                 # Build production bundle
pnpm start                 # Start production server
pnpm test                  # Run Jest tests
pnpm test:watch            # Run tests in watch mode
pnpm test:coverage         # Run tests with coverage
pnpm lint                  # Run ESLint
pnpm type-check            # Run TypeScript compiler (tsc --noEmit)
pnpm clean                 # Clean build artifacts
pnpm format                # Format code with Prettier
```

#### Python Services (services/public-api)

```bash
cd services/public-api
pytest                     # Run all tests
pytest --cov=src           # Run tests with coverage
pytest -m unit             # Run only unit tests marked with @pytest.mark.unit
pytest -m "not slow"       # Exclude slow tests

# Python code quality tools
ruff check src             # Lint with ruff
ruff format src            # Format with ruff
black .                    # Format with black (line-length 88)
mypy src                   # Type checking with mypy
isort .                    # Sort imports
bandit -r src              # Security scanning
```

## Architecture Overview

### VibeBiz SaaS Template System

This repository contains a **progressive multi-tenant SaaS template** designed to scale from MVP (0-1K users) to Full-Stack enterprise (100K+ users). The architecture follows a "start minimal, grow smart" approach with **four-stage progressive architecture**: MVP → Foundation → Growth → Full-Stack.

**Key Concepts:**

- **Progressive Architecture**: Start minimal, grow smart with defined migration paths
- **Multi-tenant by Design**: Row-Level Security (RLS) and organization-based tenancy from day one
- **License-Gated Components**: Different features available based on license tier (DEV < FOUNDATION < GROWTH < FULL < AGENCY)
- **API-First Design**: All services communicate via authenticated REST APIs

### Current Repository Structure (MVP Stage)

```
vibebiz-saas-template/
├── apps/                    # User-facing applications
│   └── public-web/         # Next.js customer application with NextAuth.js
├── services/               # Backend APIs and microservices
│   ├── public-api/         # Core business API (FastAPI)
│   ├── auth/               # Authentication service (planned)
│   ├── organizations/      # Multi-tenant org management (planned)
│   ├── notifications/      # Email/SMS notifications (planned)
│   └── users/              # User management (planned)
├── packages/               # Shared libraries (@vibebiz/ scoped)
│   ├── shared-types/       # TypeScript type definitions
│   ├── database/           # Shared DB schemas & migrations (planned)
│   ├── api-client/         # Generated TypeScript client (planned)
│   └── ui-components/      # Shared React components (planned)
├── infra/                  # Infrastructure as Code (Terraform)
├── tools/                  # Development tools and generators
├── scripts/                # Development and deployment scripts
├── docs/                   # Documentation files
├── .github/workflows/      # CI/CD pipeline templates
├── .cursor/rules/          # Comprehensive development standards (15 rule files)
└── product-requirements/   # Architecture and implementation specs (ignored in git)
```

### Core Data Model (Multi-Tenant)

Based on the PRD, the system uses PostgreSQL with Row-Level Security (RLS) and these key entities:

**Authentication & Users:**

- `users`: Core user accounts with bcrypt password hashing (cost factor 12)
- `user_sessions`: JWT session management with revocation support

**Multi-Tenancy:**

- `organizations`: Multi-tenant container with slug-based URLs
- `organization_members`: User-organization relationships with roles
- `organization_invitations`: Pending invitations with 7-day expiry tokens
- `user_organization_roles`: RBAC role assignments with expiration support

**Business Logic:**

- `projects`: Tenant-specific resources (organization_id foreign key)
- `api_keys`: Developer API access with rate limiting tiers
- `audit_logs`: Compliance and audit trail (partitioned by month)
- `permissions`: Granular permission definitions
- `roles`: Role definitions with permission mappings

**All tenant-specific tables use Row-Level Security (RLS) with organization_id for data isolation.**

### Technology Stack

#### Frontend Stack

- **Next.js 15.3.4** with App Router and Server Components
- **React 18.3.1** with TypeScript strict mode
- **Tailwind CSS** + shadcn/ui component library
- **NextAuth.js** for authentication with JWT strategy
- **Testing**: Jest + React Testing Library + Playwright (E2E)
- **Linting**: ESLint + Prettier with security plugins
- **Accessibility**: axe-core for WCAG 2.2 AA compliance testing
- Coverage threshold: 60% minimum (MVP), scalable to 90%+

#### Backend Stack

- **FastAPI** with Python 3.12+ and OpenAPI 3.1 auto-generation
- **PostgreSQL 15** with pgvector extension and Row-Level Security (RLS)
- **SQLAlchemy ORM** with Alembic migrations
- **Pydantic v2** for request/response validation
- **JWT tokens** (HS256 for MVP, RS256 prep for Foundation)
- **bcrypt** for password hashing (cost factor 12)
- **Testing**: pytest with asyncio support + Factory Boy for test data
- **Linting**: ruff + black + mypy + isort
- **Security**: bandit + semgrep for security scanning
- Coverage threshold: 60% minimum (MVP), scalable to 90%+

#### Database & Infrastructure

- **PostgreSQL 15** with Row-Level Security (RLS) for multi-tenancy
- **pgvector** extension for future AI/embeddings features
- **Docker Compose** for local development
- **Google Cloud Platform** for production deployment (Foundation stage)
- **Terraform** for Infrastructure as Code (Foundation+)

### Build System & Development

- **Turborepo** for build orchestration and intelligent caching
- **pnpm workspaces** for efficient dependency management
- **Pre-commit hooks** with comprehensive quality gates
- **Docker** support for consistent development environments

## 🚨 Critical Security Requirements (NEVER VIOLATE)

### Multi-Tenant Security (HIGHEST PRIORITY)

Based on the extensive .cursor/rules configuration, this system implements enterprise-grade multi-tenant security:

- **ALWAYS implement Row-Level Security (RLS)** for any tenant-specific database table
- **NEVER query database without proper tenant isolation** via organization_id
- **ALWAYS validate user belongs to organization** before accessing resources
- **ALWAYS use current_setting('app.current_org_id')** in PostgreSQL RLS policies
- **NEVER hardcode tenant IDs or organization IDs** in code
- **ALWAYS validate tenant context in API middleware** before processing requests

### Authentication & Authorization

- **NEVER store plaintext passwords** - use bcrypt with cost factor 12+
- **ALWAYS implement JWT token validation** with proper expiration
- **NEVER expose admin endpoints** without proper role-based access control (RBAC)
- **ALWAYS check permissions** at both API and database level
- **NEVER trust client-side user roles** - validate server-side always
- **NEVER log authentication tokens, API keys, or sensitive credentials**

### SQL Injection Prevention

- **ALWAYS use parameterized queries** via SQLAlchemy ORM
- **NEVER concatenate user input** directly into SQL strings
- **ALWAYS validate and sanitize** all database inputs
- **NEVER use raw SQL** without explicit parameterization

### Secrets Management

- **NEVER commit secrets, API keys, or credentials** to git
- **ALWAYS use environment variables** for sensitive configuration (.env files are in .gitignore)
- **NEVER hardcode Stripe keys, database passwords, or OAuth secrets**

## Development Standards

### TypeScript/JavaScript Standards

- **ALWAYS use TypeScript with strict mode** enabled
- **NEVER use 'any' type** - use proper type definitions or unknown
- **ALWAYS generate API client types** from OpenAPI schemas
- **NEVER skip type checking with @ts-ignore** without justification comment
- **ALWAYS implement proper error boundaries** in React components
- **NEVER use inline styles** - use Tailwind CSS classes only

### Python/FastAPI Standards

- **ALWAYS use type hints** for all function parameters and return values
- **ALWAYS use Pydantic models** for request/response validation
- **NEVER return raw database objects** - use response models
- **ALWAYS implement proper exception handling** with HTTPException
- **ALWAYS use async/await** for database operations
- **NEVER use blocking I/O operations** in async functions

### Database & ORM Standards

- **ALWAYS use Alembic migrations** for schema changes
- **NEVER modify database schema** without creating migration
- **ALWAYS include rollback logic** in database migrations
- **ALWAYS include created_at and updated_at** timestamps on entities
- **NEVER expose internal database IDs** in public APIs
- **ALWAYS use database transactions** for multi-operation changes

### API Design Standards

- **ALWAYS version APIs** with /v1/, /v2/ prefixes
- **ALWAYS implement proper HTTP status codes** (200, 201, 400, 401, 403, 404, 500)
- **NEVER expose stack traces** or internal errors to API consumers
- **ALWAYS implement rate limiting** for public endpoints
- **ALWAYS validate request sizes** and implement proper pagination
- **ALWAYS implement CORS policies** appropriate for environment

## Testing Requirements (Mandatory)

### Coverage & Quality Standards

- **90% minimum code coverage** for new features (60% currently enforced, configurable higher)
- **100% coverage for security functions**
- **ALWAYS test multi-tenant data isolation** in integration tests
- **NEVER merge code without corresponding unit tests**
- **ALWAYS test error conditions and edge cases**

### Testing Framework Configuration

#### TypeScript Testing (Jest)

- **React Testing Library** for component testing
- **Global test utilities** available via `testUtils`
- **Coverage threshold**: 60% minimum (lines, functions, branches, statements)
- Tests in `__tests__/` directories or `*.test.ts` files
- Coverage reports in `coverage/` directory (ignored in git)

#### Python Testing (pytest)

- **pytest-asyncio** for async test support
- **pytest-cov** for coverage reporting with 60% minimum threshold
- **Factory Boy** for test data generation
- **Test markers**: `@pytest.mark.unit`, `@pytest.mark.integration`, `@pytest.mark.slow`, `@pytest.mark.api`, `@pytest.mark.auth`
- Coverage reports in `htmlcov/` and `coverage.xml` (ignored in git)

### Required Test Types

- **Unit tests**: Mock dependencies, test behavior not implementation
- **Integration tests**: Real database scenarios, test service interactions
- **E2E tests**: Complete user workflows
- **Security tests**: OWASP Top 10 validation
- **Accessibility tests**: WCAG 2.2 AA compliance

## Quality Gates (Must Pass Before Merge)

### Automated Checks

- ✅ All tests pass with minimum coverage threshold
- ✅ ESLint and Prettier formatting passes
- ✅ TypeScript compilation succeeds with no errors
- ✅ Python type checking passes with mypy
- ✅ Python linting passes with ruff
- ✅ Security vulnerability scans pass (bandit for Python)
- ✅ Build artifacts generate successfully
- ✅ No circular dependencies detected

### Manual Review Requirements

- ✅ Code review approved by qualified team member
- ✅ Security review for authentication/authorization changes
- ✅ Architecture review for significant design changes
- ✅ Documentation updated for API or configuration changes

## Git Workflow Standards

- **ALWAYS use conventional commit messages** (feat:, fix:, docs:, etc.)
- **NEVER commit directly to main branch**
- **ALWAYS create feature branches** with descriptive names
- **ALWAYS squash commits** before merging to maintain clean history
- **NEVER commit generated files** or build artifacts (see .gitignore)
- **ALWAYS include issue numbers** in commit messages when applicable

## Important Files & Directories

### Configuration Files

- `turbo.json`: Build orchestration configuration with task dependencies
- `pnpm-workspace.yaml`: Workspace package definitions
- `pyproject.toml`: Python dependencies, tool configuration, and build settings
- `pytest.ini`: pytest configuration (in services/public-api)
- `jest.config.ts`: Jest configuration for TypeScript testing

### Development Standards

- `.cursor/rules/`: 15 comprehensive development rule files covering:
  - `base-rules.mdc`: Core security and architecture standards
  - `monorepo-rules.mdc`: Monorepo best practices
  - `testing-rules.mdc`: Comprehensive testing requirements
  - `python-rules.mdc`: Python-specific standards
  - `nextjs-typescript-rules.mdc`: Frontend development standards
  - And 10 other specialized rule files

### Ignored Files (.gitignore)

The repository ignores common development artifacts:

- **Node.js**: `node_modules/`, `.next/`, coverage reports, TypeScript build info
- **Python**: `__pycache__/`, `.venv/`, `htmlcov/`, `.coverage`, `dist/`
- **Development**: `.env` files (except `.env.example`), IDE files, OS files
- **Build artifacts**: `build/`, `dist/`, `.turbo/` cache
- **Product requirements**: `product-requirements/` directory

## Development Environment Setup

### Prerequisites

- **Node.js 18+** and **pnpm 9+**
- **Python 3.12+**
- **Git** with conventional commit standards

### Initial Setup

1. Install dependencies: `pnpm install`
2. Install pre-commit hooks: `pre-commit install --hook-type commit-msg --hook-type pre-commit`
3. Set up environment variables from `.env.example` files
4. Start development environment: `pnpm dev`

### Running Quality Checks

```bash
# Run all pre-commit checks manually
pnpm all-checks  # Uses ./scripts/run-all-checks.sh

# Run individual checks
pnpm lint        # ESLint for TypeScript
pnpm type-check  # TypeScript compilation
ruff check .     # Python linting
mypy services/   # Python type checking
bandit -r services/  # Python security scanning
```

## 🚫 Critical Anti-Patterns to Avoid

### Security Anti-Patterns

- **NEVER use eval()** or similar dynamic code execution
- **NEVER trust user input** without proper validation and sanitization
- **NEVER implement custom cryptography** - use established libraries
- **NEVER use HTTP** for production APIs - HTTPS only
- **NEVER expose internal service URLs** in logs or responses

### Performance Anti-Patterns

- **NEVER perform N+1 queries** - use proper joins or batching
- **NEVER use SELECT \*** in production code
- **NEVER block event loops** with synchronous operations
- **NEVER ignore memory leaks** or resource cleanup

### Code Quality Anti-Patterns

- **NEVER use magic numbers or strings** - use proper constants
- **NEVER implement God objects** or functions with too many responsibilities
- **NEVER skip error handling** or use empty catch blocks
- **NEVER create circular dependencies** between modules
- **NEVER copy-paste code** - extract into reusable functions

## Progressive Architecture Approach

This template is designed to grow with your needs:

### Current Stage: MVP/Foundation

- Monorepo with basic services
- Single PostgreSQL instance
- Container-based deployment
- Basic monitoring and security

### Future Stages

- **Growth**: Service decomposition, auto-scaling, advanced caching
- **Full-Stack**: Microservices, service mesh, multi-region deployment

This codebase represents an enterprise-grade, multi-tenant SaaS template with comprehensive security, testing, and development standards. Always prioritize security requirements, maintain test coverage, and follow the progressive architecture principles outlined in the extensive rule documentation.
