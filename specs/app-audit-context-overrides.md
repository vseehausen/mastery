# App-Level Audit: Context Overrides & Findings

Last updated: 2026-02-07
Auditor: app-auditor (UX improvement team)

## Context Overrides for Mastery Mobile App

### Product Context
**What is Mastery?**
A vocabulary learning app focused on spaced repetition using FSRS algorithm. Users import vocabulary from Kindle via desktop app, and mobile app provides the learning experience with AI-enriched meanings.

**Primary value proposition:**
- Capture vocabulary effortlessly from reading (via desktop)
- Learn with intelligent spaced repetition
- Rich, multi-cue learning (definitions, synonyms, cloze, disambiguation)

**Target users:**
- Active readers who want to retain vocabulary from their reading
- Learners who value systematic, science-backed learning methods
- Users comfortable with connected desktop+mobile workflow

### Platform Context
**Platform:** Flutter mobile app (iOS focused, based on simulator testing infrastructure)

**Key platform constraints:**
- Online-required (no offline mode)
- Direct Supabase queries with Riverpod caching
- No local SQLite database
- Requires desktop app for vocabulary import

### Technical Context
**Architecture:**
- State management: Riverpod with FutureProvider.autoDispose
- UI framework: shadcn_ui components with custom Mastery theme
- Backend: Supabase (auth, database, edge functions)
- Spaced repetition: FSRS algorithm

**Data flow:**
- Desktop app → Supabase (import sessions, encounters)
- Edge function (parse-vocab) → enrichment generation
- Mobile app → direct Supabase queries for all data
- No local persistence beyond Riverpod memory cache

### Business Context
**Current stage:** Development/MVP phase
**Recent work:** Navigation simplification from 4 tabs to 3 tabs

**Key metrics (implied from audit):**
- Session completion rate (Today → Session → Complete)
- Vocabulary enrichment coverage
- Streak maintenance
- Daily learning time target adherence

### User Constraints
**User must:**
- Have active internet connection
- Own/access desktop app for vocabulary import
- Complete imports before mobile learning begins
- Wait for AI enrichment to complete before optimal learning

**User journey dependencies:**
1. Desktop: Import Kindle vocabulary
2. Backend: Process and enrich vocabulary
3. Mobile: Learn enriched vocabulary with spaced repetition

---

## Primary User Jobs (Top 3)

### 1. Learn Today (P0)
**Job:** Complete my daily spaced repetition session quickly and effectively.

**User intent:**
"When I open the app, I want to immediately know if I have cards to review and start learning with minimal friction."

**Current flow:**
- App opens → Today tab (default)
- User sees due cards count and primary CTA
- Tap "Start session" → SessionScreen
- Complete cards → SessionCompleteScreen → return to Today

**Terminal goal:** Session completed, progress toward daily time target made.

### 2. Browse Words (P1)
**Job:** Explore my vocabulary library, check enrichment status, and drill into word details.

**User intent:**
"I want to browse my imported words, see which ones are enriched, and review detailed meanings when curious."

**Current flow:**
- Today/Progress → Words tab
- Search/filter vocabulary
- Tap word → VocabularyDetailScreen
- View meanings, encounters, edit/regenerate

**Terminal goal:** User satisfies curiosity, understands a word better, or confirms enrichment status.

### 3. Track Outcomes (P2)
**Job:** Monitor my learning progress, maintain streak, and adjust settings.

**User intent:**
"I want to see how I'm doing (streak, completion) and access settings to tune my learning plan."

**Current flow:**
- Today/Words → Progress tab
- View streak, vocabulary count, due cards
- Access Learning Settings or Account Settings
- Adjust preferences

**Terminal goal:** User understands their progress and feels motivated to continue or adjusts plan.

---

## Core Loop

