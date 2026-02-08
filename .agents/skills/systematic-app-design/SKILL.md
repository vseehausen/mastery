---
name: systematic-app-design
description: Systematic app design workflow from UX flows to implementation-ready UI using explicit heuristics, context overrides, prioritization, and measurable quality gates. Use when defining or redesigning app experiences, reviewing usability, preparing build-ready UI specs, or self-critiquing product decisions beyond taste-based feedback.
---

# Systematic App Design

Design apps that are easy to understand on first use, efficient on repeated use, trustworthy under failure, buildable without guesswork, and evolvable without breaking mental models.

Replace taste-based design, pixel-first workflows, and ad-hoc navigation decisions with first-principles reasoning, explicit heuristics, repeatable checklists, and enforceable quality gates.

## Core Belief

Treat visual quality as the result of correct flows, interactions, and state modeling.

## Core Belief: Subtraction First

Every screen starts with too much. The default design action is removal, not addition.

- Begin each screen by listing what could be removed, not what should be added.
- A screen is done when nothing left can be removed without breaking the user's task.
- If a choice is between adding an element and removing one, remove.
- Never polish what should be deleted.

## Rule Precedence

Apply rules in this order:

1. Hard constraints
2. Context overrides
3. Default heuristics
4. Exceptions with explicit rationale

Do not treat default heuristics as absolute rules.

## Context Overrides (Required per feature)

Define and keep visible before design work:

- product constraints (for example online-required, compliance, growth goals)
- platform constraints (mobile, desktop, web, device capabilities)
- technical constraints (API latency, sync model, architecture boundaries)
- business constraints (deadline, staffing, legal requirements)
- user constraints (novice vs expert, accessibility needs, locale requirements)

For online-required products, model `degraded-network` or `network-error` states instead of full offline feature parity unless the product explicitly supports offline operation.

## Operating Model

Design top-down in this order:

1. Define flows to determine what happens.
2. Define screens to determine where decisions are made.
3. Define interactions to determine how decisions are taken.
4. Define visual language to make decisions legible.
5. Define system and state behavior to make everything correct.
6. Run checklists to prevent regressions.

Do not use lower layers to compensate for failures in higher layers.

## Hard Constraints

- Reject screens without an explicit flow.
- Reject flows without a terminal goal.
- Never use visual polish to hide flow or interaction failures.
- Treat unclear interaction as defect, not acceptable ambiguity.
- Cross-check screen content against feature specs before design work. Flag and reject elements that violate explicit spec prohibitions.
- Treat a spec-prohibited element on screen as a P0 defect.

## Element Justification Protocol

Run this audit for every screen before applying default heuristics.

1. State the screen purpose in one sentence. The sentence names one user task.
2. List every visible element (text, icon, metric, button, decoration).
3. Classify each element:
   - Essential: directly enables the screen's single task.
   - Supportive: helps orientation or trust without enabling the task.
   - Noise: does not serve the task and does not aid orientation.
4. Remove Noise. No exceptions. If removal feels risky, the screen purpose is wrong.
5. Demote Supportive elements visually (smaller, muted, peripheral). They must not compete with Essential elements for attention.
6. Check redundancy: same data point must not appear more than once per screen.
7. Check cross-screen duplication: if data is the primary content of another tab or screen, do not duplicate it here unless it directly serves this screen's task.
8. Apply the actionability test to every remaining metric or number: "What should the user DO with this information on THIS screen?" If the answer is "nothing" or "feel good," move it to a progress or stats surface.
9. 3-second test: a new user looking at the screen must identify what to do within 3 seconds. If not, remove or demote elements until they can.

## Default Heuristics

### 1. Flow and Navigation (Default)

- Keep one flow focused on one user outcome.
- Name flows by outcome, not step.
- Target shallow navigation for primary tasks (typically 3 levels or fewer).
- Keep wayfinding explicit:
where am I
what can I do next
- Avoid dead ends.
- Use tabs as destinations (typically 3-5 top-level destinations).
- Use push navigation for drill-down.
- Use modals for short interrupting tasks.
- Keep global navigation separate from task actions.
- Define clear start, completion, and cancel behavior.
- Route cancel to a stable state.
- Recover errors in place and preserve user input.
- Expose system limits before action.
- Prefer disabled with explanation over allow-and-fail.

