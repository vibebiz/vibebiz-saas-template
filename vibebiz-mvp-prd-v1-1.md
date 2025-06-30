# VibeBiz SaaS Template System - Product Requirements Document v1.1

**Version**: 1.1
**Date**: 2025-06-29
**Changes from v1.0**: Enhanced production-readiness with accessibility testing, metrics endpoint, improved migration tooling, and additional template functions

## Context

VibeBiz is a comprehensive SaaS template system designed to enable entrepreneurs and developers to rapidly build, deploy, and scale multi-tenant SaaS applications. The system provides a four-stage progressive architecture (MVP, Foundation, Growth, Full-Stack) that allows businesses to start simple and grow seamlessly to enterprise scale.

The template system includes:

- A CLI tool (`vibebiz`) for project creation, migration between stages, and component management
- A licensing system that gates access to different components and stages
- Pre-built, production-ready components for common SaaS functionality
- A monorepo structure using Turborepo for efficient development
- Progressive deployment from local Docker Compose to cloud infrastructure
- PostgreSQL database with Row-Level Security (RLS) from day one
- Secure-by-default and quality-driven development practices from MVP stage
- Production-grade observability and migration tooling

This PRD focuses on implementing the core template system infrastructure, CLI tools, licensing model, and the MVP stage template with its essential components.

## Repository Architecture

The VibeBiz system requires **two separate Git repositories** to properly implement the licensing model and code protection strategy:

### Repository 1: `vibebiz-platform` (Private Repository)

This repository contains the cloud-hosted services that VibeBiz operates to manage licenses and distribute template components.

**Purpose**: Core business infrastructure for license validation and component distribution
**Visibility**: Private
**Contents**:

- License Server API (`services/license-api`)
- Template Registry API (`services/registry-api`)
- License Management Dashboard (`apps/license-dashboard`)
- Component storage configuration (Google Cloud Storage)
- Private signing keys and business logic

### Repository 2: `vibebiz-saas-template` (Public Repository)

This repository is the open-source template that developers use to build their SaaS applications.

**Purpose**: Customer-facing SaaS template with progressive architecture
**Visibility**: Public (Apache 2.0 License)
**Contents**:

- CLI tool source code
- MVP stage components (available with DEV license)
- Monorepo structure (apps/, services/, packages/, etc.)
- Documentation and community resources
- Migration scripts and tooling

**Note**: Premium components (Foundation, Growth, Full-Stack) are NOT included in the public repository. They are stored privately and distributed through the CLI after license validation.

## Code Protection Strategy

1. **CLI as Gatekeeper**: The `vibebiz` CLI tool is distributed via npm but does not contain any template source code
2. **License Validation**: All commands that create projects or add components require a valid `VIBEBIZ_LICENSE_KEY`
3. **On-Demand Distribution**: Template code is fetched from the private registry only after successful license validation
4. **Secure Storage**: Premium components are stored in private Google Cloud Storage buckets
5. **Time-Limited Access**: Downloads use pre-signed URLs that expire after 5 minutes

## Data Model Reference

The system uses PostgreSQL with the following key tables:

- **users**: Core user accounts with authentication (id, email, password_hash, full_name, status, created_at, updated_at)
- **organizations**: Multi-tenant container (id, name, slug, settings, created_at, updated_at)
- **organization_members**: User-organization relationships (id, organization_id, user_id, status, joined_at)
- **organization_invitations**: Pending invitations with tokens (id, organization_id, email, role_id, token_hash, expires_at)
- **user_organization_roles**: RBAC role assignments (id, user_id, organization_id, role_id, granted_by, expires_at)
- **permissions**: Granular permission definitions (id, name, resource, action, description)
- **roles**: Role definitions with permission mappings (id, name, slug, description, is_system, scope)
- **projects**: Tenant-specific resources (id, organization_id, name, slug, description, status, created_by)
- **api_keys**: Developer API access (id, organization_id, created_by, name, key_hash, permissions, rate_limit_tier)
- **audit_logs**: Compliance and audit trail (id, organization_id, user_id, action, resource_type, resource_id, changes, created_at)
- **user_sessions**: JWT session management (id, user_id, token_hash, refresh_token_hash, expires_at, revoked_tokens)

All tenant-specific tables use Row-Level Security (RLS) with organization_id for data isolation.

## MVP API Endpoints Reference

The MVP stage includes the following core business logic endpoints:

### Authentication Endpoints

- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User authentication
- `POST /api/v1/auth/logout` - Session invalidation
- `GET /api/v1/auth/me` - Current user information
- `POST /api/v1/auth/refresh` - Refresh access token

### User Management

- `GET /api/v1/users/me` - Get current user profile
- `PATCH /api/v1/users/{id}` - Update user profile

### Organization Management

- `GET /api/v1/organizations` - List user's organizations
- `POST /api/v1/organizations` - Create new organization
- `GET /api/v1/organizations/{id}` - Get organization details
- `PATCH /api/v1/organizations/{id}` - Update organization
- `DELETE /api/v1/organizations/{id}` - Delete organization (soft)

### Project Management

- `GET /api/v1/projects` - List projects in current org
- `POST /api/v1/projects` - Create project
- `GET /api/v1/projects/{id}` - Get project details
- `PATCH /api/v1/projects/{id}` - Update project
- `DELETE /api/v1/projects/{id}` - Delete project (soft)

### Billing Stub

- `GET /api/v1/billing/subscription` - Get subscription status (returns mock data)
- `GET /api/v1/billing/plans` - List available plans (hardcoded)

### System

- `GET /healthz` - Health check
- `GET /metrics` - Prometheus metrics (optional, feature-flagged)
- `GET /openapi.json` - OpenAPI specification
- `GET /docs` - Swagger UI documentation
- `GET /redoc` - ReDoc documentation

---

# Part 1: VibeBiz Platform Requirements (`vibebiz-platform` Private Repository)

## Feature 2: Template Access Infrastructure

The infrastructure needed to manage template access, licensing, and distribution.

### Story 2.1: License Server API

**Type**: Backend API Story

**As a** VibeBiz administrator
**I want** to manage and validate licenses through an API
**So that** I can control access to templates and track usage

**Acceptance Criteria**:

- **Given** a valid admin API key
  - **When** I POST to `/api/v1/licenses` with tier and expiry
  - **Then** I should be able to create a new license returning signed JWT
- **Given** a license creation request
  - **When** processed successfully
  - **Then** it should return a signed JWT license key and store in database
- **Given** a license verification request from CLI
  - **When** POST to `/api/v1/license/verify` with license key
  - **Then** it should validate signature and log usage with timestamp
- **Given** a revoked license
  - **When** verification is attempted
  - **Then** it should return 403 Forbidden with reason
- **Given** rate limiting is enabled
  - **When** more than 100 requests/hour from same IP
  - **Then** it should return 429 Too Many Requests with Retry-After header
- **Given** Stripe webhook for payment
  - **When** subscription created/cancelled
  - **Then** it should create/revoke license automatically

**Architecture Design Notes**:

- Use FastAPI for the license server
- PostgreSQL database with tables: licenses, license_usage_logs, revoked_licenses
- Sign licenses with ED25519 private key
- Implement webhook for payment provider integration (Stripe)
- Deploy on Cloud Run with Cloud SQL backend
- Use Redis for rate limiting and revocation cache
- API authentication using API keys for admin endpoints
- Structured logging for all license operations

**Dependencies**: None

**Related Stories**: 2.2, 2.3

### Story 2.2: License Management Dashboard

**Type**: Frontend Story

**As a** VibeBiz administrator
**I want** a web dashboard to manage licenses
**So that** I can create, revoke, and monitor license usage

**Design/UX Considerations**:

- Clean, modern interface using shadcn/ui components
- Real-time updates for usage statistics
- Search and filter capabilities for license list
- Export functionality for compliance reporting
- Mobile-responsive design

**Acceptance Criteria**:

- **Given** I'm authenticated as an admin
  - **When** I access the dashboard at <https://licenses.vibebiz.dev>
  - **Then** I should see a list of all licenses with status, tier, and expiry
- **Given** the license list is displayed
  - **When** I click "Create License"
  - **Then** I should see a form with tier selection (DEV/FOUNDATION/GROWTH/FULL/AGENCY) and expiry date
- **Given** a license exists
  - **When** I click "Revoke" and confirm
  - **Then** it should be marked as revoked with reason and timestamp
