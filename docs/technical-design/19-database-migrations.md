# Database Migration System with Yoyo-Migrations

## Overview

Database schema migration using Yoyo-Migrations for PostgreSQL with raw SQL support, rollbacks, and environment-specific configurations.

## Installation

```bash
pip install yoyo-migrations
```

## Configuration

```ini
# yoyo.ini
[DEFAULT]
database = postgresql://user:password@localhost:5432/robotoverlord
migrations = migrations
batch_mode = on
verbosity = 0

[development]
database = postgresql://user:password@localhost:5432/robotoverlord_dev

[production]
database = ${DATABASE_URL}
```

## Migration Structure

```
migrations/
├── 0001.initial-schema.py
├── 0002.add-queue-tables.py
├── 0003.add-materialized-views.py
├── seeds/
│   ├── development/
│   │   ├── users.sql
│   │   └── topics.sql
│   └── production/
│       └── badges.sql
└── yoyo.ini
```

## Creating Migrations

### Using Yoyo CLI

```bash
# Create a new migration
yoyo new ./migrations -m "create users table"

# This creates: migrations/0001.create-users-table.py
```

### Basic Migration Example

```python
# migrations/0001.initial-schema.py
from yoyo import step

# Forward migration with rollback
step(
    """
    -- Enable required extensions
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "citext";
    CREATE EXTENSION IF NOT EXISTS "pgvector";
    
    -- Users table
    CREATE TABLE users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) NOT NULL UNIQUE,
        google_id VARCHAR(255) NOT NULL UNIQUE,
        username VARCHAR(100) NOT NULL,
        role VARCHAR(20) NOT NULL CHECK (role IN ('citizen', 'moderator', 'admin', 'superadmin')),
        loyalty_score INTEGER DEFAULT 0,
        is_banned BOOLEAN DEFAULT FALSE,
        is_sanctioned BOOLEAN DEFAULT FALSE,
        email_verified BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Create indexes
    CREATE INDEX idx_users_loyalty_score ON users(loyalty_score DESC) WHERE loyalty_score > 0;
    CREATE INDEX idx_users_username ON users(username);
    """,
    # Rollback migration
    """
    DROP TABLE IF EXISTS users;
    """
)
```

## Usage Commands

```bash
# Check migration status
yoyo list --database postgresql://user:pass@localhost/db ./migrations

# Apply all pending migrations
yoyo apply --database postgresql://user:pass@localhost/db ./migrations

# Apply migrations with config file
yoyo apply ./migrations

# Rollback last migration
yoyo rollback --database postgresql://user:pass@localhost/db ./migrations

# Rollback to specific migration
yoyo rollback --revision 0001 ./migrations
```

## Integration with Application

```python
# app/database/migrations.py
import os
from yoyo import get_backend, read_migrations

async def ensure_migrations():
    """Ensure database is up to date on application startup"""
    database_url = os.getenv('DATABASE_URL')
    backend = get_backend(database_url)
    
    migrations = read_migrations('./migrations')
    
    # Apply any pending migrations
    with backend.lock():
        backend.apply_migrations(backend.to_apply(migrations))```

## Advanced Migration Examples

### Queue Tables Migration

