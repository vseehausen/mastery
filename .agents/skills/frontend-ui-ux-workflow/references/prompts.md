# Prompt Templates

Use one prompt at a time. Do not request many variants in a single run.

## 1) Screen Brief Prompt

```text
Build a concise screen brief from these inputs:
- Flutter source file(s): {paths}
- Simulator screenshots: {light_and_dark_paths}
- UX goal: {goal}
- Current pain points: {pain_points}

Return only:
1) user task on this screen,
2) current blockers,
3) measurable improvement target,
4) required states to verify.
```

## 2) Visual Direction Prompt

```text
You are a product designer-engineer improving one mobile screen.
Context:
- Product: Mastery (Flutter)
- Screen/state: {screen_state}
- Goal: {goal}
- Constraints: production-ready Flutter, token-first theming, no behavior regressions

Pick ONE distinct visual direction and define:
1) typography hierarchy,
2) spacing rhythm,
3) color/accent strategy,
4) interaction emphasis,
5) one memorable visual decision.

Return one direction only. Keep output implementation-ready.
```

## 3) Flutter Implementation Prompt

```text
Implement the approved direction for {screen_state} in Flutter.

Requirements:
- Use existing token/theme files first.
- If new token values are needed, update token/theme sources before widget styling.
- Keep behavior unchanged unless explicitly requested.
- Include explicit handling for relevant states: default/loading/error/empty/validation/disabled.
- Return exact files changed and the reason for each file.

Validation gates:
- Simulator parity in Light and Dark.
- Scroll verification at top/middle/bottom if the screen scrolls.
```

## 4) Objective QA Prompt

```text
Evaluate this implemented screen using objective UX checks only:
- readability and contrast
- tap target size and spacing
- hierarchy clarity
- task completion speed (friction points)
- empty/error/loading quality

Return:
1) pass/fail per check,
2) top 5 issues by severity,
3) minimal code-level fixes,
4) final verdict: pass or needs another pass.
```
