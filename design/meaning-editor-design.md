# Design Brief: Meaning Editor Screen

**Screen:** Edit Meaning (currently MeaningEditor widget)
**Status:** Design specification from mockup
**Date:** 2026-02-08

---

## Overview

Clean, focused form for editing vocabulary word meanings. Emphasizes clarity, good spacing, and smart interaction patterns (tag-based inputs for multi-value fields).

---

## Layout Structure

```
┌─────────────────────────────────────┐
│ [×]      Edit Meaning          [ ]  │  ← Header (sticky)
├─────────────────────────────────────┤
│                                     │
│ TRANSLATION                         │  ← Scrollable content
│ [Schmierfett                    ]   │
│                                     │
│ DEFINITION                          │
│ [Grease is a thick, oily        ]   │
│ [substance used for...          ]   │
│                                     │
│ PART OF SPEECH                      │
│ [Noun                           ▾]  │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ SYNONYMS                   3 added  │
│ [Add a synonym...              +]   │
│ [lubricant ×] [oil ×] [slime ×]     │
│                                     │
│ ALT TRANSLATIONS                    │
│ [Add translation...            +]   │
│ [Fett ×] [Öl ×] [Schmiermittel ×]   │
│                                     │
├─────────────────────────────────────┤
│ [Cancel]         [Save Changes]     │  ← Footer (sticky)
└─────────────────────────────────────┘
```

---

## Component Specifications

### Header (Sticky)
```dart
AppBar(
  backgroundColor: Colors.white.withOpacity(0.8),
  backdropFilter: blur(10),
  leading: IconButton(
    icon: Icon(Icons.x, size: 20),
    onPressed: () => Navigator.pop(context),
  ),
  title: Text('Edit Meaning', fontSize: 15, fontWeight: semibold),
  centerTitle: true,
)
```

**Styling:**
- Height: ~56px (including status bar padding)
- Background: white/80% + backdrop blur
- Border bottom: 1px zinc-100
- Elevation: 0 (uses border instead)

---

### Form Fields

#### 1. Text Input (Translation, single-line)
```dart
Column(
  crossAxisAlignment: start,
  children: [
    Text(
      'TRANSLATION',
      style: TextStyle(
        fontSize: 10,
        fontWeight: medium,
        color: zinc-500,
        letterSpacing: 0.05em,
      ),
    ),
    SizedBox(height: 8),
    TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: zinc-50,
        border: OutlineInputBorder(
          borderRadius: 12,
          borderSide: BorderSide(color: zinc-200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: 12,
          borderSide: BorderSide(color: zinc-400),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      style: TextStyle(fontSize: 15, color: zinc-900),
    ),
  ],
)
```

**States:**
- Default: zinc-50 background, zinc-200 border
- Focus: white background, zinc-400 border, 4px zinc-100 ring
- Hover: (desktop only) subtle border darkening

**Dimensions:**
- Border radius: 12px
- Horizontal padding: 14px
- Vertical padding: 12px
- Font size: 15px

---

#### 2. Textarea (Definition, multi-line)
Same as text input, but:
```dart
TextField(
  maxLines: 3,
  // ... same decoration
)
```

**Specifics:**
- Initial rows: 3
- Resize: none (fixed height)
- Line height: 1.6 (relaxed reading)

---

#### 3. Dropdown (Part of Speech)
```dart
DropdownButtonFormField(
  decoration: InputDecoration(
    // ... same as text input
    suffixIcon: Icon(Icons.chevron_down, size: 16, color: zinc-400),
  ),
  items: [
    DropdownMenuItem(value: 'noun', child: Text('Noun')),
    DropdownMenuItem(value: 'verb', child: Text('Verb')),
    DropdownMenuItem(value: 'adjective', child: Text('Adjective')),
    // ... etc
  ],
)
```

**Icon:**
- chevron-down (16px, zinc-400)
- Position: right-aligned, 14px from edge
- Hover state: zinc-600

---

#### 4. Tag Input (Synonyms, Alt Translations)

**Layout:**
```dart
Column(
  children: [
    // Label + count
    Row(
      mainAxisAlignment: spaceBetween,
      children: [
        Text('SYNONYMS', style: labelStyle),
        Text('3 added', style: TextStyle(
          fontSize: 10,
          color: zinc-400,
          fontWeight: medium,
        )),
      ],
    ),
    SizedBox(height: 12),

    // Input with inline add button
    Stack(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Add a synonym...',
            // ... same as above
            contentPadding: EdgeInsets.only(
              left: 14,
              right: 40, // space for button
              top: 12,
              bottom: 12,
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: IconButton(
            icon: Icon(Icons.plus, size: 16),
            onPressed: () => _addTag(),
            style: IconButton.styleFrom(
              foregroundColor: zinc-400,
              hoverForegroundColor: zinc-900,
              backgroundColor: transparent,
              hoverBackgroundColor: zinc-200,
            ),
          ),
        ),
      ],
    ),
    SizedBox(height: 12),

    // Tag chips
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => TagChip(
        label: tag,
        onDelete: () => _removeTag(tag),
      )).toList(),
    ),
  ],
)
```

