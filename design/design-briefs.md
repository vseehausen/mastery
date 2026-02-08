# Design Briefs for Mastery App Screens

These briefs are greenfield execution specs for design and implementation handoff.

## Global Requirements (All Briefs)

- Build on shadcn design system patterns and component behavior.
- Use existing design tokens for color, spacing, typography, radius, shadow, and motion.
- Do not hardcode visual values that already exist as semantic tokens.
- Deliver light and dark variants with the same semantic structure.
- Support core states: default, loading, empty (where applicable), error, disabled.
- Keep mobile-first ergonomics: clear hierarchy, thumb-safe interactions, stable layouts.

---

## Design Brief 1: Auth Flow

**Screens:** AuthScreen, EmailSignInScreen, EmailSignUpScreen, OAuthLoadingScreen  
**Files:** `lib/features/auth/presentation/screens/`

### Purpose
Establish trust and clarity in the first-run experience and minimize friction to account access.

### Design Direction
- Simple, high-clarity onboarding surface with one primary action focus per step.
- Consistent form and button behavior based on shadcn patterns.
- Fast feedback for validation and async auth states.

### Information Architecture
1. Welcome and method selection (OAuth + email path)
2. Email Sign Up flow
3. Email Sign In flow
4. OAuth handoff/loading and return handling

### Scope
- Welcome screen with brand area, provider actions, and email CTA.
- Sign-up form: name, email, password, validation and error handling.
- Sign-in form: email, password, forgot-password entry point.
- OAuth loading state with progress feedback and fallback messaging.

### States
- Default
- Field validation error
- Submission loading
- Network/auth failure
- Success (handoff or signed-in destination)

### Key Interactions
- OAuth provider selection
- Password visibility toggle
- Inline validation feedback
- Sign up and sign in cross-navigation

### Constraints
- Mobile single-column layout.
- Primary CTA always visible without confusion.
- Error feedback must be specific and recoverable.

### Deliverables
1. Auth flow screen set (light/dark, all states).
2. Form interaction spec (validation, disabled/loading, error handling).
3. OAuth loading/return state spec.
4. Token-mapped implementation notes for listed files.

---

## Design Brief 2: Session + Card Experience

**Screens:** SessionScreen + RecallCard, RecognitionCard, DefinitionCueCard, SynonymCueCard, ClozeCueCard, DisambiguationCard  
**Files:** `lib/features/learn/screens/session_screen.dart`, `lib/features/learn/widgets/`

### Purpose
Core daily learning loop used for 3-8 minutes. The experience should feel focused, responsive, and deliberate.

### Design Direction
- Build on shadcn interaction patterns for controls, surfaces, and overlays.
- Prioritize low-latency feedback and clear progression through each card.
- Keep visual hierarchy strong with minimal cognitive noise.

### Information Architecture
1. Persistent session chrome (top)
2. Current card content (center)
3. Primary action zone (bottom)
4. Temporary overlays (pause, saving, error, confirm-close)
5. Transition layer (card swap and feedback)

### Scope

**A. Session Chrome**
1. Close (X) button
2. Timer (circular progress + MM:SS)
3. Pause/Play toggle
4. Progress bar (items completed / total)

**B. Card Types (shared structural system)**
1. RecallCard
2. RecognitionCard
3. DefinitionCueCard
4. SynonymCueCard
5. ClozeCueCard
6. DisambiguationCard

**C. Shared Grade Button Row**
- Again / Hard / Good / Easy
- Semantic intent mapping via DS tokens

**D. States**
- Card unrevealed / revealed / grading / saving
- Correct and incorrect feedback (recognition/disambiguation)
- Paused overlay
- Loading next batch
- Error with retry

### Interaction and Motion Contract
- Use `AppAnimation` tokens for reveal, feedback, and card transitions.
- Reveal answer with smooth transition and stable layout.
- Grade tap: immediate press feedback, haptic signal, brief confirmation, then advance.
- MCQ tap: feedback window (800ms), then auto-advance.
- Pause and close actions use explicit overlay/dialog confirmation patterns.

### Layout and Content Constraints
- Grade buttons must be thumb-safe and confidently tappable.
- Helper text must remain visible in hierarchy.
- Long words must render safely without truncation failures.
- Context content supports 2-3 lines without action overlap.

### Deliverables
1. Session chrome and all card variants (light/dark, all states).
2. Reusable Grade Button Row component spec.
3. State and transition matrix.
4. Interaction spec for reveal, grade, feedback, pause, and close.
5. Token-mapped implementation notes for listed files.

---

## Design Brief 3: Words (Vocabulary List)

**Screen:** VocabularyScreenNew  
**File:** `lib/features/vocabulary/presentation/screens/vocabulary_screen.dart`

### Purpose
Provide a fast, browsable vocabulary library with efficient search and filtering.

### Design Direction
- Dense but readable information layout.
- Clear filter/search affordances with immediate response.
- Consistent list item patterns for scanning and navigation.

### Information Architecture
1. Screen header and utilities
2. Search input
3. Filter controls
4. Vocabulary list content
5. Empty/loading/error state surfaces

### Scope
- Search bar with clear/reset behavior.
- Filter chips/toggles for list subsets.
- Vocabulary row/card component for word metadata.
- Pull-to-refresh and skeleton loading treatment.
- Empty state with next-step guidance.

### States
- Default populated list
- Searching
- Filtered results
- Empty results
- Initial loading
- Refreshing
- Error with retry

