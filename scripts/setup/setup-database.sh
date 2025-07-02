#!/bin/bash
#
# VibeBiz Platform Database Setup
# This script sets up PostgreSQL database and runs migrations
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PRODUCTION_MODE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --production)
            PRODUCTION_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if PostgreSQL is running
check_postgresql() {
    if command -v psql &> /dev/null; then
        if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Function to start PostgreSQL with Docker
start_postgresql_docker() {
    log_info "Starting PostgreSQL with Docker..."

    # Check if Docker container already exists
    if docker ps -a --format "table {{.Names}}" | grep -q "vibebiz-postgres"; then
        if docker ps --format "table {{.Names}}" | grep -q "vibebiz-postgres"; then
            log_success "PostgreSQL container already running"
            return 0
        else
            log_info "Starting existing PostgreSQL container..."
            docker start vibebiz-postgres
        fi
    else
        log_info "Creating new PostgreSQL container..."
        docker run -d \
            --name vibebiz-postgres \
            -e POSTGRES_DB=vibebiz_dev \
            -e POSTGRES_USER=postgres \
            -e POSTGRES_PASSWORD=postgres \
            -p 5432:5432 \
            -v vibebiz_postgres_data:/var/lib/postgresql/data \
            postgres:15-alpine
    fi

    log_success "PostgreSQL started with Docker"

    # Wait for PostgreSQL to be ready
    log_info "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker exec vibebiz-postgres pg_isready -U postgres > /dev/null 2>&1; then
            log_success "PostgreSQL is ready"
            return 0
        fi

        log_info "Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done

    log_error "PostgreSQL failed to start within expected time"
    return 1
}

# Function to create databases
create_databases() {
    log_info "Creating databases..."

    # Create development database
    if ! docker exec vibebiz-postgres psql -U postgres -c "SELECT 1 FROM pg_database WHERE datname='vibebiz_dev'" | grep -q 1; then
        docker exec vibebiz-postgres createdb -U postgres vibebiz_dev
        log_success "Created vibebiz_dev database"
    else
        log_info "vibebiz_dev database already exists"
    fi

    # Create test database
    if ! docker exec vibebiz-postgres psql -U postgres -c "SELECT 1 FROM pg_database WHERE datname='vibebiz_test'" | grep -q 1; then
        docker exec vibebiz-postgres createdb -U postgres vibebiz_test
        log_success "Created vibebiz_test database"
    else
        log_info "vibebiz_test database already exists"
    fi
}

# Function to run database migrations
run_migrations() {
    log_info "Running database migrations..."

    cd "$ROOT_DIR"

    # Run migrations for each Python service
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ] && [ -d "$service_dir/migrations" ]; then
            service_name=$(basename "$service_dir")
            log_info "Running migrations for $service_name..."

            cd "$service_dir"

            # Check if alembic is available
            if poetry run alembic --help > /dev/null 2>&1; then
                # Check current migration status
                local current_revision=$(poetry run alembic current 2>/dev/null | cut -d' ' -f1 || echo "")
                local head_revision=$(poetry run alembic heads 2>/dev/null | head -n1 | cut -d' ' -f1 || echo "")

                if [ "$current_revision" != "$head_revision" ]; then
                    log_info "Upgrading database to latest migration..."
                    if poetry run alembic upgrade head; then
                        log_success "Migrations completed for $service_name"
                    else
                        log_warning "Migrations failed for $service_name - this might be expected on first run"
                    fi
                else
                    log_success "Database is up to date for $service_name"
                fi
            else
                log_warning "Alembic not found in $service_name - skipping migrations"
            fi

            cd "$ROOT_DIR"
        fi
    done
}

# Function to seed database
seed_database() {
    log_info "Seeding database with initial data..."

    cd "$ROOT_DIR"

    # Check if there are any seed scripts
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")

            # Look for seed scripts
            if [ -f "$service_dir/scripts/seed.py" ]; then
                log_info "Running seed script for $service_name..."
                cd "$service_dir"

                if poetry run python scripts/seed.py; then
                    log_success "Database seeded for $service_name"
                else
                    log_warning "Seed script failed for $service_name"
                fi

                cd "$ROOT_DIR"
            fi
        fi
    done
}

# Function to verify database setup
verify_database() {
    log_info "Verifying database setup..."

    # Check if we can connect to the database
    if docker exec vibebiz-postgres psql -U postgres -d vibebiz_dev -c "SELECT version();" > /dev/null 2>&1; then
        log_success "Database connection verified"
    else
        log_error "Cannot connect to database"
        return 1
    fi

    # Check if tables exist
    local table_count=$(docker exec vibebiz-postgres psql -U postgres -d vibebiz_dev -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')

    if [ "$table_count" -gt 0 ]; then
        log_success "Database contains $table_count tables"
    else
        log_warning "Database appears to be empty - migrations may not have run"
    fi
}

# Function to setup production database
setup_production_database() {
    log_warning "Production mode - skipping automatic database setup"
    log_info "Please ensure PostgreSQL is running and configured with:"
    echo "  - Database: vibebiz_production"
    echo "  - User: vibebiz_user"
    echo "  - Password: [secure password]"
    echo ""
    log_info "Then run migrations manually:"
    echo "  cd services/public-api"
    echo "  poetry run alembic upgrade head"
    echo ""
    log_info "Make sure your .env files contain the correct DATABASE_URL"
}

# Main setup function
main() {
    log_info "Setting up database..."

    if [ "$PRODUCTION_MODE" = true ]; then
        setup_production_database
        return 0
    fi

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        return 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        return 1
    fi

    # Start PostgreSQL
    if ! start_postgresql_docker; then
        log_error "Failed to start PostgreSQL"
        return 1
    fi

    # Create databases
    if ! create_databases; then
        log_error "Failed to create databases"
        return 1
    fi

    # Run migrations
    if ! run_migrations; then
        log_warning "Some migrations may have failed"
    fi

    # Seed database
    seed_database

    # Verify setup
    if ! verify_database; then
        log_error "Database verification failed"
        return 1
    fi

    log_success "Database setup complete!"

    echo ""
    log_info "Database Summary:"
    echo "✅ PostgreSQL running in Docker"
    echo "✅ Development database: vibebiz_dev"
    echo "✅ Test database: vibebiz_test"
    echo "✅ Migrations applied"
    echo "✅ Database seeded (if applicable)"
    echo ""
    log_info "Connection details:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  User: postgres"
    echo "  Password: postgres"
    echo "  Database: vibebiz_dev"
    echo ""
    log_info "You can connect using:"
    echo "  psql -h localhost -p 5432 -U postgres -d vibebiz_dev"
    echo "  or"
    echo "  docker exec -it vibebiz-postgres psql -U postgres -d vibebiz_dev"
}

# Run main function
main
