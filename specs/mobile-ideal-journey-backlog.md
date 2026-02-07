# Mobile Ideal Journey Backlog

Last updated: 2026-02-07

## Epic 1: Navigation Simplification (P0)

Goal: reduce cognitive overhead and improve task focus by reducing primary tabs from 4 to 3.

### Stories

1. As a learner, I want a focused `Today` tab so I can start learning quickly.
2. As a learner, I want `Progress` grouped separately from daily action so I can review outcomes without distraction.
3. As a learner, I want Settings accessible without a dedicated tab so primary navigation stays simple.

### Tasks

- Replace 4-tab shell with 3 tabs: `Today`, `Words`, `Progress`.
- Update bottom nav labels/icons.
- Wire Settings access from `Progress` and `Today` header action.
- Regression-check tab switching and navigation stacks.

### Acceptance Criteria

- App launches with exactly 3 tabs.
- Learning session can be started from `Today`.
- Settings remains reachable in <=2 taps.

## Epic 2: Today Decision Screen (P0)

Goal: turn app-open into a clear decision and fast session start.

### Stories

1. As a learner with due cards, I can start or continue in one tap.
2. As a learner with no due cards, I understand what to do next.
3. As a learner, I can see essential day context (due, progress, streak).

### Tasks

- Build new `TodayScreen` with:
  - Hero card and primary CTA
  - Session state variants (start/continue/done/no-items)
  - Summary cards (due items, vocabulary count, streak/progress)
- Add link to `SyncStatusScreen` and `NoItemsReadyScreen`.
- Invalidate providers on refresh actions.

### Acceptance Criteria

- Primary CTA always visible above fold.
- No blank or ambiguous empty state.
- No placeholder/mock values shown.

## Epic 3: Session Entry & Recovery (P0)

Goal: provide explicit no-items and sync recovery paths.

### Stories

1. As a learner with no available items, I get a clear explanation and actions.
2. As a learner waiting on import/enrichment, I can inspect sync status.

### Tasks

- Add `NoItemsReadyScreen` with refresh and sync actions.
- Add `SyncStatusScreen` timeline/state model from available data:
  - no vocabulary imported
  - enrichment in progress
  - ready but no due items
  - ready to learn
- Add provider invalidation helpers for status refresh.

### Acceptance Criteria

- Users can recover from no-items state without dead-end.
- Sync status never shows spinner-only uncertainty.

## Epic 4: Progress Surface (P1)

Goal: show learning outcomes and controls in one place.

### Stories

1. As a learner, I can see streak and progress outcomes quickly.
2. As a learner, I can access learning preferences and account settings from Progress.

### Tasks

- Add `ProgressScreen` with key cards:
  - current/longest streak
  - words learned / due now
  - today completion
- Add quick actions:
  - open learning settings
  - open settings

### Acceptance Criteria

- Progress screen renders with loading/error states.
- Learning settings and settings navigation works.

## Epic 5: Design/System Consistency Cleanup (P1)

Goal: reduce visual inconsistency and dead-end controls.

### Tasks

- Remove non-functional placeholders from primary flows.
- Ensure consistent button hierarchy and copy tone.
- Validate all new screens in light/dark modes.

### Acceptance Criteria

- No user-facing “not yet implemented” in primary journey screens.
- CTA styles and spacing are consistent across new screens.

## QA and Validation Checklist

- `flutter analyze` passes with zero issues.
- `flutter test` passes (or failures documented).
- Manual check of 3-tab shell and each new screen path:
  - Today -> Start session
  - Today -> No items -> Sync status
  - Progress -> Learning settings
  - Progress -> Settings

## Checklist Audit Snapshot (2026-02-07)

Legend: `pass` = implemented and consistent, `partial` = present but incomplete or inconsistent, `fail` = missing.

### App-Level Checklist

- Purpose: `pass` (clear in product framing and current flow)
- Primary user jobs (top 3): `pass` (learn today, browse words, track outcomes)
- Core loop identified: `pass` (`Today -> Session -> Result -> Today`)
- Top-level destinations (3–5): `pass` (`Today`, `Words`, `Progress`)
- Push vs modal rules defined: `partial` (patterns used, but no written nav contract)
- Auth global states: `pass` (guarded signed-in/signed-out handling)
- Connectivity global states: `fail` (provider exists but no reliable runtime integration/banner)
- Sync global states: `partial` (strong sync screen, no global shell indicator)
- Tokens (spacing/type/colors): `partial` (type + colors centralized, spacing/radius/elevation tokens not fully standardized)
- Components inventory: `partial` (core widgets exist, no canonical inventory doc for all feature components)
- Performance policy (loading rules): `fail` (no explicit policy; spinners used broadly)
- Optimistic UI policy: `fail` (no explicit allow/deny policy)
- Data provenance visible: `partial` (dev-mode visibility; not consistently visible for all users)
- Undo/history paths: `fail` (confirm patterns exist, undo/history mostly absent)
- Accessibility baseline (Dynamic Type / AA+ / 44pt): `partial` (good defaults in places, no formal verification gates)
- Analytics core funnels: `fail` (telemetry for planning exists; product funnel instrumentation not defined)