### 2. Interaction and UX (Default)

- Prefer one clear primary action per screen.
- Keep secondary actions visually subordinate.
- Keep destructive actions non-primary.
- Keep one decision focus per screen.
- Prefer recognition over recall.
- Prefer useful defaults over empty states.
- Split into steps when action is irreversible, complex, or high error cost.
- Keep reversible tasks on one screen when possible.
- Show immediate feedback and visible state changes.
- Zero-Latency Actions: Background processes (saving, fetching) must not block user flow.
- Show progress for long-running actions.
- Prevent errors before explaining.
- Validate inline.
- Prefer undo over confirm.
- Confirm only irreversible actions.
- Keep affordances honest and consistent.

#### 2a. Action Hierarchy (Implementation Rules)

**Purpose**: Use when designing, building, or reviewing any screen. Provides systematic framework for deciding what actions to show, where to place them, and how to style them.

**Sources**: Material Design 3 (action hierarchy, FAB, bottom sheets), Apple HIG (action sheets, context menus, swipe actions), Carbon Design System (button grouping, emphasis), Helios Design System (button ordering), NN/g research (bottom sheet guidelines, progressive disclosure).

**Non-Negotiable Rules**:

1. **One Primary Per Screen**: Every screen has exactly ONE primary action (or zero if purely informational). This is the action that moves the user forward in their goal. If you can't identify it, you don't understand the screen's purpose yet.

2. **Max 3 Visible Buttons**: At any time, the user should see at most: 1 primary + 2 secondary actions. Everything else goes into progressive disclosure (overflow menu, bottom sheet, swipe, long-press).

3. **Hierarchy Must Be Visually Obvious**: A user who has never seen the screen should be able to identify the primary action in <1 second. If they can't, your visual hierarchy is broken.

4. **Consistent Patterns Across Similar Screens**: All list screens use the same action pattern. All detail screens use the same action pattern. All edit modals use the same action pattern. No ad-hoc solutions.

**Action Tiers**:

- **🔴 Primary** (FilledButton / FAB): The ONE action that fulfills the screen's purpose. Filled button with high contrast, or FAB for creation actions. Placement: bottom of screen (sticky) for task completion, or inline with content. Flutter: `FilledButton`, `FloatingActionButton`.

- **🟡 Secondary** (OutlinedButton / IconButton in AppBar): Actions that support the primary goal (1-2 max visible). Outlined button or icon in app bar. Flutter: `OutlinedButton`, `IconButton` in `AppBar.actions`.

- **⚪ Tertiary** (TextButton / Small IconButton): Low-priority actions that are useful but not essential. Text button or small muted icon row. Feedback (👍👎) lives here — visible but quiet. Flutter: `TextButton`, small `IconButton` with muted colors.

- **📦 Overflow** (PopupMenuButton / BottomSheet): Everything else: share, export, flag, report, advanced settings. Triggered by ⋯ button or long-press. Flutter: `PopupMenuButton`, `showModalBottomSheet`.

- **❌ Destructive** (Red text, separated, with confirmation): Delete, reset, remove — always in overflow menu, never inline. Red text color, visually separated (divider above). Always requires confirmation dialog. Flutter: Red `TextStyle` in menu, `showDialog` for confirmation.

**Screen Type Templates**:

*LIST SCREEN*:
```
┌─ AppBar ───────────────────────────┐
│  Title                    🔍  ⚙️   │  ← search + sort in app bar
├────────────────────────────────────┤
│  [Filter] [Filter] [Filter]  →     │  ← horizontal scrolling chips
├────────────────────────────────────┤
│  ┌ List Item ──────────────────┐   │
│  │  Content              →     │   │  ← tap navigates to detail
│  └─────────────────────────────┘   │  ← swipe left: delete
│  ┌ List Item ──────────────────┐   │     swipe right: archive
│  │  Content              →     │   │
│  └─────────────────────────────┘   │
│                                    │
│                          [+] FAB   │  ← primary: create new item
└────────────────────────────────────┘
```
Actions: 🔴 Primary: FAB (Add) or Search bar (if finding > creating), 🟡 Secondary: Filter chips (scrollable), ⚪ Tertiary: Sort toggle (icon in app bar), 📦 Overflow: Bulk select, Export, Import, 👆 Swipe: Quick actions on items, Long-press: Context menu for item-specific actions.

