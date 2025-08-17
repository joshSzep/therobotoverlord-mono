# Token Refresh Strategy

## Overview

Seamless authentication experience with activity-based token refresh to prevent user interruption during active sessions.

## Token Lifecycle Management

### Access Token Strategy
- **Base Lifetime**: 15 minutes
- **Activity Window**: 5 minutes before expiry
- **Refresh Trigger**: Any user activity within the activity window

### Background Refresh Implementation

```python
class TokenRefreshService:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.activity_window = 300  # 5 minutes in seconds
        self.token_lifetime = 900   # 15 minutes in seconds
    
    async def track_user_activity(self, user_id: str, session_id: str):
        """Track user activity for token refresh decisions"""
        activity_key = f"activity:{user_id}:{session_id}"
        await self.redis.setex(activity_key, self.activity_window, int(time.time()))
    
    async def should_refresh_token(self, token_payload: dict) -> bool:
        """Determine if token should be refreshed based on activity"""
        user_id = token_payload.get('sub')
        session_id = token_payload.get('sid')
        token_exp = token_payload.get('exp')
        
        # Check if token is within refresh window
        current_time = int(time.time())
        time_until_expiry = token_exp - current_time
        
        if time_until_expiry > self.activity_window:
            return False  # Too early to refresh
        
        # Check for recent activity
        activity_key = f"activity:{user_id}:{session_id}"
        recent_activity = await self.redis.get(activity_key)
        
        return recent_activity is not None
    
    async def refresh_if_needed(self, request, response):
        """Middleware to handle automatic token refresh"""
        token = self.extract_access_token(request)
        if not token:
            return
        
        try:
            payload = self.decode_token(token)
            
            if await self.should_refresh_token(payload):
                # Generate new access token
                new_token = await self.generate_access_token(
                    user_id=payload['sub'],
                    session_id=payload['sid'],
                    permissions=payload['permissions']
                )
                
                # Set new cookie
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
