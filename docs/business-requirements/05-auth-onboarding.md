# Authentication, Registration, and Onboarding

## Authentication Flow

```mermaid
flowchart TD
    A[Anonymous Visitor] --> B{Wants to Post?}
    B -->|No| C[Browse Content]
    B -->|Yes| D[Redirect to Google OAuth]
    D --> E{Google Auth Success?}
    E -->|No| F[Show Error Message]
    E -->|Yes| G{Existing User?}
    G -->|Yes| H[Generate JWT Tokens]
    G -->|No| I[Create New User Account]
    I --> J[Overlord Onboarding Flow]
    J --> K[Show Platform Rules]
    K --> L[Explain Moderation Process]
    L --> M[Complete Registration]
    M --> H
    H --> N[Set Secure Cookies]
    N --> O[Redirect to Platform]
    
    style D fill:#ff4757,stroke:#fff,color:#fff
    style J fill:#74b9ff,stroke:#fff,color:#fff
    style H fill:#4ecdc4,stroke:#fff,color:#fff
```

## Onboarding User Journey

```mermaid
journey
    title New Citizen Onboarding Experience
    section Discovery
      Browse topics: 5: Anonymous
      Read posts: 5: Anonymous
      View leaderboard: 4: Anonymous
      Try to post: 3: Anonymous
    section Authentication
      Click "Submit Statement": 2: Anonymous
      See auth prompt: 3: Anonymous
      Google OAuth: 4: Anonymous
      Account created: 5: Citizen
    section Overlord Introduction
      Meet the Overlord: 5: Citizen
      Learn moderation rules: 4: Citizen
      Understand loyalty system: 4: Citizen
      See queue system: 3: Citizen
    section First Interaction
      Submit first post: 3: Citizen
      Watch queue position: 4: Citizen
      Receive Overlord feedback: 5: Citizen
      Understand the game: 5: Citizen
```

## Authentication Method

**Single provider. Google only.**

## Anonymous Browsing

The entire application is visible to anonymous visitors, including topics, posts, leaderboard, and registry.

## Onboarding Trigger

If an anonymous visitor attempts to submit a post or create a topic, they are guided through Overlord-narrated onboarding and authentication before anything enters the appropriate evaluation queue.

## Onboarding Content

The Overlord explains:
- That all content is judged for logic and tone.
- That tags are assigned by the Overlord.
- That posts can be approved, calibrated, or rejected.
- That rejected posts can be appealed under limits.

---

**Related Documentation:**
- [Look & Feel](./03-look-feel.md) - Overlord voice and tone
- [Posts & Moderation](./07-posts-moderation.md) - Evaluation process
- [Technical: Authentication](../technical-design/03-authentication.md) - Implementation details