*DETAIL SCREEN*:
```
┌─ AppBar ───────────────────────────┐
│  ←  Title                     ✏️   │  ← edit in app bar
├────────────────────────────────────┤
│                                    │
│  Content area                      │
│  (scrollable)                      │
│                                    │
│  👍  👎  ↻                         │  ← inline feedback (muted)
│                                    │
│  Supporting content                │
│  (examples, quotes, etc.)         │
│                                    │
├────────────────────────────────────┤
│  [ Primary Action ]          ⋯     │  ← filled btn + overflow
└────────────────────────────────────┘
```
Actions: 🔴 Primary: The forward-moving action (Practice, Start Reading, etc.), 🟡 Secondary: Edit (✏️ in app bar), ⚪ Tertiary: Feedback row (👍👎↻) — inline, muted, 1-tap, 📦 Overflow (⋯): Share, Flag, Report, Delete, ❌ Destructive: Delete at bottom of overflow menu, red, with divider.

*EDIT MODAL (Full Screen)*:
```
┌─ Header ───────────────────────────┐
│  ✕  Edit [Thing]                   │  ← X to dismiss
├────────────────────────────────────┤
│                                    │
│  Form fields                       │
│  (scrollable)                      │
│                                    │
├────────────────────────────────────┤
│  Cancel              [Save] filled │  ← sticky bottom
└────────────────────────────────────┘
```
Actions: 🔴 Primary: Save (filled, right-aligned, sticky bottom), 🟡 Secondary: Cancel (text button, left of primary), ✕ Dismiss: X in top-left (same as Cancel but more discoverable), No overflow menu needed — edit modals are focused.

*PRACTICE/INTERACTION SCREEN*:
```
┌─ Minimal AppBar ───────────────────┐
│  ✕                    ⋯            │  ← exit + overflow
├────────────────────────────────────┤
│  ━━━━━━━━━━━━━━━━━━━━ 3/20        │  ← progress bar
│                                    │
│  Card content                      │
│  (the thing being practiced)       │
│                                    │
│                                    │
├────────────────────────────────────┤
│  [Again] [Hard] [Good] [Easy]      │  ← primary: the answer
│  or                                │
│  [ Show Answer ] (single primary)  │
└────────────────────────────────────┘
```
Actions: 🔴 Primary: Answer buttons (the whole point of the screen), 🟡 Secondary: Show Answer (before revealing), ⚪ Tertiary: Skip (swipe gesture or text button), 📦 Overflow (⋯): Pause, Session settings, Report issue, ✕ Exit: Always available, top-left, with "are you sure?" if mid-session.

**Decision Checklists**:

*Before Building a Screen*:
- [ ] What is the ONE thing the user came here to do? → That's your primary action
- [ ] What supports that goal? → Those are secondary (max 2)
- [ ] What do power users occasionally need? → Overflow menu
- [ ] Is there anything destructive? → Red, separated, confirm
- [ ] Which template above matches this screen type?
- [ ] Does this pattern match other screens of the same type?

*Before Shipping a Screen*:
- [ ] Exactly 1 primary action (or 0 if informational)
- [ ] Primary is visually dominant (filled, high contrast, largest)
- [ ] ≤ 3 visible action buttons total
- [ ] Additional actions in overflow/bottom sheet
- [ ] Destructive actions: red, separated, confirmation required
- [ ] Feedback (if applicable): inline, muted, 1-tap
- [ ] All touch targets ≥ 48x48dp
- [ ] No overflow on smallest device (test 375pt width)
- [ ] Pattern consistent with other screens of same type

*Feedback Placement Decision*:
- Is feedback the CORE interaction? (practice session) → Inline, prominent, primary tier
- Is feedback about content quality? (word detail) → Inline, muted, tertiary tier
- Is feedback about app issues? (bug report) → Overflow menu
- Does feedback need explanation? (report reason) → Bottom sheet with options

**Anti-Patterns to Catch**:

