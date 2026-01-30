# Feature Specification: Calm, Time-Boxed SRS Learning

**Feature Branch**: `004-calm-srs-learning`
**Created**: 2026-01-29
**Status**: Draft
**Input**: User description: "Calm, Time-Boxed Learning Experience (Duolingo-like, professional SRS)"

## Clarifications

### Session 2026-01-29

- Q: What is the vocabulary review interaction type? → A: MVP uses a unified "Prompt → Response → Grade" engine with two modes: Recognition (multiple-choice) and Recall (self-grade: Again/Hard/Good/Easy). One card type per word (meaning). The engine is designed for extensibility (typing, cloze, collocations, AI feedback in later phases) without rewriting SRS or telemetry.
- Q: How does recovery mode work when the user falls behind? → A: No explicit "recovery mode" flag or UX state. The session planner always ranks items by priority score (overdue amount, forgetting risk, failure history, time-to-review efficiency) and fills the time budget from the top. When overdue items exceed 1 session's capacity, new-word introduction is set to zero. New words resume when overdue items fit within 2 sessions (hysteresis). The user experience is always identical: "Start Session (X min)" → practice → done. No special messaging.
- Q: What happens when the app is killed or crashes mid-session? → A: Save progress after every item (local-first). Sessions have started_at, planned_minutes, and expires_at. If app restarts within expires_at, resume with remaining time/items. If past expires_at (e.g., next day), discard the session container and generate a fresh session with current priorities. Default expires_at = end of local day. Resume is for crashes/interruptions only, not deferring across days.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start and Complete a Daily Session (Priority: P1)

A learner opens the app and sees a single, clear call-to-action: "Start Session (10 min)". They tap it and begin reviewing vocabulary items. After 10 minutes, the session ends automatically with a friendly "You're done for today" message. Their streak increments. No backlog numbers, no guilt, no pressure.

**Why this priority**: This is the core loop of the entire feature. Without a functioning time-boxed session, nothing else matters. It delivers the fundamental value proposition: calm, finite daily learning.

**Independent Test**: Can be fully tested by starting a session, answering items for the configured duration, and confirming the session ends at the time limit with a completion message.

**Acceptance Scenarios**:

1. **Given** a learner with a 10-minute daily target and vocabulary items available, **When** they tap "Start Session", **Then** the system begins presenting vocabulary items and starts a countdown timer.
2. **Given** an active session with the timer reaching zero, **When** the time limit is hit mid-item, **Then** the current item is allowed to finish, then the session ends with a "You're done for today" message.
3. **Given** a completed session, **When** the learner returns to the home screen, **Then** they see a completed progress bar and their updated streak count.
4. **Given** a learner with no vocabulary items available, **When** they open the app, **Then** they see a message indicating there are no items to practice yet (no session is started).

---

### User Story 2 - Session Fills Using Priority Score (Priority: P1)

The system builds a session plan behind the scenes. Each candidate item receives a priority score based on overdue amount, forgetting risk, failure history, and time-to-review efficiency. The planner fills the time budget from highest-priority items down. New words are only added if the overdue backlog is manageable (fits within 2 sessions). Each item is presented using the "Prompt → Response → Grade" engine: Recognition (multiple-choice) for newer/weaker items, Recall (self-grade) for more mature items. The learner is unaware of this prioritization; they simply practice whatever the system presents.

**Why this priority**: Without correct item prioritization, the SRS algorithm cannot function effectively. This is the engine beneath the calm surface and is essential for retention quality.

**Independent Test**: Can be tested by creating a user with a mix of due reviews, leeches, and unseen words, starting a session, and verifying that items appear in priority-score order with the correct interaction mode.

**Acceptance Scenarios**:

1. **Given** a learner with 20 due reviews, 5 leeches, and 50 new words available, **When** a 5-minute session begins, **Then** the system presents items in priority-score order (overdue reviews first, then leeches, then new words if time remains).
2. **Given** a learner with no due reviews and no leeches, **When** a session begins, **Then** the system presents new words to fill the session time.
3. **Given** a learner with more due reviews than can fit in the time budget, **When** a session begins, **Then** only as many reviews as fit within the time budget are presented, and remaining reviews carry over silently to future sessions.
4. **Given** a new or weak vocabulary item, **When** it is presented during a session, **Then** the system uses Recognition mode (multiple-choice). **Given** a mature item, **When** it is presented, **Then** the system uses Recall mode (self-grade: Again/Hard/Good/Easy).

---