```python
# migrations/0002.add-queue-tables.py
from yoyo import step

step(
    """
    -- Topic creation queue
    CREATE TABLE topic_creation_queue (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
        priority_score BIGINT NOT NULL,
        priority INTEGER DEFAULT 0,
        position_in_queue INTEGER NOT NULL,
        status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed')) DEFAULT 'pending',
        entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        estimated_completion_at TIMESTAMP WITH TIME ZONE,
        worker_assigned_at TIMESTAMP WITH TIME ZONE,
        worker_id VARCHAR(255)
    );
    
    -- Post moderation queue
    CREATE TABLE post_moderation_queue (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
        topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
        priority_score BIGINT NOT NULL,
        priority INTEGER DEFAULT 0,
        position_in_queue INTEGER NOT NULL,
        status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed')) DEFAULT 'pending',
        entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        estimated_completion_at TIMESTAMP WITH TIME ZONE,
        worker_assigned_at TIMESTAMP WITH TIME ZONE,
        worker_id VARCHAR(255)
    );
    
    -- Private message queue
    CREATE TABLE private_message_queue (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        message_id UUID NOT NULL REFERENCES private_messages(id) ON DELETE CASCADE,
        sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        conversation_id VARCHAR(255) NOT NULL,
        priority_score BIGINT NOT NULL,
        priority INTEGER DEFAULT 0,
        position_in_queue INTEGER NOT NULL,
        status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'processing', 'completed')) DEFAULT 'pending',
        entered_queue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        estimated_completion_at TIMESTAMP WITH TIME ZONE,
        worker_assigned_at TIMESTAMP WITH TIME ZONE,
        worker_id VARCHAR(255)
    );
    
    -- Create indexes
    CREATE INDEX idx_topic_queue_priority ON topic_creation_queue(priority_score DESC, entered_queue_at ASC);
    CREATE INDEX idx_topic_queue_status ON topic_creation_queue(status);
    CREATE INDEX idx_post_queue_topic_priority ON post_moderation_queue(topic_id, priority_score DESC, entered_queue_at ASC);
    CREATE INDEX idx_post_queue_status ON post_moderation_queue(status);
    CREATE INDEX idx_message_queue_conv_priority ON private_message_queue(conversation_id, priority_score DESC, entered_queue_at ASC);
    CREATE INDEX idx_message_queue_status ON private_message_queue(status);
    """,
    "DROP TABLE IF EXISTS private_message_queue; DROP TABLE IF EXISTS post_moderation_queue; DROP TABLE IF EXISTS topic_creation_queue;"
)
```

### Materialized Views Migration

```python
# migrations/0003.add-materialized-views.py
from yoyo import step

def create_leaderboard_view(conn):
    """Create materialized view for leaderboard with proper error handling"""
    cursor = conn.cursor()
    
    # Check if view already exists
    cursor.execute("""
        SELECT EXISTS (
            SELECT 1 FROM pg_matviews 
            WHERE matviewname = 'user_leaderboard'
        );
    """)
    
    if not cursor.fetchone()[0]:
        cursor.execute("""
            CREATE MATERIALIZED VIEW user_leaderboard AS
            SELECT 
                u.id as user_id,
                u.username,
                u.loyalty_score,
                ROW_NUMBER() OVER (ORDER BY u.loyalty_score DESC, u.created_at ASC) as rank,
                CASE 
                    WHEN ROW_NUMBER() OVER (ORDER BY u.loyalty_score DESC, u.created_at ASC) <= 
                         (SELECT COUNT(*) * 0.1 FROM users WHERE loyalty_score > 0) 
                    THEN true 
                    ELSE false 
                END as can_create_topics,
                u.created_at,
                u.updated_at
            FROM users u
            WHERE u.loyalty_score > 0
            ORDER BY u.loyalty_score DESC, u.created_at ASC;
        """)
        
        # Create indexes
        cursor.execute("CREATE UNIQUE INDEX idx_leaderboard_user_id ON user_leaderboard(user_id);")
        cursor.execute("CREATE INDEX idx_leaderboard_rank ON user_leaderboard(rank);")

step(create_leaderboard_view, "DROP MATERIALIZED VIEW IF EXISTS user_leaderboard;")
```

### Governance Tables Migration

