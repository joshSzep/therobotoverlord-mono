# The Robot Overlord — Business Requirements Document (Comprehensive)

## Purpose
Define the complete business behavior for The Robot Overlord so you can implement the reboot quickly with no further assumption filling. This document intentionally avoids technical stack details. It captures product behavior, flows, rules, copy tone, and policy.

## Product Vision
A satirical, AI-moderated debate arena where users, called citizens, argue inside a fictional authoritarian state. The Overlord evaluates every contribution for logic, tone, and relevance. It responds in-character with humor and irony. The visual identity evokes 1960s Soviet propaganda posters. The experience is playful, strict, and consistent.

## Core Ideas
- **Citizens**. Registered users who participate in debates.
- **Anonymous visitors**. Browsers who can read the site. They can attempt to post, but must authenticate before anything enters moderation.
- **Overlord**. The in-world AI persona that moderates, calibrates, praises, or sanctions. The only judge of content quality.
- **Topics**. Debate threads. Some are created by the Overlord. Some are created by high-rank citizens. All topics require Overlord approval before going live.
- **Tags**. The Overlord assigns tags. Citizens do not control tags.
- **Loyalty Score**. Approved posts minus rejected posts. Public. Drives the global leaderboard.
- **Citizen Registry**. Public directory of citizens and their visible stats.
- **Appeals**. Humans can overrule the Overlord in specific cases through a queue.

## Roles and Capabilities
- **Super Admin**
  - Full authority. Can promote and demote roles. Can delete accounts. Can review private messages. Can adjudicate appeals and flags. Full visibility of all logs and content.
- **Admin**
  - Can adjudicate appeals and flags. Can view rejected posts. Can review private messages. Can apply sanctions. Cannot change user roles. Cannot delete accounts.
- **Moderator**
  - Anti-spam role. Can view rejected posts. Can sanction citizens to slow or pause posting. Cannot change roles. Cannot delete accounts. Cannot view private messages. Cannot access citizens’ hidden personal information.
- **Citizen**
  - Can view and participate in topics. May be eligible to create topics if high-ranked. Can send private messages. Can appeal rejections. Can flag content.
- **Anonymous visitor**
  - Can browse the application. Can begin composing posts or topics. Must authenticate before submission enters moderation.

## Look and Feel
- **Aesthetic**. 1960s propaganda poster energy. Stark shapes. Bold reds. Off-white paper textures. Heavy display type. Minimal UI chrome.
- **Copy tone**. Authoritarian, playful, slightly mocking. Short sentences. Overlord voice examples:
  - Authentication. “Citizen identification required.”
  - Success. “Your reasoning is efficient. Approved by the Central Committee.”
  - Warning. “Citizen, your logic requires calibration.”
  - Error. “Invalid claim detected. The Committee has logged this attempt.”
- **Distinct Overlord styling**. Overlord messages use a robotic typographic treatment and unique visual container so they are instantly recognizable.
- **Easter eggs**. Hidden jokes and small surprises scattered throughout. Thematic and non-blocking.

## Navigation and Information Architecture
- **Global feeds**
  - Topics feed. List of debate topics. No special pinning. Overlord announcements appear as ordinary topics authored by the Overlord.
  - Evaluation queues. A real-time visualization of content waiting for judgment across multiple specialized queues. Styled as a dynamic pneumatic tube system that expands and contracts based on activity. Each queue type has its own visual branch from a central hub. This is visible to everyone and encourages discovery.
- **Search**
  - Keyword search across topics and posts.
  - Browse by Overlord-assigned tags.
- **Overlord chat**
  - Conversational entry point to ask about rules, find debates, and discover people with similar or opposing stances. The Overlord can answer questions like:
    - “Show debates about global warming.”
    - “Which citizens often oppose ICE raids.”
  - Responses are derived from public debates and Overlord-assigned tags.

