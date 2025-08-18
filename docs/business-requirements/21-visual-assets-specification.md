# Visual Assets Specification

## Overview

Complete specification of all visual assets required for The Robot Overlord platform, prioritizing SVG format for scalability and maintaining the 1960s Soviet propaganda aesthetic.

## Brand Identity Assets

### Primary Logo
- **File**: `logo-primary.svg`
- **Description**: Main Robot Overlord logo with authoritarian styling
- **Usage**: Header, authentication pages, official communications
- **Variants**: 
  - `logo-primary-light.svg` (for dark backgrounds)
  - `logo-primary-dark.svg` (for light backgrounds)
  - `logo-primary-monochrome.svg` (single color version)

### Secondary Marks
- **File**: `logo-icon.svg`
- **Description**: Simplified icon version for favicons and small spaces
- **Size**: 32x32, 64x64, 128x128 variants
- **Usage**: Browser tabs, mobile app icons, social media

### Overlord Avatar
- **File**: `overlord-avatar.svg`
- **Description**: Stylized robot head/face representing the AI Overlord
- **Usage**: Chat interface, moderation messages, system notifications
- **Style**: Geometric, authoritarian, glowing elements for dark theme
- **Colors**: Light Text (`#E8E8E8`) with Overlord Red (`#FF4757`) accents

## Iconography System

### Navigation Icons
- **File**: `icon-home.svg` - Home/dashboard
- **File**: `icon-topics.svg` - Topics listing
- **File**: `icon-profile.svg` - User profile
- **File**: `icon-chat.svg` - Overlord chat
- **File**: `icon-search.svg` - Search functionality
- **File**: `icon-notifications.svg` - Notifications bell
- **File**: `icon-settings.svg` - User settings

### Queue System Icons
- **File**: `icon-queue-topic.svg` - Topic Approval Bureau (🏛️ replacement)
- **File**: `icon-queue-post.svg` - Debate Moderation Office (📝 replacement)
- **File**: `icon-queue-message.svg` - Private Communication Review (🔒 replacement)
- **File**: `icon-queue-position.svg` - Queue position indicator
- **File**: `icon-queue-time.svg` - Estimated wait time

### Content Action Icons
- **File**: `icon-post.svg` - Submit statement
- **File**: `icon-flag.svg` - Report treason
- **File**: `icon-appeal.svg` - Petition the Central Committee
- **File**: `icon-approve.svg` - Approved content
- **File**: `icon-reject.svg` - Rejected content
- **File**: `icon-calibrate.svg` - Content requiring calibration

### Status & Badge Icons
- **File**: `icon-loyalty-high.svg` - High loyalty score indicator
- **File**: `icon-loyalty-medium.svg` - Medium loyalty score indicator
- **File**: `icon-loyalty-low.svg` - Low loyalty score indicator
- **File**: `icon-rank-citizen.svg` - Citizen rank badge
- **File**: `icon-rank-loyal.svg` - Loyal Worker rank badge
- **File**: `icon-rank-exemplary.svg` - Exemplary Citizen rank badge
- **File**: `icon-moderator.svg` - Moderator badge
- **File**: `icon-admin.svg` - Admin badge

### System Status Icons
- **File**: `icon-online.svg` - User online status
- **File**: `icon-offline.svg` - User offline status
- **File**: `icon-processing.svg` - Content being processed
- **File**: `icon-error.svg` - Error state
- **File**: `icon-warning.svg` - Warning state
- **File**: `icon-success.svg` - Success state

## UI Component Graphics

### Queue Status Cards
- **File**: `card-background-topic.svg` - Topic Approval Bureau card background
- **File**: `card-background-post.svg` - Debate Moderation Office card background
- **File**: `card-background-message.svg` - Private Communication Review card background
- **File**: `card-border-active.svg` - Active queue item border
- **File**: `card-border-processing.svg` - Processing queue item border

### Overlord Message Containers
- **File**: `message-container-overlord.svg` - Distinctive container for Overlord messages
- **File**: `message-container-system.svg` - System notification container
- **File**: `message-container-sanction.svg` - Sanction notice container
- **File**: `speech-bubble-overlord.svg` - Chat message bubble for Overlord

### Profile Elements
- **File**: `graveyard-header.svg` - Header graphic for rejected posts section
- **File**: `profile-banner-citizen.svg` - Default citizen profile banner
- **File**: `profile-banner-moderator.svg` - Moderator profile banner
- **File**: `profile-banner-admin.svg` - Admin profile banner

