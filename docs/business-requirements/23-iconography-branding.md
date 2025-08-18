# Iconography & Branding Assets

## Overview

Comprehensive specification for iconography system and branding assets that reinforce The Robot Overlord's authoritarian aesthetic while maintaining usability and accessibility.

## Brand Identity System

### Logo Hierarchy
- **Primary Logo**: Full wordmark with robot emblem
- **Secondary Logo**: Wordmark only (for constrained spaces)
- **Icon Mark**: Robot emblem only (favicons, app icons)
- **Monogram**: "RO" lettermark (ultra-constrained spaces)

### Logo Construction
- **Proportions**: 3:1 ratio (wordmark to emblem)
- **Clear Space**: Minimum 2x the height of the "R" in all directions
- **Minimum Size**: 120px width for primary logo, 32px for icon mark
- **Typography**: Custom geometric sans-serif with sharp, angular cuts

### Brand Colors - Extended Palette (Dark Mode)

#### Primary Colors
- **Overlord Red**: `#FF4757` - Primary brand color, authority, power (brightened for dark backgrounds)
- **Authority Red**: `#FF3742` - Brighter variant, emphasis, hierarchy
- **Deep Black**: `#0C0C0C` - Primary dark background
- **Surface Dark**: `#1A1A1A` - Secondary dark surfaces, cards, containers

#### Secondary Colors
- **Light Text**: `#E8E8E8` - Primary text, high contrast on dark
- **Muted Light**: `#B0B0B0` - Secondary text, borders, subtle elements
- **Steel Dark**: `#2A2A2A` - Intermediate dark for depth and layering

#### Status Colors
- **Approved Green**: `#4ECDC4` - Success, approval, positive actions (cyan-green for dark)
- **Warning Amber**: `#FFD93D` - Caution, pending review, attention needed (bright yellow)
- **Rejected Red**: `#FF6B6B` - Errors, rejection, negative actions (coral red)
- **Processing Blue**: `#74B9FF` - In-progress, loading, system activity (bright blue)

## Icon Design Principles

### Visual Style
- **Geometric Construction**: Based on 24x24 grid system
- **Line Weight**: 1.5px standard stroke width
- **Corner Radius**: Sharp corners preferred, minimal rounding (1px max)
- **Fill vs. Stroke**: Prefer outlined icons with optional filled variants
- **Optical Alignment**: Visually centered, not mathematically centered

### Icon Categories

#### Navigation Icons (24x24px)
```
icon-home.svg          - House outline with sharp roof angles
icon-topics.svg        - Stack of documents with corner fold
icon-profile.svg       - Geometric head silhouette
icon-chat.svg          - Speech bubble with angular tail
icon-search.svg        - Magnifying glass with square handle
icon-notifications.svg - Bell with angular clapper
icon-settings.svg      - Gear with sharp teeth
icon-logout.svg        - Door with exit arrow
```

#### Content Action Icons (20x20px)
```
icon-create.svg        - Plus sign in square frame
icon-edit.svg          - Pencil with angular tip
icon-delete.svg        - Trash can with sharp edges
icon-share.svg         - Arrow branching into three directions
icon-bookmark.svg      - Ribbon bookmark with sharp fold
icon-like.svg          - Thumbs up with geometric thumb
icon-dislike.svg       - Thumbs down with geometric thumb
icon-flag.svg          - Triangular flag on pole
```

#### System Status Icons (16x16px)
```
icon-success.svg       - Checkmark in circle
icon-warning.svg       - Exclamation in triangle
icon-error.svg         - X in circle
icon-info.svg          - Lowercase 'i' in circle
icon-loading.svg       - Circular arrow (rotation animation)
icon-offline.svg       - Cloud with diagonal slash
icon-sync.svg          - Two curved arrows forming circle
```

#### Queue & Moderation Icons (24x24px)
```
icon-queue-topic.svg   - Government building with columns
icon-queue-post.svg    - Document with magnifying glass
icon-queue-message.svg - Envelope with lock overlay
icon-approve.svg       - Shield with checkmark
icon-reject.svg        - Shield with X
icon-calibrate.svg     - Dial/gauge with needle and glow
icon-appeal.svg        - Scales of justice with glow
icon-sanction.svg      - Gavel with sharp handle and glow
```

## Overlord Character Assets

### Robot Avatar Variations
- **Primary Avatar**: Front-facing robot head with geometric features and subtle glow
- **Profile Avatar**: Side view for smaller spaces with glowing accents
- **Thinking Avatar**: With glowing thought bubble or processing indicator
- **Speaking Avatar**: With glowing speech lines or sound waves
- **Alert Avatar**: With pulsing warning indicators or glowing red eyes

