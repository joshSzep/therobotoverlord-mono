# Technical Design Documentation

## Overview

This directory contains the complete technical design for **The Robot Overlord** platform implementation.

## Document Structure

### Infrastructure & Deployment
- [**Deployment & Infrastructure**](./01-deployment-infrastructure.md) - Hosting, environments, and service architecture
- [**Frontend Design Requirements**](./02-frontend-design.md) - UI/UX implementation guidelines
- [**Authentication & Authorization**](./03-authentication.md) - JWT-based auth system and security

### Core Architecture
- [**API Design**](./04-api-design.md) - REST API structure and response formats
- [**Database Schema**](./05-database-schema.md) - Complete PostgreSQL schema design
- [**Real-time Streaming**](./06-realtime-streaming.md) - WebSocket implementation for live updates

### AI & Advanced Features
- [**AI/LLM Integration**](./07-ai-llm-integration.md) - PydanticAI and Claude integration
- [**RBAC & Permissions**](./08-rbac-permissions.md) - Role-based access control system
- [**Loyalty Scoring System**](./09-loyalty-scoring.md) - Event-driven reputation calculation
- [**Multilingual System**](./10-multilingual.md) - Translation architecture and flow

### Implementation Details
- [**Background Processing**](./11-background-processing.md) - Arq worker system for async tasks
- [**Queue Management**](./12-queue-management.md) - Multi-queue orchestration logic
- [**Performance & Scaling**](./13-performance-scaling.md) - Optimization strategies
- [**Security & Compliance**](./14-security-compliance.md) - Security measures and data protection
- [**Queue Status Service**](./15-queue-status-service.md) - Simplified queue status system
- [**Token Refresh Strategy**](./16-token-refresh-strategy.md) - Activity-based authentication refresh
- [**Database Performance Optimization**](./17-database-performance-optimization.md) - Incremental updates and materialized views

## Cross-References

For business context and requirements, see [Business Requirements Documentation](../business-requirements/README.md).

## Implementation Status

All technical specifications are based on the current system design. Implementation should follow the modular structure defined in these documents.