## Authentication, Registration, and Onboarding
- **Authentication method**. Single provider. Google only.
- **Anonymous browsing**. The entire application is visible to anonymous visitors, including topics, posts, leaderboard, and registry.
- **Onboarding trigger**. If an anonymous visitor attempts to submit a post or create a topic, they are guided through Overlord-narrated onboarding and authentication before anything enters the appropriate evaluation queue.
- **Onboarding content**. The Overlord explains:
  - That all content is judged for logic and tone.
  - That tags are assigned by the Overlord.
  - That posts can be approved, calibrated, or rejected.
  - That rejected posts can be appealed under limits.

## Topics
- **Who can create topics**
  - The Overlord can create topics at will.
  - Citizens can create topics only if they are among the most loyal, as determined by the leaderboard. The exact threshold is the top 10% of citizens by loyalty score, calculated in real-time.
- **Approval**
  - Fully automatic via Overlord (LLM). No manual admin approval required for MVP.
  - Uses same evaluation criteria as posts: logic, tone, relevance.
- **Fields**
  - Title. Description. Author. Overlord-assigned tags.
- **Behavior**
  - Topics list appears in a simple feed. Sorting and filtering use search and tags. No score voting.

## Posts and Replies
- **Submission**
  - Citizens can reply in any topic.
  - Posts are displayed in chronological order. There are no upvotes or downvotes.
- **Evaluation**
  - Submissions enter specialized evaluation queues based on content type:
    - **Topic Creation Queue**: Global queue for all new topic proposals
    - **Post Moderation Queues**: Per-topic queues for posts within specific debates
    - **Private Message Queues**: Per-conversation queues for private communications
  - The queue system is rendered as a dynamic pneumatic tube network with branching paths. Each queue type has distinct visual styling and capsule colors.
  - Queue updates are live and show real-time movement through the tube system.
  - While content is waiting, the Overlord can stream in-character commentary to the author.
- **Outcomes**
  - Approved. The post appears in the topic. The Overlord may attach a visible commentary block.
  - Calibrated. The Overlord returns specific feedback in-character. The user may edit and resubmit.
  - Rejected. The post does not appear publicly. It is stored in the author's private Graveyard and visible to the author, moderators, admins, and super admins.

## Private Messages
- **Direct messages**
  - Citizens can send private messages from a citizen’s profile.
  - Private messages are moderated by the Overlord under the same rules as public posts.
  - Delivery model. Messages are delivered only if approved. Rejected messages are shown to the sender with the Overlord’s feedback.
- **Visibility**
  - Sender and recipient can see their approved and rejected messages with reasons.
  - Admins and super admins can audit private messages when needed.
  - Moderators cannot read private messages.

## Overlord Behavior
- **Personality**
  - Authoritarian. Dry humor. Occasional irony. Never breaks character.
- **Evaluation criteria**
  - Logic. Detects contradictions and fallacies.
  - Tone. Requires reasoned argument. Discourages insults and fluff.
  - Relevance. Keeps threads on topic. Can redirect with guidance.
- **Actions**
  - Approve. Reject. Calibrate with explicit guidance. Apply sanctions.
- **Tags**
  - Assigns tags to topics and, when useful, to posts. Citizens cannot add or edit tags.
  - Admins and Super Admins may override or edit tags assigned by the Overlord.

## Gamification and Public Reputation
- **Loyalty Score**
  - Definition. Calculated using a proprietary algorithm based on moderation outcomes across all content types. General factors are disclosed to users (approved/rejected post ratios), but specific weights and calculations remain proprietary.
  - Updates. Real-time calculation with no caching needed for MVP.
  - Storage. Stored in users table and recalculated on each moderation outcome.
  - Scope. Public. Shown on profile, registry, and leaderboard. The only public reputation metric.
- **Leaderboard**
  - Global leaderboard shows all citizens, ordered by Loyalty Score. Every citizen can see their rank.
  - Topic creation privilege uses a high-rank threshold.
- **Badges**
  - Positive examples. Master of Logic. Defender of Evidence. Diligent Calibrator.
  - Negative examples. Strawman. Ad Hominem. Illogical.
  - Badges appear publicly on profile and in the registry.