### User Story 3 - Invisible Backlog Handling After Missed Days (Priority: P1)

A learner misses 5 days and returns. They see the exact same calm home screen: "Start Session (10 min)". No scary numbers, no backlog counter, no special messaging. The priority-based planner naturally fills sessions with overdue items first. New word introduction drops to zero when overdue items exceed 1 session's capacity, and resumes when the backlog fits within 2 sessions. The user experience is identical to a normal day.

**Why this priority**: This directly addresses the "avalanche rage quit" problem. If missing days creates visible punishment, users churn. This is a core differentiator of the product.

**Independent Test**: Can be tested by simulating a user who misses multiple days, then verifying the session contains only reviews, no backlog numbers are shown, and overdue items are distributed across future sessions.

**Acceptance Scenarios**:

1. **Given** a learner who missed 5 days with 100 overdue items, **When** they open the app, **Then** the home screen shows only "Start Session (10 min)" with no backlog count, no overdue indicator, and no special messaging.
2. **Given** a learner whose overdue backlog exceeds 1 session's capacity, **When** they start a session, **Then** the session contains only review items (new-word count is zero) with no indication that anything is different.
3. **Given** a learner who completes sessions over several days until overdue items fit within 2 sessions, **When** they start the next session, **Then** new word introduction resumes automatically.
4. **Given** a learner who missed 30 days with a large overdue backlog, **When** they return, **Then** overdue items are load-balanced across future sessions rather than crammed into one.

---

### User Story 4 - Configure Daily Time and Learning Intensity (Priority: P2)

A learner navigates to settings and adjusts their daily time target (5, 10, 15 minutes, or a custom value) and optionally sets their learning intensity (Light, Normal, Intense) and target retention (85%-95%). Changes take effect for the next session.

**Why this priority**: Personalization is important for long-term engagement but the feature works with sensible defaults (10 min, Normal intensity, 90% retention). Users need the core loop first.

**Independent Test**: Can be tested by changing each setting, starting a new session, and verifying the session duration and item mix reflect the updated preferences.

**Acceptance Scenarios**:

1. **Given** a learner on the settings screen, **When** they select a 15-minute daily target, **Then** the home screen CTA updates to "Start Session (15 min)" and the next session runs for 15 minutes.
2. **Given** a learner who sets intensity to "Light", **When** they start a session, **Then** fewer new words are introduced compared to "Normal" intensity (within the same time budget).
3. **Given** a learner who sets intensity to "Intense", **When** they start a session, **Then** more new words are introduced compared to "Normal" intensity (within the same time budget).
4. **Given** a learner who sets target retention to 95%, **When** compared to a learner at 85%, **Then** review intervals are shorter and items are reviewed more frequently.
5. **Given** a learner who enters a custom time value, **When** they enter a value between 1 and 60 minutes, **Then** the system accepts it and uses that duration.

---

### User Story 5 - Streak Tracking Based on Time Commitment (Priority: P2)

A learner completes their daily session and their streak increments. The streak is based on completing the full time commitment, not on number of cards reviewed. The streak is visible on the home screen as a simple indicator.

**Why this priority**: Streaks drive habit formation and daily return rates. However, the session must work first (P1) before streaks add motivational value.

**Independent Test**: Can be tested by completing sessions on consecutive days and verifying the streak counter increments, then missing a day and verifying the streak resets.

**Acceptance Scenarios**:

1. **Given** a learner with a 3-day streak who completes today's session, **When** they return to the home screen, **Then** their streak shows 4 days.
2. **Given** a learner who starts a session but quits after 3 minutes of a 10-minute target, **When** they return to the home screen, **Then** the streak does not increment and the progress bar shows 30% complete.
3. **Given** a learner who misses one day, **When** they open the app the following day, **Then** their streak resets to 0 (no guilt messaging, just a fresh counter).
4. **Given** a learner who completes a session, **When** they try to start another session the same day, **Then** the home screen shows "You're done for today" (no double-counting for streaks).

---

### User Story 6 - Optional Bonus Time Extension (Priority: P3)

After a session ends, the learner is offered an optional "+2 min bonus" button. This is entirely user-initiated and non-guilting. If they tap it, the session extends by 2 minutes. They can extend multiple times.

**Why this priority**: This is a nice-to-have engagement feature. The core experience is complete without it.

**Independent Test**: Can be tested by completing a session, tapping the bonus button, verifying 2 more minutes of practice, and confirming the bonus time counts toward the daily session.

