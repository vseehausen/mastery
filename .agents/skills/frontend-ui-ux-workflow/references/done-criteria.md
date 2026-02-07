# Done Criteria

All items must pass before moving to the next screen.

## Scope Completion

- Target screen and state are explicitly named.
- UX goal for this pass is explicitly named.
- No unrelated screen changes are bundled into the same pass.

## Implementation Completion

- Flutter implementation is complete for the target state.
- Required supporting states are implemented (loading/error/empty/validation/disabled where relevant).
- Token/theme updates are centralized and consistent with existing theme architecture.

## Validation Completion

- QA checklist (`references/qa-checklist.md`) has no `fail` items.
- Simulator verification is complete in Light and Dark.
- Scroll verification is complete at top/middle/bottom for scrollable screens.

## Regression Safety

- Core user task behavior is unchanged unless explicitly requested.
- No new visual blockers for navigation or task completion are introduced.
- Changed files and rationale are documented in the task summary.

## Ship Verdict

- Final verdict is `pass`.
- If any item fails, verdict is `needs another pass`.