| Anti-Pattern | Why It's Bad | Fix |
|--------------|--------------|-----|
| Multiple filled buttons on one screen | Destroys hierarchy, user doesn't know what to tap | One filled, rest outlined or text |
| "Preview" as primary on a detail screen | User is already viewing the content | Make practice/forward action primary |
| Feedback in overflow menu only | Nobody will use it, too many taps | Inline muted icon row for 👍👎, overflow for report |
| Buttons in middle of scrollable content | Gets lost, inconsistent position | Sticky bottom bar or clear section |
| 4+ buttons in a row | Overflow, tiny tap targets | Max 3 visible, rest in menu |
| Delete button same style as other actions | Accidental destructive actions | Red, separated, confirmation required |
| Different patterns for similar screens | Users can't build muscle memory | Use templates above consistently |
| FAB + bottom action bar | Visual conflict, unclear primary | Choose one: FAB for creation, bottom bar for completion |

### 3. Content Worth (Default)

- Every metric on screen must answer: what should the user do next?
- Metrics that inform action belong on action screens. Metrics that reflect on outcomes belong on progress screens. Never mix.
- Vanity metrics (totals, counts, streaks-as-decoration) are noise on action screens.
- If removing a number does not change the user's next action, the number does not belong on this screen.
- Prefer qualitative status ("You're done," "Ready to learn") over quantitative status ("47 cards due," "350 words saved") on action screens.
- Card counts, backlog sizes, and due-item numbers are pressure indicators. Show them only on screens explicitly designed for progress review, never on primary action surfaces.
- When in doubt, remove the metric. It can always be added to a dedicated stats surface later.

### 4. Visual Design and Aesthetics (Default)

- Keep one dominant focal point per screen.
- Encode importance with size, contrast, and position.
- Remove elements before adding decoration.
- Prefer spacing over borders.
- Keep strict alignment and spacing rhythm.
- Use proximity and similarity to signal grouping.
- Use two typefaces max.
- Keep a clear type scale and readable line length.
- Avoid centered body text.
- Start neutral and use one accent family per screen.
- Use color to encode meaning, not decoration.
- Reserve red for danger and error.
- Default to comfortable density.
- Use dense layouts only for expert views.
- Prefer clarity over cleverness.
- Prioritize visual calm: screen should feel restful, not busy.
- Provide breathing room: generous whitespace around the focal point and primary action.
- Practice purposeful restraint: fewer elements done well always beats more elements done adequately.
- Follow the order: Remove, then Simplify, then Polish. Never polish what should be removed.
- Test with the removal rule: if removing an element does not hurt task completion, keep it removed.

### 5. System, Trust, and Reality (Default)

- Model each screen as explicit state.
- Design loading, ready, empty, error, and degraded-network states.
- Avoid impossible states.
- Show immediate visual response.
- Use skeletons or progress for delay.
- Use optimistic UI by default for all non-critical actions.
- Background all saving and fetching operations; never block the UI for network latency.
- Show consequences before commitment.
- Make permissions and limits visible.
- Keep history or logs available for trust.
- Ensure keyboard navigability and screen-reader semantics.
- Never rely on color alone.
- Keep touch targets adequate.
- Keep motion optional.
- Keep text out of images.
- Tolerate text expansion and locale formatting.
- Consider RTL early.
- Provide guidance for novices and shortcuts for experts.
- Preserve mental models across product evolution.
- Map UI cleanly to code and state ownership.
- Use tokens as source of truth.
- Do not allow UI behavior without specification.

## Exception Policy

Allow exceptions only when all conditions are met:

- state the specific rule being overridden
- provide context-based rationale
- describe user impact and risk
- define mitigation
- add test coverage for the exception

Record exceptions in the output contract.

## Prioritization Model

Classify issues by user harm, frequency, and implementation effort.

- `P0`: blocks core job completion, causes data loss, breaks trust, or creates severe accessibility barrier
- `P1`: causes significant friction, confusion, repeated errors, major performance pain, or places unnecessary or spec-prohibited elements on screen
- `P2`: clarity or polish issue with low user harm

Fix order:

1. P0 first
2. P1 second
3. P2 last

Within same priority, prefer lower effort fixes that reduce high-frequency pain first.

## Measurable Acceptance Gates

Define and report these gates for core flows:

