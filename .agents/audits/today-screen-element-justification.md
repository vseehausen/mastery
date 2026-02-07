# Today Screen Element Justification Audit

**Date**: 2026-02-07
**Auditor**: today-auditor
**Screen**: Today (Home Screen)
**Spec Reference**: specs/004-calm-srs-learning/spec.md

---

## 1. Screen Purpose (One Sentence)

**Start a time-boxed learning session.**

---

## 2. All Visible Elements

From screenshot and UI accessibility data:

1. Screen title: "Today"
2. Welcome text: "Welcome back, Learner"
3. Settings icon (top right)
4. Card: "Continue your session"
5. Subtext: "11 cards available. Keep momentum with a short finish."
6. Progress bar emoji: 📦
7. Progress percentage: "4% completed"
8. Primary CTA: "Continue session" button
9. Metric card: "Due now" / "11" / "Cards ready"
10. Metric card: "Vocabulary" / "254" / "Words saved"
11. Metric card: "Current streak" / "1 days" / "Consecutive learning days"
12. Section header: "Quick actions"
13. Action link: "No-cards guidance"
14. Tab bar: "Today" (selected)
15. Tab bar: "Words"
16. Tab bar: "Progress"

---

## 3. Element Classification

| # | Element | Classification | Rationale |
|---|---------|---------------|-----------|
| 1 | "Today" title | Supportive | Orientation - tells user where they are |
| 2 | "Welcome back, Learner" | Noise | Does not help start session; greeting adds no task value |
| 3 | Settings icon | Supportive | Access to configuration, not directly task-enabling |
| 4 | "Continue your session" | Essential | Names the task/action |
| 5 | "11 cards available..." | **NOISE (SPEC VIOLATION)** | Violates FR-004: card count is pressure indicator |
| 6 | Progress emoji 📦 | Supportive | Visual orientation aid |
| 7 | "4% completed" | Supportive | Session progress feedback (FR-002 requirement) |
| 8 | "Continue session" button | Essential | Primary action to complete task |
| 9 | "Due now / 11 / Cards ready" | **NOISE (SPEC VIOLATION)** | Violates FR-004: "due-item numbers" explicit prohibition |
| 10 | "Vocabulary / 254 / Words saved" | Noise | Vanity metric, no actionable purpose on this screen |
| 11 | "Current streak / 1 days" | Supportive | FR-003 requires streak display, motivational feedback |
| 12 | "Quick actions" | Supportive | Section orientation |
| 13 | "No-cards guidance" | Supportive | Help/support access |
| 14-16 | Tab bar | Essential | Primary navigation |

---

## 4. Actionability Test Results

**Test**: "What should the user DO with this information on THIS screen?"

| Metric/Number | Answer | Disposition |
|---------------|--------|-------------|
| "11 cards available" | Nothing actionable; creates pressure | **REMOVE** |
| "11 Cards ready" | Nothing actionable; creates pressure | **REMOVE** |
| "254 Words saved" | Nothing; feel good vanity metric | **REMOVE** (move to Progress screen) |
| "1 days" streak | Motivational feedback, supports habit formation | **KEEP** (FR-003 requirement) |
| "4% completed" | Shows session progress, supports task completion | **KEEP** (FR-002 requirement) |

---

## 5. Spec Compliance Cross-Check

**FR-004**: System MUST NOT display card counts, backlog sizes, due-item numbers, or any quantity-based pressure indicators on any user-facing screen.

| Element | Spec Prohibition | Status |
|---------|------------------|--------|
| "11 cards available" | Card count | ❌ **VIOLATION** |
| "11 Cards ready" | Card count / due-item number | ❌ **VIOLATION** |
| "254 Words saved" | N/A (vanity metric, not prohibited but noise) | ⚠️ **NOISE** |

**Priority**: P0 - Spec violations that create pressure indicators explicitly prohibited.

---

## 6. Redundancy Check

| Data Point | Appears Where | Issue |
|------------|---------------|-------|
| Card count | Two places: session card subtext + "Due now" metric card | **REDUNDANT** (both should be removed per FR-004) |

---

## 7. Cross-Screen Duplication Check

| Element | Primary Home Screen | Appears Elsewhere? | Disposition |
|---------|---------------|-------------------|-------------|
| "254 Words saved" | Today | Likely belongs on Progress screen | **MOVE** to Progress screen |
| "Current streak" | Today | May belong on Progress screen | **VERIFY** - FR-003 requires it on home; may also appear on Progress |

---

## 8. 3-Second Test

**Current state**: FAIL
**Reason**: Multiple competing metric cards distract from primary action. User sees numbers before seeing "Continue session" button.

**Expected**: User should immediately identify "Start/Continue session" as the one thing to do.

---

## 9. Visual Hierarchy Issues

