# UI Component Visual Requirements

## Overview

Detailed visual specifications for all user interface components in The Robot Overlord platform, maintaining the 1960s Soviet propaganda aesthetic while ensuring modern usability.

## Navigation Components

### Primary Navigation Bar
- **Background**: Deep Black (`#0C0C0C`) with subtle dark surface texture overlay
- **Typography**: Bold, condensed sans-serif in Light Text (`#E8E8E8`)
- **Logo Placement**: Left-aligned, 40px height on desktop, 32px on mobile
- **Navigation Items**: Right-aligned, 16px spacing between items
- **Active State**: Underline with Overlord Red (`#FF4757`)
- **Hover State**: Overlord Red glow effect with smooth transition

### Mobile Navigation Menu
- **Trigger**: Hamburger icon (3 horizontal lines, 2px stroke) in Light Text
- **Overlay**: Full-screen slide-in from right
- **Background**: Surface Dark (`#1A1A1A`) with 95% opacity
- **Items**: Stacked vertically, 48px touch targets in Light Text
- **Close Button**: X icon in top-right corner with Overlord Red accent

### Breadcrumb Navigation
- **Separator**: Forward slash (/) in Muted Light (`#B0B0B0`)
- **Current Page**: Light Text (`#E8E8E8`), no link styling
- **Previous Pages**: Muted Light with Overlord Red underline on hover
- **Typography**: 14px regular weight

## Content Display Components

### Topic Cards
- **Container**: Surface Dark (`#1A1A1A`) background with 1px Muted Light border
- **Header**: Overlord Red accent bar (4px height) at top with subtle glow
- **Title**: 18px bold Light Text (`#E8E8E8`)
- **Description**: 14px Muted Light (`#B0B0B0`), 2-line truncation
- **Metadata**: 12px Muted Light (author, date, post count)
- **Hover State**: Overlord Red glow shadow (0 2px 12px rgba(255,71,87,0.3))
- **Dimensions**: 320px width, variable height

### Post Cards
- **Container**: Surface Dark (`#1A1A1A`) with subtle Overlord Red border-left accent
- **Author Avatar**: 32px circular with dark border, default to user initials on dark background
- **Author Name**: 14px bold Light Text with loyalty rank badge
- **Content**: 16px line-height 1.5, Light Text (`#E8E8E8`)
- **Timestamp**: 12px Muted Light (`#B0B0B0`), relative format
- **Actions**: Like, flag, reply icons (16px) in Muted Light, Overlord Red on hover

### Queue Status Cards
- **Topic Approval Bureau**:
  - Background: Gradient from Surface Dark to Deep Black with Overlord Red glow
  - Icon: Government building silhouette (24px) in Light Text
  - Border: 2px solid Overlord Red with subtle glow
  - Status Indicator: Glowing dot (8px) - cyan/yellow/coral

- **Debate Moderation Office**:
  - Background: Surface Dark with subtle diagonal glow pattern
  - Icon: Document with checkmark (24px) in Light Text
  - Border: 1px solid Muted Light with glow accent
  - Progress Bar: Overlord Red fill on dark track with glow

- **Private Communication Review**:
  - Background: Surface Dark with lock glow watermark
  - Icon: Padlock (24px) in Light Text
  - Border: Dashed 1px Muted Light with subtle glow
  - Privacy Indicator: Shield icon with Overlord Red glow in corner

## Form Components

### Input Fields
- **Default State**: 
  - Border: 1px solid Muted Light (`#B0B0B0`)
  - Background: Surface Dark (`#1A1A1A`)
  - Padding: 12px 16px
  - Typography: 16px Light Text (`#E8E8E8`)
  - Border-radius: 2px (minimal rounding)

- **Focus State**:
  - Border: 2px solid Overlord Red (`#FF4757`)
  - Box-shadow: 0 0 0 3px rgba(255, 71, 87, 0.2)
  - Background remains Surface Dark

- **Error State**:
  - Border: 2px solid Rejected Red (`#FF6B6B`)
  - Background: Dark red tint (`#2A1A1A`)
  - Error message: 14px Rejected Red below field

- **Success State**:
  - Border: 2px solid Approved Green (`#4ECDC4`)
  - Checkmark icon in right padding area with cyan glow

### Buttons
- **Primary Button** (Submit, Authenticate):
  - Background: Overlord Red (`#FF4757`) with subtle glow
  - Text: Light Text (`#E8E8E8`), 16px bold
  - Padding: 12px 24px
  - Border: None
  - Hover: Authority Red (`#FF3742`) with enhanced glow
  - Active: Darker red with inset glow shadow

- **Secondary Button** (Cancel, Back):
  - Background: Transparent
  - Text: Muted Light (`#B0B0B0`), 16px medium
  - Border: 1px solid Muted Light
  - Padding: 11px 23px (1px less for border)
  - Hover: Surface Dark background, Light Text

- **Danger Button** (Report, Delete):
  - Background: Rejected Red (`#FF6B6B`) with glow
  - Text: Light Text (`#E8E8E8`), 16px bold
  - Same dimensions as primary
  - Hover: Brighter rejected red with enhanced glow

- **Icon Buttons**:
  - Size: 40x40px minimum (touch-friendly)
  - Icon: 20px centered in Muted Light
  - Background: Transparent
  - Hover: 15% Surface Dark background with Overlord Red glow
  - Active: 25% Surface Dark background

