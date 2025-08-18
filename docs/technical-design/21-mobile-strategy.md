# Mobile Strategy & Progressive Web App

## Overview

Mobile-first responsive design strategy for The Robot Overlord, ensuring optimal experience across all devices with Progressive Web App capabilities.

## Mobile-First Design Principles

### Core Philosophy
- **Mobile-first**: Design for smallest screens first, enhance upward
- **Touch-optimized**: All interactions designed for finger navigation
- **Performance-focused**: Fast loading on mobile networks
- **Authoritarian aesthetics**: Maintain Soviet propaganda theme on mobile

### Responsive Breakpoints

```scss
// Mobile-first breakpoints
$breakpoints: (
  'mobile': 320px,     // Small phones
  'mobile-lg': 414px,  // Large phones
  'tablet': 768px,     // Tablets
  'desktop': 1024px,   // Small desktops
  'desktop-lg': 1440px // Large desktops
);

// Usage
@media (min-width: 768px) {
  // Tablet and up styles
}
```

### Layout Strategy

#### Mobile Layout (320px - 767px)
- **Single column**: All content stacked vertically
- **Collapsible navigation**: Hamburger menu with slide-out drawer
- **Bottom tab bar**: Primary navigation at thumb reach
- **Floating action button**: Quick post creation
- **Swipe gestures**: Navigate between sections

#### Tablet Layout (768px - 1023px)
- **Dual column**: Sidebar + main content
- **Persistent navigation**: Always visible sidebar
- **Split view**: Topics list + selected topic detail
- **Gesture support**: Swipe to navigate, pinch to zoom

#### Desktop Layout (1024px+)
- **Multi-column**: Full three-column layout
- **Hover states**: Rich interactions on mouse hover
- **Keyboard shortcuts**: Power user features
- **Dense information**: More content per screen

## Progressive Web App (PWA) Specifications

### PWA Manifest

```json
{
  "name": "The Robot Overlord",
  "short_name": "Overlord",
  "description": "AI-moderated debate arena in a satirical authoritarian state",
  "start_url": "/",
  "display": "standalone",
  "orientation": "portrait-primary",
  "theme_color": "#8B0000",
  "background_color": "#2F1B14",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "categories": ["social", "productivity"],
  "shortcuts": [
    {
      "name": "New Topic",
      "short_name": "Create",
      "description": "Create a new debate topic",
      "url": "/topics/new",
      "icons": [{"src": "/icons/create-192.png", "sizes": "192x192"}]
    },
    {
      "name": "Queue Status",
      "short_name": "Queue",
      "description": "Check moderation queue",
      "url": "/queue",
      "icons": [{"src": "/icons/queue-192.png", "sizes": "192x192"}]
    }
  ]
}
```

### Service Worker Strategy

```javascript
// Service Worker for offline functionality
const CACHE_NAME = 'overlord-v1';
const STATIC_CACHE = [
  '/',
  '/css/main.css',
  '/js/app.js',
  '/fonts/soviet-font.woff2',
  '/icons/icon-192.png',
  '/offline.html'
];

// Cache-first strategy for static assets
// Network-first for API calls with fallback
// Stale-while-revalidate for user content

self.addEventListener('fetch', event => {
  if (event.request.url.includes('/api/')) {
    // Network-first for API calls
    event.respondWith(networkFirstStrategy(event.request));
  } else if (event.request.destination === 'image') {
    // Cache-first for images
    event.respondWith(cacheFirstStrategy(event.request));
  } else {
    // Stale-while-revalidate for pages
    event.respondWith(staleWhileRevalidateStrategy(event.request));
  }
});
```

### Offline Functionality

#### Offline Capabilities
- **Read cached content**: Previously viewed topics and posts
- **Draft composition**: Write posts offline, sync when online
- **Queue status**: Show last known queue state
- **Profile access**: View cached profile information
- **Offline indicator**: Clear visual feedback when offline

#### Sync Strategy
```javascript
// Background Sync for draft posts
self.addEventListener('sync', event => {
  if (event.tag === 'draft-sync') {
    event.waitUntil(syncDrafts());
  }
  if (event.tag === 'queue-check') {
    event.waitUntil(syncQueueStatus());
  }
});

// Periodic Background Sync for queue updates
self.addEventListener('periodicsync', event => {
  if (event.tag === 'queue-updates') {
    event.waitUntil(updateQueueStatus());
  }
});
```

## Mobile-Specific UX Patterns

### Navigation Design

#### Bottom Tab Navigation
```scss
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 60px;
  background: $overlord-red;
  display: flex;
  justify-content: space-around;
  align-items: center;
  z-index: 1000;
  
  .nav-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    min-width: 44px; // Touch target minimum
    min-height: 44px;
    
    .icon {
      width: 24px;
      height: 24px;
      margin-bottom: 2px;
    }
    
    .label {
      font-size: 10px;
      text-transform: uppercase;
    }
  }
}
```

