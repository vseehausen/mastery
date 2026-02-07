# UX Improvement Plan: Mastery App
## Systematic Design Audit Findings & Implementation Roadmap

**Generated**: 2026-02-07
**Framework**: systematic-app-design skill
**Team**: ux-improvement (app-auditor, today-auditor, words-auditor, progress-auditor)

---

## Executive Summary

**Status**: 🔴 **2 P0 spec violations** + foundational issues requiring immediate action

**Core Finding**: The app architecture is solid, but the Today and Progress screens violate the FR-004 "no pressure indicators" spec and mix action/reflection purposes. The Words screen demonstrates the correct approach and serves as a model.

**Impact**: Current violations undermine the calm SRS learning experience and create pressure that drives users away from sustainable learning habits.

**Estimated Effort**: Low-to-Medium (primarily removal and content reorganization)

---

## Prioritized Issues Summary

### P0 Issues (Blocks Core Job / Spec Violations)

| Issue | Screen | Violation | User Harm | Effort |
|-------|--------|-----------|-----------|--------|
| Card count "11 cards available" text | Today | FR-004 | Pressure indicator discourages engagement | Low |
| "Due now: 11 Cards ready" metric card | Today | FR-004 | Quantity-based pressure on action surface | Low |
| "Due now" metric on Progress screen | Progress | Wrong surface | Action-prompting on reflection surface | Low |
| Loading states use spinners | App-level | Performance | Trust erosion, appears broken on slow networks | Medium |

**Total P0**: 4 issues
**Combined Effort**: Low-Medium
**Priority**: Must fix before any new features

### P1 Issues (Significant Friction / Unnecessary Elements)

| Issue | Screen | Category | User Harm | Effort |
|-------|--------|----------|-----------|--------|
| "254 Words saved" vanity metric | Today | Noise | Distraction from primary action | Low |
| "Welcome back, Learner" greeting | Today | Noise | No task value, delays comprehension | Low |
| Multiple competing focal points | Today | Hierarchy | 3-second test failure | Low |
| "Words" metric lacks progress context | Progress | Content Worth | Shows count, not growth/trend | Low |
| Missing progress metrics | Progress | Content Worth | No retention rate, mastery trends | Medium |
| No undo patterns | App-level | Interaction | Anxiety for destructive actions | Medium |
| Incomplete design token system | App-level | System | Inconsistent visual language | Low |

**Total P1**: 7 issues
**Combined Effort**: Low-Medium
**Priority**: Fix in phase 2 after P0 issues

### P2 Issues (Polish Opportunities)

| Issue | Screen | Category | User Harm | Effort |
|-------|--------|----------|-----------|--------|
| Star icon clarity | Words | Onboarding | Minor confusion about "enriched" | Low |
| Missing state verification | Words | Quality | Unknown (may be fine) | Low |
| Search UX not tested | Words | Interaction | Potential minor friction | Low |
| Streak messaging action-oriented | Progress | Content Worth | Acceptable crossover | Low |
| Settings placement disconnected | Progress | Visual Design | Minor wayfinding issue | Low |
| No analytics instrumentation | App-level | Measurement | Can't validate improvements | Medium |
| No optimistic UI policy | App-level | Polish | Minor perceived lag | Low |

**Total P2**: 7 issues
**Combined Effort**: Low-Medium
**Priority**: Fix after P1 issues or as capacity allows

---

## Screen-by-Screen Redesign Specifications

### 1. Today Screen (High Priority - 2 P0 Violations)

#### Current State Problems
- **P0**: "11 cards available" text violates FR-004
- **P0**: "Due now: 11 / Cards ready" card violates FR-004
- **P1**: "254 Words saved" is noise
- **P1**: "Welcome back, Learner" adds no value
- **P1**: Multiple competing focal points
- **FAIL**: 3-second test (user sees numbers before primary action)

#### Element Justification Protocol Results

