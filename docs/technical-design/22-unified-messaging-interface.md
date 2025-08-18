# Unified Messaging Interface

## Overview

Design for a unified messaging interface that handles both citizen-to-citizen private messages and direct chat with the Robot Overlord. While visually identical, these conversations have fundamentally different behaviors and capabilities.

## Visual Design Consistency

### Shared Interface Elements

#### Message Thread Layout
```scss
.message-thread {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: $dark-background;
  
  .thread-header {
    padding: 16px;
    background: $overlord-red;
    color: white;
    display: flex;
    align-items: center;
    
    .participant-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      margin-right: 12px;
      
      &.overlord {
        background: linear-gradient(45deg, $overlord-red, $gold);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
        
        &::before {
          content: "⚡";
        }
      }
    }
    
    .participant-info {
      flex: 1;
      
      .name {
        font-weight: bold;
        font-size: 16px;
      }
      
      .status {
        font-size: 12px;
        opacity: 0.8;
        
        &.overlord { content: "Supreme AI Authority"; }
        &.citizen { content: "Citizen of the State"; }
        &.moderator { content: "Anti-Spam Enforcer"; }
        &.admin { content: "State Administrator"; }
      }
    }
  }
  
  .messages-container {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
    
    .message {
      margin-bottom: 16px;
      display: flex;
      
      &.sent {
        justify-content: flex-end;
        
        .message-bubble {
          background: $citizen-blue;
          color: white;
          border-radius: 18px 18px 4px 18px;
        }
      }
      
      &.received {
        justify-content: flex-start;
        
        .message-bubble {
          background: $card-background;
          border: 1px solid $border-color;
          border-radius: 18px 18px 18px 4px;
          
          &.overlord {
            background: linear-gradient(135deg, $overlord-red, darken($overlord-red, 10%));
            color: white;
            border: none;
          }
        }
      }
      
      .message-bubble {
        max-width: 70%;
        padding: 12px 16px;
        
        .message-content {
          font-size: 14px;
          line-height: 1.4;
          margin-bottom: 4px;
        }
        
        .message-meta {
          font-size: 10px;
          opacity: 0.7;
          display: flex;
          justify-content: space-between;
          align-items: center;
          
          .timestamp {
            font-style: italic;
          }
          
          .status-indicator {
            display: flex;
            align-items: center;
            gap: 4px;
            
            &.pending { color: $warning-yellow; }
            &.approved { color: $success-green; }
            &.rejected { color: $error-red; }
          }
        }
      }
    }
  }
  
  .message-input {
    padding: 16px;
    background: $card-background;
    border-top: 1px solid $border-color;
    
    .input-container {
      display: flex;
      align-items: flex-end;
      gap: 12px;
      
      .text-input {
        flex: 1;
        min-height: 40px;
        max-height: 120px;
        padding: 12px 16px;
        background: $input-background;
        border: 1px solid $border-color;
        border-radius: 20px;
        resize: none;
        font-family: inherit;
        
        &:focus {
          outline: none;
          border-color: $overlord-red;
        }
      }
      
      .send-button {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background: $overlord-red;
        color: white;
        border: none;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        
        &:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
        
        &:hover:not(:disabled) {
          background: darken($overlord-red, 10%);
        }
      }
    }
  }
}
```

### Overlord-Specific Visual Enhancements

#### Special Message Types
```scss
.message-bubble.overlord {
  .command-response {
    background: rgba(255, 215, 0, 0.1);
    border: 1px solid $gold;
    border-radius: 8px;
    padding: 8px;
    margin-top: 8px;
    
    .command-result {
      font-family: 'Courier New', monospace;
      font-size: 12px;
      color: $gold;
    }
  }
  
  .notification-message {
    border-left: 4px solid $warning-yellow;
    padding-left: 12px;
    
    &.sanction { border-left-color: $error-red; }
    &.approval { border-left-color: $success-green; }
  }
  
  .contextual-links {
    margin-top: 8px;
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    
    .context-link {
      padding: 4px 8px;
      background: rgba(255, 215, 0, 0.2);
      border-radius: 12px;
      font-size: 10px;
      text-decoration: none;
      color: $gold;
      
      &:hover {
        background: rgba(255, 215, 0, 0.3);
      }
    }
  }
}
```

## Behavioral Differences

### Citizen-to-Citizen Private Messages