**Primary loop:** Today → Session → Result → Today

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌──────────┐   Start Session   ┌────────┐ │
│  │  Today   │ ─────────────────> │Session │ │
│  │  Screen  │                    │ Screen │ │
│  └──────────┘                    └────────┘ │
│       ^                              │       │
│       │                              │       │
│       │         Complete Session     │       │
│       └──────────────────────────────┘       │
│           (via SessionCompleteScreen)        │
│                                             │
└─────────────────────────────────────────────┘
```

**Secondary loops:**
- Browse loop: Words → Detail → Back to Words
- Settings loop: Progress → Settings → Back to Progress
- Recovery loop: Today → No Items → Sync Status → Back to Today

---

## Top-Level Navigation (3-Tab Layout)

### Tab 1: Today (HomeScreen index 0)
**Purpose:** Daily decision and session entry
**Icon:** `Icons.today_outlined`
**Screen:** `TodayScreen`

**Content:**
- Welcome header with user name
- Hero card with primary CTA (start/continue/done/no-items)
- Metric cards (due now, vocabulary, streak)
- Quick actions (no-items guidance, settings access)

**Routes from Today:**
- Push → SessionScreen (start session)
- Push → NoItemsReadyScreen (no cards available)
- Push → SyncStatusScreen (from no-items or global banner)
- Push → SettingsScreen (from header action)

### Tab 2: Words (HomeScreen index 1)
**Purpose:** Vocabulary browse/search and word drill-down
**Icon:** `Icons.book_outlined`
**Screen:** `VocabularyScreenNew`

**Content:**
- Search bar with query input
- Filter chips (All, Enriched, Not Enriched)
- Scrollable list of WordCard widgets
- Empty states for no vocabulary or filtered results

**Routes from Words:**
- Push → VocabularyDetailScreen (word tap)

### Tab 3: Progress (HomeScreen index 2)
**Purpose:** Outcomes and settings entry points
**Icon:** `Icons.insights_outlined`
**Screen:** `ProgressScreen`

**Content:**
- Progress hero card (streak performance)
- Data cards (words, due now)
- Action tiles (Learning preferences, Account settings)

**Routes from Progress:**
- Push → LearningSettingsScreen
- Push → SettingsScreen

---

## Global States

### 1. Authentication State
**Provider:** `authStateProvider`, `isAuthenticatedProvider`

**States:**
- Unauthenticated → AuthScreen (AuthGuard)
- OAuth in progress → OAuthLoadingScreen
- Authenticated → HomeScreen

**Visibility:** App-level guard, not shown in shell once authenticated

**Recovery:** Auto-sign-out on refresh token errors, manual sign-out from Settings

### 2. Connectivity State
**Provider:** `connectivityProvider`

**States:**
- Connected (normal operation)
- Disconnected (offline banner shown)

**Visibility:** GlobalStatusBanner above bottom nav (when offline)

**Recovery:** "Retry" action in banner → check connectivity and invalidate providers

### 3. Sync/Enrichment State
**Providers:** `vocabularyCountProvider`, `enrichedVocabularyIdsProvider`, `showEnrichmentProgressOnHomeProvider`

**States:**
- No vocabulary imported
- Vocabulary imported, enrichment in progress
- All enriched, ready to learn
- Enrichment error

**Visibility:**
- GlobalStatusBanner above bottom nav (when enabled)
- SyncStatusScreen (detailed timeline view)

**Recovery:**
- "Refresh" action in banner → invalidate providers
- "Details" action → navigate to SyncStatusScreen
- Dismissible for enrichment progress banner (session-scoped)

### 4. Session State
**Providers:** `dueCardsProvider`, `hasItemsToReviewProvider`, `hasCompletedTodayProvider`, `todayProgressProvider`

**States:**
- No items ready
- Items ready, not started
- Session in progress (progress 0-100%)
- Session completed today

**Visibility:**
- Hero card on TodayScreen (reflects current state)
- Progress indicator (when in progress)
- Session timer and card UI (SessionScreen)

**Recovery:**
- Refresh on TodayScreen pull-to-refresh
- Auto-invalidation on session completion

---

## App-Level Flow Map

```
┌─────────────────────────────────────────────────────────────┐
│                      App Entry                               │
│                                                              │
│  App Launch → AuthGuard → (check auth state)                │
│                                                              │
│  ├─ Not authenticated → AuthScreen                          │
│  │   └─ Sign in/up → OAuth flow → OAuthLoadingScreen        │
│  │       └─ Success → HomeScreen (authenticated)            │
│  │                                                           │
│  └─ Authenticated → HomeScreen (3-tab shell)                │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│               HomeScreen (3-Tab Shell)                       │
│                                                              │
│  [Global Status Banner] (conditional, above bottom nav)      │
│  ├─ Offline → Retry action                                  │
│  ├─ Enrichment progress → Details action                    │
│  └─ Sync error → Refresh action                             │
│                                                              │
│  [IndexedStack - switches on selectedIndex]                 │
│  ├─ Index 0: TodayScreen                                    │
│  ├─ Index 1: VocabularyScreenNew                            │
│  └─ Index 2: ProgressScreen                                 │
│                                                              │
│  [Bottom Navigation Bar] (3 tabs: Today, Words, Progress)   │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Today Flow Tree                            │
│                                                              │
│  TodayScreen                                                 │
│  ├─ Primary CTA action:                                     │
│  │   ├─ Has items → Push SessionScreen                      │
│  │   │   └─ Complete → Replace SessionCompleteScreen        │
│  │   │       └─ "Done" → Pop to TodayScreen                 │
│  │   └─ No items → Push NoItemsReadyScreen                  │
│  │       ├─ "Check sync status" → Push SyncStatusScreen     │
│  │       └─ "Refresh" → Invalidate providers, stay          │
│  ├─ Settings icon → Push SettingsScreen                     │
│  └─ Quick action: "No-cards guidance" → Push NoItemsScreen  │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Words Flow Tree                            │
│                                                              │
│  VocabularyScreenNew                                         │
│  ├─ Search bar → Filter vocabulary list in place            │
│  ├─ Filter chips → Filter by enrichment status in place     │
│  ├─ Word tap → Push VocabularyDetailScreen                  │
│  │   ├─ View meanings (definition, synonym, etc.)           │
│  │   ├─ Edit/regenerate enrichment (modals)                 │
│  │   └─ Back → Pop to VocabularyScreenNew                   │
│  └─ Pull-to-refresh → Invalidate providers, reload          │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Progress Flow Tree                          │
│                                                              │
│  ProgressScreen                                              │
│  ├─ "Learning preferences" → Push LearningSettingsScreen    │
│  │   └─ Edit preferences (daily target, etc.)               │
│  │       └─ Back → Pop to ProgressScreen                    │
│  ├─ "Account and app settings" → Push SettingsScreen        │
│  │   ├─ Profile, notifications, sign out                    │
│  │   └─ Back → Pop to ProgressScreen                        │
│  └─ Pull-to-refresh → Invalidate providers, reload          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## App-Level Checklist Assessment

