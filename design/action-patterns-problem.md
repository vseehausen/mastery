# Problem Definition: Action Button Patterns & Hierarchy

**Date:** 2026-02-08
**Status:** Problem definition for design system
**Audience:** Designer

---

## The Problem

We don't have a consistent, systematic pattern for handling actions across the app. This leads to:
1. **Action overflow** (too many buttons don't fit on screen)
2. **Unclear hierarchy** (which actions are primary/secondary/tertiary?)
3. **Inconsistent patterns** (feedback mechanisms scattered across different UI patterns)
4. **Poor scalability** (adding new actions breaks layouts)

### Recent Example: Vocabulary Detail Screen

**Initial attempt:**
```
[Preview Cards] [👍] [👎] [🚩] [⋮ More]
     ↑ expanded   ↑ 3 icon buttons  ↑ menu with 1 item
```

**Problems identified:**
- 5 buttons total → 24px overflow on iPhone screen
- "Way too many options" visible (cognitive overload)
- Menu contained only 1 item (re-generate) → bad UX pattern
- Feedback actions (thumbs/flag) given same visual weight as primary action
- No clear visual hierarchy (everything looks equally important)

**Current solution:**
```
[Preview] [⋮ Menu]
   ↑ primary  ↑ contains: feedback + re-generate
```

**Still problematic:**
- Hides feedback behind menu (was it better visible?)
- "Preview" not really the primary action (reading the word is)
- Pattern doesn't scale to other screens

---

## Why This Is a Systemic Problem

This isn't just about one screen. The same issues appear across the app:

### 1. **Vocabulary List Screen**
- Add vocabulary button
- Filter/sort controls
- Bulk actions (when selecting multiple items)
- Future: export, share, archive actions

### 2. **Practice Session Screen**
- Skip card
- Pause session
- Settings/options
- Report issue with card
- Future: hints, explanations, audio

### 3. **Card Preview Modal**
- Navigate between cards
- Edit card
- Flag issues
- Close modal

### 4. **Source Detail Screen**
- Edit source
- Add notes
- Archive/delete
- Share
- Future: re-sync, export highlights

### 5. **Settings Screen**
- Multiple action buttons per section
- Destructive actions (logout, delete account)
- Primary actions (save, sync)

---

## Design Constraints

### Technical Constraints
- **Screen width:** iPhone SE (375px) to iPhone Pro Max (428px)
- **Touch target minimum:** 44x44 points (iOS HIG)
- **Safe area:** Account for notch, home indicator, keyboard
- **One-handed use:** Bottom 1/3 of screen is prime real estate

### UX Constraints
- **Discoverability:** Important actions must be visible without exploration
- **Reversibility:** Destructive actions need confirmation
- **Cognitive load:** Max 3-4 visible choices at once (Hick's Law)
- **Context preservation:** Menus/sheets shouldn't lose scroll position

### Brand Constraints
- **Minimal cognitive noise** (Design Brief 2) - no instructional hints
- **Clean, focused interface** - content over chrome
- **Subtle actions** - available but not dominant

---

## Questions for Designer

### 1. Action Hierarchy Pattern
How should we systematically categorize and display actions?

**Example hierarchy:**
- **Primary:** The main thing users come here to do (1 action max)
- **Secondary:** Common supporting actions (2-3 actions)
- **Tertiary:** Less common, contextual actions (menu/overflow)
- **Destructive:** Dangerous actions (needs confirmation pattern)
- **Feedback:** Quality/issue reporting (separate pattern?)

**Current confusion:**
- Is "Preview cards" primary or secondary?
- Are feedback actions (thumbs/flag) secondary or tertiary?
- Should re-generate be visible or hidden?

### 2. Button Treatment Scale
What visual treatments should each level get?

**Options to consider:**
```
Primary:     [Solid button] or [Large outline] or [FAB]?
Secondary:   [Outline button] or [Icon + label] or [Text button]?
Tertiary:    [Icon only] or [Menu item] or [Swipe action]?
Feedback:    [Inline icons] or [Sheet] or [Context menu]?
Destructive: [Red outline] or [Sheet with confirm] or [Swipe to delete]?
```

### 3. Responsive Patterns
How do actions adapt to screen width and content?

**Scenarios:**
- **Vocabulary detail:** Content screen with optional actions
- **Practice session:** Action-heavy, full-screen interaction
- **List screen:** Row actions + bulk actions + global actions

**Questions:**
- When do we collapse buttons into menus?
- Do we use bottom sheets, popovers, or context menus?
- Should primary actions be fixed (sticky) or scroll away?

### 4. Feedback Action Pattern
Where/how should quality feedback (thumbs/flag) be handled?

**Current state:** Inconsistent
- Detail screen: Icons in action bar → Now in menu
- Card preview: Not present
- Practice session: Implicit (card difficulty rating)

**Options:**
- Always visible but subtle (inline icons)
- Always in menu (consistent location)
- Swipe gestures (like email apps)
- Long-press context menu
- Dedicated feedback button that opens sheet

### 5. Multi-Screen Consistency
Should the same action type always use the same pattern?

**Examples:**
- "Edit" action: Always in header? Always first in menu? Icon or text?
- "Delete" action: Always swipe-to-delete? Always in menu? Always needs confirm?
- "Share" action: Always in overflow? Always uses native share sheet?

---

## Success Criteria

A successful design system for actions should:

1. **Be teachable** - Engineers can look at a screen and know which pattern to use
2. **Be scalable** - Adding a new action doesn't break the layout or hierarchy
3. **Be consistent** - Same action types use same patterns across screens
4. **Be accessible** - Touch targets, VoiceOver, Dynamic Type all work
5. **Be performant** - No jank, smooth animations, instant feedback
6. **Be maintainable** - Implemented as reusable components/widgets

---

## Deliverables Requested

1. **Action Hierarchy Framework**
   - Definition of primary/secondary/tertiary/destructive/feedback
   - Decision tree: "I have action X, which level is it?"
   - Visual examples for each level

2. **Component Patterns**
   - Button variations (solid, outline, text, icon)
   - Menu patterns (bottom sheet, popover, context menu)
   - Action bar layouts (1 action, 2 actions, 3+ actions)
   - Responsive breakpoints (when to collapse)

3. **Screen-Specific Applications**
   - Apply pattern to: vocabulary detail, practice session, list screen
   - Show before/after for each
   - Handle edge cases (no actions, many actions, destructive actions)

4. **Implementation Guide**
   - When to use each pattern
   - Flutter widget recommendations
   - Spacing, sizing, color tokens
   - Animation/transition specs

---

## Reference Examples

### Good Examples (Industry)
- **Apple Mail:** Swipe actions + toolbar + menu hierarchy is clear
- **Things 3:** Action hierarchy is obvious, scales well
- **Notion:** Context menus work well, actions feel discoverable

### Bad Examples (What We're Avoiding)
- **Settings panels with too many buttons** - cognitive overload
- **Gmail's endless nested menus** - actions not discoverable
- **Microsoft apps with ribbon overload** - too much chrome

---

## Open Questions

1. Should we use native iOS patterns (swipe actions, context menus) or custom?
2. Do we need a FAB (floating action button) pattern for primary actions?
3. How do we handle actions that need input (edit, create) vs instant actions (delete, share)?
4. Should destructive actions always be in menus, or can they be visible with confirmation?
5. How do we indicate that a menu has items without showing "⋮" everywhere?

---

## Timeline

- **Problem definition:** Today (this document)
- **Design exploration:** 2-3 days
- **Review & iterate:** 1-2 days
- **Specification:** 1 day
- **Implementation:** Ongoing (per screen)

---

## Context: What Led Here

We recently restructured the vocabulary detail screen:
- Removed ExpansionTiles (flattened UI)
- Removed card borders (cleaner aesthetic)
- Consolidated actions into fewer buttons

But we discovered:
- Initial action bar had 5 buttons (overflow)
- Feedback mechanisms felt scattered
- No clear primary action
- Adding more features would make it worse

This revealed that we need a **systematic approach**, not one-off solutions.

---

## Notes

- This affects both mobile app design and (future) web app
- Should integrate with existing design system (MasteryColorScheme, shadcn components)
- Must work with current Flutter/shadcn_ui component library
- Should consider accessibility from the start (VoiceOver, Switch Control, etc.)