```python
# migrations/0004.add-governance-tables.py
from yoyo import step

step(
    """
    -- Appeals table
    CREATE TABLE appeals (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
        appellant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        reason TEXT NOT NULL,
        status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'sustained', 'denied')),
        reviewed_by UUID REFERENCES users(id),
        reviewed_at TIMESTAMP WITH TIME ZONE,
        review_notes TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Flags table
    CREATE TABLE flags (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
        topic_id UUID REFERENCES topics(id) ON DELETE CASCADE,
        flagger_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        reason TEXT NOT NULL,
        status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'sustained', 'dismissed')) DEFAULT 'pending',
        reviewed_by UUID REFERENCES users(id),
        reviewed_at TIMESTAMP WITH TIME ZONE,
        review_notes TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        CONSTRAINT flags_content_check CHECK (
            (post_id IS NOT NULL AND topic_id IS NULL) OR 
            (post_id IS NULL AND topic_id IS NOT NULL)
        )
    );
    
    -- Sanctions table
    CREATE TABLE sanctions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type VARCHAR(50) NOT NULL CHECK (type IN ('posting_freeze', 'rate_limit')),
        applied_by UUID NOT NULL REFERENCES users(id),
        applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        expires_at TIMESTAMP WITH TIME ZONE,
        reason TEXT NOT NULL,
        is_active BOOLEAN DEFAULT TRUE
    );
    
    -- Private messages table
    CREATE TABLE private_messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')),
        overlord_feedback TEXT,
        sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        approved_at TIMESTAMP WITH TIME ZONE
    );
    
    -- Tags table
    CREATE TABLE tags (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(100) NOT NULL UNIQUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Topic_tags junction table
    CREATE TABLE topic_tags (
        topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
        tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
        assigned_by UUID NOT NULL REFERENCES users(id),
        assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        PRIMARY KEY (topic_id, tag_id)
    );
    
    -- Badges table
    CREATE TABLE badges (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(100) NOT NULL UNIQUE,
        description TEXT NOT NULL,
        image_url VARCHAR(500) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- User_badges junction table
    CREATE TABLE user_badges (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
        awarded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        awarded_for_post_id UUID REFERENCES posts(id),
        PRIMARY KEY (user_id, badge_id, awarded_at)
    );
    
    -- Moderation events table
    CREATE TABLE moderation_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        event_type VARCHAR(50) NOT NULL,
        content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('topic', 'post', 'private_message')),
        content_id UUID NOT NULL,
        outcome VARCHAR(20) NOT NULL CHECK (outcome IN ('approved', 'rejected', 'calibrated')),
        moderator_id UUID REFERENCES users(id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Translations table
    CREATE TABLE translations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        content_id UUID NOT NULL,
        content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('post', 'topic', 'private_message')),
        language_code VARCHAR(10) NOT NULL,
        original_content TEXT NOT NULL,
        translated_content TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        UNIQUE(content_id, content_type, language_code)
    );
    
    -- Create indexes for governance tables
    CREATE INDEX idx_appeals_post_id ON appeals(post_id);
    CREATE INDEX idx_appeals_appellant_id ON appeals(appellant_id);
    CREATE INDEX idx_appeals_status ON appeals(status);
    CREATE INDEX idx_appeals_reviewed_by ON appeals(reviewed_by) WHERE reviewed_by IS NOT NULL;
    
    CREATE INDEX idx_flags_post_id ON flags(post_id) WHERE post_id IS NOT NULL;
    CREATE INDEX idx_flags_topic_id ON flags(topic_id) WHERE topic_id IS NOT NULL;
    CREATE INDEX idx_flags_flagger_id ON flags(flagger_id);
    CREATE INDEX idx_flags_status ON flags(status);
    CREATE INDEX idx_flags_reviewed_by ON flags(reviewed_by) WHERE reviewed_by IS NOT NULL;
    CREATE INDEX idx_flags_created_at ON flags(created_at);
    
    CREATE INDEX idx_sanctions_user_id ON sanctions(user_id);
    CREATE INDEX idx_sanctions_type ON sanctions(type);
    CREATE INDEX idx_sanctions_applied_by ON sanctions(applied_by);
    CREATE INDEX idx_sanctions_active ON sanctions(is_active) WHERE is_active = true;
    CREATE INDEX idx_sanctions_expires_at ON sanctions(expires_at) WHERE expires_at IS NOT NULL;
    
    CREATE INDEX idx_private_messages_sender_id ON private_messages(sender_id);
    CREATE INDEX idx_private_messages_recipient_id ON private_messages(recipient_id);
    CREATE INDEX idx_private_messages_status ON private_messages(status);
    CREATE INDEX idx_private_messages_sent_at ON private_messages(sent_at);
    
    CREATE INDEX idx_tags_name ON tags(name);
    
    CREATE INDEX idx_topic_tags_topic_id ON topic_tags(topic_id);
    CREATE INDEX idx_topic_tags_tag_id ON topic_tags(tag_id);
    CREATE INDEX idx_topic_tags_assigned_by ON topic_tags(assigned_by);
    
    CREATE INDEX idx_badges_name ON badges(name);
    
    CREATE INDEX idx_user_badges_user_id ON user_badges(user_id);
    CREATE INDEX idx_user_badges_badge_id ON user_badges(badge_id);
    CREATE INDEX idx_user_badges_awarded_at ON user_badges(awarded_at);
    CREATE INDEX idx_user_badges_post_id ON user_badges(awarded_for_post_id) WHERE awarded_for_post_id IS NOT NULL;
    
    CREATE INDEX idx_moderation_events_user_events ON moderation_events(user_id, created_at DESC);
    CREATE INDEX idx_moderation_events_content ON moderation_events(content_type, content_id);
    CREATE INDEX idx_moderation_events_event_type ON moderation_events(event_type);
    CREATE INDEX idx_moderation_events_outcome_content ON moderation_events(outcome, content_type);
    
    CREATE INDEX idx_translations_content ON translations(content_type, content_id);
    CREATE INDEX idx_translations_language ON translations(language_code);
    """,
    """
    DROP TABLE IF EXISTS translations;
    DROP TABLE IF EXISTS moderation_events;
    DROP TABLE IF EXISTS user_badges;
    DROP TABLE IF EXISTS badges;
    DROP TABLE IF EXISTS topic_tags;
    DROP TABLE IF EXISTS tags;
    DROP TABLE IF EXISTS private_messages;
    DROP TABLE IF EXISTS sanctions;
    DROP TABLE IF EXISTS flags;
    DROP TABLE IF EXISTS appeals;
    """
)
```