- **Given** a license is selected
  - **When** I view details
  - **Then** I should see usage statistics, call-home logs, and commands used
- **Given** usage data exists
  - **When** viewing analytics
  - **Then** I should see charts of CLI usage by tier, command, and time period
- **Given** I need compliance data
  - **When** I click "Export"
  - **Then** I should download CSV with license and usage data

**Architecture Design Notes**:

- Next.js 15 app with App Router
- Tailwind CSS with shadcn/ui components
- NextAuth.js with admin role check (<admin@vibebiz.dev> domain)
- Server-Sent Events for real-time updates
- Chart.js for usage analytics
- React Query for data fetching and caching

**Dependencies**: 2.1

**Related Stories**: 2.3

### Story 2.3: Template Registry Service

**Type**: Backend API Story

**As a** developer
**I want** to download template components from a registry
**So that** I can add them to my project

**Acceptance Criteria**:

- **Given** a valid license key
  - **When** I request a component download with matching tier
  - **Then** I should receive a pre-signed URL valid for 5 minutes
- **Given** an invalid license tier
  - **When** requesting a restricted component
  - **Then** I should receive 403 Forbidden with required tier info
- **Given** a component request
  - **When** successful
  - **Then** usage should be logged with component, version, license_id, and timestamp
- **Given** component files are stored
  - **When** in cloud storage
  - **Then** they should be organized by version and include SHA256 checksums
- **Given** component metadata request
  - **When** GET /api/v1/components
  - **Then** it should return list filtered by license tier

**Architecture Design Notes**:

- Store components in Google Cloud Storage with versioning
- Use signed URLs for secure, time-limited access
- Components stored as tar.gz archives with SHA256 checksums
- Implement CDN for global distribution
- Track download metrics for popular components
- Component path structure: /components/{slug}/{version}/{slug}-{version}.tar.gz
- Metadata in registry database, files in cloud storage

**Dependencies**: 2.1

**Related Stories**: 4.2 (in public repo)

### Story 2.4: Component Storage Management

**Type**: Backend API Story

**As a** VibeBiz administrator
**I want** to manage component storage and distribution
**So that** I can release new components and versions

**Acceptance Criteria**:

- **Given** a new component version
  - **When** I upload it to cloud storage
  - **Then** it should be versioned and checksummed
- **Given** component metadata
  - **When** stored in database
  - **Then** it should match the catalog schema from vibebiz_add_components_v4.4_catalog_licensed.md
- **Given** a component is uploaded
  - **When** to Google Cloud Storage
  - **Then** it should be in the correct bucket structure
- **Given** old component versions
  - **When** superseded
  - **Then** they should remain available for existing projects

**Architecture Design Notes**:

- Google Cloud Storage bucket structure:
  - /components/{slug}/{version}/{slug}-{version}.tar.gz
  - /components/{slug}/{version}/checksum.sha256
- Implement versioning policy
- CDN configuration for global access
- Backup strategy for disaster recovery

**Dependencies**: 2.3

**Related Stories**: None

---

# Part 2: VibeBiz SaaS Template Requirements (`vibebiz-saas-template` Public Repository)

## Feature 1: VibeBiz CLI Tool Foundation

The CLI tool is the primary interface for developers to create, manage, and evolve their SaaS applications using the VibeBiz template system.

### Story 1.1: CLI Tool Initialization and Global Commands

**Type**: Backend API Story

**As a** developer
**I want** to install and initialize the VibeBiz CLI tool
**So that** I can create and manage VibeBiz projects

**Acceptance Criteria**:

- **Given** the CLI is published as an npm package
  - **When** I run `npm install -g @vibebiz/cli`
  - **Then** the CLI should be installed globally and accessible via the `vibebiz` command
- **Given** the CLI is installed
  - **When** I run `vibebiz --version`
  - **Then** I should see the current version number
- **Given** the CLI is installed
  - **When** I run `vibebiz --help`
  - **Then** I should see a list of available commands: create, init, dev, migrate, add, deploy, test, security, validate, cost, doctor
- **Given** no license key is set
  - **When** I run any command requiring a license
  - **Then** I should see an error message: "⚠️ Missing VIBEBIZ_LICENSE_KEY"
- **Given** an invalid command
  - **When** I run `vibebiz invalid-command`
  - **Then** I should see an error and command suggestions

**Architecture Design Notes**:

- Use `@oclif/core` framework for CLI structure
- Store version in package.json and read dynamically
- Implement command structure: `vibebiz <command> <subcommand> [options]`
- Check for VIBEBIZ_LICENSE_KEY environment variable on initialization
- Support both global and project-local installations
- Use Cue templates for code generation
- Taskfile for command orchestration
- CLI package does NOT include template source code

**Dependencies**: None

**Related Stories**: 1.2, 2.1 (in private repo)

### Story 1.2: License Key Validation System

**Type**: Backend API Story

**As a** VibeBiz system administrator
**I want** to validate license keys locally and optionally online
**So that** I can enforce licensing tiers and track usage

**Acceptance Criteria**:

- **Given** a valid license key in JWT format
  - **When** the CLI validates it locally
  - **Then** it should verify the ECDSA signature using the bundled public key
- **Given** an expired license key
  - **When** the CLI validates it
  - **Then** it should throw an error indicating the license has expired with expiry date
- **Given** a license key with tier "DEV"
  - **When** attempting to use a "FOUNDATION" tier component
  - **Then** it should throw an error: "Tier FOUNDATION required → your licence: DEV"
- **Given** VIBEBIZ_OFFLINE_MODE is not set
  - **When** validating a license
  - **Then** the CLI should make a non-blocking API call to the license server with 200ms timeout
- **Given** the license server is unavailable
  - **When** validating in online mode
  - **Then** the CLI should continue with local validation only
- **Given** a license key near expiry (< 30 days)
  - **When** validating
  - **Then** it should show a warning about upcoming expiration

**Architecture Design Notes**:

- License key is a signed JWT containing: tier, expiry, customer_id
- Bundle ECDSA public key with the CLI for offline validation
- Implement tiers: DEV < FOUNDATION < GROWTH < FULL < AGENCY
- Call-home endpoint: POST <https://api.vibebiz.dev/v1/license/verify>
- Fire-and-forget with 200ms timeout for online validation
- Cache validation results for 1 hour to reduce API calls
- License key format: `eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9...`

**Dependencies**: None

**Related Stories**: 1.1, 3.1

### Story 1.3: Project Configuration Management

**Type**: Backend API Story

**As a** developer
**I want** the CLI to manage project configuration
**So that** I can track project state and settings

**Acceptance Criteria**:

- **Given** a VibeBiz project exists
  - **When** I check the project root
  - **Then** there should be a `.vibebiz/config.json` file
- **Given** the config file exists
  - **When** I read it
  - **Then** it should contain: project_name, current_stage, installed_components, version, created_at, last_migration, template_hash
- **Given** I run `vibebiz add <component>`
  - **When** the component is installed
  - **Then** the config should be updated with the new component and timestamp
- **Given** corrupted config file
  - **When** the CLI reads it
  - **Then** it should show an error and offer to regenerate from project analysis
- **Given** I run `vibebiz doctor`
  - **When** in a project directory
  - **Then** it should validate config against actual project structure

**Architecture Design Notes**:

- Config schema:

```json
{
  "version": "1.0.0",
  "project_name": "my-saas-app",
  "current_stage": "mvp",
  "installed_components": [
    "public-web",
    "public-api",
    "auth-service",
    "organization-service",
    "notification-service",
    "user-service"
  ],
  "license_tier_used": "DEV",
  "created_at": "2025-01-01T00:00:00Z",
  "last_migration": null,
  "project_id": "uuid-v4",
  "template_hash": "sha256-hash-of-original-template"
}
```

- Use JSON schema validation
- Implement config migration for future versions
- Store in `.vibebiz` directory (not in .gitignore)
- Backup config before modifications
- Store template hash for divergence detection

**Dependencies**: None

**Related Stories**: 3.1, 4.1

### Story 1.4: Template Function System

**Type**: Backend API Story

**As a** developer
**I want** to use template functions to generate code
**So that** I can quickly scaffold new features

**Acceptance Criteria**:

- **Given** template functions are available
  - **When** I run `vibebiz generate --list`
  - **Then** I should see available template functions
- **Given** I run `vibebiz generate api-endpoint`
  - **When** with required parameters
  - **Then** it should generate endpoint, model, and test files