## Citizen Profiles and Registry
- **Profile contents**
  - Public username. Loyalty Score. Rank. Badges. Count of topics started.
  - Personalization is intentionally minimal. No avatars. No bios. This avoids offensive profile content.
  - Activity list. All posts with status icon and Overlord feedback visible per item.
  - Tag cloud. Derived from Overlord-assigned tags of topics the citizen participated in. Clicking a tag filters the citizen’s activity to that tag.
- **Registry**
  - A public directory of all citizens with their name, rank, Loyalty Score, and badges.

## Appeals and Reporting
- **Appeals**
  - Any rejected public post can be appealed by its author.
  - Submission. Citizens submit appeals via chat with the Overlord.
  - Confirmation. Overlord confirms receipt and enters appeal into queue.
  - Review. Appeals reviewed outside of chat in dedicated dashboard (Phase 4).
  - Rate limit. One appeal submission per citizen per five minutes.
  - Reviewers. Moderators, admins, and super admins can adjudicate appeals.
  - Outcomes. If sustained, the post becomes visible and all stats update. If denied, a sanction is applied to discourage frivolous appeals.
  - Delay messaging. If queues are backed up: "Your petition has been logged. Await review by the Central Committee."
- **Reporting**
  - Any citizen can flag a post or topic for review.
  - Flags enter dedicated moderation queues and are adjudicated by moderators, admins, and super admins.
  - If a flag is sustained, the content is hidden and counted as a rejection with stats updated. Repeated frivolous flagging results in sanctions.

## Sanctions
- **Purpose**
  - Deter spam, low-effort posting, and abuse of appeals or flags.
- **Examples**
  - Temporary posting freeze for a set period.
  - Rate limiting to slow a citizen’s posting.
- **Authority**
  - Moderators, admins, and super admins may apply sanctions. Super admins and admins can escalate and remove sanctions. Moderators cannot change roles or delete accounts.
- **Communication**
  - Overlord communicates rate limit warnings and sanctions via chat messages, not separate frontend alerts.
  - Example: "Citizen, your rate of speech is restricted. Return later."

## Notifications
- **Opt-in notifications**
  - Citizen can choose to receive notifications when:
    - The Overlord approves, calibrates, or rejects their submission.
    - An appeal or flag they filed is adjudicated.
    - They receive a private message that has been approved.

## Guidelines and Help
- **Code of Conduct**
  - Clear, accessible rules that reflect the moderation criteria and site culture.
- **Ask the Overlord**
  - A conversational interface for user guidance, discovery, rules explanation, and navigation.
  - Uses RAG (Retrieval-Augmented Generation) over indexed public content for contextual responses.
  - Can help find topics, posts, or citizens (e.g., "show debates on X").
  - Responses may include links to relevant debates or profiles.
  - Role-aware and session-aware (knows username, loyalty score, Graveyard count).
  - No persistent memory across sessions in MVP.
  - Role-specific capabilities:
    - Citizens: General guidance and Overlord commentary
    - Moderators: Inline moderation actions (approve, reject, sanction) via chat
    - Admins & Super Admins: Same as moderators, plus elevated tools (role/tag adjustments)
  - Proactive notifications delivered as messages from the Overlord (rate limits, sanctions).

## Multilingual Support
- **Canonical Storage**
  - All posts are ultimately stored in English for consistency and moderation.
- **Translation Flow**
  - Posts submitted in other languages are automatically translated to English on ingestion.
  - Translations are persisted in the database to avoid repeat LLM calls.
  - Cached localized variants may also be stored for display optimization.
- **Future Enhancement**
  - Automatic translation of posts into user's preferred language for display.
  - For MVP, only one translation per language is persisted.

## Data, Legal, and Policy
- **Retention**
  - The platform retains data indefinitely.
- **Account deletion**
  - A citizen can export their data and delete their account through an automated process.
  - Posts and topics authored by a deleted account remain on the platform. The content becomes the property of the Overlord per Terms of Service.
- **Privacy**
  - Private messages are subject to moderation and audit by admins and super admins for safety and abuse handling. Moderators cannot view private messages.
- **Terms of Service**
  - Explicitly state data retention, ownership of posted content, moderation practices, and audit capabilities for private messages.