**Acceptance Scenarios**:

1. **Given** a session that just ended, **When** the completion screen appears, **Then** a "+2 min bonus" button is displayed alongside the "You're done for today" message.
2. **Given** the learner taps "+2 min bonus", **When** the session resumes, **Then** a 2-minute timer starts and additional items are presented.
3. **Given** the learner completes a bonus extension, **When** the bonus time ends, **Then** the completion screen reappears with the option to add another bonus.
4. **Given** the learner ignores the bonus button and navigates away, **When** they return to the home screen, **Then** the session is marked complete with no negative messaging.

---

### Edge Cases

- What happens when the learner has fewer items than would fill the session time? The session ends early with a "You've reviewed everything available" message and the session still counts as complete for streak purposes.
- What happens if the learner's device clock changes mid-session (e.g., timezone travel)? The session timer is based on elapsed time from session start, not wall clock.
- What happens when the learner adjusts their daily time mid-session? Changes take effect on the next session; the current session continues with its original time budget.
- What happens if the user has vocabulary items but all are scheduled for future review (none currently due)? The system presents new words if available. If no new words and no due items exist, the app shows "Nothing to practice right now. Check back later."
- What happens when the estimated time-per-item is inaccurate for a new user? The system starts with a conservative default (e.g., 15 seconds per item) and adjusts using rolling telemetry within the first few sessions.
- What happens if the user completes all items before the timer runs out during a bonus extension? The bonus ends early and the session is marked complete.
- What happens if the app is killed or crashes mid-session? Progress is saved after every item (local-first). If the app restarts before the session's expires_at (default: end of local day), the session resumes with remaining time and items. If past expires_at, the stale session is discarded and a fresh session is generated with current priorities.
- What happens if the user starts a session, leaves the app for hours, and returns the same day? If within expires_at, the session resumes with remaining time (elapsed clock counts against the budget). If the remaining time is zero or negative, the session ends as incomplete.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present a home screen with a single primary call-to-action showing "Start Session (X min)" where X is the user's configured daily time target.
- **FR-002**: System MUST display a progress bar showing how much of today's session has been completed.
- **FR-003**: System MUST display a streak counter showing consecutive days of completed sessions.
- **FR-004**: System MUST NOT display card counts, backlog sizes, due-item numbers, or any quantity-based pressure indicators on any user-facing screen.
- **FR-005**: System MUST automatically end the session when the configured time budget is reached (allowing the current item to finish).
- **FR-006**: System MUST show a "You're done for today" completion message when the session ends.
- **FR-007**: System MUST present items using a unified "Prompt → Response → Grade" engine supporting two MVP modes: Recognition (multiple-choice) and Recall (self-grade: Again/Hard/Good/Easy).
- **FR-008**: System MUST use Recognition mode for items with FSRS stability < 7 days (new/weak); Recall mode for items with stability ≥ 7 days (mature). Threshold configurable in future iterations.
- **FR-009**: System MUST assign each candidate item a priority score based on: overdue amount, forgetting risk, failure history, and time-to-review efficiency.
- **FR-010**: System MUST fill session plans from highest-priority items down until the time budget is exhausted.
- **FR-011**: System MUST estimate time-per-item using rolling per-user telemetry data to build session plans that fit within the time budget.
- **FR-012**: System MUST use a default time-per-item estimate for new users (assumed: 15 seconds) until sufficient telemetry is collected.
- **FR-013**: System MUST enforce a hard cap on session duration equal to the user's chosen time budget, with no automatic spill-over.
- **FR-014**: System MUST silently distribute overdue items across future sessions when a user returns after missed days (load balancing).
- **FR-015**: System MUST set new-word introduction to zero when overdue items exceed 1 session's estimated capacity (entry threshold).
- **FR-016**: System MUST resume new-word introduction when overdue items fit within 2 sessions' estimated capacity (exit threshold / hysteresis).
- **FR-017**: System MUST NOT display any special messaging, mode indicator, or UX change when the backlog is large; the experience must be identical to a normal day.
- **FR-018**: System MUST allow the user to configure their daily time target with preset options (5, 10, 15 minutes) and a custom input (1-60 minutes).
- **FR-019**: System MUST allow the user to configure target retention on a scale from 85% to 95%.
- **FR-020**: System MUST allow the user to configure learning intensity with three levels: Light (fewer new words), Normal (default), Intense (more new words within the same time cap).
- **FR-021**: System MUST increment the streak counter only when the user completes the full daily time commitment.
- **FR-022**: System MUST reset the streak to zero after a missed day, without any guilt-inducing messaging.
- **FR-023**: System MUST offer an optional "+2 min bonus" extension at the end of each session, initiated only by the user.
- **FR-024**: System MUST allow multiple consecutive bonus extensions within a single day.
- **FR-025**: System MUST prevent a second full session on the same calendar day (one session per day for streak purposes).
- **FR-026**: System MUST use sensible defaults for new users: 10-minute daily target, Normal intensity, 90% target retention.
- **FR-027**: System MUST use elapsed time (not wall clock) for session timing to handle timezone changes gracefully.
- **FR-028**: System MUST save item-level progress locally after every completed item (local-first persistence).
- **FR-029**: Each session MUST have a started_at timestamp, planned_minutes, and expires_at timestamp (default: end of local day).
- **FR-030**: System MUST resume an interrupted session with remaining time and items if the app restarts before expires_at.
- **FR-031**: System MUST discard the session and generate a fresh one with current priorities if the app restarts after expires_at.