Legend: `✅ pass` | `⚠️ partial` | `❌ fail`

### Strategic Clarity
- [✅] **Purpose clear:** Vocabulary learning via spaced repetition with AI enrichment
- [✅] **Primary jobs (top 3):** Learn today, browse words, track outcomes
- [✅] **Core loop identified:** Today → Session → Result → Today
- [✅] **Top-level destinations (3–5):** Today, Words, Progress (3 tabs)

### Navigation Structure
- [✅] **Push vs modal rules defined:** Navigation contract exists (specs/mobile-navigation-contract.md)
- [✅] **Tab semantics:** Destination-based, not action-based
- [⚠️] **Close vs back semantics:** Defined in contract, but not consistently enforced in all screens

### Global States
- [✅] **Auth global states:** Properly guarded with AuthGuard, refresh token error handling
- [⚠️] **Connectivity global states:** Provider exists, banner shows offline, but no proactive connectivity checks or recovery UX refinement
- [⚠️] **Sync global states:** Strong sync screen exists, banner shows enrichment progress, but no persistent shell indicator (banner is dismissible)

### Design System Foundation
- [⚠️] **Tokens (spacing/type/colors):** Color and type tokens centralized, spacing/radius/elevation not fully tokenized
- [⚠️] **Components inventory:** Core widgets exist (WordCard, StatCard, GlobalStatusBanner), but no canonical inventory doc
- [⚠️] **Typography:** Clear scale defined in MasteryTextStyles, used consistently
- [✅] **Color semantics:** Neutral-first with accent/warning/destructive roles, light/dark support

### Performance & Reliability
- [❌] **Performance policy (loading rules):** No explicit skeleton vs spinner policy (uses spinner broadly)
- [❌] **Optimistic UI policy:** No explicit policy (mutations currently pessimistic)
- [⚠️] **Data provenance visible:** Dev-mode only for AI-generated content (not visible for all users)

### User Trust & Safety
- [⚠️] **Undo/history paths:** Confirm dialogs exist for destructive actions, but undo patterns mostly absent
- [✅] **Error states:** Consistent error handling with retry affordances
- [✅] **Empty states:** Well-defined empty states with context and next actions

### Accessibility & Quality
- [⚠️] **Accessibility baseline:** Good defaults (44pt tap targets, AA+ contrast in places), but no formal verification gates
- [❌] **Analytics core funnels:** Telemetry infrastructure not evident, no product funnel instrumentation

---

## Identified P0/P1/P2 Issues at App Level

### P0 Issues (Blocking core user jobs)

