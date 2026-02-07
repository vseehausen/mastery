# Mobile Navigation Contract

Last updated: 2026-02-07

## Primary Destinations (Bottom Tabs)

- `Today` (`HomeScreen` index 0): daily decision and session entry.
- `Words` (`HomeScreen` index 1): vocabulary browse/search and word drill-down.
- `Progress` (`HomeScreen` index 2): outcomes and settings entry points.

Rules:
- Tabs are destinations, never direct task actions.
- Tab order and labels are invariant across contexts.

## Route Semantics

### Push Routes (`Navigator.push`)

Use for drill-down and context-preserving details.

- `Today -> SessionScreen`
- `Today -> NoItemsReadyScreen`
- `Today -> SyncStatusScreen`
- `Today -> SettingsScreen`
- `Words -> VocabularyDetailScreen`
- `Progress -> LearningSettingsScreen`
- `Progress -> SettingsScreen`

Back behavior:
- Returns to previous stable screen with prior state preserved.

### Replace Routes (`Navigator.pushReplacement`)

Use for flow terminal transitions.

- `SessionScreen -> SessionCompleteScreen`
- Auth email subflows complete/cancel back to auth entry screens as defined in auth flow.

Back behavior:
- Returns to prior stable surface outside completed step (not to obsolete intermediate state).

### Modal Routes (`showDialog`, `showModalBottomSheet`)

Use for short interrupting decisions only.

- Confirm exit session
- Confirm sign out
- Confirm re-generate enrichment
- Feedback category selector bottom sheet

Cancel behavior:
- Dismisses modal and returns to unchanged underlying screen state.

## Close vs Back Semantics

- Back (`leading back arrow`): for pushed detail screens.
- Close (`X`): only for active session interruption where user remains in same parent flow.

## Global State Visibility Contract

- Offline or sync-risk states are surfaced globally above tab bar.
- Banner actions are constrained:
  - Offline: retry connectivity/status
  - Syncing: open sync details
  - Sync error: refresh sync status providers

## Error Recovery Contract

- Recovery happens in place whenever possible.
- User input is preserved on recoverable errors.
- No forced restart of a full flow unless session state is invalid or expired.