#### Slide-Out Menu
```scss
.mobile-menu {
  position: fixed;
  top: 0;
  left: -300px;
  width: 300px;
  height: 100vh;
  background: $dark-background;
  transition: transform 0.3s ease;
  z-index: 2000;
  
  &.open {
    transform: translateX(300px);
  }
  
  .menu-header {
    padding: 20px;
    background: $overlord-red;
    
    .citizen-info {
      display: flex;
      align-items: center;
      
      .avatar {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        margin-right: 12px;
      }
      
      .loyalty-score {
        font-weight: bold;
        color: $gold;
      }
    }
  }
}
```

### Touch Interactions

#### Gesture Support
```javascript
class TouchGestureHandler {
  constructor(element) {
    this.element = element;
    this.startX = 0;
    this.startY = 0;
    this.currentX = 0;
    this.currentY = 0;
    
    this.bindEvents();
  }
  
  bindEvents() {
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this));
    this.element.addEventListener('touchmove', this.handleTouchMove.bind(this));
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this));
  }
  
  handleSwipeLeft() {
    // Navigate to next topic
    this.navigateToNext();
  }
  
  handleSwipeRight() {
    // Navigate to previous topic
    this.navigateToPrevious();
  }
  
  handleSwipeUp() {
    // Show more options
    this.showActionSheet();
  }
  
  handleLongPress() {
    // Show context menu
    this.showContextMenu();
  }
}
```

#### Touch-Optimized Components

##### Mobile Post Cards
```scss
.post-card-mobile {
  padding: 16px;
  margin-bottom: 8px;
  background: $card-background;
  border-left: 4px solid $overlord-red;
  
  .post-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
    
    .citizen-name {
      font-weight: bold;
      font-size: 14px;
    }
    
    .post-status {
      padding: 4px 8px;
      border-radius: 12px;
      font-size: 10px;
      text-transform: uppercase;
      
      &.approved { background: $success-green; }
      &.pending { background: $warning-yellow; }
      &.rejected { background: $error-red; }
    }
  }
  
  .post-content {
    font-size: 16px;
    line-height: 1.5;
    margin-bottom: 12px;
  }
  
  .post-actions {
    display: flex;
    justify-content: space-between;
    align-items: center;
    
    .action-button {
      min-width: 44px;
      min-height: 44px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 50%;
      background: transparent;
      border: 1px solid $border-color;
      
      &:active {
        background: rgba(139, 0, 0, 0.1);
        transform: scale(0.95);
      }
    }
  }
}
```

##### Mobile Topic List
```scss
.topic-list-mobile {
  .topic-item {
    padding: 16px;
    border-bottom: 1px solid $border-color;
    
    .topic-title {
      font-size: 18px;
      font-weight: bold;
      margin-bottom: 8px;
      line-height: 1.3;
    }
    
    .topic-meta {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 12px;
      color: $text-secondary;
      
      .participant-count {
        display: flex;
        align-items: center;
        
        .icon {
          width: 16px;
          height: 16px;
          margin-right: 4px;
        }
      }
      
      .last-activity {
        font-style: italic;
      }
    }
    
    .topic-tags {
      margin-top: 8px;
      display: flex;
      flex-wrap: wrap;
      gap: 4px;
      
      .tag {
        padding: 2px 6px;
        background: rgba(139, 0, 0, 0.1);
        border-radius: 8px;
        font-size: 10px;
        text-transform: uppercase;
      }
    }
  }
}
```

### Mobile Queue Visualization

#### Compact Queue Display
```scss
.queue-mobile {
  .queue-summary {
    padding: 16px;
    background: $overlord-red;
    color: white;
    text-align: center;
    
    .queue-count {
      font-size: 32px;
      font-weight: bold;
      display: block;
    }
    
    .queue-label {
      font-size: 12px;
      text-transform: uppercase;
      opacity: 0.8;
    }
  }
  
  .queue-items {
    .queue-item {
      padding: 12px 16px;
      border-bottom: 1px solid $border-color;
      display: flex;
      align-items: center;
      
      .position-indicator {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        background: $overlord-red;
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        margin-right: 12px;
      }
      
      .item-content {
        flex: 1;
        
        .content-preview {
          font-size: 14px;
          margin-bottom: 4px;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        
        .submission-time {
          font-size: 10px;
          color: $text-secondary;
        }
      }
      
      .queue-status {
        padding: 4px 8px;
        border-radius: 8px;
        font-size: 10px;
        text-transform: uppercase;
      }
    }
  }
}
```

## Push Notifications