- **Given** I run `vibebiz generate react-component`
  - **When** with component name
  - **Then** it should create component with TypeScript and tests
- **Given** template execution
  - **When** generating files
  - **Then** it should respect existing files and prompt for overwrite
- **Given** custom templates
  - **When** in `.vibebiz/templates/`
  - **Then** they should be available for generation

**Architecture Design Notes**:

- Built-in template functions:
  - `api-endpoint`: FastAPI endpoint with Pydantic model
  - `react-component`: React component with TypeScript
  - `database-migration`: Alembic migration template
  - `service`: New microservice scaffold
  - `crud-resource`: Complete CRUD for a resource
  - `seed-script`: Idempotent Faker-based seed with deterministic option
  - `pytest-suite`: Python test harness with coverage config
  - `jest-suite`: JavaScript test harness with coverage config
- Use Handlebars or similar for templating
- Support custom templates in project
- Interactive prompts for required parameters
- Dry-run mode to preview changes

**Dependencies**: 1.1

**Related Stories**: None

## Feature 3: MVP Template Implementation

The core MVP template with essential SaaS components for rapid prototyping.

### Story 3.1: MVP Project Scaffolding

**Type**: Backend API Story

**As a** developer
**I want** to create a new MVP project with complete monorepo structure
**So that** I can start building immediately

**Acceptance Criteria**:

- **Given** I run `vibebiz create my-app --stage mvp`
  - **When** the command completes
  - **Then** it should create a monorepo with apps/, services/, packages/, infra/, and tools/ directories
- **Given** the project is created
  - **When** I check the structure
  - **Then** it should match the defined monorepo layout with all MVP services
- **Given** the monorepo is created
  - **When** I check configuration files
  - **Then** it should include turbo.json, pnpm-workspace.yaml, docker-compose.yml, and .env.example
- **Given** Git is installed
  - **When** project creation completes
  - **Then** it should initialize a git repository with initial commit
- **Given** I run `vibebiz init my-app`
  - **When** for quick start
  - **Then** it should create MVP project with default settings
- **Given** security tools are configured
  - **When** project is created
  - **Then** ESLint, Bandit, and basic security scanning should be pre-configured

**Architecture Design Notes**:

- Monorepo structure:

```
my-app/
├── apps/
│   └── public-web/          # Next.js 15 customer-facing app
├── services/
│   ├── public-api/          # FastAPI core business logic
│   ├── auth/                # Authentication service
│   ├── organizations/       # Multi-tenant org management
│   ├── notifications/       # Email/SMS notifications
│   └── users/               # User management
├── packages/
│   ├── database/            # Shared DB schemas & migrations
│   ├── api-client/          # Generated TypeScript client
│   ├── shared-types/        # TypeScript type definitions
│   └── ui-components/       # Shared React components
├── infra/
│   ├── docker/              # Dockerfiles
│   └── terraform/           # Future IaC (prep for Foundation)
├── tools/
│   ├── scripts/             # Automation scripts
│   └── generators/          # Code generators
├── .github/
│   └── workflows/           # Basic CI/CD templates
├── docs/
│   ├── api/                 # API documentation
│   └── guides/              # Quick start guides
├── docker-compose.yml
├── turbo.json
├── pnpm-workspace.yaml
├── .env.example
├── .gitignore
├── .eslintrc.js             # Security-focused linting
├── .bandit                  # Python security scanning
└── README.md
```

- Use Turborepo for monorepo management
- Configure pnpm workspaces for dependency management
- Include comprehensive .gitignore
- PostgreSQL 15 in Docker for database
- Pre-configure security tools from day one
- MVP files are bundled with CLI or fetched from secure location
- Store original template hash for divergence detection

**Dependencies**: 1.1, 1.2

**Related Stories**: 3.2, 3.3

### Story 3.2: Public Web Application (Next.js)

**Type**: Frontend Story

**As a** end user
**I want** to access a modern web application
**So that** I can use the SaaS product

**Design/UX Considerations**:

- Modern, clean design using Tailwind CSS
- Responsive mobile-first approach
- Fast page loads with SSR/SSG where appropriate
- Accessible UI following WCAG guidelines
- shadcn/ui component library for consistency

**Acceptance Criteria**:

- **Given** the MVP template is installed
  - **When** I run `pnpm dev`
  - **Then** the Next.js app should start on <http://localhost:3000>
- **Given** the app is running
  - **When** I visit the homepage
  - **Then** I should see a landing page with login/signup options and product info
- **Given** I click signup
  - **When** I submit the form with email and password
  - **Then** it should create a user via the auth service API and auto-login
- **Given** I'm logged in
  - **When** I access the dashboard
  - **Then** I should see user info and organization context
- **Given** the app is built
  - **When** using TypeScript
  - **Then** it should have proper type safety with generated API types
- **Given** I'm not authenticated
  - **When** accessing protected routes
  - **Then** I should be redirected to login
- **Given** billing page is accessed
  - **When** in MVP
  - **Then** it should show billing stub with mock subscription data
- **Given** security headers
  - **When** responses are sent
  - **Then** CSP headers should be present via Helmet.js

**Architecture Design Notes**:

- Next.js 15 with App Router and Server Components
- Tailwind CSS with shadcn/ui component library
- NextAuth.js for authentication with JWT strategy
- API client using generated TypeScript types from OpenAPI
- Environment variables for API_URL configuration
- Responsive design with mobile-first approach
- Billing stub UI showing fake "Free Plan" status
- Helmet.js configuration for security headers
- Structure:
  - app/ (App Router pages)
  - components/ (UI components)
  - lib/ (utilities and API client)
  - public/ (static assets)

**Dependencies**: 3.4, 3.5

**Related Stories**: 3.3

### Story 3.3: Public API Service (FastAPI)

**Type**: Backend API Story

**As a** frontend developer
**I want** a RESTful API with OpenAPI documentation
**So that** I can build frontend features

**Acceptance Criteria**:

- **Given** the API service is running
  - **When** I access <http://localhost:8000/docs>
  - **Then** I should see interactive Swagger documentation with all endpoints
- **Given** a POST request to `/api/v1/auth/register`
  - **When** with valid email and password
  - **Then** it should create a user and return JWT access and refresh tokens
- **Given** an authenticated request
  - **When** with valid JWT in Authorization header
  - **Then** it should allow access to protected endpoints with org context
- **Given** an invalid request
  - **When** missing required fields
  - **Then** it should return 422 with detailed validation errors
- **Given** the API is running
  - **When** I access `/healthz`
  - **Then** it should return 200 OK with {"status": "ok"}
- **Given** rate limiting
  - **When** exceeding 1000 requests/hour
  - **Then** it should return 429 with rate limit headers
- **Given** billing endpoints accessed
  - **When** GET /api/v1/billing/subscription
  - **Then** it should return mock subscription data
- **Given** metrics endpoint enabled
  - **When** ENABLE_METRICS=true and GET /metrics
  - **Then** it should return Prometheus-formatted metrics
- **Given** API schema versioning
  - **When** breaking changes occur
  - **Then** they should be registered under docs/api/ with contract tests

**Architecture Design Notes**:

- FastAPI with Pydantic v2 for validation
- PostgreSQL connection via asyncpg with connection pooling
- JWT tokens with 24-hour expiry for access, 7-day for refresh
- CORS configuration for frontend URL
- OpenAPI 3.1 specification auto-generated
- Rate limiting using slowapi
- Structured JSON logging
- Error response format matching API requirements doc
- Multi-tenant context from JWT claims
- Billing stub returns hardcoded subscription status
- Optional Prometheus metrics endpoint behind feature flag
- Contract test templates included for schema validation

**Dependencies**: 3.6

**Related Stories**: 3.2, 3.4

### Story 3.4: Authentication Service

**Type**: Backend API Story

**As a** user
**I want** to securely authenticate and manage my sessions
**So that** I can access protected resources

**Acceptance Criteria**:

- **Given** a registration request
  - **When** with unique email
  - **Then** it should hash password with bcrypt (cost 12) and store user
- **Given** a login request
  - **When** with correct credentials
  - **Then** it should return JWT access (24h) and refresh tokens (7d)
- **Given** an expired access token
  - **When** refresh token is valid
  - **Then** it should issue new access token and optionally new refresh token
- **Given** a logout request
  - **When** with valid token
  - **Then** it should revoke the session in user_sessions table