## Illustrations & Graphics

### Authentication Flow
- **File**: `illustration-welcome.svg` - Welcome screen illustration
- **File**: `illustration-onboarding-1.svg` - Onboarding step 1: Platform introduction
- **File**: `illustration-onboarding-2.svg` - Onboarding step 2: Moderation explanation
- **File**: `illustration-onboarding-3.svg` - Onboarding step 3: Appeals process

### Empty States
- **File**: `empty-state-topics.svg` - No topics available
- **File**: `empty-state-posts.svg` - No posts in topic
- **File**: `empty-state-messages.svg` - No private messages
- **File**: `empty-state-notifications.svg` - No notifications
- **File**: `empty-state-graveyard.svg` - No rejected posts
- **File**: `empty-state-search.svg` - No search results

### Error States
- **File**: `error-404.svg` - Page not found
- **File**: `error-403.svg` - Access denied
- **File**: `error-500.svg` - Server error
- **File**: `error-network.svg` - Network connection error

### Loading States
- **File**: `loading-spinner.svg` - General loading indicator
- **File**: `loading-queue.svg` - Queue processing animation
- **File**: `loading-overlord.svg` - Overlord thinking animation

## Background Elements

### Texture Overlays
- **File**: `texture-dark-surface.svg` - Dark surface texture overlay
- **File**: `texture-propaganda-dark.svg` - Dark propaganda poster texture
- **File**: `texture-noise-dark.svg` - Dark noise texture for depth
- **File**: `texture-metal-dark.svg` - Dark brushed metal texture

### Decorative Elements
- **File**: `border-propaganda-dark.svg` - Dark propaganda-style decorative borders
- **File**: `divider-authoritarian-dark.svg` - Dark section dividers with glowing accents
- **File**: `pattern-geometric-dark.svg` - Dark geometric background patterns
- **File**: `glow-accent.svg` - Subtle glow effects for dark theme highlights

## Color Specifications

### Primary Palette (Dark Mode)
- **Overlord Red**: `#FF4757` - Primary brand color, brightened for dark backgrounds
- **Authority Red**: `#FF3742` - Brighter variant for emphasis
- **Deep Black**: `#0C0C0C` - Primary dark background
- **Surface Dark**: `#1A1A1A` - Secondary dark surfaces
- **Light Text**: `#E8E8E8` - Primary light text
- **Muted Light**: `#B0B0B0` - Secondary light text and borders

### Status Colors (Dark Mode)
- **Approved Green**: `#4ECDC4` - Success states, cyan-green for dark backgrounds
- **Warning Amber**: `#FFD93D` - Caution states, bright yellow
- **Rejected Red**: `#FF6B6B` - Error/rejection states, coral red
- **Processing Blue**: `#74B9FF` - In-progress states, bright blue

## Technical Specifications

### SVG Requirements
- **Viewbox**: Consistent 24x24 for icons, scalable for larger graphics
- **Stroke Width**: 1.5px standard for line icons
- **Fill Rules**: Even-odd for complex shapes
- **Optimization**: Minified SVG code, removed unnecessary metadata
- **Accessibility**: Include `<title>` and `<desc>` elements for screen readers

### File Organization
```
/assets/
  /icons/
    /navigation/
    /queue/
    /content/
    /status/
    /system/
  /illustrations/
    /auth/
    /empty-states/
    /errors/
    /loading/
  /ui-components/
    /cards/
    /containers/
    /profiles/
  /brand/
    /logos/
    /avatars/
  /backgrounds/
    /textures/
    /patterns/
```

### Responsive Considerations
- **Mobile**: Icons scale to minimum 44px touch targets
- **Tablet**: Medium density displays, 1.5x scaling
- **Desktop**: High density displays, 2x scaling support
- **Print**: Vector format ensures crisp printing at any size

## Implementation Notes

### CSS Integration
- Use CSS custom properties for color theming
- Implement dark mode variants where appropriate
- Ensure proper contrast ratios (WCAG AA compliance)

### Performance
- Lazy load non-critical illustrations
- Use SVG sprites for frequently used icons
- Implement proper caching headers

### Accessibility
- All icons include descriptive alt text
- Color is not the only means of conveying information
- High contrast mode compatibility

---

**Related Documentation:**
- [Look & Feel](./03-look-feel.md) - Design principles and aesthetic guidelines
- [Queue Visualization](./16-queue-visualization.md) - Queue-specific visual requirements
- [Technical: Frontend Design](../technical-design/02-frontend-design.md) - Implementation guidelines