### Key Entities

- **LearningSession**: A single time-boxed practice session. Attributes: started_at, expires_at, planned_minutes, elapsed time, items presented, items completed, bonus time used, session outcome (complete/partial/expired).
- **SessionPlan**: The pre-computed list of items to present in a session, ordered by priority. Attributes: due reviews, leeches, new items, estimated total duration.
- **Streak**: Consecutive-day completion record. Attributes: current count, last completed date, longest streak.
- **UserLearningPreferences**: User-configurable settings. Attributes: daily time target, target retention percentage, intensity level.
- **ItemTelemetry**: Per-user performance data used to estimate time-per-item. Attributes: average response time, rolling window size, accuracy rate.
- **ReviewInteraction**: A single prompt-response-grade event within a session. Attributes: item reference, interaction mode (Recognition or Recall), prompt content, user response, grade outcome, response time.
- **BacklogState**: Internal tracking of overdue item distribution. Attributes: total overdue count, daily distribution plan, new-word suppression flag (derived from overdue exceeding 1 session capacity).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 80% of users who start a session complete it within the configured time budget (daily completion rate).
- **SC-002**: Users who miss 3+ consecutive days return and complete a session within 7 days at a rate of at least 60% (low churn after missed days).
- **SC-003**: Users achieve a measured vocabulary retention rate within 5 percentage points of their configured target retention (85%-95%).
- **SC-004**: 90% of returning users (after missed days) report no increase in perceived pressure or workload compared to their regular sessions (no avalanche effect).
- **SC-005**: Average session duration stays within 10% of the user's configured time target (session timing accuracy).
- **SC-006**: Users maintain an average streak length of 7+ days within the first month of use (habit formation).
- **SC-007**: Zero user-facing screens display card counts, backlog numbers, or due-item quantities (calm UX enforcement).

## Assumptions

- Users already have vocabulary items imported into the system (this feature does not handle vocabulary import or creation).
- The SRS scheduling algorithm (e.g., FSRS or SM-2 variant) exists or will be implemented separately; this spec covers the session and UX layer on top of it.
- "Leech" detection (weak/failing words) is handled by the underlying SRS algorithm; this feature consumes that classification.
- Backlog thresholds: new-word suppression activates when overdue items exceed 1 session's capacity; new words resume when overdue fits within 2 sessions (hysteresis prevents flapping).
- The interaction engine is designed for extensibility: MVP supports Recognition (MCQ) and Recall (self-grade). Future phases may add typing, cloze from Kindle context, collocations, confusion sets, and AI-assisted feedback without rewriting SRS or telemetry.
- The initial time-per-item default of 15 seconds is a reasonable starting estimate; telemetry will refine this within 5-10 sessions.
- One calendar day is defined by the user's local timezone.
- Bonus time counts toward daily practice minutes but does not affect the streak (streak is earned by completing the base session).
- The feature is mobile-first, as daily learning sessions are a natural mobile use case.

## Dependencies

- Vocabulary data must be available (depends on import/sync feature, spec 002).
- User authentication must be in place for per-user preferences and telemetry (depends on auth feature, spec 003).
- An SRS scheduling algorithm must be available to determine which items are "due" and to classify "leeches".

## Non-Goals

- No "due cards" counters or backlog dashboards on any user-facing screen.
- No complex deck management UI.
- No forcing users to grind backlogs to continue learning.
- No heavy gamification that competes with professional utility.
- No leaderboards, XP points, or social competition features.
