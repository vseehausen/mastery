# UI/UX QA Checklist (Screen-Level)

Mark each item as `pass` or `fail`.

## Readability and Contrast
- Body text remains readable without zoom in both Light and Dark.
- Primary and secondary text maintain clear contrast against background.
- Disabled and helper text remain legible and clearly lower emphasis.

## Tap Targets and Spacing
- Primary interactive controls are comfortably tappable (target around 44x44dp or larger).
- Adjacent tappable elements have enough spacing to prevent mis-taps.
- Edge actions are not clipped by safe area or keyboard.

## Hierarchy and Clarity
- Screen title, primary content, and primary action are identifiable in under 2 seconds.
- One primary action is visually dominant; secondary actions stay clearly secondary.
- Visual grouping reflects task order and mental model.

## State Quality
- Relevant states exist and are visually distinct: default/loading/error/empty.
- Forms include validation feedback and disabled affordance when needed.
- Loading and error messaging explains what is happening and what to do next.

## Task Completion Friction
- Core user task can be completed with minimal detours and no ambiguous steps.
- Scroll depth required for the core task is reasonable for the screen context.
- No control needed for task completion is hidden behind unclear affordances.

## Theme and Runtime Verification
- Screen is verified in simulator for both Light and Dark.
- Scrollable screens are verified at top, middle, and bottom in both themes.
- Simulator runtime rendering is treated as source of truth over static assumptions.