#### Message Flow
```typescript
interface PrivateMessage {
  id: string;
  senderId: string;
  recipientId: string;
  content: string;
  status: 'pending' | 'approved' | 'rejected';
  moderationFeedback?: string;
  createdAt: Date;
  deliveredAt?: Date;
}

class PrivateMessageHandler {
  async sendMessage(senderId: string, recipientId: string, content: string) {
    // 1. Create message in pending state
    const message = await this.createMessage({
      senderId,
      recipientId,
      content,
      status: 'pending'
    });
    
    // 2. Queue for moderation
    await this.queueForModeration(message);
    
    // 3. Show as "pending" to sender
    this.showPendingMessage(senderId, message);
    
    // 4. No notification to recipient until approved
    return message;
  }
  
  async handleModerationResult(messageId: string, decision: ModerationDecision) {
    const message = await this.getMessage(messageId);
    
    if (decision.approved) {
      // Deliver to recipient
      await this.deliverMessage(message);
      this.notifyRecipient(message.recipientId, message);
    } else {
      // Show rejection feedback to sender
      await this.updateMessage(messageId, {
        status: 'rejected',
        moderationFeedback: decision.feedback
      });
      this.showRejectionFeedback(message.senderId, message);
    }
  }
}
```

#### UI Behavior
- **Send button**: Shows loading state while message is queued
- **Message status**: Clear pending/approved/rejected indicators
- **Rejection handling**: Inline feedback display with retry option
- **Delivery confirmation**: "Delivered" indicator when recipient receives message
- **No real-time**: Messages only appear when moderation is complete

### Robot Overlord Chat Interface

#### Chat Flow
```typescript
interface OverlordChatMessage {
  id: string;
  userId: string;
  content: string;
  type: 'user' | 'overlord';
  context?: {
    userRole: UserRole;
    loyaltyScore: number;
    recentActivity: string[];
    sessionId: string;
  };
  actions?: OverlordAction[];
  links?: ContextualLink[];
  createdAt: Date;
}

class OverlordChatHandler {
  async sendToOverlord(userId: string, content: string) {
    // 1. Immediate response - no moderation queue
    const userMessage = this.createUserMessage(userId, content);
    this.displayMessage(userMessage);
    
    // 2. Show typing indicator
    this.showTypingIndicator();
    
    // 3. Get user context
    const context = await this.getUserContext(userId);
    
    // 4. Generate Overlord response
    const response = await this.generateOverlordResponse(content, context);
    
    // 5. Execute any inline actions (for moderators/admins)
    if (response.actions) {
      await this.executeActions(response.actions, userId);
    }
    
    // 6. Display response with contextual links
    this.displayOverlordResponse(response);
    
    return response;
  }
  
  async executeActions(actions: OverlordAction[], userId: string) {
    for (const action of actions) {
      switch (action.type) {
        case 'approve_post':
          await this.moderationService.approvePost(action.postId, userId);
          break;
        case 'sanction_citizen':
          await this.sanctionService.applySanction(action.citizenId, action.duration);
          break;
        case 'update_tags':
          await this.topicService.updateTags(action.topicId, action.tags);
          break;
      }
    }
  }
}
```

#### UI Behavior
- **Instant responses**: No moderation delay, immediate back-and-forth
- **Typing indicators**: Shows when Overlord is "thinking"
- **Contextual actions**: Inline buttons for moderator actions
- **Rich responses**: Links to topics, profiles, queue items
- **Session awareness**: References user's recent activity and status
- **Proactive messages**: Overlord can initiate conversations (sanctions, notifications)

## Mobile-Specific Adaptations

### Unified Mobile Interface
```scss
@media (max-width: 767px) {
  .message-thread {
    .thread-header {
      padding: 12px 16px;
      
      .participant-avatar {
        width: 32px;
        height: 32px;
      }
      
      .participant-info .name {
        font-size: 14px;
      }
    }
    
    .messages-container {
      padding: 12px;
      
      .message-bubble {
        max-width: 85%;
        
        .message-content {
          font-size: 16px; // Larger for mobile readability
        }
      }
    }
    
    .message-input {
      padding: 12px;
      
      .input-container {
        .text-input {
          font-size: 16px; // Prevent zoom on iOS
        }
      }
    }
  }
  
  // Mobile-specific Overlord enhancements
  .message-bubble.overlord {
    .contextual-links {
      .context-link {
        min-height: 44px; // Touch target
        display: flex;
        align-items: center;
        justify-content: center;
      }
    }
    
    .command-response {
      .action-buttons {
        display: flex;
        gap: 8px;
        margin-top: 8px;
        
        .action-btn {
          flex: 1;
          min-height: 44px;
          background: rgba(255, 215, 0, 0.2);
          border: 1px solid $gold;
          border-radius: 8px;
          color: $gold;
          font-size: 12px;
        }
      }
    }
  }
}
```

