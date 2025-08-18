# The Robot Overlord - Documentation

## Overview

Complete documentation for **The Robot Overlord** - a satirical, AI-moderated debate arena where users argue inside a fictional authoritarian state with 1960s Soviet propaganda aesthetics.

## Documentation Structure

### [Business Requirements](./business-requirements/README.md)
Complete product specifications, user experience flows, and business logic.

**Key Documents:**
- [Product Vision & Core Ideas](./business-requirements/01-product-vision.md)
- [Roles & Capabilities](./business-requirements/02-roles-capabilities.md)
- [Look & Feel](./business-requirements/03-look-feel.md)
- [Posts & Moderation](./business-requirements/07-posts-moderation.md)
- [Overlord Behavior](./business-requirements/09-overlord-behavior.md)
- [Queue Visualization](./business-requirements/16-queue-visualization.md)

### [Technical Design](./technical-design/README.md)
Implementation specifications, architecture decisions, and system design.

**Key Documents:**
- [Deployment & Infrastructure](./technical-design/01-deployment-infrastructure.md)
- [Authentication & Authorization](./technical-design/03-authentication.md)
- [Database Schema](./technical-design/05-database-schema.md)
- [Real-time Streaming](./technical-design/06-realtime-streaming.md)
- [AI/LLM Integration](./technical-design/07-ai-llm-integration.md)
- [Queue Management](./technical-design/12-queue-management.md)

## Quick Navigation

### By Feature
- **Authentication**: [Business](./business-requirements/05-auth-onboarding.md) | [Technical](./technical-design/03-authentication.md)
- **Content Moderation**: [Business](./business-requirements/07-posts-moderation.md) | [Technical](./technical-design/07-ai-llm-integration.md)
- **Queue System**: [Business](./business-requirements/16-queue-visualization.md) | [Technical](./technical-design/12-queue-management.md)
- **User Roles**: [Business](./business-requirements/02-roles-capabilities.md) | [Technical](./technical-design/08-rbac-permissions.md)
- **Loyalty System**: [Business](./business-requirements/10-gamification-reputation.md) | [Technical](./technical-design/09-loyalty-scoring.md)
- **Overlord Behavior**: [Business](./business-requirements/09-overlord-behavior.md) | [Technical](./technical-design/07-ai-llm-integration.md)

### By Implementation Phase
- **Phase 1 - Core Forum**: [Core Forum Implementation](./business-requirements/19-success-delivery.md)
- **Phase 2 - Moderation**: [Posts & Moderation](./business-requirements/07-posts-moderation.md)
- **Phase 3 - Reputation**: [Gamification & Reputation](./business-requirements/10-gamification-reputation.md)
- **Phase 4 - Governance**: [Appeals & Reporting](./business-requirements/12-appeals-reporting.md)

## Document Status

All documentation reflects the current comprehensive specification. Both business and technical documents are fully modularized with cross-references for easy navigation.