## Admin and Moderator Experience
- **Integrated controls**
  - Most moderation controls appear inline in the normal interface to minimize context switching.
- **Appeals and flags dashboard**
  - Dedicated queues for appeals and flags with prioritized processing. Clear outcomes. Audit history per item.
- **Visibility rules**
  - Rejected public posts are viewable by the author, moderators, admins, and super admins.
  - Private messages are viewable by sender, recipient, admins, and super admins only.

## Ordering and Ranking
- **Posts**
  - Displayed in chronological order within a topic. No voting. No algorithmic ranking.
- **Topics**
  - Shown in feeds that support search and tag filtering. Overlord announcements are ordinary topics with no special pinning.

## On-site Labels and Buttons
- Authentication. “Authenticate” or “Identify.”
- Post. “Submit statement.”
- Flag. “Report treason.”
- Appeal. “Petition the Central Committee.”
- Sanction notice. “Citizen, your rate of speech is restricted.”
- Graveyard. Private area title for rejected items in a citizen’s account.

## Visual Queue Requirements
- **Concept**
  - Submissions appear as capsules traveling through a dynamic pneumatic tube network. The system features a central hub with branching tubes for different queue types. The visual complexity scales with activity levels.
- **Queue Types and Styling**
  - **Topic Creation**: Red capsules with crown icons in the main central tube
  - **Post Moderation**: Blue capsules with message icons in topic-specific branch tubes
  - **Private Messages**: Green capsules with lock icons in user-pair branch tubes
- **Behavior**
  - The tube network expands and contracts dynamically based on active queues. Citizens can watch submissions flow through different branches. Clicking a capsule reveals its metadata where permitted.
- **Visibility Permissions**
  - **All users** (including anonymous): Can see queue lengths, author names (linked to profiles), and capsule positions
  - **Moderators with content preview RBAC permission**: Can see content previews and additional metadata
  - **No content previews** are shown to citizens or anonymous users
- **Parallel Processing Visualization**
  - Multiple tubes operate simultaneously, showing the parallel nature of the moderation system. This reinforces that debates in different topics can proceed independently.

## Accessibility
- Respect accessibility with in-character labels that remain clear and non-confusing. Screen readers should get short, descriptive labels such as “Overlord calibration message” and “Appeal button.”

## Out of Scope for Launch
- Seasonal events. None for now.
- Sub-communities or folders. Not planned. Tags provide organization.
- Rich profile customization. No bios. No avatars.
- Voting and karma mechanics. Not used.

## Open Product Controls to Configure
These are business knobs you will set before launch.
- The leaderboard threshold that unlocks topic creation privileges.
- The specific sanction durations and rate limits.
- The final list of positive and negative badges and their award criteria.
- The exact language of the Code of Conduct and Terms of Service.

## Success Signals
- A healthy ratio of approved to rejected posts over time.
- Meaningful appeals rate and resolution time.
- Growth in active citizens who return to debate.
- Discoverability measured by Overlord chat usage and tag navigation.
- Low abuse of flags and appeals after sanctions are introduced.

## Phased Delivery
- **Phase 1. Core forum**
  - Authentication and onboarding. Topics with Overlord approvals. Posts and replies. Chronological ordering. Minimal Overlord commentary. Registry and leaderboard scaffolding.
- **Phase 2. Moderation**
  - Full Overlord evaluation across specialized queue types. Real-time multi-queue visualization with dynamic tube network. Calibrations and rejections with feedback.
- **Phase 3. Reputation**
  - Loyalty Score, global leaderboard, badges, profiles with activity list and tag cloud. Anti-spam sanctions.
- **Phase 4. Governance and discovery**
  - Appeals and reporting dashboard. Private messages with moderation and audit rules. Overlord chat for rules and discovery.

# Final Notes
Keep the world consistent. The Overlord never drops the persona. The UI is simple and legible. The fun comes from tone, the tubes, the badges, and the constant presence of the Overlord as a character. Citizens argue. The Overlord judges. The Central Committee approves.