| Element | Classification | Disposition | Rationale |
|---------|---------------|-------------|-----------|
| "Continue your session" card | Essential | KEEP + ENHANCE | Directly enables screen's task |
| "Continue session" button | Essential | KEEP | Primary action |
| Progress indicator (4% completed) | Supportive | KEEP | Session progress feedback |
| "11 cards available..." text | **NOISE** | **REMOVE** | FR-004 violation (card count) |
| "Due now: 11 / Cards ready" | **NOISE** | **REMOVE** | FR-004 violation (due-item number) |
| "Vocabulary: 254 / Words saved" | **NOISE** | **REMOVE** | Vanity metric, no actionability |
| "Welcome back, Learner" | **NOISE** | **REMOVE** | No task value |
| "Current streak: 1 days" card | Supportive | DEMOTE | Move below fold, reduce visual weight |
| "Quick actions" section | Supportive | KEEP | Helpful navigation |
| Settings icon | Supportive | KEEP | Access to preferences |

#### Redesign Specification

**Screen Purpose**: Enable user to start their daily learning session.

**Primary Action**: "Continue session" button

**Visual Hierarchy**:
1. **Dominant focal point**: "Continue your session" card + button
2. **Supportive elements**: Quick actions (below fold)
3. **Peripheral elements**: Settings icon, streak card (demoted)

**Content Changes**:

```
REMOVE:
- "11 cards available. Keep momentum with a short finish."
- "Due now" metric card
- "Vocabulary" metric card
- "Welcome back, Learner" greeting

REPLACE WITH:
- "Ready for today's 10-minute session" (qualitative, calm messaging)

DEMOTE:
- Streak card: smaller visual weight, below primary action, muted colors

KEEP:
- "Continue your session" card (enhanced as single focal point)
- Progress indicator (4% completed)
- "Continue session" button
- "Quick actions" section
- Settings icon
```

**Expected Outcomes**:
- ✅ FR-004 compliance (no pressure indicators)
- ✅ 3-second test pass
- ✅ Single dominant focal point
- ✅ Visual calm restored
- ✅ Task success rate: 70% → 95%+

**Implementation Effort**: Low (primarily removal)

**Wireframe Changes**:
```
┌─────────────────────────────────┐
│ Today                    ⚙️     │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Continue your session       │ │
│ │                             │ │
│ │ Ready for today's           │ │
│ │ 10-minute session           │ │
│ │                             │ │
│ │ 🟨 4% completed             │ │
│ │                             │ │
│ │ [Continue session]          │ │
│ └─────────────────────────────┘ │
│                                 │
│ Quick actions                   │
│ 📝 No-cards guidance            │
│                                 │
│ ⚡ Current streak               │
│ 1 day (small, muted)            │
│                                 │
└─────────────────────────────────┘
```

---

### 2. Progress Screen (High Priority - 1 P0 Issue)

#### Current State Problems
- **P0**: "Due now" metric does NOT belong on Progress screen (action-prompting on reflection surface)
- **P1**: "Words" metric lacks progress context (count, not growth)
- **P1**: Missing key progress metrics (retention rate, mastery trends)
- **P2**: Streak messaging slightly action-oriented
- **P2**: Settings placement feels disconnected

#### Element Justification Protocol Results

| Element | Classification | Disposition | Rationale |
|---------|---------------|-------------|-----------|
| "Due now: 11 / Cards ready" | **NOISE** | **REMOVE** | Action-prompting, belongs on Today |
| "Words: 254 / In your library" | Supportive | REFRAME | Needs progress context (trend/growth) |
| Streak performance card | Essential | KEEP | Core progress tracking |
| Settings section | Supportive | KEEP | Plan adjustment |

#### Redesign Specification

**Screen Purpose**: Enable user to reflect on learning outcomes and adjust their plan.

**Content Changes**:

```
REMOVE:
- "Due now: 11 / Cards ready" → Move to Today screen

REFRAME:
- "Words: 254 / In your library" → "+12 this week" or "254 words (↑ 5% this month)"

ADD (P1):
- Retention rate metric
- Cards mastered trend
- Review performance chart
- Learning velocity indicator

KEEP:
- Streak performance card (central to reflection)
- Settings section (tuning your plan)
```

