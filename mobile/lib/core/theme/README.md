# Mastery Design System v1.1.0

Complete Shadcn/Tailwind-compatible design token system.

## Overview

This design system provides **134 tokens** across 8 categories, ensuring 100% compatibility with Shadcn UI and Tailwind CSS standards.

### Token Categories

| Category    | Count | File                    |
|-------------|-------|-------------------------|
| Colors      | 64    | `color_tokens.dart`     |
| Typography  | 15    | `typography_tokens.dart`|
| Spacing     | 12    | `spacing.dart`          |
| Radius      | 7     | `radius_tokens.dart`    |
| Shadows     | 12    | `shadow_tokens.dart`    |
| Borders     | 4     | `border_tokens.dart`    |
| Animation   | 11    | `animation_tokens.dart` |
| Z-Index     | 9     | `z_index_tokens.dart`   |
| **Total**   | **134** |                       |

## Quick Start

### Import Tokens

```dart
import 'package:mastery/core/theme/tokens.dart';
```

This single import gives you access to all design tokens.

## Usage Examples

### Colors (Theme-Aware)

```dart
// Using ThemeExtension (recommended)
Container(
  color: context.masteryColors.cardBackground,
  child: Text(
    'Hello',
    style: TextStyle(color: context.masteryColors.foreground),
  ),
)

// Using static constants (for special cases)
Container(
  color: MasteryColors.backgroundLight,
)
```

### Typography

```dart
// Using semantic text styles
Text('Title', style: MasteryTextStyles.displayLarge)
Text('Body', style: MasteryTextStyles.body)
Text('Caption', style: MasteryTextStyles.caption)

// Using tokens directly for custom styles
Text(
  'Custom',
  style: TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeBase,
    fontWeight: AppTypography.fontWeightMedium,
    height: AppTypography.lineHeightRelaxed,
  ),
)
```

### Spacing

```dart
// Padding and margins
Container(
  padding: EdgeInsets.all(AppSpacing.s4), // 16px
  margin: EdgeInsets.only(bottom: AppSpacing.s6), // 24px
)

// Screen-level padding
Padding(
  padding: EdgeInsets.symmetric(
    horizontal: AppSpacing.screenPaddingX, // 20px
    vertical: AppSpacing.screenPaddingY, // 24px
  ),
)
```

### Radius

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.md), // 8px
  ),
)

// Pills/badges
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.full), // 9999px
  ),
)
```

### Shadows

```dart
// Theme-aware shadows
Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.md(context), // Adapts to light/dark mode
  ),
)

// Explicit mode (if needed)
Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.mdLight, // Always light mode shadow
  ),
)
```

### Borders

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(
      width: AppBorderWidth.thin, // 1px
      color: context.masteryColors.border,
    ),
  ),
)

// Focus ring
Container(
  decoration: BoxDecoration(
    border: Border.all(
      width: AppBorderWidth.medium, // 2px
      color: context.masteryColors.ring,
    ),
  ),
)
```

### Animation

```dart
AnimatedContainer(
  duration: AppAnimation.duration200, // 200ms
  curve: AppAnimation.easeOut, // Cubic(0, 0, 0.2, 1)
  color: _isActive ? Colors.blue : Colors.grey,
)
```

### Z-Index (Reference)

```dart
// Stack ordering reference
// Base content: AppZIndex.base (0)
// Dropdowns: AppZIndex.dropdown (1000)
// Modals: AppZIndex.modal (1400)
// Toasts: AppZIndex.toast (1600)
// Tooltips: AppZIndex.tooltip (1700)

// Flutter uses Stack widget ordering, but these are useful for:
// - Web platform overlays
// - Platform channel communication
// - Documentation/reference
```

## Token Reference

### Complete Spacing Scale

```dart
AppSpacing.s0   // 0px
AppSpacing.s1   // 4px   (xs)
AppSpacing.s2   // 8px   (sm)
AppSpacing.s3   // 12px  (md)
AppSpacing.s4   // 16px  (lg) - most common
AppSpacing.s5   // 20px  (xl)
AppSpacing.s6   // 24px  (2xl)
AppSpacing.s8   // 32px  (3xl)
AppSpacing.s10  // 40px  (4xl)
AppSpacing.s12  // 48px  (5xl)
AppSpacing.s16  // 64px  (6xl)
AppSpacing.s20  // 80px  (7xl)
```