**Tag Chip:**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: white,
    border: Border.all(color: zinc-200),
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: zinc-900.withOpacity(0.05),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: min,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: medium,
          color: zinc-700,
        ),
      ),
      SizedBox(width: 6),
      GestureDetector(
        onTap: onDelete,
        child: Icon(
          Icons.x,
          size: 12,
          color: zinc-400,
          hoverColor: red-500,
        ),
      ),
    ],
  ),
)
```

**Interactions:**
- Type in input → press Enter or click + button → adds tag
- Click × on tag → removes tag
- Tags wrap to multiple lines if needed
- Max width: container width

---

### Divider
```dart
Container(
  height: 1,
  color: zinc-100,
  margin: EdgeInsets.symmetric(vertical: 24),
)
```

Used to separate sections (between Part of Speech and Synonyms).

---

### Footer (Sticky)

```dart
Container(
  decoration: BoxDecoration(
    color: white.withOpacity(0.9),
    border: Border(top: BorderSide(color: zinc-100)),
  ),
  padding: EdgeInsets.only(
    left: 24,
    right: 24,
    top: 16,
    bottom: 32, // extra for home indicator
  ),
  child: Row(
    spacing: 12,
    children: [
      Expanded(
        child: ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
          height: 48,
        ),
      ),
      Expanded(
        child: ShadButton(
          onPressed: _saveChanges,
          child: Text('Save Changes'),
          height: 48,
        ),
      ),
    ],
  ),
)
```

**Button specs:**
- Height: 48px
- Border radius: 12px
- Font size: 15px
- Font weight: medium (Cancel), semibold (Save)
- Active state: scale(0.98)

---

## Spacing System

```
Header: 56px (fixed, sticky top)
  ↓
Content padding: 24px horizontal, 24px top
  ↓
Field spacing: 24px between fields
  ↓
Label to input: 8px
  ↓
Input to tags: 12px
  ↓
Footer: 64px (16px padding top + 48px buttons + safe area)
```

**Internal field spacing:**
- Label → Input: 8px
- Input → Tags: 12px
- Tag spacing: 8px horizontal, 8px vertical (wrap)

---

## Typography Scale

| Element | Size | Weight | Color | Transform |
|---------|------|--------|-------|-----------|
| Header title | 15px | 600 | zinc-900 | - |
| Field label | 10px | 500 | zinc-500 | uppercase, +5% tracking |
| Input text | 15px | 400 | zinc-900 | - |
| Placeholder | 15px | 400 | zinc-400 | - |
| Tag label | 13px | 500 | zinc-700 | - |
| Tag count | 10px | 500 | zinc-400 | - |
| Button text | 15px | 500/600 | - | - |

---

## Color Palette

```dart
// Backgrounds
bg-zinc-50:   #FAFAFA  // Input default
bg-white:     #FFFFFF  // Input focused, tags
bg-zinc-100:  #F4F4F5  // Cancel button
bg-zinc-900:  #18181B  // Save button

// Borders
border-zinc-100: #F4F4F5  // Divider, footer border
border-zinc-200: #E4E4E7  // Input default, tag
border-zinc-400: #A1A1AA  // Input focused

// Text
text-zinc-400: #A1A1AA  // Placeholder, icons, count
text-zinc-500: #71717A  // Labels
text-zinc-600: #52525B  // Cancel button
text-zinc-700: #3F3F46  // Tags
text-zinc-900: #18181B  // Input text, header
text-white:    #FFFFFF  // Save button