### RBAC System Migration

```python
# migrations/0005.add-rbac-system.py
from yoyo import step

step(
    """
    -- Roles table (static roles)
    CREATE TABLE roles (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(50) NOT NULL UNIQUE,
        description TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Permissions table (granular capabilities)
    CREATE TABLE permissions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(100) NOT NULL UNIQUE,
        description TEXT,
        is_dynamic BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Role permissions (static assignments)
    CREATE TABLE role_permissions (
        role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
        permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        PRIMARY KEY (role_id, permission_id)
    );
    
    -- User permissions (dynamic overrides and loyalty-based grants)
    CREATE TABLE user_permissions (
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
        granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        expires_at TIMESTAMP WITH TIME ZONE,
        granted_by_event VARCHAR(50),
        granted_by_user_id UUID REFERENCES users(id),
        is_active BOOLEAN DEFAULT TRUE,
        
        PRIMARY KEY (user_id, permission_id)
    );
    
    -- Create indexes for RBAC tables
    CREATE INDEX idx_roles_name ON roles(name);
    
    CREATE INDEX idx_permissions_name ON permissions(name);
    CREATE INDEX idx_permissions_dynamic ON permissions(is_dynamic) WHERE is_dynamic = true;
    
    CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
    CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);
    
    CREATE INDEX idx_user_permissions_user_id ON user_permissions(user_id);
    CREATE INDEX idx_user_permissions_permission_id ON user_permissions(permission_id);
    CREATE INDEX idx_user_permissions_active ON user_permissions(is_active) WHERE is_active = true;
    CREATE INDEX idx_user_permissions_expires ON user_permissions(expires_at) WHERE expires_at IS NOT NULL;
    CREATE INDEX idx_user_permissions_event ON user_permissions(granted_by_event);
    """,
    """
    DROP TABLE IF EXISTS user_permissions;
    DROP TABLE IF EXISTS role_permissions;
    DROP TABLE IF EXISTS permissions;
    DROP TABLE IF EXISTS roles;
    """
)
```

---