### Dropdown Menus
- **Trigger**: Button styling with down arrow (8px) in Light Text
- **Container**: Surface Dark (`#1A1A1A`) background, 2px Overlord Red glow shadow
- **Items**: 40px height, 16px left padding, Light Text
- **Hover**: Muted Light background (15% opacity) with subtle glow
- **Selected**: Overlord Red background with glow, Light Text
- **Separator**: 1px Muted Light line between groups

## Overlord-Specific Components

### Overlord Message Container
- **Background**: Linear gradient from Deep Black to Surface Dark with Overlord Red glow
- **Border**: 3px solid Overlord Red with enhanced glow effect
- **Typography**: Monospace font, Light Text (`#E8E8E8`) color
- **Padding**: 16px 20px
- **Avatar**: Overlord robot head icon (32px) with red glow in top-left
- **Corner Treatment**: Sharp, angular corners with subtle glow (no border-radius)

### Overlord Chat Interface
- **Input Area**: 
  - Background: Surface Dark (`#1A1A1A`) with subtle glow
  - Border-top: 2px solid Overlord Red with glow
  - Prompt text: "Address the Overlord..." in Muted Light
  - Send button: Overlord Red with glow and paper plane icon

- **Message History**:
  - User messages: Right-aligned, Surface Dark background with border
  - Overlord messages: Left-aligned, gradient dark background with red glow
  - Timestamp: 12px Muted Light between messages

### Sanction Notice
- **Container**: Rejected Red (`#FF6B6B`) background with glowing warning stripe pattern
- **Icon**: Exclamation triangle (24px) in Light Text with glow
- **Typography**: 16px bold Light Text (`#E8E8E8`)
- **Border**: 3px solid Deep Black with red glow
- **Animation**: Pulsing glow effect on initial display

## Status & Feedback Components

### Loyalty Score Display
- **Container**: Circular progress ring with subtle glow
- **Background Ring**: Muted Light (20% opacity) on dark background
- **Progress Ring**: Gradient from Approved Green (`#4ECDC4`) to Overlord Red (`#FF4757`) with glow
- **Center Text**: Score number (24px bold Light Text) + "Loyalty" label (12px Muted Light)
- **Size**: 80px diameter on desktop, 60px on mobile

### Badge Components
- **Rank Badges**:
  - Shape: Hexagonal with sharp edges and subtle glow
  - Colors: Overlord Red (`#FF4757`) for high ranks, Muted Light for basic
  - Typography: 10px uppercase, Light Text (`#E8E8E8`)
  - Size: 20px height, variable width

- **Status Badges**:
  - Online: Approved Green (`#4ECDC4`) glowing dot (8px)
  - Offline: Muted Light (`#B0B0B0`) dot (8px)
  - Processing: Pulsing Processing Blue (`#74B9FF`) glowing dot (8px)

### Notification Components
- **Toast Notifications**:
  - Success: Approved Green (`#4ECDC4`) background with glow, Deep Black text
  - Warning: Warning Amber (`#FFD93D`) background with glow, Deep Black text
  - Error: Rejected Red (`#FF6B6B`) background with glow, Light Text
  - Info: Processing Blue (`#74B9FF`) background with glow, Light Text
  - Duration: 5 seconds auto-dismiss
  - Position: Top-right corner, 16px margin

- **Notification Bell**:
  - Icon: Bell outline (20px) in Light Text
  - Badge: Overlord Red circle with Light Text count (12px), glowing
  - Animation: Gentle shake with glow pulse when new notification arrives

## Loading & Empty States

### Loading Indicators
- **Spinner**: Overlord Red (`#FF4757`) circle with rotating gap and glow
- **Progress Bar**: Surface Dark track, Overlord Red fill with glow
- **Skeleton Loading**: Muted Light (15% opacity) blocks on dark background
- **Overlord Thinking**: Animated glowing dots with robot avatar

### Empty State Illustrations
- **Style**: Minimalist line art in Muted Light (`#B0B0B0`) with subtle glow
- **Size**: 120px square maximum
- **Message**: 16px Muted Light below illustration
- **Action Button**: Secondary button styling if applicable

## Responsive Breakpoints

### Mobile (320px - 767px)
- Navigation: Collapsible hamburger menu
- Cards: Full-width with 16px side margins
- Buttons: Minimum 44px height for touch
- Typography: Slightly larger for readability

### Tablet (768px - 1023px)
- Navigation: Horizontal with possible overflow scroll
- Cards: 2-column grid with 16px gaps
- Mixed touch and mouse interactions

### Desktop (1024px+)
- Navigation: Full horizontal layout
- Cards: 3+ column grid depending on container width
- Hover states fully enabled
- Larger click targets acceptable

## Accessibility Considerations

### Color Contrast
- All text meets WCAG AA standards (4.5:1 ratio minimum) for dark backgrounds
- Important UI elements meet AAA standards (7:1 ratio) with Light Text on dark surfaces
- Color is never the only means of conveying information
- Glow effects enhance visibility without compromising contrast

### Focus Management
- Visible focus indicators on all interactive elements
- Logical tab order throughout interface
- Skip links for keyboard navigation

### Screen Reader Support
- Semantic HTML structure
- ARIA labels for complex components
- Alt text for all meaningful images
- Status announcements for dynamic content

---

**Related Documentation:**
- [Visual Assets Specification](./21-visual-assets-specification.md) - Complete asset inventory
- [Look & Feel](./03-look-feel.md) - Design principles and aesthetic guidelines
- [Technical: Frontend Design](../technical-design/02-frontend-design.md) - Implementation guidelines