### Overlord Expressions
- **Neutral**: Standard authoritative expression with subtle Light Text glow
- **Pleased**: Slight upward angle to optical sensors with Approved Green glow
- **Displeased**: Downward angle, Overlord Red warning lights with enhanced glow
- **Processing**: Animated glowing scanning lines across face in Processing Blue
- **Offline**: Dimmed features, Muted Light coloring with reduced glow

### Character Poses
- **Commanding**: Raised arm in authoritative gesture
- **Observing**: Arms crossed, watchful stance
- **Judging**: Pointing finger, scales in other hand
- **Welcoming**: Open arms (for onboarding)
- **Blocking**: Stop gesture for access denied

## Badge & Rank System

### Loyalty Rank Badges
```
badge-citizen.svg         - Basic hexagon, Muted Light with subtle glow
badge-loyal-worker.svg    - Hexagon with star, Overlord Red with glow
badge-exemplary.svg       - Hexagon with crown, Authority Red with enhanced glow
badge-committee.svg       - Special geometric shape with multi-color glow for top tier
```

### Role Badges
```
badge-moderator.svg       - Shield with checkmark, Processing Blue glow
badge-admin.svg          - Shield with gear, Overlord Red glow
badge-super-admin.svg    - Shield with crown, Authority Red enhanced glow
badge-overlord.svg       - Unique robot emblem with signature red glow
```

### Achievement Badges
```
badge-first-post.svg     - Quill pen in circle
badge-helpful.svg        - Helping hand icon
badge-popular.svg        - Multiple thumbs up
badge-veteran.svg        - Clock with years indicator
badge-contributor.svg    - Plus sign with radiating lines
```

## Texture & Pattern Assets

### Background Textures
- **Paper Texture**: Subtle off-white paper grain for backgrounds
- **Propaganda Texture**: Aged poster texture with slight wear
- **Metal Texture**: Brushed steel for Overlord UI elements
- **Noise Texture**: Fine grain for depth without distraction

### Decorative Patterns
- **Geometric Border**: Angular frames for important content
- **Stripe Pattern**: Diagonal warning stripes for alerts
- **Grid Pattern**: Subtle grid overlay for technical sections
- **Propaganda Stars**: Five-pointed stars for emphasis elements

## Animation Specifications

### Micro-Interactions
- **Button Hover**: 150ms ease-out scale (1.02x) + glow enhancement
- **Icon Hover**: 200ms ease-in-out rotation (5 degrees) + glow appearance
- **Card Hover**: 300ms ease-out glow shadow expansion
- **Input Focus**: 200ms ease-out border color + glowing shadow

### Loading Animations
- **Spinner**: 1.5s linear infinite rotation with pulsing glow
- **Progress Bar**: 2s ease-in-out fill animation with trailing glow
- **Pulse**: 2s ease-in-out glow intensity (30% to 100%)
- **Typing Dots**: 1.5s staggered bounce with synchronized glow pulse

### Overlord Animations
- **Eye Scan**: Horizontal glowing scanning line across avatar
- **Processing**: Rotating gear overlay with pulsing glow on avatar
- **Speaking**: Subtle mouth movement with glowing sound wave pulses
- **Alert**: Overlord Red glow flash with 0.5s fade-out and pulse

## File Naming Conventions

### Structure
```
[category]-[name]-[variant].[extension]

Examples:
icon-home-outline.svg
icon-home-filled.svg
logo-primary-light.svg
badge-citizen-active.svg
texture-paper-subtle.svg
```

### Categories
- `icon-` - All iconography
- `logo-` - Brand marks and logos
- `badge-` - Rank and achievement badges
- `avatar-` - Overlord character assets
- `texture-` - Background textures and patterns
- `illustration-` - Larger graphic elements

### Variants
- `-outline` - Stroke-only version
- `-filled` - Solid fill version
- `-light` - Light theme variant
- `-dark` - Dark theme variant
- `-active` - Active/selected state
- `-disabled` - Disabled state
- `-small` - Smaller size variant
- `-large` - Larger size variant

## Implementation Guidelines

### SVG Optimization
- Remove unnecessary metadata and comments
- Combine paths where possible
- Use consistent decimal precision (2 places)
- Include viewBox for proper scaling
- Add semantic title and description elements

### Color Implementation
- Use CSS custom properties for dark theme colors
- Implement `currentColor` for icons that inherit Light Text color
- Provide enhanced glow effects for dark mode visibility
- Native dark mode as primary theme (no light mode toggle needed)
- Glow effects implemented via CSS box-shadow and filter properties

### Responsive Scaling
- Design icons at 24x24 base size
- Ensure clarity at 16x16 minimum size
- Test legibility at 48x48+ for touch interfaces
- Maintain visual weight across all sizes

---

**Related Documentation:**
- [Visual Assets Specification](./21-visual-assets-specification.md) - Complete asset inventory
- [UI Component Visuals](./22-ui-component-visuals.md) - Component-specific requirements
- [Look & Feel](./03-look-feel.md) - Design principles and aesthetic guidelines