### Typography Sizes

```dart
AppTypography.fontSizeXs    // 11px - captions
AppTypography.fontSizeSm    // 14px - body small
AppTypography.fontSizeBase  // 16px - body (default)
AppTypography.fontSizeLg    // 18px - body large
AppTypography.fontSizeXl    // 24px - h3
AppTypography.fontSize2xl   // 28px - h2, display
```

### Font Weights

```dart
AppTypography.fontWeightNormal    // 400
AppTypography.fontWeightMedium    // 500
AppTypography.fontWeightSemibold  // 600
AppTypography.fontWeightBold      // 700
```

### Radius Scale

```dart
AppRadius.none  // 0px   - sharp corners
AppRadius.sm    // 6px   - buttons, chips
AppRadius.md    // 8px   - cards (default)
AppRadius.lg    // 12px  - modals
AppRadius.xl    // 16px  - sheets
AppRadius.xxl   // 24px  - large containers
AppRadius.full  // 9999px - pills, avatars
```

### Shadow Scale

```dart
AppShadows.xs(context)   // Subtle lift
AppShadows.sm(context)   // Default cards
AppShadows.md(context)   // Hover, dropdowns
AppShadows.lg(context)   // Modals
AppShadows.xl(context)   // Sheets
AppShadows.xxl(context)  // Maximum elevation
```

### Animation Durations

```dart
AppAnimation.duration75   // 75ms  - instant feedback
AppAnimation.duration100  // 100ms - micro-interactions
AppAnimation.duration150  // 150ms - hover (most common)
AppAnimation.duration200  // 200ms - quick transitions
AppAnimation.duration300  // 300ms - default (modals)
AppAnimation.duration500  // 500ms - complex animations
AppAnimation.duration700  // 700ms - dramatic effects
```

## Design Philosophy

### Stone + Amber Palette

- **Stone (50-950)**: Neutral foundation, warm undertones
- **Amber (400-500)**: Brand accent, learning states
- **Semantic colors**: Success (Emerald), Warning (Amber), Info (Blue), Destructive (Red)
- **Domain colors**: Violet (synonym), Pink (multiple choice)

### Best Practices

1. **Always use tokens** - Never hardcode values
2. **Theme-aware colors** - Use `context.masteryColors` for automatic dark mode
3. **Semantic spacing** - Use meaningful names (e.g., `s4` for standard spacing)
4. **Consistent animations** - Stick to `duration150` or `duration300` for most UI
5. **Proper shadows** - Use theme-aware helpers: `AppShadows.md(context)`

## Migration from v1.0

### Deprecated APIs

```dart
// Old (deprecated)
MasterySpacing.lg        // Use AppSpacing.s4
MasterySpacing.radiusMd  // Use AppRadius.md

// New (v1.1)
AppSpacing.s4
AppRadius.md
```

### New Features in v1.1

- ✅ Complete typography token system
- ✅ Full spacing scale (0-80px)
- ✅ Extended radius scale (7 values)
- ✅ Complete shadow system (light + dark)
- ✅ Border width tokens
- ✅ Animation timing system
- ✅ Z-index layer reference
- ✅ Barrel file for easy imports

## Architecture

```
lib/core/theme/
├── tokens.dart              # Barrel file (import this!)
├── README.md                # This file
│
├── color_tokens.dart        # 64 color tokens + ThemeExtension
├── typography_tokens.dart   # 15 typography tokens
├── spacing.dart             # 12 spacing tokens
├── radius_tokens.dart       # 7 radius tokens
├── shadow_tokens.dart       # 12 shadow tokens
├── border_tokens.dart       # 4 border width tokens
├── animation_tokens.dart    # 11 animation tokens
├── z_index_tokens.dart      # 9 z-index tokens
│
├── text_styles.dart         # Semantic TextStyles (uses tokens)
└── app_theme.dart           # Theme configuration
```

## Contributing

When adding new tokens:

1. Follow Shadcn/Tailwind naming conventions
2. Add comprehensive documentation
3. Include usage examples
4. Update this README
5. Maintain backward compatibility with deprecation notices

---

**Mastery Design System v1.1.0** - 100% Shadcn/Tailwind Compatible 🎨