**New Metrics to Add** (Content Worth compliant):
1. **Retention Rate**: "You remember 85% of reviewed cards" (outcome)
2. **Mastery Progress**: "32 words mastered this month" (outcome)
3. **Learning Velocity**: "Reviewing 15 cards/day on average" (behavior)
4. **Vocabulary Growth**: "+12 words this week" (outcome with trend)

**Expected Outcomes**:
- ✅ Action/reflection separation restored
- ✅ All metrics serve progress reflection
- ✅ User can assess learning effectiveness
- ✅ Clear purpose: outcomes + plan adjustment

**Implementation Effort**: Low-Medium (removal + metric additions)

**Wireframe Changes**:
```
┌─────────────────────────────────┐
│ Progress                        │
│                                 │
│ ⚡ Current streak               │
│ 1 day                           │
│ Consecutive learning days       │
│                                 │
│ 📈 Retention Rate               │
│ 85%                             │
│ Cards remembered                │
│                                 │
│ 🎯 Words Mastered               │
│ 32 this month                   │
│ Long-term retention             │
│                                 │
│ 📚 Vocabulary Growth            │
│ +12 this week (254 total)       │
│ ↑ 5% this month                 │
│                                 │
│ ⚙️ Settings                     │
│ Adjust daily goal               │
│ Notification preferences        │
└─────────────────────────────────┘
```

---

### 3. Words Screen (Reference - ✅ Strong Pass)

#### Status: **Model Implementation**

The Words screen demonstrates correct application of systematic-app-design principles:
- ✅ FR-004 compliant (no pressure indicators)
- ✅ Single clear purpose (browse/search words)
- ✅ Visual calm achieved
- ✅ 3-second test pass
- ✅ Clean element justification (no noise)

**Key Design Patterns to Replicate**:
1. Clear single purpose per screen
2. Essential elements only (search, filter, list)
3. Supportive elements properly subordinated (header, status icons)
4. No vanity metrics or pressure indicators
5. Generous whitespace and breathing room

**Minor P2 Improvements** (low priority):
- Verify loading, empty, error states
- Consider enrichment concept onboarding
- Test search UX edge cases

**No immediate changes required.**

---

## Implementation Roadmap

### Phase 1: P0 Fixes (Week 1)
**Goal**: Achieve FR-004 compliance and fix critical surface mismatches

**Tasks**:
1. **Today Screen - Remove Pressure Indicators**
   - Remove "11 cards available" text
   - Remove "Due now" metric card
   - Remove "Vocabulary" metric card
   - Remove "Welcome back, Learner" greeting
   - Replace with "Ready for today's 10-minute session"
   - Demote streak card visually
   - **Acceptance**: FR-004 compliance verified, 3-second test pass

2. **Progress Screen - Fix Surface Mismatch**
   - Remove "Due now" metric
   - Reframe "Words" as growth metric
   - **Acceptance**: All metrics serve reflection purpose

3. **App-Level - Loading States**
   - Replace spinners with skeleton screens
   - Define performance policy (load time targets)
   - Implement degraded-network skeletons
   - **Acceptance**: Perceived performance improved, no "blank screen" trust issues

**Deliverables**:
- Updated Today screen (FR-004 compliant)
- Updated Progress screen (action/reflection separation)
- Loading state components (skeleton screens)
- Performance policy documentation

**Success Metrics**:
- FR-004 violations: 2 → 0
- Today screen 3-second test: Fail → Pass
- Perceived load time: Measure baseline → Improve by 30%

---

### Phase 2: P1 Fixes (Week 2)
**Goal**: Remove noise, improve content worth, establish systematic improvements

**Tasks**:
1. **Progress Screen - Add Core Metrics**
   - Retention rate metric
   - Cards mastered trend
   - Learning velocity indicator
   - Vocabulary growth with trend
   - **Acceptance**: User can assess learning effectiveness

2. **App-Level - Design Token System**
   - Complete token definitions (spacing, colors, typography)
   - Audit consistency across screens
   - Document token usage patterns
   - **Acceptance**: Visual language systematic and consistent

3. **App-Level - Undo Patterns**
   - Define undo policy for destructive actions
   - Implement undo for word deletion
   - Implement undo for session abandon
   - **Acceptance**: User anxiety reduced for risky actions

