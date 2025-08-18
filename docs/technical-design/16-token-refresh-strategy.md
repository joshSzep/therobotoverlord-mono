# Token Refresh Strategy

## Overview

Seamless authentication experience with activity-based token refresh to prevent user interruption during active sessions.

## Token Lifecycle Management

### Access Token Strategy
- **Base Lifetime**: 1 hour
- **Extension Amount**: +30 minutes per activity
- **Maximum Lifetime**: 8 hours from initial issue
- **Extension Triggers**: API calls, WebSocket activity, page navigation

### Background Refresh Implementation

```python
class TokenRefreshService:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.base_token_lifetime = 3600      # 1 hour in seconds
        self.extension_amount = 1800         # 30 minutes in seconds
        self.max_token_lifetime = 28800      # 8 hours in seconds
    
    async def extend_token_on_activity(self, token_payload: dict) -> dict:
        """Extend token lifetime based on user activity"""
        current_time = int(time.time())
        token_iat = token_payload.get('iat')  # Initial issue time
        token_exp = token_payload.get('exp')  # Current expiry
        
        # Calculate maximum allowed expiry (8 hours from initial issue)
        max_expiry = token_iat + self.max_token_lifetime
        
        # Calculate new expiry (current time + 30 minutes)
        new_expiry = current_time + self.extension_amount
        
        # Use the earlier of: new_expiry or max_expiry
        final_expiry = min(new_expiry, max_expiry)
        
        # Only extend if we're actually extending the lifetime
        if final_expiry > token_exp:
            token_payload['exp'] = final_expiry
            return token_payload
        
        return token_payload  # No extension needed/possible
    
    async def should_extend_token(self, token_payload: dict) -> bool:
        """Check if token can be extended further"""
        current_time = int(time.time())
        token_iat = token_payload.get('iat')
        token_exp = token_payload.get('exp')
        
        # Check if token hasn't reached maximum lifetime
        max_expiry = token_iat + self.max_token_lifetime
        
        # Extend if token is still valid and hasn't reached max lifetime
        return token_exp < max_expiry and token_exp > current_time
    
    async def extend_token_if_needed(self, request, response):
        """Middleware to handle automatic token extension on activity"""
        token = self.extract_access_token(request)
        if not token:
            return
        
        try:
            payload = self.decode_token(token)
            
            if await self.should_extend_token(payload):
                # Extend token lifetime
                extended_payload = await self.extend_token_on_activity(payload)
                
                # Generate new token with extended expiry
                new_token = await self.generate_access_token_from_payload(extended_payload)
                
                # Set new cookie with extended expiry
                self.set_access_token_cookie(response, new_token)
                
        except TokenExpiredError:
            # Token already expired, let normal refresh flow handle it
            pass
```

### Frontend Integration

```javascript
class AuthService {
    constructor() {
        this.activityThrottle = 30000; // Track activity every 30 seconds max
        this.lastActivitySent = 0;
        this.setupActivityTracking();
    }
    
    setupActivityTracking() {
        // Track meaningful user interactions
        const activities = ['click', 'keydown', 'scroll', 'mousemove'];
        
        activities.forEach(event => {
            document.addEventListener(event, this.throttledActivityTrack.bind(this));
        });
    }
    
    throttledActivityTrack() {
        const now = Date.now();
        if (now - this.lastActivitySent > this.activityThrottle) {
            this.trackActivity();
            this.lastActivitySent = now;
        }
    }
    
    async trackActivity() {
        try {
            await fetch('/api/v1/auth/activity', {
                method: 'POST',
                credentials: 'include' // Include cookies
            });
        } catch (error) {
            // Silently fail - activity tracking is not critical
            console.debug('Activity tracking failed:', error);
        }
    }
}
```

## API Endpoints

### Activity Tracking Endpoint

```python
@router.post("/activity")
async def track_activity(
    current_user: User = Depends(get_current_user),
    token_service: TokenRefreshService = Depends(get_token_service)
):
    """Track user activity for token refresh decisions"""
    
    session_id = current_user.session_id  # From JWT payload
    await token_service.track_user_activity(current_user.id, session_id)
    
    return {"status": "activity_tracked"}

@router.post("/refresh")
async def refresh_token(
    request: Request,
    response: Response,
    auth_service: AuthService = Depends(get_auth_service)
):
    """Manual token refresh endpoint"""
    
    refresh_token = request.cookies.get('__Secure-trl_rt')
    if not refresh_token:
        raise HTTPException(status_code=401, detail="No refresh token")
    
    try:
        # Validate and rotate refresh token
        new_tokens = await auth_service.refresh_access_token(refresh_token)
        
        # Set new cookies
        auth_service.set_auth_cookies(response, new_tokens)
        
        return {"status": "tokens_refreshed"}
        
    except InvalidTokenError:
        # Clear invalid cookies
        auth_service.clear_auth_cookies(response)
        raise HTTPException(status_code=401, detail="Invalid refresh token")
```

## Middleware Integration

```python
class TokenRefreshMiddleware:
    def __init__(self, app, token_service: TokenRefreshService):
        self.app = app
        self.token_service = token_service
    
    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            request = Request(scope, receive)
            response = Response()
            
            # Process request
            await self.app(scope, receive, send)
            
            # Check for token refresh after successful request
            if response.status_code < 400:  # Only on successful requests
                await self.token_service.refresh_if_needed(request, response)
        
        else:
            await self.app(scope, receive, send)
```

## Security Considerations

### Activity Tracking Privacy
- Only track timing, not content of activity
- Use Redis with short TTL for activity data
- No persistent storage of user behavior patterns

### Token Refresh Security
- Maintain refresh token rotation on every use
- Implement reuse detection for security
- Clear all tokens on suspicious activity

### Rate Limiting
- Limit activity tracking calls to prevent abuse
- Throttle refresh attempts per session
- Monitor for unusual refresh patterns

## Performance Characteristics

### Redis Usage
- Activity keys: 5-minute TTL, minimal memory footprint
- O(1) operations for activity checks
- Automatic cleanup via TTL expiration

### Network Overhead
- Activity tracking: ~50 bytes per call, max every 30 seconds
- Background refresh: Only when needed, transparent to user
- No additional round trips for normal operations

---

**Related Documentation:**
- [Authentication](./03-authentication.md) - Core authentication architecture
- [Security & Compliance](./14-security-compliance.md) - Security considerations
- [Performance & Scaling](./13-performance-scaling.md) - Performance optimization