- **Given** a password reset request
  - **When** for existing email
  - **Then** it should create reset token and log to console (email in Foundation)
- **Given** concurrent sessions
  - **When** user logs in from multiple devices
  - **Then** each should have separate session tracking
- **Given** token compromise
  - **When** jti needs to be blacklisted
  - **Then** Redis-backed revocation list should be checked

**Architecture Design Notes**:

- Separate service for authentication logic
- PostgreSQL users table with email uniqueness constraint
- bcrypt for password hashing with cost factor 12
- JWT with HS256 for MVP (RS256 prep for Foundation)
- Session tracking in user_sessions table
- Refresh token rotation for security
- Email service interface (console implementation for MVP)
- Audit logging for auth events
- Redis-backed jti blacklist (optional in local dev)
- Token revocation helper functions

**Dependencies**: 3.6

**Related Stories**: 3.3, 3.5

### Story 3.5: Organization Service (Multi-tenancy)

**Type**: Backend API Story

**As a** user
**I want** to create and manage organizations
**So that** I can collaborate with my team

**Acceptance Criteria**:

- **Given** an authenticated user
  - **When** they create an organization
  - **Then** they should become the owner with admin role
- **Given** an organization exists
  - **When** I'm a member
  - **Then** I should only see data for that organization via RLS
- **Given** I'm an org admin
  - **When** I invite a user by email
  - **Then** invitation should be created with 7-day expiry (console notification)
- **Given** multiple organizations exist
  - **When** I switch context
  - **Then** all API calls should be scoped to that org via JWT claim
- **Given** organization creation
  - **When** with a name
  - **Then** it should generate a unique slug
- **Given** I'm the last admin
  - **When** trying to leave organization
  - **Then** it should prevent with error message
- **Given** invitation links
  - **When** generated
  - **Then** they should use organization_invitations table with token_hash

**Architecture Design Notes**:

- PostgreSQL Row-Level Security (RLS) policies from day one
- Organization context in JWT claims (current_org_id)
- Tables: organizations, organization_members, organization_invitations
- Basic roles: owner, admin, member
- Slug generation for URL-friendly identifiers
- Middleware to set RLS context from JWT
- Organization settings in JSONB for flexibility
- Invitation tokens stored in organization_invitations table

**Dependencies**: 3.4, 3.6

**Related Stories**: 3.7

### Story 3.6: Database Setup and Migrations

**Type**: Backend API Story

**As a** developer
**I want** a properly structured database with migrations
**So that** I can evolve the schema safely

**Acceptance Criteria**:

- **Given** docker-compose is installed
  - **When** I run `docker-compose up postgres`
  - **Then** PostgreSQL 15 should start with pgvector extension enabled
- **Given** the database is running
  - **When** I run Alembic migrations
  - **Then** all MVP tables should be created with RLS policies enabled
- **Given** migration files exist
  - **When** in services/shared/database/migrations
  - **Then** they should be versioned and reversible
- **Given** the database is set up
  - **When** I run `pnpm db:seed`
  - **Then** it should create 3 orgs with users and sample data
- **Given** RLS is enabled
  - **When** on tenant tables
  - **Then** queries should be automatically filtered by org context
- **Given** invitation tables
  - **When** created
  - **Then** organization_invitations migration should be included

**Architecture Design Notes**:

- PostgreSQL 15 with pgvector for future AI features
- Alembic for Python service migrations
- Initial schema: users, organizations, organization_members, organization_invitations, projects, user_sessions, audit_logs
- Enable RLS on all tenant-scoped tables
- Create application role with restricted permissions
- Seed data script using Faker library
- Connection pooling with asyncpg
- Helper functions: update_updated_at_column(), set_current_user_id()

**Dependencies**: None

**Related Stories**: All API stories

### Story 3.7: User Service

**Type**: Backend API Story

**As a** user
**I want** to manage my profile and preferences
**So that** I can personalize my experience

**Acceptance Criteria**:

- **Given** I'm authenticated
  - **When** I GET `/api/v1/users/me`
  - **Then** I should see my profile with organization context
- **Given** I want to update my profile
  - **When** I PATCH with new data
  - **Then** it should update with optimistic locking (ETag)
- **Given** I update my email
  - **When** to a unique email
  - **Then** it should update and set email_verified to false
- **Given** preferences are stored
  - **When** in metadata JSONB field
  - **Then** they should support flexible key-value pairs
- **Given** profile updates
  - **When** occur
  - **Then** they should be logged in audit_logs table

**Architecture Design Notes**:

- User profile fields: full_name, avatar_url, timezone, locale, phone
- Metadata JSONB for extensible preferences
- Email uniqueness validation
- Audit trail for all changes
- ETag generation from updated_at timestamp
- Future Redis caching preparation

**Dependencies**: 3.4

**Related Stories**: 3.8

### Story 3.8: Notification Service (Basic)

**Type**: Backend API Story

**As a** system administrator
**I want** to send notifications to users
**So that** they stay informed about important events

**Acceptance Criteria**:

- **Given** a notification request
  - **When** for email type
  - **Then** it should be queued in notifications table
- **Given** notifications are queued
  - **When** processed by background worker
  - **Then** they should log to console (MVP: no actual sending)
- **Given** a user registers
  - **When** successfully
  - **Then** a welcome notification should be auto-queued
- **Given** notification preferences exist
  - **When** checking user settings
  - **Then** only enabled channels should be queued
- **Given** in-app notifications
  - **When** created
  - **Then** they should be retrievable via API
- **Given** failed notifications
  - **When** retry needed
  - **Then** exponential backoff and dead-letter queue should be implemented

**Architecture Design Notes**:

- PostgreSQL notifications table as queue
- Basic worker to process queue (console output for MVP)
- Notification types: email, in_app
- Template system with variable substitution
- User preferences in user_notification_preferences
- In-app notifications in separate table
- Prepare structure for Celery integration (Foundation)
- Exponential backoff: 1min, 2min, 4min, then dead-letter
- Dead-letter queue design for undeliverable messages

**Dependencies**: 3.4, 3.7

**Related Stories**: None

### Story 3.9: Basic Project Management

**Type**: Backend API Story

**As a** user
**I want** to create and manage projects within my organization
**So that** I can organize my work

**Acceptance Criteria**:

- **Given** I'm in an organization
  - **When** I POST to `/api/v1/projects`
  - **Then** it should create project scoped to current org
- **Given** a project exists
  - **When** I'm not a member of the org
  - **Then** I should get 404 (RLS filtered)
- **Given** I own a project
  - **When** I PATCH with updates
  - **Then** changes should persist with updated_at
- **Given** I DELETE a project
  - **When** as owner or admin
  - **Then** it should set status to 'deleted' (soft delete)
- **Given** project creation
  - **When** with duplicate slug in org
  - **Then** it should return 409 Conflict

**Architecture Design Notes**:

- Projects table with organization_id foreign key
- RLS policies matching organization membership
- Soft delete with status field
- Project slugs unique within organization
- Full CRUD operations as per API requirements
- Audit logging for all changes
- Support cursor pagination

**Dependencies**: 3.5

**Related Stories**: None

### Story 3.10: Audit Logging System

**Type**: Backend API Story

**As a** compliance officer
**I want** comprehensive audit logging
**So that** we can track all user actions

**Acceptance Criteria**:

- **Given** any API mutation
  - **When** it modifies data
  - **Then** it should create an audit_log entry
- **Given** an audit log entry
  - **When** created
  - **Then** it should include user_id, action, resource_type, resource_id, changes
- **Given** authentication events
  - **When** login/logout/failed attempts
  - **Then** they should be logged with IP and user agent
- **Given** audit logs table
  - **When** checking structure
  - **Then** it should be partitioned by month for performance
- **Given** sensitive data
  - **When** in audit logs
  - **Then** it should be redacted (passwords, tokens)

**Architecture Design Notes**:

- Partitioned audit_logs table by created_at
- Automatic partition creation for future months
- Action format: "resource.action" (e.g., "user.login")
- Store before/after for updates in changes JSONB
- Include request_id for tracing
- Index on organization_id, user_id, action
- Retention policy preparation (Foundation)

**Dependencies**: All API stories

**Related Stories**: None

### Story 3.11: Billing Stub Implementation

**Type**: Backend API Story

**As a** developer
**I want** a billing stub in the MVP
**So that** I can prepare for future payment integration

**Acceptance Criteria**:

