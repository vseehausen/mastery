# UI Improvement Workflow (Flutter-First, Pencil-Lite)

## 1) Select Scope

- Choose one flow.
- Choose one screen and one target state in that flow.
- Define one concrete UX goal and one measurable success signal.

## 2) Gather Inputs

- Read relevant Flutter screen and shared widgets.
- Capture simulator screenshots in Light and Dark.
- Capture top/middle/bottom for scrollable screens.
- Collect constraints (must-keep behavior, deadlines, platform rules).

## 3) Define Direction

- Pick one bold but coherent visual direction.
- Define typography hierarchy, spacing rhythm, and accent strategy.
- Decide one memorable visual move that supports task clarity.

## 4) Implement in Flutter

- Update token/theme sources first when needed.
- Apply component styling updates second.
- Apply layout/composition updates third.
- Preserve behavior unless explicitly changed.

## 5) Validate Objectively

- Run the checklist in `references/qa-checklist.md`.
- Fix `fail` items with the smallest safe code changes.
- Re-check in simulator after each fix pass.

## 6) Freeze and Record

- Confirm done criteria in `references/done-criteria.md`.
- Record screen/state completed and changed file list.
- Move to next screen only after a `pass` verdict.

## Pencil-Lite Rules

- Maintain only a flow map, key states, and component examples.
- Avoid full visual parity maintenance for every runtime state.
- Trust simulator runtime output over design board assumptions.

## Recommended Flow Order

1. Auth
2. Learn Session
3. Vocabulary Detail
4. Settings
