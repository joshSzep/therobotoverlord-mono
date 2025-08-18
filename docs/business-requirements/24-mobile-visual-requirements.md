# Mobile Visual Requirements

## Overview

Mobile-specific visual requirements and adaptations for The Robot Overlord platform, ensuring the 1960s propaganda aesthetic translates effectively to touch interfaces while maintaining usability.

## Mobile-First Design Principles

### Touch Interface Adaptations
- **Minimum Touch Target**: 44x44px for all interactive elements
- **Spacing**: 8px minimum between adjacent touch targets
- **Gesture Support**: Swipe, pinch, long-press where appropriate
- **Thumb Zones**: Critical actions within comfortable thumb reach

### Screen Size Considerations
- **Small Mobile**: 320px - 480px width
- **Large Mobile**: 481px - 767px width
- **Orientation**: Portrait-first design, landscape support
- **Safe Areas**: Account for notches, home indicators, status bars

## Navigation Adaptations

### Mobile Navigation Bar
- **Height**: 56px with 8px top/bottom padding
- **Logo**: 32px height, left-aligned with 16px margin, Light Text with glow
- **Menu Toggle**: 24px hamburger icon in Light Text, right-aligned with 16px margin
- **Background**: Deep Black (`#0C0C0C`) with 95% opacity for content visibility
- **Typography**: 16px bold Light Text (`#E8E8E8`) for menu items

### Hamburger Menu
- **Animation**: Slide-in from right, 300ms ease-out with glow trail
- **Overlay**: Full-screen with Surface Dark (`#1A1A1A`) background
- **Header**: Overlord branding with close button (32px) in Overlord Red with glow
- **Menu Items**: 
  - Height: 56px each for comfortable touch
  - Typography: 18px medium weight Light Text (`#E8E8E8`)
  - Icons: 24px left-aligned with 16px margin in Muted Light
  - Dividers: 1px Muted Light (`#B0B0B0`) between sections

### Bottom Tab Navigation (Alternative)
- **Height**: 64px with safe area padding
- **Background**: Surface Dark (`#1A1A1A`) with subtle top border glow
- **Items**: Maximum 5 tabs for optimal usability
- **Icons**: 24px with 8px bottom margin to labels
- **Labels**: 12px Light Text, truncated to single line
- **Active State**: Overlord Red (`#FF4757`) icon and label with glow
- **Inactive State**: Muted Light (`#B0B0B0`) with 60% opacity

## Content Display Adaptations

### Mobile Topic Cards
- **Layout**: Single column, full-width minus 16px margins
- **Background**: Surface Dark (`#1A1A1A`) with subtle border glow
- **Height**: Variable, minimum 120px
- **Header**: 
  - Title: 18px bold Light Text (`#E8E8E8`), 2-line maximum with ellipsis
  - Metadata: 14px Muted Light (`#B0B0B0`), single line
- **Content Preview**: 16px regular Light Text, 3-line maximum
- **Actions**: Horizontal row at bottom, 40px height buttons with glow on active

### Mobile Post Display
- **Background**: Surface Dark (`#1A1A1A`) with subtle glow border
- **Avatar**: 40px circular with dark border for better touch targeting
- **Author Info**: Stacked layout (name above timestamp) in Light Text
- **Content**: 
  - Typography: 16px Light Text (`#E8E8E8`) with 1.6 line-height for readability
  - Margins: 16px horizontal, 12px vertical
- **Actions**: Bottom-aligned row with 48px touch targets, Overlord Red glow on interaction
- **Expansion**: Tap to expand long posts with "Read more" link in Overlord Red

### Mobile Queue Cards
- **Background**: Surface Dark (`#1A1A1A`) with status-colored glow border
- **Simplified Layout**: Icon, title, and position only in Light Text
- **Height**: 80px fixed for consistent scanning
- **Progress Indicator**: Full-width glowing bar at bottom
- **Status Colors**: Glowing status indicators for quick recognition
- **Tap Action**: Expand to show full details in dark modal with glow effects

## Form Adaptations

### Mobile Input Fields
- **Background**: Surface Dark (`#1A1A1A`) with Muted Light border
- **Height**: 48px minimum for comfortable touch
- **Typography**: 16px Light Text (`#E8E8E8`) to prevent zoom on iOS
- **Padding**: 16px horizontal, 12px vertical
- **Focus State**: Larger touch area with 4px Overlord Red (`#FF4757`) glowing border
- **Labels**: Float above field when focused/filled in Muted Light

### Mobile Buttons
- **Primary Buttons**: 
  - Background: Overlord Red (`#FF4757`) with glow
  - Height: 48px minimum
  - Width: Full-width minus 32px margins
  - Typography: 16px bold Light Text (`#E8E8E8`), uppercase
  - Corner Radius: 4px with subtle glow (slightly more rounded for mobile)

- **Secondary Buttons**:
  - Same dimensions as primary
  - Outline style with 2px Muted Light border
  - Background: Transparent
  - Text: Muted Light (`#B0B0B0`)

- **Icon Buttons**:
  - Size: 48x48px minimum
  - Icon: 24px centered in Muted Light
  - Glow ripple effect on touch

### Mobile Overlord Chat
- **Input Area**: 
  - Background: Surface Dark (`#1A1A1A`) with glowing top border
  - Height: 56px with auto-expand to 120px maximum
  - Send Button: 40px circular Overlord Red with glow, positioned right
  - Attachment Button: 40px Muted Light with glow on touch, positioned left of input