### Notification Strategy
```javascript
class NotificationManager {
  async requestPermission() {
    if ('Notification' in window && 'serviceWorker' in navigator) {
      const permission = await Notification.requestPermission();
      return permission === 'granted';
    }
    return false;
  }
  
  async subscribeToPush() {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlB64ToUint8Array(VAPID_PUBLIC_KEY)
    });
    
    // Send subscription to server
    await this.sendSubscriptionToServer(subscription);
  }
  
  showNotification(title, options) {
    if (this.hasPermission()) {
      navigator.serviceWorker.ready.then(registration => {
        registration.showNotification(title, {
          ...options,
          icon: '/icons/icon-192.png',
          badge: '/icons/badge-72.png',
          vibrate: [200, 100, 200],
          tag: 'overlord-notification'
        });
      });
    }
  }
}
```

### Notification Types
- **Moderation Complete**: "Citizen, your submission has been evaluated"
- **Queue Position**: "Your content has moved up in the queue"
- **New Topic**: "A new debate topic requires your attention"
- **Direct Message**: "Private communication from [Citizen Name]"
- **Sanction Notice**: "Attention: Posting restrictions applied"
- **Appeal Result**: "Your appeal has been processed"

## Performance Optimization

### Mobile Performance Strategy

#### Critical Resource Loading
```javascript
// Critical CSS inlining
const criticalCSS = `
  /* Above-the-fold styles */
  body { font-family: 'Soviet', sans-serif; }
  .header { background: #8B0000; }
  .loading-spinner { /* ... */ }
`;

// Lazy loading for non-critical resources
const lazyLoadCSS = (href) => {
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = href;
  link.media = 'print';
  link.onload = () => link.media = 'all';
  document.head.appendChild(link);
};
```

#### Image Optimization
```html
<!-- Responsive images with WebP support -->
<picture>
  <source srcset="/images/avatar-small.webp 1x, /images/avatar-small@2x.webp 2x" type="image/webp">
  <source srcset="/images/avatar-small.jpg 1x, /images/avatar-small@2x.jpg 2x" type="image/jpeg">
  <img src="/images/avatar-small.jpg" alt="Citizen Avatar" loading="lazy" width="40" height="40">
</picture>
```

#### Bundle Splitting
```javascript
// Code splitting for mobile
const mobileComponents = () => import('./components/mobile');
const desktopComponents = () => import('./components/desktop');

const loadComponents = () => {
  if (window.innerWidth < 768) {
    return mobileComponents();
  } else {
    return desktopComponents();
  }
};
```

## Accessibility on Mobile

### Touch Accessibility
- **Minimum touch targets**: 44px × 44px
- **Adequate spacing**: 8px between interactive elements  
- **Focus indicators**: Clear visual focus for keyboard navigation
- **Screen reader support**: Proper ARIA labels and roles

### Voice Control
```javascript
// Voice command support
if ('webkitSpeechRecognition' in window) {
  const recognition = new webkitSpeechRecognition();
  recognition.continuous = false;
  recognition.interimResults = false;
  
  recognition.onresult = (event) => {
    const command = event.results[0][0].transcript.toLowerCase();
    this.handleVoiceCommand(command);
  };
  
  handleVoiceCommand(command) {
    if (command.includes('create topic')) {
      this.navigateToTopicCreation();
    } else if (command.includes('check queue')) {
      this.navigateToQueue();
    }
  }
}
```

## Implementation Roadmap

### Phase 1: Mobile-First Foundation
- [ ] Implement responsive breakpoints
- [ ] Create mobile navigation patterns
- [ ] Optimize touch interactions
- [ ] Basic PWA manifest

### Phase 2: Progressive Enhancement  
- [ ] Service worker implementation
- [ ] Offline functionality
- [ ] Push notification setup
- [ ] Background sync

### Phase 3: Advanced Mobile Features
- [ ] Gesture recognition
- [ ] Voice commands
- [ ] Advanced caching strategies
- [ ] Performance monitoring

### Phase 4: Optimization
- [ ] Bundle size optimization
- [ ] Image optimization pipeline
- [ ] Performance metrics tracking
- [ ] A/B testing mobile UX

## Testing Strategy

### Mobile Testing Approach
- **Device testing**: Physical devices across price ranges
- **Browser testing**: Chrome, Safari, Firefox mobile
- **Network testing**: 3G, 4G, WiFi conditions
- **Touch testing**: Various finger sizes and gestures
- **Accessibility testing**: Screen readers, voice control

### Performance Metrics
- **First Contentful Paint**: < 2s on 3G
- **Largest Contentful Paint**: < 3s on 3G  
- **Time to Interactive**: < 4s on 3G
- **Cumulative Layout Shift**: < 0.1
- **First Input Delay**: < 100ms

---

**Related Documentation:**
- [Frontend Design](./02-frontend-design.md) - Base UI architecture
- [Look & Feel](../business-requirements/03-look-feel.md) - Visual design system
- [Queue Visualization](../business-requirements/16-queue-visualization.md) - Mobile queue UX