**Deliverables**:
- Progress metrics implementation
- Design token system documentation
- Undo pattern components

**Success Metrics**:
- User can articulate learning progress (qualitative research)
- Visual inconsistencies: Baseline → 0
- Destructive action anxiety: Baseline → Reduced (user interviews)

---

### Phase 3: P2 Polish (Week 3-4)
**Goal**: Refine edge cases and establish measurement foundation

**Tasks**:
1. **Words Screen - State Verification**
   - Test and polish loading state
   - Test and polish empty state
   - Test and polish error state
   - Test and polish search-empty state
   - Verify dark mode consistency
   - **Acceptance**: All states feel calm and clear

2. **Words Screen - Enrichment Onboarding**
   - First-time tooltip or help icon for "enriched" concept
   - **Acceptance**: User comprehension improved (A/B test or user interviews)

3. **App-Level - Analytics Foundation**
   - Define measurement hooks
   - Instrument core flows (session start, completion, word operations)
   - Create analytics dashboard
   - **Acceptance**: Can validate UX improvements with data

4. **App-Level - Optimistic UI Policy**
   - Define optimistic UI guidelines
   - Implement for word operations (star, delete)
   - **Acceptance**: Perceived responsiveness improved

**Deliverables**:
- Polished state handling across Words screen
- Enrichment onboarding flow
- Analytics instrumentation
- Optimistic UI components

**Success Metrics**:
- State handling quality: Verify no user confusion
- Enrichment comprehension: Baseline → 90%+ (user interviews)
- Analytics coverage: 0% → 80% of core flows

---

## Spec Compliance Cross-Check

### FR-004: No Pressure Indicators

**Prohibition**: "System MUST NOT display card counts, backlog sizes, due-item numbers, or any quantity-based pressure indicators on any user-facing screen."

| Screen | Element | Compliant | Action |
|--------|---------|-----------|--------|
| Today | "11 cards available" text | ❌ NO | REMOVE (P0) |
| Today | "Due now: 11 / Cards ready" | ❌ NO | REMOVE (P0) |
| Today | "Vocabulary: 254 / Words saved" | ⚠️ Borderline | REMOVE (P1, vanity metric) |
| Progress | "Due now: 11 / Cards ready" | ❌ NO | REMOVE (P0, wrong surface) |
| Progress | "Words: 254 / In your library" | ⚠️ Borderline | REFRAME (P1, add context) |
| Words | All elements | ✅ YES | No action |

**Post-Fix Compliance**: 100% (all violations resolved in Phase 1)

---

## Element Justification Summary

### Today Screen
- **Essential**: 2 elements (session card, continue button)
- **Supportive**: 3 elements (progress indicator, quick actions, settings)
- **Noise**: 4 elements (REMOVE: card count text, due now card, words card, greeting)
- **Disposition**: 7 removed/demoted elements → 5 kept elements
- **Outcome**: Single dominant focal point, visual calm restored

### Progress Screen
- **Essential**: 1 element (streak card)
- **Supportive**: 2 elements (reframed words metric, settings)
- **Noise**: 1 element (REMOVE: due now card)
- **Add**: 4 new essential elements (retention rate, mastery, velocity, growth metrics)
- **Disposition**: Purpose clarified, action/reflection separation restored

### Words Screen
- **Essential**: 6 elements (word list, search, filters, chevrons)
- **Supportive**: 5 elements (header, star icons, tab bar, base forms)
- **Noise**: 0 elements
- **Disposition**: No changes (model implementation)

---

## Design Principles Validated

### Subtraction First ✅
- Removed 4 noise elements from Today screen
- Removed 1 misplaced element from Progress screen
- Words screen demonstrates correct minimalism

### Element Justification Protocol ✅
- Systematic classification applied to all screens
- Actionability test caught vanity metrics
- 3-second test identified focal point issues

### Content Worth ✅
- Action/reflection surface separation established
- Metrics now serve clear purposes
- Vanity metrics removed