### Core UI Element Checklist

- Tab bar (3–5, destination-based, persistent): `pass`
- Top navigation semantics (title + leading/trailing rules): `partial`
- Primary CTA (one per screen): `partial` (strong in key screens; some screens still have competing secondary actions)
- Secondary actions hierarchy: `pass`
- Lists (row affordance/full-row tap/loading/empty): `partial` (list behavior good, loading uses spinner over skeleton)
- Empty states (why + next action): `pass`
- Loading states (skeleton-first, avoid blocking nav): `fail`
- Error states (what happened + recover): `pass`
- Modals (short interrupting tasks): `pass`
- Forms/inputs (defaults + inline validation): `partial`
- Feedback (immediate response + state change): `pass`
- Undo/confirm (undo preferred, confirm irreversible): `partial`
- Typography (clear scale/readable): `pass`
- Color semantics (neutral-first, accent role, red for danger): `pass`
- Density defaults: `pass`

### Meta-Rule Compliance

- Screen without defined elements = invalid: `partial` (legacy screens still mixed with redesigned flow)
- Element without purpose = remove: `partial` (some low-value placeholder/legacy controls remain)
- Never solve flow problems with visuals: `pass` in new journey work

## Updated Work Plan (Gap-Driven)

### Epic 6: Navigation & Global State Contract (P0)

Goal: make navigation behavior and app-level states explicit and predictable.

Tasks:
- Write a navigation contract doc: route type (`push`, `modal`, `replace`) per screen.
- Add a global sync/connectivity status affordance in shell (`Today` header or app-level banner).
- Integrate real connectivity checks into the state model and recovery messaging.
- Remove or archive legacy flow entry points that conflict with the new 3-tab journey.

Acceptance Criteria:
- Every route in primary flow maps to a documented transition type.
- User can always see if app is offline/syncing/error from a primary surface.
- No duplicate/competing entry screens in the shipped flow.

Owners:
- Product Designer, Mobile Engineer

### Epic 7: Loading/Error Standardization (P0)

Goal: reduce uncertainty and perceived latency in core tasks.

Tasks:
- Define loading policy: skeleton for list/content fetches >300ms, spinner for short operations.
- Replace spinner-only loading in `Today`, `Words`, `Word Detail`, `Sync`, `Progress` with skeleton components where appropriate.
- Standardize error block copy and retry affordances across screens.

Acceptance Criteria:
- Core list/detail screens use skeletons for content loading.
- Error copy follows one reusable pattern (what happened / what to do / retry).

Owners:
- Mobile Engineer, UX Writer

### Epic 8: Trust & Safety UX Hardening (P0)

Goal: increase user trust in AI-enriched content and destructive actions.

Tasks:
- Show provenance on meaning content for all users (e.g., `AI generated`, `edited by you`).
- Add reversible action patterns where feasible (snackbar undo for non-destructive edits).
- Keep confirm dialogs only for irreversible actions (sign out, destructive regeneration).
- Add explicit consequence text before data-replacing actions.

Acceptance Criteria:
- Meaning/source provenance visible on vocabulary detail without dev mode.
- At least one undo path exists for key edit flows.
- Irreversible actions always show consequence-first confirmation.

Owners:
- Product Designer, Mobile Engineer

### Epic 9: Accessibility Baseline Enforcement (P1)

Goal: formalize accessibility compliance as a release gate.

Tasks:
- Define minimum touch-target and contrast checks per component class.
- Audit Dynamic Type scaling for core screens and overflow handling.
- Add accessibility-focused widget tests for critical controls.

Acceptance Criteria:
- Accessibility checklist added to QA gate and passes on core journey.
- No clipped/truncated primary CTA text at large text scale settings.

Owners:
- Product Designer, QA, Mobile Engineer

### Epic 10: Funnel Analytics & Outcome Telemetry (P1)

Goal: measure learning loop completion and drop-off points.

Tasks:
- Define event schema for core funnel:
  - app_open
  - today_primary_cta_tap
  - session_start
  - session_complete
  - vocabulary_detail_open
- Add instrumentation hooks in core screens and session lifecycle.
- Create dashboard for conversion from app open to session complete.

Acceptance Criteria:
- Core funnel events are emitted with stable names and properties.
- Weekly funnel report can identify top drop-off step.

Owners:
- Product Manager, Data/Backend Engineer, Mobile Engineer

### Epic 11: Design System Completion (P1)

Goal: finish token/component foundation for consistent UI evolution.

Tasks:
- Add spacing, radius, and elevation tokens (alongside existing color/type tokens).
- Publish component inventory and usage guidance.
- Refactor out one-off style values in key screens.

Acceptance Criteria:
- New screens use tokenized spacing/radius/elevation.
- Component inventory is documented and used in reviews.

Owners:
- Product Designer, Mobile Engineer