### Touch Interactions
```typescript
class MobileMessageInterface {
  setupTouchGestures() {
    // Long press on message for context menu
    this.addLongPressHandler('.message-bubble', (message) => {
      if (message.type === 'private') {
        this.showPrivateMessageMenu(message); // Report, Delete
      } else {
        this.showOverlordMessageMenu(message); // Copy, Share Link
      }
    });
    
    // Swipe left on message for quick actions
    this.addSwipeHandler('.message', 'left', (message) => {
      if (message.type === 'private' && message.status === 'rejected') {
        this.showRetryOption(message);
      } else if (message.type === 'overlord') {
        this.showQuickActions(message); // Follow links, execute commands
      }
    });
    
    // Pull to refresh for message history
    this.addPullToRefresh('.messages-container', () => {
      this.loadMoreMessages();
    });
  }
}
```

## Navigation Integration

### Message List View
```scss
.messages-list {
  .conversation-item {
    padding: 16px;
    border-bottom: 1px solid $border-color;
    display: flex;
    align-items: center;
    
    .participant-avatar {
      width: 48px;
      height: 48px;
      margin-right: 12px;
      
      &.overlord {
        background: linear-gradient(45deg, $overlord-red, $gold);
        position: relative;
        
        &::after {
          content: "⚡";
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          font-size: 20px;
        }
      }
    }
    
    .conversation-info {
      flex: 1;
      
      .participant-name {
        font-weight: bold;
        margin-bottom: 4px;
        
        &.overlord {
          color: $overlord-red;
          
          &::after {
            content: " • Supreme Authority";
            font-weight: normal;
            font-size: 12px;
            opacity: 0.7;
          }
        }
      }
      
      .last-message {
        font-size: 14px;
        color: $text-secondary;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
      
      .message-status {
        font-size: 10px;
        text-transform: uppercase;
        margin-top: 4px;
        
        &.pending { color: $warning-yellow; }
        &.rejected { color: $error-red; }
        &.unread { color: $overlord-red; font-weight: bold; }
      }
    }
    
    .conversation-meta {
      text-align: right;
      
      .timestamp {
        font-size: 12px;
        color: $text-secondary;
        margin-bottom: 4px;
      }
      
      .unread-count {
        background: $overlord-red;
        color: white;
        border-radius: 50%;
        width: 20px;
        height: 20px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 10px;
        font-weight: bold;
      }
    }
  }
}
```

## Technical Implementation

### Unified Message Router
```typescript
class MessageRouter {
  routeMessage(conversationId: string, message: string, userId: string) {
    if (conversationId === 'overlord') {
      return this.overlordChatHandler.sendToOverlord(userId, message);
    } else {
      const recipientId = this.extractRecipientId(conversationId, userId);
      return this.privateMessageHandler.sendMessage(userId, recipientId, message);
    }
  }
  
  getConversationHistory(conversationId: string, userId: string) {
    if (conversationId === 'overlord') {
      return this.overlordChatHandler.getChatHistory(userId);
    } else {
      return this.privateMessageHandler.getMessageHistory(conversationId, userId);
    }
  }
  
  markAsRead(conversationId: string, userId: string) {
    // Different read receipt handling for each type
    if (conversationId === 'overlord') {
      // Overlord messages are always "read" immediately
      return Promise.resolve();
    } else {
      return this.privateMessageHandler.markAsRead(conversationId, userId);
    }
  }
}
```

### Real-time Updates
```typescript
class UnifiedMessageSubscription {
  subscribe(userId: string) {
    // Private message updates
    this.subscribeToPrivateMessages(userId, (update) => {
      this.updateMessageStatus(update.messageId, update.status);
      if (update.status === 'approved') {
        this.showNewMessage(update);
      } else if (update.status === 'rejected') {
        this.showRejectionFeedback(update);
      }
    });
    
    // Overlord proactive messages
    this.subscribeToOverlordMessages(userId, (message) => {
      this.showOverlordNotification(message);
      this.addToConversationHistory('overlord', message);
    });
    
    // Queue status updates (for Overlord chat context)
    this.subscribeToQueueUpdates(userId, (queueStatus) => {
      this.updateOverlordContext({ queueStatus });
    });
  }
}
```

## Summary

The unified messaging interface provides a seamless user experience where both private messages and Overlord chat look identical but behave according to their distinct purposes:

- **Visual consistency**: Same layout, styling, and interaction patterns
- **Behavioral distinction**: Immediate responses vs. moderated delivery
- **Context awareness**: Overlord knows user role and status
- **Mobile optimization**: Touch-friendly with gesture support
- **Technical separation**: Different backend handlers with unified routing

Citizens experience a natural messaging flow regardless of whether they're communicating with peers or consulting the supreme AI authority.

---

**Related Documentation:**
- [Private Messaging](../business-requirements/08-private-messaging.md) - Business requirements
- [Guidelines & Help](../business-requirements/14-guidelines-help.md) - Overlord chat features  
- [Mobile Strategy](./21-mobile-strategy.md) - Mobile interface design
- [AI/LLM Integration](./07-ai-llm-integration.md) - Overlord chat implementation