- **Given** GET /api/v1/billing/subscription
  - **When** called with valid auth
  - **Then** it should return mock subscription data
- **Given** GET /api/v1/billing/plans
  - **When** called
  - **Then** it should return hardcoded plan options
- **Given** the billing UI
  - **When** accessed in frontend
  - **Then** it should show "Free Plan" with upgrade button (non-functional)
- **Given** subscription mock data
  - **When** returned
  - **Then** it should match the data model structure for easy replacement

**Architecture Design Notes**:

- Hardcoded responses matching future Stripe integration
- Mock subscription response:

```json
{
  "id": "sub_mock_123",
  "plan": {
    "id": "plan_free",
    "name": "Free Plan",
    "price_monthly": 0
  },
  "status": "active",
  "current_period_end": "2025-12-31T23:59:59Z"
}
```

- Plans endpoint returns free/starter/pro options
- UI placeholder for Stripe integration
- Database tables created but not used

**Dependencies**: 3.3

**Related Stories**: 3.2

## Feature 4: Component Management System

The ability to add new components to existing projects based on license tier.

### Story 4.1: Component Addition Command

**Type**: Backend API Story

**As a** developer
**I want** to add new components to my project
**So that** I can extend functionality as needed

**Acceptance Criteria**:

- **Given** I run `vibebiz add payment-service`
  - **When** I have FOUNDATION tier or higher
  - **Then** it should download and install the component
- **Given** component requires FOUNDATION tier
  - **When** I have DEV tier
  - **Then** it should error: "Tier FOUNDATION required → your licence: DEV"
- **Given** component is installed
  - **When** successfully
  - **Then** it should update .vibebiz/config.json with component and timestamp
- **Given** component has dependencies
  - **When** on auth-service and org-service
  - **Then** it should verify they exist first
- **Given** component exists
  - **When** trying to add again
  - **Then** it should show "Component 'payment-service' is already installed"
- **Given** component files are extracted
  - **When** to the monorepo
  - **Then** they should merge without overwriting existing files

**Architecture Design Notes**:

- Read component metadata from registry API
- Validate license tier before download
- Download tar.gz from signed URL
- Verify SHA256 checksum
- Extract to correct directory based on type
- Run post-install scripts if present
- Update turbo.json pipeline if needed
- Update docker-compose.yml if needed
- Handle component versioning
- Component code is NOT in the public repository

**Dependencies**: 1.2, 2.3 (in private repo)

**Related Stories**: 4.2

### Story 4.2: Component Metadata Interface

**Type**: Backend API Story

**As a** developer
**I want** to discover available components
**So that** I can understand what I can add to my project

**Acceptance Criteria**:

- **Given** CLI calls registry API
  - **When** with valid license
  - **Then** it should receive components filtered by license tier
- **Given** component metadata
  - **When** returned
  - **Then** it should include: slug, name, description, version, phase, licence, requires, provides
- **Given** a component has prerequisites
  - **When** displayed
  - **Then** it should show required dependencies clearly
- **Given** component compatibility
  - **When** checked
  - **Then** it should validate against project stage

**Architecture Design Notes**:

- CLI interfaces with Template Registry API
- Component metadata schema:

```yaml
slug: payment-service
name: Payment Service
description: Stripe payment processing
version: 1.2.0
phase: foundation
licence: FOUNDATION
requires:
  - auth-service
  - organization-service
provides:
  - rest_api
  - webhooks
  - db_migrations
```

- Cache metadata locally for offline browsing
- Version compatibility checking

**Dependencies**: 2.3 (in private repo)

**Related Stories**: 4.1

## Feature 5: Migration System

The ability to migrate projects between stages (MVP → Foundation → Growth → Full).

### Story 5.1: Migration Planning and Analysis

**Type**: Backend API Story

**As a** developer
**I want** to analyze migration requirements before executing
**So that** I can prepare for the migration

**Acceptance Criteria**:

- **Given** I run `vibebiz migrate foundation --dry-run`
  - **When** from MVP stage
  - **Then** it should show required changes without executing
- **Given** migration analysis
  - **When** completed
  - **Then** it should show: infrastructure needed, data volume, estimated time, costs
- **Given** incompatible customizations
  - **When** detected in code
  - **Then** it should list files that need manual review
- **Given** data migration needed
  - **When** from local PostgreSQL to Cloud SQL
  - **Then** it should show database size and estimated transfer time
- **Given** cost estimation
  - **When** for cloud resources
  - **Then** it should show monthly estimates for each service
- **Given** custom code divergence
  - **When** detected
  - **Then** it should use jsdiff/python-deepdiff against template_hash

**Architecture Design Notes**:

- Analyze project structure and modifications
- Check component compatibility
- Calculate data volume from PostgreSQL
- Estimate cloud resource costs
- Generate migration checklist
- Save analysis for actual migration
- Identify custom code that needs review
- Use jsdiff for JavaScript/TypeScript files
- Use python-deepdiff for Python files
- Compare against original template_hash from config.json

**Dependencies**: 1.3

**Related Stories**: 5.2

### Story 5.2: MVP to Foundation Migration

**Type**: Backend API Story

**As a** developer
**I want** to migrate from MVP to Foundation stage
**So that** I can deploy to production

**Acceptance Criteria**:

- **Given** I run `vibebiz migrate foundation`
  - **When** after dry-run confirmation
  - **Then** it should execute the complete migration
- **Given** local PostgreSQL data
  - **When** migrating
  - **Then** it should use pg_dump/restore to Cloud SQL with validation
- **Given** environment variables
  - **When** in .env files
  - **Then** they should be migrated to Secret Manager
- **Given** migration completes
  - **When** successfully
  - **Then** config.json should show stage: "foundation" with migration timestamp
- **Given** migration fails
  - **When** at any step
  - **Then** it should log failure point and provide rollback instructions
- **Given** post-migration
  - **When** complete
  - **Then** it should run health checks on all services
- **Given** security tools
  - **When** migrating to Foundation
  - **Then** it should add Semgrep, container scanning, and SLSA
- **Given** downtime expected
  - **When** for data migration
  - **Then** it should be < 5 minutes for databases < 1GB

**Architecture Design Notes**:

- Zero data transformation (PostgreSQL to PostgreSQL)
- Use pg_dump with custom format for speed
- Terraform for GCP infrastructure provisioning
- Update docker-compose for cloud services
- Generate GitHub Actions workflows
- Add security scanning pipeline (Semgrep, Trivy)
- Configure Cloud Build for CI/CD
- Update service URLs and configs
- Backup local data before migration
- Migration only requires cloud deployment, no schema changes
- License tier check required before migration
- Snapshot Cloud SQL immediately after creation
- Document downtime expectation: ~5 min for <1GB
- Maintain read-only mode during transfer

**Dependencies**: 5.1

**Related Stories**: None

### Story 5.3: Migration User Experience

**Type**: Frontend Story

**As a** developer
**I want** clear feedback during migration
**So that** I understand the process and can handle issues

**Acceptance Criteria**:

- **Given** migration starts
  - **When** running
  - **Then** it should show progress bar with current step
- **Given** migration steps
  - **When** displayed
  - **Then** they should show: backup, provision, migrate, validate, finalize
- **Given** a step fails
  - **When** during migration
  - **Then** it should show detailed error and recovery options
- **Given** migration completes
  - **When** successfully
  - **Then** it should display summary with next steps
- **Given** rollback needed
  - **When** failure occurs
  - **Then** it should provide automated rollback using Cloud SQL snapshot

**Architecture Design Notes**:

- Interactive CLI with progress indicators
- Step-by-step status updates
- Log file for detailed debugging
- Rollback instructions on failure
- Post-migration checklist
- Links to new cloud resources
- Automated rollback script using:
  - Cloud SQL snapshot restore
  - Docker Compose fallback for local revert
  - Preserved .env.backup files

**Dependencies**: 5.2

**Related Stories**: None

## Feature 6: Development Environment

Local development setup and tooling for the MVP template.

### Story 6.1: Local Development Orchestration

**Type**: Backend API Story

**As a** developer
**I want** to run all services locally with one command
**So that** I can develop efficiently

**Acceptance Criteria**:

- **Given** I run `vibebiz dev mvp`
  - **When** in project directory
  - **Then** it should start all services via docker-compose
- **Given** services are starting
  - **When** with health checks
  - **Then** it should show status and wait for all healthy
