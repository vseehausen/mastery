# First Trial: Auth Flow

## Target

- Flow: `Auth`
- Screen: `mobile/lib/features/auth/presentation/screens/auth_screen.dart`
- State: Default (no error), plus error banner variant

## UX Goal

- Make primary sign-in choices clearer in under 2 seconds.
- Reduce visual noise while preserving trust and clarity.

## Inputs for the Loop

- Flutter source:
  - `mobile/lib/features/auth/presentation/screens/auth_screen.dart`
  - `mobile/lib/features/auth/presentation/widgets/oauth_button.dart`
  - `mobile/lib/features/auth/presentation/widgets/auth_logo.dart`
  - `mobile/lib/features/auth/presentation/widgets/auth_divider.dart`
- Simulator captures required:
  - Light: top and bottom
  - Dark: top and bottom
  - Error message shown in at least one theme

## Execution

1. Generate a screen brief with the Screen Brief Prompt.
2. Generate one visual direction with the Visual Direction Prompt.
3. Implement in Flutter with token-first updates only where needed.
4. Run QA checklist and done criteria.
5. Return verdict: `pass` or `needs another pass`.
