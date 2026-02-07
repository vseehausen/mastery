# Mastery Theme System - Usage Guide

## Overview

The Mastery app uses a **Stone + Amber** color palette with a complete ThemeExtension system that eliminates `isDark ?` ternaries.

**Design System**: v1.0.0
**Base Palette**: Stone (warm neutrals)
**Brand Accent**: Amber

## 🎨 Color System

### Three Ways to Access Colors

#### 1. **ThemeExtension (Recommended - Coming Soon)**

The cleanest approach using context-aware theme extension:

```dart
Widget build(BuildContext context) {
  final colors = context.masteryColors;

  return Container(
    color: colors.cardBackground,
    child: Text(
      'Hello',
      style: TextStyle(color: colors.foreground),
    ),
  );
}
```

**Note**: This requires ThemeExtension support in ShadApp (currently in progress). For now, use method #2 or #3.

#### 2. **Helper Methods (Current Best Practice)**

Use context-aware helper methods for semantic colors:

```dart
Widget build(BuildContext context) {
  return Container(
    color: MasteryColors.getStatusColor(context, LearningStatus.known),
    child: Text(
      'Known Word',
      style: TextStyle(
        color: MasteryColors.getCueColor(context, 'translation'),
      ),
    ),
  );
}
```

#### 3. **Static Constants (Backward Compatible, avoid and refactor to 1.)**

Direct access when you already know the brightness:

```dart
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
    child: Text(
      'Hello',
      style: TextStyle(
        color: isDark ? MasteryColors.foregroundDark : MasteryColors.foregroundLight,
      ),
    ),
  );
}
```

## 📚 Color Token Reference

### Surfaces
- `background` / `backgroundLight` / `backgroundDark` - App background
- `foreground` / `foregroundLight` / `foregroundDark` - Primary text
- `cardBackground` / `cardLight` / `cardDark` - Card surfaces
- `cardForeground` / `cardForegroundLight` / `cardForegroundDark` - Text on cards

### Actions
- `primaryAction` / `primaryLight` / `primaryDark` - Primary buttons
- `secondaryAction` / `secondaryLight` / `secondaryDark` - Secondary buttons
- `accent` / `accentLight` / `accentDark` - **Brand amber** highlight
- `destructive` / `destructiveLight` / `destructiveDark` - Delete/danger actions

### Semantic States
- `success` / `successLight` / `successDark` - ✅ "Known" status, correct answers
- `warning` / `warningLight` / `warningDark` - ⚠️ "Learning" status, timers
- `info` / `infoLight` / `infoDark` - ℹ️ Informational states

### Form Elements
- `border` / `borderLight` / `borderDark` - Subtle borders
- `input` / `inputLight` / `inputDark` - Input field borders
- `ring` / `ringLight` / `ringDark` - Focus indicators (amber)
- `selection` / `selectionLight` / `selectionDark` - Text selection (amber tint)

### Domain Cues
- `cueSynonym` / `cueSynonymLight` / `cueSynonymDark` - 🟣 Violet
- `cueMultipleChoice` / `cueMultipleChoiceLight` / `cueMultipleChoiceDark` - 🩷 Pink

**Note**: Translation (blue), definition (green), and cloze (amber) map to semantic colors:
- Translation → `info`
- Definition → `success`
- Cloze → `warning`

## 🔧 Helper Methods

### Status Colors

```dart
// Get color for learning status (Known/Learning/Unknown)
MasteryColors.getStatusColor(context, LearningStatus.known)
MasteryColors.getStatusMutedColor(context, LearningStatus.learning)
```

### Cue Type Colors

```dart
// Get color for cue type
MasteryColors.getCueColor(context, 'translation')  // Blue
MasteryColors.getCueColor(context, 'definition')   // Green
MasteryColors.getCueColor(context, 'synonym')      // Violet
MasteryColors.getCueColor(context, 'cloze')        // Amber
MasteryColors.getCueColor(context, 'multiple_choice') // Pink
```

## 🎯 Migration from Old Tokens

Removed tokens have been replaced with semantic equivalents:

| Old Token | New Token |
|-----------|-----------|
| `activeLight/Dark` | `foregroundLight/Dark` |
| `knownLight/Dark` | `successLight/Dark` |
| `knownMutedLight/Dark` | `successMutedLight/Dark` |
| `learningLight/Dark` | `warningLight/Dark` |
| `learningMutedLight/Dark` | `warningMutedLight/Dark` |
| `unknownLight/Dark` | `mutedLight/Dark` |
| `cueTranslationLight/Dark` | `infoLight/Dark` |
| `cueDefinitionLight/Dark` | `successLight/Dark` |
| `cueClozeLight/Dark` | `warningLight/Dark` |

## 🚀 Best Practices

1. **Use helper methods** for semantic colors (status, cue types)
2. **Use static constants** for UI structure colors (borders, backgrounds)
3. **Avoid hardcoded `Color(0x...)`** - always reference MasteryColors
4. **Check context availability** before using helper methods
5. **Future**: Migrate to `context.masteryColors` once ThemeExtension is fully integrated

## 📖 Examples

### Status Badge
```dart
Container(
  decoration: BoxDecoration(
    color: MasteryColors.getStatusMutedColor(context, status),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    'Known',
    style: TextStyle(
      color: MasteryColors.getStatusColor(context, status),
    ),
  ),
)
```

### Cue Type Chip
```dart
Container(
  decoration: BoxDecoration(
    color: MasteryColors.getCueColor(context, cueType).withOpacity(0.1),
    border: Border.all(
      color: MasteryColors.getCueColor(context, cueType).withOpacity(0.3),
    ),
  ),
  child: Text(
    'Translation',
    style: TextStyle(color: MasteryColors.getCueColor(context, cueType)),
  ),
)
```

### Theme-Aware Card
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
Container(
  decoration: BoxDecoration(
    color: isDark ? MasteryColors.cardDark : MasteryColors.cardLight,
    border: Border.all(
      color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
    ),
  ),
  child: Text(
    'Content',
    style: TextStyle(
      color: isDark ? MasteryColors.foregroundDark : MasteryColors.foregroundLight,
    ),
  ),
)
```

---

**Last Updated**: 2026-02-07
**Design System Version**: v1.0.0