- **Given** a service fails to start
  - **When** due to port conflict
  - **Then** it should show error: "Port 3000 already in use by process X"
- **Given** services are running
  - **When** I modify code
  - **Then** they should hot-reload (Next.js HMR, FastAPI --reload)
- **Given** I press Ctrl+C
  - **When** services running
  - **Then** they should stop gracefully with cleanup
- **Given** first time setup
  - **When** database empty
  - **Then** it should run migrations automatically

**Architecture Design Notes**:

- Wrapper around docker-compose with enhanced UX
- Service health endpoints polling
- Port conflict detection before start
- Colored log output with service prefixes
- Environment variable validation
- Database readiness before API start
- Show URLs for all services when ready

**Dependencies**: 3.1

**Related Stories**: 6.2

### Story 6.2: Development Data Seeding

**Type**: Backend API Story

**As a** developer
**I want** realistic test data in my local environment
**So that** I can test features properly

**Acceptance Criteria**:

- **Given** I run `pnpm db:seed`
  - **When** database has schema
  - **Then** it should create 3 organizations with data
- **Given** seed data is created
  - **When** for organizations
  - **Then** each should have 5-10 users and 3-5 projects
- **Given** test users are created
  - **When** with passwords
  - **Then** they should use 'password123' for easy testing
- **Given** I run seed command again
  - **When** data exists
  - **Then** it should skip existing records or offer --force option
- **Given** seed completes
  - **When** successfully
  - **Then** it should output test credentials and org slugs
- **Given** CI environment
  - **When** --deterministic flag is used
  - **Then** it should use fixed Faker seed for reproducible data

**Architecture Design Notes**:

- Python script using Faker library
- Organizations: acme-corp, tech-startup, enterprise-co
- Consistent test users: admin@, user@, viewer@ each org
- Projects in various states
- Sample API keys for testing
- Notification preferences
- Audit log entries
- Document credentials in README
- Deterministic mode: `FAKER_SEED=42` for CI

**Dependencies**: 3.6

**Related Stories**: 6.1

## Feature 7: Testing Infrastructure

Comprehensive testing setup for the MVP template.

### Story 7.1: Unit Test Framework (✅ COMPLETE)

**Type**: Backend API Story

**As a** developer
**I want** unit tests for all services
**So that** I can ensure code quality

**Acceptance Criteria**:

- **Given** the MVP template
  - **When** I run `pnpm test`
  - **Then** it should run all unit tests via Turborepo
- **Given** a TypeScript service
  - **When** tests run
  - **Then** they should use Jest with ts-jest and report coverage
- **Given** a Python service
  - **When** tests run
  - **Then** they should use pytest with pytest-cov
- **Given** tests complete
  - **When** successfully
  - **Then** combined coverage should be reported
- **Given** coverage thresholds
  - **When** below 60% (MVP minimum)
  - **Then** the test suite should fail with coverage report

**Architecture Design Notes**:

- Jest config for TypeScript with ts-jest
- Pytest config for Python with asyncio support
- Coverage reports in JSON and HTML
- Test database with transaction rollback
- Mock external services
- Shared fixtures for common test data
- GitHub Actions ready output format

**Dependencies**: All service stories

**Related Stories**: 7.2

### Story 7.2: Integration Test Setup

**Type**: Backend API Story

**As a** developer
**I want** integration tests for API endpoints
**So that** I can verify end-to-end functionality

**Acceptance Criteria**:

- **Given** I run `pnpm test:integration`
  - **When** services not running
  - **Then** it should start PostgreSQL via testcontainers
- **Given** integration tests run
  - **When** for auth endpoints
  - **Then** they should test full registration/login flow
- **Given** test data is needed
  - **When** for each test
  - **Then** it should be created in transaction and rolled back
- **Given** API tests
  - **When** making requests
  - **Then** they should validate response schema against OpenAPI
- **Given** multi-service tests
  - **When** testing org creation
  - **Then** they should verify user service updates

**Architecture Design Notes**:

- Testcontainers for PostgreSQL isolation
- Supertest for API testing
- Database transaction per test
- JWT token generation for auth tests
- OpenAPI schema validation
- Separate test configuration
- Parallel execution where possible

**Dependencies**: 7.1

**Related Stories**: None

### Story 7.3: E2E Test Framework

**Type**: Frontend Story

**As a** QA engineer
**I want** end-to-end tests for critical user flows
**So that** I can ensure the system works for users

**Acceptance Criteria**:

- **Given** I run `pnpm test:e2e`
  - **When** with services running
  - **Then** it should run Playwright tests
- **Given** E2E tests
  - **When** for signup flow
  - **Then** they should test UI through to database
- **Given** test failures
  - **When** occur
  - **Then** screenshots and traces should be captured
- **Given** E2E tests complete
  - **When** in CI
  - **Then** they should generate HTML report
- **Given** CSP headers
  - **When** checked in E2E tests
  - **Then** they should assert CSP header exists

**Architecture Design Notes**:

- Playwright for cross-browser testing
- Critical paths: signup, login, create org, invite user
- Page object model for maintainability
- Test data cleanup after runs
- Visual regression testing prep
- Run against local docker-compose
- CSP header assertion included

**Dependencies**: All frontend stories

**Related Stories**: 7.1, 7.2, 7.4

### Story 7.4: Accessibility Test Suite

**Type**: Frontend Story

**As a** accessibility compliance officer
**I want** automated accessibility testing
**So that** we meet WCAG 2.2 standards

**Acceptance Criteria**:

- **Given** accessibility tests configured
  - **When** I run `pnpm test:a11y`
  - **Then** it should run axe-playwright tests
- **Given** unit tests
  - **When** for React components
  - **Then** they should include axe-jest assertions
- **Given** Lighthouse budget
  - **When** configured
  - **Then** it should fail if accessibility score < 75
- **Given** critical user flows
  - **When** tested
  - **Then** they should have 90% automated rule coverage
- **Given** violations found
  - **When** during testing
  - **Then** they should report specific WCAG criteria

**Architecture Design Notes**:

- axe-playwright for E2E accessibility testing
- axe-jest for component-level testing
- Lighthouse CI with performance budgets
- Critical flows: signup, login, dashboard navigation
- WCAG 2.2 Level AA compliance target
- Automated reports with violation details
- Manual testing checklist for remaining 10%

**Dependencies**: 7.3

**Related Stories**: 7.1, 7.3

## Feature 8: Security Implementation

Security features and best practices for the MVP template.

### Story 8.1: Environment Variable Management

**Type**: Backend API Story

**As a** developer
**I want** secure environment variable handling
**So that** secrets are not exposed

**Acceptance Criteria**:

- **Given** the MVP template
  - **When** I check the repository
  - **Then** .env files should be in .gitignore
- **Given** environment files
  - **When** needed for services
  - **Then** comprehensive .env.example files should exist
- **Given** a service starts
  - **When** missing required env vars
  - **Then** it should fail with clear message listing missing vars
- **Given** sensitive variables
  - **When** in logs
  - **Then** they should be redacted as \*\*\*
- **Given** .env.example
  - **When** for each service
  - **Then** it should include descriptions and valid examples

**Architecture Design Notes**:

- .env, .env.local, .env.\*.local in .gitignore
- Required vs optional vars clearly marked
- Validation on startup using pydantic/zod
- Structured config objects
- Redaction in logging middleware
- Different configs for dev/test/prod

**Dependencies**: None

**Related Stories**: 8.2

### Story 8.2: Basic Security Headers and CORS

**Type**: Backend API Story

**As a** security engineer
**I want** proper security headers and CORS configuration
**So that** the application is protected from common attacks

**Acceptance Criteria**:

- **Given** any API response
  - **When** from FastAPI services
  - **Then** it should include: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection
- **Given** CORS configuration
  - **When** for development
  - **Then** it should allow <http://localhost:3000> only
- **Given** production config
  - **When** CORS is set
  - **Then** it should read allowed origins from environment
- **Given** the Next.js app
  - **When** serving pages
  - **Then** it should set CSP headers via Helmet.js
- **Given** rate limit headers
  - **When** on API responses
  - **Then** they should show: X-RateLimit-Limit, X-RateLimit-Remaining

**Architecture Design Notes**:

- FastAPI middleware for security headers
- CORS middleware with environment config
- Helmet.js for Next.js security headers
- CSP policy blocking inline scripts
- HSTS header in production only
- Rate limiting with proper headers
- Referrer-Policy and Permissions-Policy