- task success rate target (recommended >= 90%)
- median completion time target (recommended <= current baseline, or <= baseline + 10% when baseline is unstable)
- unrecovered error rate target (recommended <= 2% on critical flows)
- error recovery success target (recommended >= 80%)
- user-facing regression budget (define allowed deltas for latency and completion metrics)

If no baseline exists, define provisional targets and mark as `needs calibration`.

## Accessibility Acceptance Gates (WCAG 2.2 AA)

Minimum pass checks:

- text contrast >= 4.5:1 (normal text)
- text contrast >= 3:1 (large text)
- non-text UI contrast >= 3:1
- mobile touch target >= 44x44 px
- focus indicator visible for keyboard navigation
- interactive controls have accessible names and roles
- errors exposed to assistive tech and linked to affected inputs
- color not used as sole signal
- reduced motion respected where animations can affect usability

## Checklists

### A. App-Level Checklist

- Define primary user jobs.
- Identify the core loop.
- Define top-level navigation (3-5 destinations).
- Define global states (auth, sync, degraded-network).
- Define design tokens and component primitives.
- Define loading and performance policy.
- Define trust, safety, and undo policy.
- Define accessibility baseline.
- Define analytics funnels.
- Define context overrides for this feature.
- Define prioritization policy for this release.
- Define measurable acceptance gates.

### B. Flow Checklist

- Name flow by user outcome.
- Define one terminal goal.
- Define explicit start and end.
- List happy path.
- Keep depth at 3 or less.
- Define entry, exit, and cancel paths.
- Define loading, empty, error, and degraded-network paths.
- Preserve progress during recovery.
- Show limits before action.
- Keep structure consistent with similar flows.
- Assign P0/P1/P2 risk for each known failure mode.
- Define measurement hooks for success, time, and recovery.

### C. Screen Checklist

- Define screen name and purpose.
- Define entry points.
- Define exit points.
- Define back versus close semantics.
- Define one primary action (reference Action Hierarchy section 2a).
- Define secondary actions (max 2 visible, reference Action Hierarchy section 2a).
- Verify action hierarchy compliance:
  - Exactly 1 primary action (or 0 if informational)
  - Primary is visually dominant (filled, high contrast, largest)
  - ≤ 3 visible action buttons total
  - Additional actions in overflow/bottom sheet
  - Destructive actions: red, separated, confirmation required
  - Pattern matches screen type template (List/Detail/Edit/Practice)
- Define state model:
loading
ready
empty
error
degraded-network
- Define interaction rules:
decision count
defaults
validation
undo or confirm
- Define focal point and visual hierarchy.
- Define explicit accessibility pass checks.
- Define analytics events.
- Cover edge cases.
- Record any exceptions with rationale and mitigation.
- Run Element Justification Protocol. Record classification for each element.
- Verify no redundant data (same information in multiple places on screen).
- Verify no unjustified cross-screen duplication.
- Pass the 3-second test: user can identify what to do within 3 seconds.
- Cross-check screen content against relevant feature specs for explicit prohibitions.
- Verify screen feels visually calm: restful whitespace, clear focal point, no competing elements.

### D. UI Element Checklist

- Keep tabs for destinations only.
- Keep nav bars with title and contextual actions.
- Keep one primary CTA with outcome language.
- Define loading and empty states for all lists.
- Use modals for short interrupting tasks with clear exit.
- Ensure errors explain and recover.
- Ensure feedback is immediate and visible.
- Keep typography readable and consistent.
- Keep color meaningful and restrained.
- Verify target size and contrast thresholds.
- Verify screen-reader labels for interactive controls.
- Verify every metric passes the actionability test.
- Verify no vanity metrics on action screens.

## Output Contract

When applying this skill, return:

- flow map and terminal goals
- per-screen decision model and primary action
- state matrix (loading, ready, empty, error, degraded-network)
- interaction and error-recovery rules
- visual hierarchy decisions and token strategy
- implementation notes mapping UI behavior to code/state ownership
- checklist pass or fail report with explicit failures
- prioritization table (`P0/P1/P2`, user harm, effort, recommendation)
- measurable gate report (target, observed, pass/fail, calibration status)
- accessibility gate report (each WCAG check pass/fail)
- exception log (rule, rationale, mitigation, validation status)
- element justification log (per screen: element, classification, disposition)
- spec compliance cross-check (spec ID, prohibition, screen element, pass/fail)