- **Message Bubbles**:
  - User: Surface Dark background with Muted Light border
  - Overlord: Gradient dark background with Overlord Red glow
  - Maximum width: 80% of screen width
  - Minimum touch target: 44px height
  - Tail positioning: Adjusted for thumb interaction

## Mobile-Specific Components

### Pull-to-Refresh
- **Indicator**: Overlord Red (`#FF4757`) spinner with glowing robot avatar
- **Animation**: 1.5s rotation with subtle bounce and glow pulse
- **Trigger Distance**: 80px pull threshold
- **Feedback**: Haptic feedback on trigger (iOS)
- **Background**: Surface Dark (`#1A1A1A`) with subtle glow effect

### Swipe Actions
- **Post Cards**: 
  - Swipe right: Like/approve (Approved Green `#4ECDC4` background with glow)
  - Swipe left: Flag/report (Rejected Red `#FF6B6B` background with glow)
  - Icon: 32px centered in swipe area with Light Text (`#E8E8E8`)
  - Threshold: 25% of card width

### Mobile Modals
- **Slide-up Animation**: From bottom, 400ms ease-out with glow trail
- **Background**: Surface Dark (`#1A1A1A`) with subtle glow overlay
- **Header**: 
  - Height: 56px with close button (32px) in Overlord Red
  - Title: 18px bold Light Text (`#E8E8E8`), centered
  - Background: Deep Black (`#0C0C0C`) with 1px Overlord Red bottom border
- **Content**: Scrollable with momentum, Light Text on dark background
- **Actions**: Sticky bottom bar with glowing primary/secondary buttons

### Mobile Notifications
- **Toast Position**: Top of screen, below status bar
- **Background**: Surface Dark (`#1A1A1A`) with status-colored glow border
- **Height**: 64px minimum for readability
- **Typography**: Light Text (`#E8E8E8`) with status-colored accents
- **Animation**: Slide down from top with glow trail, 300ms ease-out
- **Dismissal**: Swipe up or auto-dismiss after 4 seconds
- **Multiple Notifications**: Stack with 4px spacing and cascading glow

## Responsive Images & Icons

### Icon Scaling
- **Base Size**: 24x24px at 1x density
- **Retina Support**: 48x48px at 2x density, 72x72px at 3x density
- **Touch Targets**: Minimum 44x44px interactive area
- **Optical Alignment**: Adjust positioning for visual centering

### Image Optimization
- **Format**: WebP with JPEG fallback
- **Lazy Loading**: Images below fold load on scroll
- **Placeholder**: Committee Gray background with loading animation
- **Error State**: Broken image icon with retry option

### Avatar Handling
- **Sizes**: 32px (small), 40px (medium), 56px (large)
- **Background**: Surface Dark (`#1A1A1A`) with subtle border
- **Fallback**: User initials in Light Text (`#E8E8E8`) on Overlord Red (`#FF4757`) circle with glow
- **Loading**: Glowing skeleton animation in avatar shape
- **Caching**: Aggressive caching with cache-busting for updates

## Performance Considerations

### Touch Response
- **Immediate Feedback**: Visual response within 16ms of touch
- **Loading States**: Show immediately for actions taking >200ms
- **Optimistic Updates**: Update UI before server confirmation
- **Error Recovery**: Clear rollback mechanism for failed actions

### Animation Performance
- **60fps Target**: All animations maintain smooth framerate
- **Hardware Acceleration**: Use transform and opacity for animations
- **Reduced Motion**: Respect system accessibility preferences
- **Battery Consideration**: Minimize continuous animations

### Network Awareness
- **Offline Indicators**: Clear visual feedback for connectivity issues
- **Progressive Loading**: Load critical content first
- **Image Compression**: Aggressive compression for mobile networks
- **Caching Strategy**: Cache frequently accessed visual assets

## Accessibility on Mobile

### Screen Reader Support
- **Touch Exploration**: Logical reading order for VoiceOver/TalkBack
- **Gesture Navigation**: Support for accessibility gestures
- **Announcements**: Status changes announced clearly
- **Landmarks**: Proper heading structure and navigation landmarks

### Visual Accessibility
- **Text Size**: Support for system text size preferences with Light Text scaling
- **High Contrast**: Enhanced contrast mode with increased glow effects
- **Color Blindness**: Color plus glow patterns ensure communication accessibility
- **Focus Indicators**: Visible glowing focus indicators for external keyboard users

### Motor Accessibility
- **Large Touch Targets**: Exceed minimum requirements where possible
- **Gesture Alternatives**: Button alternatives for all swipe actions
- **Timing**: No time-based interactions without alternatives
- **Shake Alternatives**: Alternative to device motion gestures

## Platform-Specific Considerations

### iOS Adaptations
- **Safe Areas**: Proper handling of notch and home indicator
- **Navigation**: iOS-style back gesture support
- **Haptics**: Appropriate haptic feedback for actions
- **Status Bar**: Dynamic status bar styling

### Android Adaptations
- **Material Guidelines**: Subtle incorporation where appropriate
- **Back Button**: Hardware back button support
- **Navigation Bar**: Proper handling of gesture navigation
- **Adaptive Icons**: Support for Android adaptive icon system

---

**Related Documentation:**
- [Visual Assets Specification](./21-visual-assets-specification.md) - Complete asset inventory
- [UI Component Visuals](./22-ui-component-visuals.md) - Desktop component specifications
- [Technical: Mobile Strategy](../technical-design/21-mobile-strategy.md) - Technical implementation details
