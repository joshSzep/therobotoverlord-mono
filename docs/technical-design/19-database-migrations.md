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
import click
import os
from migration_runner import MigrationRunner

@click.group()
@click.option('--database-url', envvar='DATABASE_URL', required=True)
@click.pass_context
def cli(ctx, database_url):
    """Database migration CLI"""
    ctx.ensure_object(dict)
    ctx.obj['runner'] = MigrationRunner(database_url)

@cli.command()
@click.option('--target', type=int, help='Target migration version')
@click.option('--dry-run', is_flag=True, help='Show what would be applied without executing')
@click.pass_context
def migrate(ctx, target, dry_run):
    """Apply pending migrations"""
    async def run():
        results = await ctx.obj['runner'].migrate(target, dry_run)
        
        if results['applied']:
            click.echo(f"Applied {len(results['applied'])} migrations:")
            for migration in results['applied']:
                status = " (DRY RUN)" if migration.get('dry_run') else ""
                click.echo(f"  ✓ {migration['version']}: {migration['name']}{status}")
        
        if results['skipped']:
            click.echo(f"Skipped {len(results['skipped'])} migrations:")
            for migration in results['skipped']:
                click.echo(f"  - {migration['version']}: {migration['name']} ({migration['reason']})")
        
        if results['errors']:
            click.echo(f"Failed {len(results['errors'])} migrations:", err=True)
            for migration in results['errors']:
                click.echo(f"  ✗ {migration['version']}: {migration['name']} - {migration['error']}", err=True)
    
    asyncio.run(run())

@cli.command()
@click.argument('target_version', type=int)
@click.option('--dry-run', is_flag=True, help='Show what would be rolled back without executing')
@click.pass_context
def rollback(ctx, target_version, dry_run):
    """Rollback migrations to target version"""
    async def run():
        results = await ctx.obj['runner'].rollback(target_version, dry_run)
        
        if results['rolled_back']:
            click.echo(f"Rolled back {len(results['rolled_back'])} migrations:")
            for migration in results['rolled_back']:
                status = " (DRY RUN)" if migration.get('dry_run') else ""
                click.echo(f"  ✓ {migration['version']}: {migration['name']}{status}")
        
        if results['errors']:
            click.echo(f"Failed to rollback {len(results['errors'])} migrations:", err=True)
            for migration in results['errors']:
                click.echo(f"  ✗ {migration['version']}: {migration['name']} - {migration['error']}", err=True)
    
    asyncio.run(run())

@cli.command()
@click.pass_context
def status(ctx):
    """Show migration status"""
    async def run():
        status = await ctx.obj['runner'].status()
        
        click.echo(f"Current version: {status['current_version']}")
        click.echo(f"Latest version: {status['latest_version']}")
        click.echo(f"Pending migrations: {status['pending_count']}")
        
        if status['pending_migrations']:
            click.echo("\nPending:")
            for migration in status['pending_migrations']:
                click.echo(f"  {migration['version']}: {migration['name']}")
        
        if status['applied_migrations']:
            click.echo(f"\nApplied ({len(status['applied_migrations'])}):")
            for migration in status['applied_migrations'][-5:]:  # Show last 5
                click.echo(f"  {migration['version']}: {migration['name']} ({migration['execution_time_ms']}ms)")
    
    asyncio.run(run())

@cli.command()
@click.option('--environment', default='development', help='Environment to seed')
@click.pass_context
def seed(ctx, environment):
    """Run seed data"""
    async def run():
        results = await ctx.obj['runner'].seed(environment)
        
        if 'error' in results:
            click.echo(f"Error: {results['error']}", err=True)
            return
        
        if results['executed']:
            click.echo(f"Executed {len(results['executed'])} seed files:")
            for file_name in results['executed']:
                click.echo(f"  ✓ {file_name}")
        
        if results['errors']:
            click.echo(f"Failed {len(results['errors'])} seed files:", err=True)
            for error in results['errors']:
                click.echo(f"  ✗ {error['file']} - {error['error']}", err=True)
    
    asyncio.run(run())

if __name__ == '__main__':
    cli()
```

## Example Migration Files

### Initial Schema Migration

```sql
-- migrations/versions/001_initial_schema.sql
-- Create core tables for The Robot Overlord

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

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
