---
name: systematic-app-design
description: Systematic app design workflow from UX flows to implementation-ready UI using explicit heuristics, context overrides, prioritization, and measurable quality gates. Use when defining or redesigning app experiences, reviewing usability, preparing build-ready UI specs, or self-critiquing product decisions beyond taste-based feedback.
---

# Systematic App Design

Design apps that are easy to understand on first use, efficient on repeated use, trustworthy under failure, buildable without guesswork, and evolvable without breaking mental models.

Replace taste-based design, pixel-first workflows, and ad-hoc navigation decisions with first-principles reasoning, explicit heuristics, repeatable checklists, and enforceable quality gates.

## Core Belief

Treat visual quality as the result of correct flows, interactions, and state modeling.

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
- Show progress for long-running actions.
- Prevent errors before explaining.
- Validate inline.
- Prefer undo over confirm.
- Confirm only irreversible actions.
- Keep affordances honest and consistent.

### 3. Visual Design and Aesthetics (Default)

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

### 4. System, Trust, and Reality (Default)

- Model each screen as explicit state.
- Design loading, ready, empty, error, and degraded-network states.
- Avoid impossible states.
- Show immediate visual response.
- Use skeletons or progress for delay.
- Use optimistic UI only when safe.
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
- `P1`: causes significant friction, confusion, repeated errors, or major performance pain
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
- Define one primary action.
- Define secondary actions.
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