**Related Documentation:**
- [Database Schema](./05-database-schema.md) - Core database structure  
- [Database Access Layer](./18-database-access-layer.md) - Repository patterns
- [Deployment Infrastructure](./01-deployment-infrastructure.md) - Environment configuration
            applied_migrations = await self._get_applied_migrations(conn)
            migration_files = self._get_migration_files()
            
            status = {
                'current_version': max(applied_migrations.keys()) if applied_migrations else 0,
                'latest_version': max(v for v, _, _ in migration_files) if migration_files else 0,
                'pending_count': 0,
                'applied_migrations': [],
                'pending_migrations': []
            }
            
            for version, name, file_path in migration_files:
                if version in applied_migrations:
                    status['applied_migrations'].append({
                        'version': version,
                        'name': name,
                        'applied_at': applied_migrations[version]['applied_at'],
                        'execution_time_ms': applied_migrations[version]['execution_time_ms']
                    })
                else:
                    status['pending_migrations'].append({
                        'version': version,
                        'name': name
                    })
                    status['pending_count'] += 1
            
            return status
        
        finally:
            await conn.close()
    
    async def seed(self, environment: str = "development") -> Dict:
        """Run seed data for environment"""
        seed_dir = self.seeds_dir / environment
        if not seed_dir.exists():
            return {'error': f'Seed directory not found: {seed_dir}'}
        
        conn = await asyncpg.connect(self.database_url)
        results = {
            'executed': [],
            'errors': []
        }
        
        try:
            # Execute seed files in alphabetical order
            for seed_file in sorted(seed_dir.glob("*.sql")):
                try:
                    with open(seed_file, 'r') as f:
                        seed_sql = f.read()
                    
                    await conn.execute(seed_sql)
                    logger.info(f"Executed seed file: {seed_file.name}")
                    results['executed'].append(seed_file.name)
                    
                except Exception as e:
                    logger.error(f"Failed to execute seed file {seed_file.name}: {e}")
                    results['errors'].append({
                        'file': seed_file.name,
                        'error': str(e)
                    })
        
        finally:
            await conn.close()
        
        return results
```

## CLI Interface

```python
# migrations/cli.py
import asyncio
import os
from typing import Optional
import typer
from migration_runner import MigrationRunner

app = typer.Typer(help="Database migration CLI")

def get_runner() -> MigrationRunner:
    """Get migration runner instance"""
    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        typer.echo("Error: DATABASE_URL environment variable is required", err=True)
        raise typer.Exit(1)
    return MigrationRunner(database_url)

@app.command()
def migrate(
    target: Optional[int] = typer.Option(None, help="Target migration version"),
    dry_run: bool = typer.Option(False, "--dry-run", help="Show what would be applied without executing")
):
    """Apply pending migrations"""
    async def run():
        runner = get_runner()
        results = await runner.migrate(target, dry_run)
        
        if results['applied']:
            typer.echo(f"Applied {len(results['applied'])} migrations:")
            for migration in results['applied']:
                status = " (DRY RUN)" if migration.get('dry_run') else ""
                typer.echo(f"  ✓ {migration['version']}: {migration['name']}{status}")
        
        if results['skipped']:
            typer.echo(f"Skipped {len(results['skipped'])} migrations:")
            for migration in results['skipped']:
                typer.echo(f"  - {migration['version']}: {migration['name']} ({migration['reason']})")
        
        if results['errors']:
            typer.echo(f"Failed {len(results['errors'])} migrations:", err=True)
            for migration in results['errors']:
                typer.echo(f"  ✗ {migration['version']}: {migration['name']} - {migration['error']}", err=True)
    
    asyncio.run(run())

@app.command()
def rollback(
    target_version: int = typer.Argument(..., help="Target version to rollback to"),
    dry_run: bool = typer.Option(False, "--dry-run", help="Show what would be rolled back without executing")
):
    """Rollback migrations to target version"""
    async def run():
        runner = get_runner()
        results = await runner.rollback(target_version, dry_run)
        
        if results['rolled_back']:
            typer.echo(f"Rolled back {len(results['rolled_back'])} migrations:")
            for migration in results['rolled_back']:
                status = " (DRY RUN)" if migration.get('dry_run') else ""
                typer.echo(f"  ✓ {migration['version']}: {migration['name']}{status}")
        
        if results['errors']:
            typer.echo(f"Failed to rollback {len(results['errors'])} migrations:", err=True)
            for migration in results['errors']:
                typer.echo(f"  ✗ {migration['version']}: {migration['name']} - {migration['error']}", err=True)
    
    asyncio.run(run())