**Dependencies**: 3.3

**Related Stories**: 8.3

### Story 8.3: Input Validation and Sanitization

**Type**: Backend API Story

**As a** security engineer
**I want** all inputs validated and sanitized
**So that** injection attacks are prevented

**Acceptance Criteria**:

- **Given** API endpoints
  - **When** receiving data
  - **Then** Pydantic models should validate all inputs
- **Given** string inputs
  - **When** stored in database
  - **Then** they should use parameterized queries only
- **Given** file uploads
  - **When** processed
  - **Then** they should validate MIME type and size < 10MB
- **Given** validation errors
  - **When** returned
  - **Then** they should not expose internal structure
- **Given** email inputs
  - **When** validated
  - **Then** they should use proper email regex
- **Given** SQL queries
  - **When** built
  - **Then** they should never use string concatenation

**Architecture Design Notes**:

- Pydantic models for every endpoint
- SQLAlchemy with parameterized queries
- No raw SQL without parameters
- File validation by magic bytes not extension
- Generic error messages
- HTML escaping for any rendered content
- Path traversal prevention

**Dependencies**: 3.3

**Related Stories**: None

### Story 8.4: Authentication Security

**Type**: Backend API Story

**As a** security engineer
**I want** secure authentication implementation
**So that** user accounts are protected

**Acceptance Criteria**:

- **Given** password storage
  - **When** user registers
  - **Then** passwords should be hashed with bcrypt cost 12
- **Given** login attempts
  - **When** failing 5 times
  - **Then** account should be temporarily locked for 15 minutes
- **Given** JWT tokens
  - **When** generated
  - **Then** they should include iat, exp, and jti claims
- **Given** refresh tokens
  - **When** used
  - **Then** they should be rotated (new token issued)
- **Given** concurrent sessions
  - **When** exceeding 5 per user
  - **Then** oldest session should be revoked

**Architecture Design Notes**:

- bcrypt with cost factor 12
- Account lockout in user_sessions table
- JWT with standard claims
- Refresh token rotation
- Session limiting logic
- Timing attack prevention
- Audit log for auth events

**Dependencies**: 3.4

**Related Stories**: None

### Story 8.5: Quality-Driven Development Setup

**Type**: Backend API Story

**As a** developer
**I want** quality and security tools configured from the start
**So that** best practices are enforced

**Acceptance Criteria**:

- **Given** Python code
  - **When** linted
  - **Then** Bandit should check for security issues
- **Given** TypeScript code
  - **When** linted
  - **Then** ESLint with security plugin should run
- **Given** dependencies
  - **When** installed
  - **Then** npm audit and pip-audit should check vulnerabilities
- **Given** git commits
  - **When** made
  - **Then** pre-commit hooks should run security checks
- **Given** CI pipeline
  - **When** running
  - **Then** it should include security scanning steps

**Architecture Design Notes**:

- Bandit configuration for Python security
- ESLint-plugin-security for TypeScript
- Pre-commit hooks with security checks
- GitHub Dependabot enabled
- Basic SAST scanning in CI
- Prepare for Semgrep (Foundation)
- Security checklist in PR template

**Dependencies**: 3.1

**Related Stories**: None

## Feature 9: Documentation and Developer Experience

Documentation and tooling for developers using the template.

### Story 9.1: API Documentation Generation

**Type**: Backend API Story

**As a** frontend developer
**I want** automatically generated API documentation
**So that** I can understand available endpoints

**Acceptance Criteria**:

- **Given** FastAPI services running
  - **When** I visit /docs
  - **Then** I should see Swagger UI with all endpoints
- **Given** OpenAPI schema
  - **When** at /openapi.json
  - **Then** it should include examples and descriptions
- **Given** TypeScript types needed
  - **When** I run `pnpm generate:types`
  - **Then** they should be created from OpenAPI schema
- **Given** API documentation
  - **When** viewing
  - **Then** it should show required headers and auth
- **Given** Redoc view
  - **When** at /redoc
  - **Then** it should show alternative documentation format

**Architecture Design Notes**:

- FastAPI automatic OpenAPI 3.1 generation
- Response examples in Pydantic models
- openapi-typescript-codegen for types
- Proper descriptions for all endpoints
- Authentication documentation
- Error response examples
- Webhook payload examples

**Dependencies**: 3.3

**Related Stories**: 9.2

### Story 9.2: Getting Started Documentation

**Type**: Frontend Story

**As a** new developer
**I want** clear getting started documentation
**So that** I can quickly understand the template

**Acceptance Criteria**:

- **Given** the project README.md
  - **When** at project root
  - **Then** it should have: prerequisites, quick start, architecture overview
- **Given** architecture docs
  - **When** in docs/architecture.md
  - **Then** it should explain system design with diagrams
- **Given** service READMEs
  - **When** in each service
  - **Then** they should explain purpose and endpoints
- **Given** common tasks
  - **When** in docs/guides/
  - **Then** they should have step-by-step instructions
- **Given** API examples
  - **When** in docs
  - **Then** they should show curl and TypeScript examples
- **Given** migration guide
  - **When** in docs
  - **Then** it should explain MVP to Foundation migration process
- **Given** quick start media
  - **When** in README
  - **Then** it should link to video or GIF demonstration

**Architecture Design Notes**:

- Main README with quick start (< 5 mins)
- Architecture diagrams using Mermaid
- Service-specific documentation
- Common tasks: add user, create org, test payments
- Troubleshooting guide
- Environment setup guide
- Links to VibeBiz docs site
- Migration path explanation
- Quick start video/GIF for visual learners

**Dependencies**: None

**Related Stories**: None

### Story 9.3: Code Comments and Examples

**Type**: Backend API Story

**As a** developer
**I want** well-commented code with examples
**So that** I can understand and extend the template

**Acceptance Criteria**:

- **Given** service code
  - **When** reviewing
  - **Then** complex logic should have explanatory comments
- **Given** configuration files
  - **When** checking
  - **Then** they should have inline documentation
- **Given** API endpoints
  - **When** in code
  - **Then** they should have docstrings with examples
- **Given** utility functions
  - **When** reviewing
  - **Then** they should have JSDoc/docstring documentation
- **Given** template functions
  - **When** used
  - **Then** they should have usage examples in comments

**Architecture Design Notes**:

- Docstrings for all public functions
- Complex business logic explained
- Configuration options documented
- TODO comments for extension points
- Example usage in comments
- Link to relevant docs
- Template function examples

**Dependencies**: All stories

**Related Stories**: None

## Feature 10: Monitoring and Observability

Basic monitoring and observability for the MVP template.

### Story 10.1: Health Check Endpoints

**Type**: Backend API Story

**As a** DevOps engineer
**I want** health check endpoints for all services
**So that** I can monitor service availability

**Acceptance Criteria**:

- **Given** any service
  - **When** GET /healthz
  - **Then** it should return 200 with {"status": "ok", "version": "x.x.x"}
- **Given** database dependency
  - **When** PostgreSQL is down
  - **Then** health check should return 503 Service Unavailable
- **Given** health check
  - **When** called
  - **Then** response time should be < 100ms
- **Given** Kubernetes deployment
  - **When** configured
  - **Then** it should use /healthz for liveness probe
- **Given** the response
  - **When** healthy
  - **Then** it should include service name and uptime

**Architecture Design Notes**:

- /healthz endpoint on all services
- No authentication required
- Database connectivity check with timeout
- Version from package.json/pyproject.toml
- Uptime calculation
- Ready for K8s probes
- Prometheus metrics endpoint prep

**Dependencies**: All service stories

**Related Stories**: 10.2

### Story 10.2: Structured Logging

**Type**: Backend API Story

**As a** developer
**I want** structured JSON logging
**So that** I can debug issues effectively

**Acceptance Criteria**:

- **Given** any log output
  - **When** from services
  - **Then** it should be structured JSON with timestamp
- **Given** API request
  - **When** processed
  - **Then** logs should include: request_id, user_id, org_id, duration
- **Given** errors occur
  - **When** logged
  - **Then** they should include stack trace and context
- **Given** log levels
  - **When** configured
  - **Then** development should use DEBUG, production INFO
- **Given** sensitive data
  - **When** in logs
  - **Then** it should be redacted (passwords, tokens, keys)

**Architecture Design Notes**:

