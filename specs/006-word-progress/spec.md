# Feature Specification: Word-Level Progress & Motivation

**Feature Branch**: `006-word-progress`
**Created**: 2026-02-08
**Status**: Draft
**Input**: User description: "PRD — Word-Level Progress & Motivation (Phase 3)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See Real-Time Progress During Learning (Priority: P1)

As a learner completing my daily session, I want to see immediate feedback when a word reaches a new progress stage, so I feel a sense of accomplishment and understand that my effort is building real competence.

**Why this priority**: This is the core value proposition—turning abstract learning activity into visible competence signals. Without this, users cannot experience the motivation benefit the feature provides.

**Independent Test**: Can be fully tested by completing a learning session with words at different stages and verifying that micro-feedback appears at the moment of stage transitions (e.g., "Stabilizing", "Active now"). Delivers immediate motivational value to users.

**Acceptance Scenarios**:

1. **Given** I'm reviewing a word that has had multiple successful recalls over time, **When** I answer correctly again during my session, **Then** I see brief micro-feedback "Stabilizing" displayed
2. **Given** I'm reviewing a word for the first time using a definition cue (non-translation), **When** I answer correctly, **Then** I see brief micro-feedback "Active now" displayed
3. **Given** I'm reviewing a word that doesn't meet any transition criteria, **When** I complete the review, **Then** no micro-feedback is shown (session continues smoothly)
4. **Given** I answer a word incorrectly, **When** the next card appears, **Then** no progress micro-feedback is shown for that word

---

### User Story 2 - Review Session Progress Summary (Priority: P2)

As a learner who just completed my session, I want to see a compact summary of which words advanced and how, so I understand the session's impact on my vocabulary competence without needing to check individual words.

**Why this priority**: Provides post-session reflection and reinforcement. Less critical than real-time feedback but essential for understanding cumulative progress over sessions.

**Independent Test**: Can be tested by completing a session where multiple words transition stages, then verifying the recap shows accurate counts (e.g., "2 words stabilized • 1 word became Active"). Delivers session-level accomplishment signal.

**Acceptance Scenarios**:

1. **Given** I just finished a session where 2 words stabilized and 1 became Active, **When** the session completes, **Then** I see a compact recap: "2 words stabilized • 1 word became Active"
2. **Given** I finished a session but no words changed stages, **When** the session completes, **Then** I see the standard "Done ✅" message without a progress recap
3. **Given** I finished a session where 1 word reached Mastered, **When** the session completes, **Then** the recap highlights this rare achievement prominently
4. **Given** I finished a session with multiple transition types, **When** I see the recap, **Then** transitions are summarized by type in order of significance (Mastered → Active → Stabilizing)

---

### User Story 3 - Track Word Progress Over Time (Priority: P3)

As a learner browsing my vocabulary list, I want to see each word's current progress stage, so I can gauge my overall vocabulary maturity and identify which words need more practice.

**Why this priority**: Supports long-term engagement and vocabulary management. Less urgent than in-session feedback but valuable for users who want to understand their vocabulary landscape.

**Independent Test**: Can be tested by viewing the vocabulary list and verifying that each word displays its current stage (Captured, Practicing, Stabilizing, Active, Mastered). Delivers portfolio-level competence awareness.

**Acceptance Scenarios**:

1. **Given** I'm viewing my vocabulary list, **When** I see a word I just captured from reading but haven't reviewed yet, **Then** its stage is shown as "Captured"
2. **Given** I'm viewing my vocabulary list, **When** I see a word I've been practicing in SRS, **Then** its stage is shown as "Practicing", "Stabilizing", "Active", or "Mastered" based on its learning history
3. **Given** I'm viewing my vocabulary list, **When** I filter or sort by progress stage, **Then** I can easily identify words at specific stages

---

### Edge Cases

- What happens when a word regresses (user forgets it after multiple lapses)? The stage should reflect current competence, potentially moving back from Active → Practicing if retrieval success drops
- How does the system handle words captured but never reviewed? They remain at "Captured" indefinitely until first review
- What happens when a user completes a session with only translation cues (no non-translation retrieval)? Words can progress to Stabilizing but not to Active
- How are simultaneous transitions handled (e.g., a word becomes both Stabilizing and Active in same session)? Show the highest/most significant transition only
- What happens if enrichment fails or is incomplete? Word remains at "Captured" (enrichment is informational only, doesn't block progression)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST track word progress through defined stages: Captured → Practicing → Stabilizing → Active → Mastered
- **FR-002**: System MUST update word stage based on logged learning events (captures, recalls, retrieval types, stability metrics)
- **FR-003**: System MUST display brief micro-feedback ("Stabilizing", "Active now") when a word transitions to a new stage during a session
- **FR-004**: System MUST generate a post-session recap summarizing progress transitions (e.g., "2 words stabilized • 1 word became Active")
- **FR-005**: System MUST only promote a word to "Active" after at least one successful non-translation retrieval (definition, synonym, or context cue)
- **FR-006**: System MUST display each word's current progress stage in the vocabulary list
- **FR-007**: System MUST determine progress stages using deterministic logic based solely on learning event data (no randomness or hidden factors)
- **FR-008**: System MUST NOT show backlog indicators, debt counters, or pressure signals related to word progress
- **FR-009**: System MUST maintain the timeboxed learning session model (session ends when time limit reached, not when progress goals met)
- **FR-010**: System MUST record sufficient learning event data to calculate stage transitions (recall success/failure, cue type, timestamp, stability metrics)
- **FR-011**: System MUST distinguish between translation-based retrieval (word → meaning) and non-translation retrieval (meaning/synonym/context → word)
- **FR-012**: System MUST make "Mastered" status difficult to achieve, requiring high stability, rare reviews, and low lapse rate

### Key Entities

- **Word Progress Stage**: Represents a word's current competence level (Captured, Practicing, Stabilizing, Active, Mastered). Derived from user-driven learning events and current SRS metrics.
- **Learning Event**: Represents a discrete user-initiated learning interaction (recall attempt, cue type used, success/failure). Logged with timestamp and sufficient detail to calculate stage transitions.
- **Stage Transition**: Represents a change from one progress stage to another, triggered by specific learning event patterns (e.g., first non-translation success → Active).
- **Session Recap**: Summary of stage transitions that occurred during a completed learning session, grouped by transition type for compact presentation.
- **Cue Type**: Classification of how a word was presented during recall (translation, definition, synonym, cloze, disambiguation). Used to determine eligibility for "Active" status.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 60% of users see one or more words reach "Active" status within their first 3 weeks of regular use
- **SC-002**: "Mastered" status is achieved by less than 5% of words in a typical user's vocabulary after 3 months
- **SC-003**: Success rate on non-translation cues (definition, synonym, context) increases by 15% within 6 weeks of feature launch
- **SC-004**: Average session completion time remains within 5% of pre-feature baseline (no increase in session friction)
- **SC-005**: Users perceive progress feedback as informational and motivating (90%+ positive sentiment in user feedback on progress micro-feedback)
- **SC-006**: Zero user complaints about feeling pressured or stressed by progress indicators
- **SC-007**: Users can explain how words advance through stages when asked (80%+ provide correct explanation in user interviews)