1. **Primary action visibility**: "Continue session" button competes with three metric cards below it
2. **Focal point confusion**: Metrics draw eye away from essential task
3. **Information overload**: Five distinct information units before primary action (title, welcome, session card header, card count, progress)

---

## 10. Redesign Proposal

### Remove (P0 - Spec Violations)
- ❌ "11 cards available. Keep momentum with a short finish." → Replace with qualitative messaging
- ❌ "Due now / 11 / Cards ready" metric card → Remove entirely
- ❌ "Vocabulary / 254 / Words saved" metric card → Move to Progress screen

### Remove (P1 - Noise)
- ❌ "Welcome back, Learner" → Provides no task value

### Keep (Essential)
- ✅ "Today" title
- ✅ "Continue your session" heading
- ✅ "Continue session" button
- ✅ Tab bar navigation

### Keep (Supportive - Demote Visually)
- ✅ "Current streak / 1 days" → Keep but demote visually (smaller, peripheral)
- ✅ "4% completed" progress indicator → Keep but integrate into session card
- ✅ Settings icon
- ✅ "Quick actions" / "No-cards guidance"

### Proposed Qualitative Messaging Replacements

Instead of "11 cards available. Keep momentum with a short finish.":

**Option A (Recommended)**: "Ready for today's 10-minute session."
**Option B**: "Your session is ready."
**Option C**: Remove subtext entirely; let button speak for itself.

---

## 11. Priority Classification

| Issue | Priority | User Harm | Frequency | Effort |
|-------|----------|-----------|-----------|--------|
| Card count display violates FR-004 | P0 | Breaks spec, creates pressure | Every view | Low (remove text) |
| "Due now / 11 Cards ready" violates FR-004 | P0 | Breaks spec, creates pressure | Every view | Low (remove card) |
| "254 Words saved" vanity metric | P1 | Clutters action screen | Every view | Low (remove card) |
| "Welcome back, Learner" noise | P1 | Minor distraction | Every view | Low (remove text) |
| Multiple competing focal points | P1 | Delays task identification | Every view | Medium (redesign layout) |

---

## 12. Revised Screen Content

### Minimal Essential Version

```
[Today]                                    [⚙️]

Continue your session
Ready for today's 10-minute session.

[Progress bar: 4%]

┌────────────────────────────────────┐
│      [Continue session]            │
└────────────────────────────────────┘

Current streak
🔥 1 days
Consecutive learning days

Quick actions
📄 No-cards guidance

[Today] [Words] [Progress]
```

### Visual Hierarchy Adjustments
1. **Dominant focal point**: "Continue session" button (largest, highest contrast)
2. **Supportive elements demoted**:
   - Streak card: smaller size, muted colors, positioned below primary action
   - Progress percentage: integrated into session card, not competing element
3. **Breathing room**: Generous whitespace around primary action
4. **No competing metrics**: All vanity/pressure metrics removed

---

## 13. Acceptance Gates

### Task Success
- **Target**: >= 90% of users successfully start session within 3 seconds of screen load
- **Current**: Likely <70% due to competing focal points
- **Post-redesign**: Expected 95%+

### 3-Second Test
- **Target**: User identifies primary action within 3 seconds
- **Current**: FAIL (multiple competing elements)
- **Post-redesign**: PASS (one clear CTA, qualitative messaging)

### Spec Compliance
- **Target**: 100% compliance with FR-004
- **Current**: FAIL (two card count violations)
- **Post-redesign**: PASS (all pressure indicators removed)

---

## 14. Implementation Notes

### Code Changes Required
1. Remove or replace subtext in session card: `/lib/features/home/widgets/*`
2. Remove "Due now" metric card widget
3. Remove "Words saved" metric card widget
4. Demote streak card styling (smaller, muted)
5. Update session card messaging to qualitative alternatives

### State Model Impact
- Session card still shows: title, qualitative status, progress bar, CTA button
- No changes to underlying session planning logic
- No changes to SRS scheduler or item prioritization
- Vanity metrics moved to Progress screen (separate task)

---

## 15. Exception Log

**None**. All spec prohibitions are absolute. FR-004 is a hard constraint with no exceptions permitted.

---

## 16. Conclusion

**Current state**: The Today screen contains two P0 spec violations (FR-004 prohibitions on card counts and due-item numbers) and multiple P1 noise elements that compete with the primary task.

**Recommendation**: Remove all pressure indicators, remove vanity metrics, replace quantitative messaging with qualitative alternatives, demote supportive elements, and establish "Continue session" button as the single dominant focal point.

**Estimated effort**: Low (primarily removal, minimal new content)
**Risk**: Low (simplification reduces visual complexity, improves task clarity)
**Expected impact**: Improved task success rate, faster time-to-action, full FR-004 compliance, reduced user pressure/guilt.