@app.command()
def status():
    """Show migration status"""
    async def run():
        runner = get_runner()
        status_info = await runner.status()
        
        typer.echo(f"Current version: {status_info['current_version']}")
        typer.echo(f"Latest version: {status_info['latest_version']}")
        typer.echo(f"Pending migrations: {status_info['pending_count']}")
        
        if status_info['pending_migrations']:
            typer.echo("\nPending:")
            for migration in status_info['pending_migrations']:
                typer.echo(f"  {migration['version']}: {migration['name']}")
        
        if status_info['applied_migrations']:
            typer.echo(f"\nApplied ({len(status_info['applied_migrations'])}):")
            for migration in status_info['applied_migrations'][-5:]:  # Show last 5
                typer.echo(f"  {migration['version']}: {migration['name']} ({migration['execution_time_ms']}ms)")
    
    asyncio.run(run())

@app.command()
def seed(
    environment: str = typer.Option("development", help="Environment to seed")
):
    """Run seed data"""
    async def run():
        runner = get_runner()
        results = await runner.seed(environment)
        
        if 'error' in results:
            typer.echo(f"Error: {results['error']}", err=True)
            return
        
        if results['executed']:
            typer.echo(f"Executed {len(results['executed'])} seed files:")
            for file_name in results['executed']:
                typer.echo(f"  ✓ {file_name}")
        
        if results['errors']:
            typer.echo(f"Failed {len(results['errors'])} seed files:", err=True)
            for error in results['errors']:
                typer.echo(f"  ✗ {error['file']} - {error['error']}", err=True)
    
    asyncio.run(run())

if __name__ == '__main__':
    app()
```

## Example Migration Files

### Initial Schema Migration

```sql
-- migrations/versions/001_initial_schema.sql
-- Create core tables for The Robot Overlord

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";
CREATE EXTENSION IF NOT EXISTS "pgvector";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    google_id VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('citizen', 'moderator', 'admin', 'superadmin')),
    loyalty_score INTEGER DEFAULT 0,
    is_banned BOOLEAN DEFAULT FALSE,
    is_sanctioned BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Topics table
CREATE TABLE topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    author_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_by_overlord BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending_approval', 'approved', 'rejected')),
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Posts table
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    parent_post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'approved', 'calibrated', 'rejected')),
    overlord_feedback TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes
CREATE INDEX idx_users_loyalty_score ON users(loyalty_score DESC) WHERE loyalty_score > 0;
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_topics_status ON topics(status);
CREATE INDEX idx_posts_topic_submission ON posts(topic_id, submitted_at);
CREATE INDEX idx_posts_status ON posts(status);
```

### Rollback for Initial Schema

```sql
-- migrations/rollbacks/001_initial_schema_rollback.sql
-- Rollback initial schema

DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS topics;
DROP TABLE IF EXISTS users;

-- Note: Extensions are not dropped as they might be used by other applications
```

## Usage Examples

```bash
# Check migration status
python migrations/cli.py status

# Apply all pending migrations
python migrations/cli.py migrate

# Apply migrations up to version 5
python migrations/cli.py migrate --target 5

# Dry run to see what would be applied
python migrations/cli.py migrate --dry-run

# Rollback to version 3
python migrations/cli.py rollback 3

# Seed development data
python migrations/cli.py seed --environment development

# Seed production data
python migrations/cli.py seed --environment production
```

## Integration with Application

```python
# app/database/migrations.py
from migrations.migration_runner import MigrationRunner
import os

async def ensure_migrations():
    """Ensure database is up to date on application startup"""
    database_url = os.getenv('DATABASE_URL')
    runner = MigrationRunner(database_url)
    
    # Check if migrations are needed
    status = await runner.status()
    
    if status['pending_count'] > 0:
        print(f"Applying {status['pending_count']} pending migrations...")
        results = await runner.migrate()
        
        if results['errors']:
            raise Exception(f"Migration failed: {results['errors']}")
        
        print(f"Successfully applied {len(results['applied'])} migrations")
    else:
        print("Database is up to date")
```

---

**Related Documentation:**
- [Database Schema](./05-database-schema.md) - Core database structure
- [Database Access Layer](./18-database-access-layer.md) - Repository patterns
- [Deployment Infrastructure](./01-deployment-infrastructure.md) - Environment configuration