### Key Interactions
- Type to filter results in real time
- Toggle filters
- Open word detail from list item
- Pull-to-refresh

### Constraints
- Must scale to large lists with smooth scrolling.
- Maintain at-a-glance readability for status metadata.
- Preserve stable layout while filtering/loading.

### Deliverables
1. Vocabulary list screen spec (light/dark, all states).
2. Search/filter interaction spec.
3. Reusable word list item component spec.
4. Token-mapped implementation notes for listed file.

---

## Design Brief 4: Vocabulary Detail

**Screen:** VocabularyDetailScreen  
**File:** `lib/features/vocabulary/vocabulary_detail_screen.dart`

### Purpose
Present complete word understanding context and provide immediate practice/action pathways.

### Design Direction
- Structured, sectioned reading experience with clear content hierarchy.
- Keep high-value actions prominent without crowding the content.
- Support both sparse and rich data gracefully.

### Information Architecture
1. Word header and status
2. Meaning and linguistic metadata
3. Encounter/context section
4. Cue preview section
5. Learning stats
6. Action row (practice/edit/re-enrich/feedback)
7. Optional advanced section

### Scope
- Section system with clear boundaries and spacing rhythm.
- "Practice now" action prominence strategy.
- Inline editing mode for meaning updates.
- Feedback and enrichment action treatment.

### States
- Fully enriched
- Partially enriched
- Minimal data
- Loading
- Editing
- Save in progress
- Error/retry

### Key Interactions
- Start practice from detail
- Expand/collapse advanced areas
- Edit and save meaning
- Submit enrichment feedback

### Constraints
- Must remain readable with long definitions and long context text.
- Must support deep scroll without losing action clarity.
- Section order should reduce cognitive load.

### Deliverables
1. Vocabulary detail screen spec (light/dark, all states).
2. Section and action hierarchy specification.
3. Inline edit interaction specification.
4. Token-mapped implementation notes for listed file.

---

## Design Brief 5: Today Screen (Home)

**Screen:** TodayScreen  
**File:** `lib/features/home/presentation/screens/today_screen.dart`

### Purpose
Serve as the daily decision point with one clear next action.

### Design Direction
- Single-focus home surface with immediate comprehension.
- Session readiness and progress should be visible at a glance.
- Keep decorative elements secondary to action clarity.

### Information Architecture
1. Header (title + settings access)
2. Primary hero card (today action/state)
3. Supporting progress/status block
4. Optional lightweight motivation element

### Scope
- Hero card variants for key session conditions.
- Progress indicator treatment integrated into hero or support block.
- Clear primary action strategy for each state.

### States
- No items available
- Session ready
- Session in progress
- Session complete
- Refreshing
- Error/retry

### Key Interactions
- Start session
- Resume session
- Open settings
- Pull-to-refresh

### Constraints
- One dominant action at all times.
- Avoid clutter and competing CTAs.
- Keep top-level status readable in under 2 seconds.

### Deliverables
1. Today screen spec (light/dark, all states).
2. Hero card variant system and action mapping.
3. Progress/status interaction notes.
4. Token-mapped implementation notes for listed file.

---

## Design Brief 6: Progress Screen

**Screen:** ProgressScreen  
**File:** `lib/features/progress/presentation/screens/progress_screen.dart`

### Purpose
Reinforce momentum through clear, motivating progress visibility.

### Design Direction
- Rewarding but restrained presentation.
- Focus on trend comprehension over complex charting.
- Maintain clarity for both new and advanced learners.

### Information Architecture
1. Streak summary
2. Mastery distribution
3. Vocabulary growth snapshot
4. Recent session list
5. Today's completion status

### Scope
- Simple data visualizations with accessible labeling.
- Streak and milestone emphasis.
- Recent session summaries with compact metadata.

### States
- Minimal data
- Standard data
- Rich history
- Loading
- Refreshing
- Error/retry

### Key Interactions
- Pull-to-refresh
- Navigate to related details from summary modules
- Review recent session entries

### Constraints
- Visualizations must be legible and simple.
- Avoid dense dashboards on small screens.
- Preserve motivational tone without gamified noise.

### Deliverables
1. Progress screen spec (light/dark, all states).
2. Visualization and labeling rules.
3. Module-level interaction specification.
4. Token-mapped implementation notes for listed file.

---

## Design Brief 7: Session Complete

**Screen:** SessionCompleteScreen  
**File:** `lib/features/learn/screens/session_complete_screen.dart`

### Purpose
Mark the end of a session with clear accomplishment feedback and a confident next step.

### Design Direction
- Reward moment with controlled emphasis.
- Keep actions obvious and low-friction.
- Present outcomes quickly before optional depth.

### Information Architecture
1. Completion header/visual
2. Session summary stats
3. Streak highlight
4. Follow-up actions (extend or finish)

### Scope
- Completion visual system.
- Stats presentation and priority.
- Action pair design: bonus extension and done.
- Optional variant messaging for different completion outcomes.

### States
- Full completion
- Partial completion (time-ended)
- Items exhausted
- Save in progress
- Error/retry

### Key Interactions
- Start bonus extension
- Finish and return
- Dismiss completion screen safely

### Constraints
- Celebration should be subtle and product-appropriate.
- Key stats must remain scannable.
- Primary next step must be unambiguous.

### Deliverables
1. Session completion screen spec (light/dark, all states).
2. Outcome variant system and copy guidance.
3. Action and transition interaction specification.
4. Token-mapped implementation notes for listed file.
