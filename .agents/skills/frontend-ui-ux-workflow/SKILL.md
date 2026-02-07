---
name: frontend-ui-ux-workflow
description: Flutter-first UI/UX improvement workflow for Mastery. Use when improving or redesigning mobile screens, selecting one bold visual direction per screen, applying changes in Flutter before design tools, using Pencil in a lightweight flow-map mode, and validating Light/Dark simulator parity with objective UX checks.
---

# Frontend UI/UX Workflow

Use this skill to ship measurable UI improvements without maintaining full design-file parity.

## Operating Model

- Keep Flutter code as the single source of truth for tokens and behavior.
- Keep colors, spacing, and typography tokenized in `mobile/lib/core/theme/color_tokens.dart` and theme files.
- Use Pencil only in `Pencil-lite` mode:
  - Flow map (screen order)
  - Key states
  - Component examples
- Avoid mirroring every runtime state in Pencil.
- Create one improved variant per screen iteration, not many alternatives.

## Repo Anchors

- Token source: `mobile/lib/core/theme/color_tokens.dart`
- Theme source: `mobile/lib/core/theme/app_theme.dart`
- Screen code: `mobile/lib/features/**/screens/*.dart`
- Optional design board: `design/mastery-design.pen`

## Required Loop (Per Screen)

1. Scope one flow and one target screen/state.
2. Gather inputs: Flutter source, simulator screenshots, and UX goal.
3. Choose one strong visual direction and define hierarchy before coding.
4. Implement in Flutter first (tokens, then components, then layout).
5. Validate in simulator in Light and Dark.
6. Validate scrollable screens at top, middle, and bottom.
7. Run objective QA checks from `references/qa-checklist.md`.
8. Stop only when done criteria in `references/done-criteria.md` pass.

## Flow Batching

- Finish one flow fully before moving to the next.
- Use this default order unless current product priorities override it:
1. Auth
2. Learn Session
3. Vocabulary Detail
4. Settings

## References

- Workflow details: `references/workflow.md`
- Prompt templates: `references/prompts.md`
- QA checklist: `references/qa-checklist.md`
- Done criteria: `references/done-criteria.md`
- Distinctive frontend doctrine: `references/distinctive-frontend-design.md`
- First trial target: `references/trial-auth-screen.md`

## Output Contract

Return:

- Target screen and state
- Files changed
- Token/theme deltas
- Objective QA results
- Ship verdict: `pass` or `needs another pass`