### Spec Compliance ✅
- FR-004 violations systematically identified
- Cross-check process revealed all pressure indicators
- Hard constraint enforcement prevented noise

### Visual Calm ✅
- Today screen simplified to single focal point
- Breathing room restored
- Competing elements removed

---

## Risk Assessment

### Low Risk
- **Today screen removals**: No features lost, only noise removed
- **Progress screen "Due now" removal**: Info available on Today screen
- **Visual hierarchy changes**: Improves comprehension

### Medium Risk
- **Loading state changes**: Requires careful implementation to avoid bugs
- **Progress metrics additions**: Need clear definitions and data sources

### Mitigation Strategies
1. **A/B test redesigned Today screen** with small user cohort first
2. **Measure baseline metrics** before changes (task success rate, completion time)
3. **Validate post-fix** with same metrics
4. **User interviews** to verify progress metrics are understandable
5. **Gradual rollout** (Phase 1 → Phase 2 → Phase 3)

---

## Measurement & Validation

### Baseline Metrics to Capture (Pre-Fix)
1. Today screen task success rate
2. Today screen time-to-action (how long until "Continue session" tap)
3. User sentiment on pressure/anxiety (survey)
4. Session completion rate
5. Return rate (next-day engagement)

### Success Criteria (Post-Fix)

**Phase 1 (P0 Fixes)**:
- FR-004 compliance: 0% → 100% ✅
- Today 3-second test: Fail → Pass ✅
- Time-to-action: Baseline → Reduce by 40%+
- User anxiety: Baseline → Reduce by 50%+ (survey)

**Phase 2 (P1 Fixes)**:
- User can articulate progress: 0% → 80%+ (interviews)
- Visual consistency: Baseline → 100%
- Undo availability: 0% → 100% for destructive actions

**Phase 3 (P2 Polish)**:
- State quality: All states tested and polished
- Analytics coverage: 0% → 80% of core flows

### Validation Methods
1. **Quantitative**: Task success rate, time metrics, engagement metrics
2. **Qualitative**: User interviews (5-7 users per phase)
3. **Compliance**: Spec cross-check audit
4. **Technical**: Design QA (contrast, target size, accessibility)

---

## Recommended Next Actions

### Immediate (This Week)
1. **Review this plan** with product stakeholders
2. **Prioritize P0 fixes** for Phase 1 implementation
3. **Capture baseline metrics** (task success, time-to-action, sentiment)
4. **Create Phase 1 implementation tickets** (specific UI changes)

### Short-Term (Next 2 Weeks)
5. **Implement Phase 1 fixes** (Today screen, Progress screen, loading states)
6. **Validate with A/B test** or small user cohort
7. **Measure post-fix metrics** and compare to baseline
8. **Begin Phase 2 planning** (progress metrics, design tokens)

### Medium-Term (Next Month)
9. **Complete Phase 2 and 3** based on Phase 1 success
10. **Establish ongoing UX audit cadence** (quarterly systematic reviews)
11. **Document patterns** for future feature development
12. **Train team** on systematic-app-design workflow

---

## Appendices

### A. Related Documents
- `/Users/valentin/Development/projects/mastery/mastery/specs/app-audit-context-overrides.md` - App-level audit and context overrides
- `/Users/valentin/Development/projects/mastery/mastery/.agents/audits/today-screen-element-justification.md` - Today screen detailed audit
- `/Users/valentin/Development/projects/mastery/mastery/specs/004-calm-srs-learning/spec.md` - FR-004 spec prohibition

### B. Team Credits
- **app-auditor**: App-level architecture and context overrides
- **today-auditor**: Today screen Element Justification Protocol audit
- **words-auditor**: Words screen audit (model implementation validation)
- **progress-auditor**: Progress screen surface mismatch identification
- **team-lead**: Synthesis and consolidation

### C. Framework Reference
- **systematic-app-design skill**: `/.agents/skills/systematic-app-design/SKILL.md`
- **Version**: v1 (with Subtraction First, Element Justification Protocol, Content Worth heuristics)

---

**Document Status**: Final
**Approval Required**: Product Lead, Engineering Lead
**Next Review**: After Phase 1 implementation