- Python: structlog with JSON renderer
- TypeScript: winston with JSON format
- Request ID generation (UUID v4)
- Context injection middleware
- Performance timing
- Error serialization
- Log level from environment
- Redaction patterns

**Dependencies**: None

**Related Stories**: 10.1

### Story 10.3: Error Tracking Setup

**Type**: Backend API Story

**As a** developer
**I want** error tracking configured
**So that** I can monitor production issues

**Acceptance Criteria**:

- **Given** an unhandled error
  - **When** in production
  - **Then** it should be logged with full context
- **Given** error tracking
  - **When** configured
  - **Then** Sentry SDK should be optional via env var
- **Given** 4xx errors
  - **When** from client mistakes
  - **Then** they should be logged but not alerted
- **Given** 5xx errors
  - **When** from server issues
  - **Then** they should trigger alerts (when Sentry configured)

**Architecture Design Notes**:

- Sentry SDK with environment toggle
- User context attached to errors
- Release tracking
- Source maps for frontend
- Ignore list for expected errors
- Performance monitoring prep
- Local error logging fallback

**Dependencies**: 10.2

**Related Stories**: None

### Story 10.4: Metrics Endpoint

**Type**: Backend API Story

**As a** DevOps engineer
**I want** Prometheus-compatible metrics
**So that** I can prepare for future observability

**Acceptance Criteria**:

- **Given** ENABLE_METRICS=true
  - **When** GET /metrics
  - **Then** it should return Prometheus text format
- **Given** metrics endpoint
  - **When** enabled
  - **Then** it should track request count, duration, and errors
- **Given** metrics disabled
  - **When** ENABLE_METRICS not set
  - **Then** endpoint should return 404
- **Given** custom metrics
  - **When** defined
  - **Then** they should follow Prometheus naming conventions

**Architecture Design Notes**:

- Optional /metrics endpoint behind env flag
- Basic metrics: http_requests_total, http_request_duration_seconds
- No infrastructure cost in MVP
- Preparation for OpenTelemetry in Foundation
- prometheus-fastapi-instrumentator for Python
- prom-client for Node.js services

**Dependencies**: 3.3

**Related Stories**: 10.1

## Feature 11: Performance Optimization

Performance optimizations for the MVP template.

### Story 11.1: Database Query Optimization

**Type**: Backend API Story

**As a** developer
**I want** optimized database queries
**So that** the application performs well

**Acceptance Criteria**:

- **Given** database tables
  - **When** created
  - **Then** they should have appropriate indexes
- **Given** N+1 queries
  - **When** possible
  - **Then** they should be prevented with eager loading
- **Given** pagination
  - **When** on large tables
  - **Then** it should use cursor-based pagination
- **Given** frequently accessed data
  - **When** like user profiles
  - **Then** query patterns should be optimized

**Architecture Design Notes**:

- Indexes on foreign keys and common WHERE clauses
- SQLAlchemy eager loading with joinedload
- Cursor pagination implementation
- Query performance logging in development
- Connection pooling configuration
- Prepared statements where possible

**Dependencies**: 3.6

**Related Stories**: None

### Story 11.2: API Response Optimization

**Type**: Backend API Story

**As a** developer
**I want** optimized API responses
**So that** the frontend performs well

**Acceptance Criteria**:

- **Given** API responses
  - **When** large
  - **Then** they should support gzip compression
- **Given** list endpoints
  - **When** returning many items
  - **Then** they should paginate with max 50 items
- **Given** unchanged resources
  - **When** requested again
  - **Then** they should use ETag/If-None-Match
- **Given** response times
  - **When** measured
  - **Then** p95 should be < 500ms for MVP

**Architecture Design Notes**:

- Gzip middleware on FastAPI
- Default pagination with page_size
- ETag generation from updated_at
- Response time logging
- Minimal serialization overhead
- Field filtering support prep

**Dependencies**: 3.3

**Related Stories**: None

## Feature 12: Deployment Preparation

Preparing the MVP template for future deployment.

### Story 12.1: Docker Configuration

**Type**: Backend API Story

**As a** DevOps engineer
**I want** proper Docker configuration
**So that** services can be containerized

**Acceptance Criteria**:

- **Given** each service
  - **When** building
  - **Then** it should have an optimized Dockerfile
- **Given** Docker images
  - **When** built
  - **Then** they should use multi-stage builds for size
- **Given** development mode
  - **When** using Docker
  - **Then** it should support hot reloading
- **Given** production builds
  - **When** created
  - **Then** they should exclude dev dependencies

**Architecture Design Notes**:

- Multi-stage Dockerfiles
- Non-root user for security
- Layer caching optimization
- Health check commands
- Build args for flexibility
- .dockerignore files
- Development vs production stages

**Dependencies**: All service stories

**Related Stories**: 12.2

### Story 12.2: CI/CD Pipeline Templates

**Type**: Backend API Story

**As a** developer
**I want** CI/CD pipeline templates
**So that** I can automate testing and deployment

**Acceptance Criteria**:

- **Given** GitHub Actions
  - **When** templates provided
  - **Then** they should include test, build, and deploy workflows
- **Given** pull requests
  - **When** opened
  - **Then** CI should run tests and linting
- **Given** main branch
  - **When** pushed
  - **Then** it should build and prepare for deployment
- **Given** security scanning
  - **When** in CI
  - **Then** it should check dependencies and containers
- **Given** quality checks
  - **When** in CI
  - **Then** they should run Bandit and ESLint security

**Architecture Design Notes**:

- .github/workflows/ templates
- Test workflow with coverage
- Build workflow with caching
- Security scanning with Dependabot
- Container scanning prep
- Environment-based deployment
- Secrets management
- Quality tool integration

**Dependencies**: 7.1, 8.1

**Related Stories**: None

### Story 12.3: Production Configuration

**Type**: Backend API Story

**As a** developer
**I want** production-ready configuration
**So that** the application can run safely in production

**Acceptance Criteria**:

- **Given** production config
  - **When** applied
  - **Then** debug mode should be disabled
- **Given** logging
  - **When** in production
  - **Then** it should use INFO level minimum
- **Given** error responses
  - **When** in production
  - **Then** they should not expose stack traces
- **Given** CORS settings
  - **When** for production
  - **Then** they should restrict to specific domains

**Architecture Design Notes**:

- Production environment detection
- Secure defaults for production
- Error message sanitization
- Strict CORS configuration
- HTTPS enforcement prep
- Security headers enabled
- Rate limiting enabled

**Dependencies**: 8.2, 10.2

**Related Stories**: None

---

## Implementation Order

### Phase 1: VibeBiz Platform (Private Repository)

1. Set up `vibebiz-platform` repository
2. Implement License Server API (Story 2.1)
3. Implement Template Registry Service (Story 2.3)
4. Build License Management Dashboard (Story 2.2)
5. Set up component storage (Story 2.4)

### Phase 2: VibeBiz SaaS Template (Public Repository)

1. Set up `vibebiz-saas-template` repository
2. Implement CLI foundation (Stories 1.1-1.4)
3. Build MVP template components (Stories 3.1-3.11)
4. Implement component management (Stories 4.1-4.2)
5. Build migration system (Stories 5.1-5.3)
6. Complete remaining features (6-12)

### Deployment Strategy

**VibeBiz Platform (Private)**:

- Deploy APIs on Google Cloud Run
- Use Cloud SQL for PostgreSQL database
- Store components in Google Cloud Storage
- Deploy dashboard on Cloud Run or Vercel

**VibeBiz SaaS Template (Public)**:

- Publish CLI to npm registry
- Host public repository on GitHub
- Provide Docker Compose for local development
- Include Terraform scripts for cloud migration

---

## Summary of v1.1 Enhancements

1. **Production-Grade Security**: Added CSP header testing, token revocation list, and enhanced security validation
2. **Accessibility Testing**: New Story 7.4 for comprehensive WCAG 2.2 compliance testing
3. **Enhanced Observability**: Added optional /metrics endpoint (Story 10.4) for Prometheus compatibility
4. **Improved Templates**: Added seed-script and test-suite generators to template functions
5. **Better Migration Tooling**:
   - Custom code divergence detection with diff algorithms
   - Documented downtime expectations (< 5 min for < 1GB)
   - Automated rollback strategy with Cloud SQL snapshots
6. **Enhanced Documentation**: Added quick start video/GIF requirement for better developer onboarding
7. **CI-Ready Seeding**: Added --deterministic flag for reproducible test data