// Focus ring
ring-zinc-100: #F4F4F5 @ 100% opacity, 4px blur
```

---

## Interaction Patterns

### Adding a Tag
1. User types in input field
2. User presses Enter OR clicks + icon
3. If value not empty and not duplicate:
   - Add tag to list
   - Clear input field
   - Focus returns to input
4. If duplicate: show subtle error (shake animation?)

### Removing a Tag
1. User clicks × on tag chip
2. Tag fades out (200ms)
3. Remaining tags reflow with animation

### Form Validation
- Translation: Required, min 1 character
- Definition: Optional
- Part of speech: Required (default to first option)
- Synonyms: Optional
- Alt translations: Optional

### Save Behavior
1. User clicks "Save Changes"
2. Button shows loading state (spinner)
3. Validate all fields
4. If valid: Save to backend → Close modal → Show success toast
5. If invalid: Highlight errors, scroll to first error

### Cancel Behavior
1. User clicks "Cancel" or × header button
2. If form dirty (has changes):
   - Show confirmation dialog: "Discard changes?"
3. If confirmed or form clean:
   - Close modal

---

## Focus Management

**Tab order:**
1. Close button (header)
2. Translation input
3. Definition textarea
4. Part of speech dropdown
5. Synonyms input
6. (tags are not in tab order, use keyboard to delete?)
7. Alt translations input
8. Cancel button
9. Save button

**Focus ring:**
- 4px solid ring
- Color: zinc-100
- Applied to: inputs, buttons
- Visible only on keyboard focus (not mouse click)

---

## Responsive Behavior

**Mobile (default):**
- Single column
- Footer buttons equal width (1:1 ratio)
- Horizontal padding: 24px

**Tablet/Desktop (future):**
- Max width: 600px, centered
- Footer buttons proportional (Cancel narrower, Save wider?)
- Horizontal padding: increased to 32px?

---

## Accessibility

- **Labels:** All inputs have visible labels (not placeholders as labels)
- **Focus indicators:** Clear 4px ring on keyboard focus
- **Touch targets:** Minimum 44x44pt for all interactive elements
- **Screen readers:** Proper ARIA labels, semantic HTML
- **Keyboard navigation:** Full tab order, Enter to submit, Escape to cancel
- **Color contrast:** All text meets WCAG AA (4.5:1 minimum)

---

## Edge Cases

### Empty State
- No synonyms: Input visible, no tags, no "X added" count
- No alt translations: Same as above

### Long Values
- Long translation: Single line, scrolls horizontally? Or wraps?
- Long definition: Textarea expands? Or scrolls internally?
- Long tag label: Truncate with ellipsis? Or wrap?

**Decision needed:** How to handle overflow in each case.

### Many Tags
- 10+ synonyms: Wrap to multiple rows, scroll container if needed
- Maintain 8px spacing, wrap naturally

### Validation Errors
- Show error below field (red text, icon)
- Highlight field border in red
- Scroll to first error on submit

---

## Animation Specs

**Input focus:**
- Duration: 200ms
- Easing: cubic-bezier(0.4, 0, 0.2, 1)
- Properties: background-color, border-color, box-shadow

**Tag add:**
- Duration: 150ms
- Easing: ease-out
- Animation: scale(0.8) → scale(1), opacity 0 → 1

**Tag remove:**
- Duration: 200ms
- Easing: ease-in
- Animation: scale(1) → scale(0.8), opacity 1 → 0

**Button press:**
- Duration: 100ms
- Easing: ease-out
- Animation: scale(1) → scale(0.98)

---

## Implementation Notes

### Current State
- Uses MeaningEditor widget
- Likely has basic form fields
- May not have tag-based inputs for synonyms/alt translations

### Migration Path
1. **Phase 1:** Update field styling (backgrounds, borders, spacing)
2. **Phase 2:** Implement tag input pattern for synonyms/alt translations
3. **Phase 3:** Add sticky header/footer with backdrop blur
4. **Phase 4:** Polish animations and focus states

### Flutter Widgets
- Form fields: `TextField`, `TextFormField`
- Tags: Custom `TagChip` widget (can use `Chip` as base)
- Dropdown: `DropdownButtonFormField`
- Header: `AppBar` with backdrop filter
- Footer: `Container` with `Row` of `ShadButton`s
- Scrolling: `SingleChildScrollView` for main content

### Package Dependencies
- `shadcn_ui` - Button components
- Standard Flutter widgets for form fields
- `flutter_hooks` (if using hooks pattern)
- `riverpod` for state management

---

## Success Criteria

**Visual:**
- [ ] Matches mockup spacing and sizing
- [ ] Clean focus states with rings
- [ ] Tags display properly with wrap
- [ ] Sticky header and footer work smoothly

**Functional:**
- [ ] All fields save correctly
- [ ] Tag add/remove works smoothly
- [ ] Form validation shows errors clearly
- [ ] Cancel prompts if form dirty

**UX:**
- [ ] Keyboard navigation works completely
- [ ] Touch targets are 44pt minimum
- [ ] Animations feel smooth and natural
- [ ] Loading states are clear

---

## Open Questions

1. **Long text handling:** Wrap or scroll for long translations/tags?
2. **Max tags:** Should we limit synonyms/alt translations (e.g., max 10)?
3. **Validation:** Real-time or on submit only?
4. **Keyboard shortcuts:** Cmd+Enter to save, Escape to cancel?
5. **Tag order:** User-sortable? Alphabetical? Insertion order?
6. **Duplicate detection:** Case-sensitive? Trim whitespace?

---

## Related Screens

This pattern could apply to:
- Edit source metadata
- Edit user profile
- Create custom vocabulary entry
- Any form-heavy editing interface

The tag input pattern is particularly reusable for any multi-value field.