**P0-1: Loading states use spinners instead of skeletons**
- **Impact:** Perceived latency, uncertainty in core flows (Today, Words, Progress)
- **Current:** CircularProgressIndicator used broadly
- **Expected:** Skeleton loaders for content >300ms, spinners for quick operations
- **Affects:** Today screen (due cards, streak), Words screen (vocabulary list), Progress screen (metrics)

**P0-2: No explicit performance/loading policy**
- **Impact:** Inconsistent loading UX, no clear framework for engineers
- **Current:** Ad-hoc loading decisions per screen
- **Expected:** Documented policy (skeleton vs spinner, timing thresholds, loading state hierarchy)

**P0-3: Connectivity recovery UX is basic**
- **Impact:** Users may not realize they're offline until actions fail
- **Current:** Banner shows offline, "Retry" invalidates providers
- **Expected:** Proactive checks, clearer recovery messaging, consider persistent indicator

### P1 Issues (Degraded experience)

**P1-1: Data provenance only visible in dev mode**
- **Impact:** User trust in AI-generated meanings is low without transparency
- **Current:** Provenance (AI generated, edited by user) only in dev mode
- **Expected:** Always show provenance on vocabulary detail screen

**P1-2: No undo patterns for user edits**
- **Impact:** User hesitancy to edit/regenerate meanings (fear of losing data)
- **Current:** Confirm dialogs only, no undo
- **Expected:** Snackbar undo for non-destructive edits, confirm for irreversible actions

**P1-3: Spacing/radius/elevation tokens not standardized**
- **Impact:** Visual inconsistency, harder to maintain design system
- **Current:** Color and type tokens exist, but spacing/radius/elevation are hardcoded values
- **Expected:** Full token system (like shadcn's CSS variables)

**P1-4: No component inventory documentation**
- **Impact:** Engineers reinvent components, inconsistent usage
- **Current:** Components exist but no canonical list or usage guide
- **Expected:** Component inventory with usage guidelines

**P1-5: Global sync banner is dismissible per session**
- **Impact:** User may dismiss and forget enrichment is incomplete
- **Current:** Banner can be dismissed, persists only for session
- **Expected:** Consider persistent indicator or re-show logic based on enrichment status

### P2 Issues (Polish & optimization)

**P2-1: No analytics instrumentation**
- **Impact:** Cannot measure funnel conversion or identify drop-off points
- **Current:** No event tracking evident
- **Expected:** Core funnel events (app_open, session_start, session_complete, etc.)

**P2-2: Optimistic UI policy not defined**
- **Impact:** Slower perceived performance on mutations
- **Current:** Pessimistic mutations (wait for server response)
- **Expected:** Optimistic updates for low-risk mutations (like/dislike feedback, card ratings)

**P2-3: Accessibility not enforced in QA gate**
- **Impact:** Accessibility issues may slip through
- **Current:** Good defaults, but no formal verification
- **Expected:** Accessibility checklist in QA, Dynamic Type testing, contrast verification

---

## Recommendations

### Immediate Actions (Epic 6-7 from backlog)

1. **Define and implement loading/skeleton policy** (P0)
   - Document skeleton vs spinner rules
   - Replace spinners with skeletons in Today, Words, Progress screens
   - Standardize error block copy and retry patterns

2. **Improve connectivity/sync state visibility** (P0)
   - Consider persistent sync indicator (not just banner)
   - Refine offline recovery messaging
   - Add real connectivity checks to global state

3. **Show data provenance for all users** (P1)
   - Remove dev-mode gate for AI provenance
   - Display "AI generated" or "Edited by you" on vocabulary detail

### Medium-term Actions (Epic 8-11 from backlog)

4. **Add undo patterns** (P1)
   - Snackbar undo for edits
   - Keep confirm dialogs for irreversible actions

5. **Complete design system tokens** (P1)
   - Add spacing, radius, elevation tokens
   - Refactor hardcoded values in key screens

6. **Create component inventory** (P1)
   - Document all shared widgets
   - Add usage guidelines

7. **Add analytics instrumentation** (P2)
   - Define core funnel events
   - Instrument Today → Session → Complete flow

### Long-term Actions

8. **Define optimistic UI policy** (P2)
9. **Formalize accessibility compliance** (P2)

---

## Next Steps

This app-level audit provides context for detailed screen-level audits:
- Today screen (Task #2)
- Words screen (Task #3)
- Progress screen (Task #4)

Each screen audit should use the Element Justification Protocol and reference:
- Primary user jobs defined here
- Navigation contract (specs/mobile-navigation-contract.md)
- Global state contracts
- App-level checklist items

Final deliverable: Consolidated UX improvement plan (Task #5) will synthesize all findings.
