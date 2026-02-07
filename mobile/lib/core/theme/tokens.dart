/// Mastery Design System Tokens
///
/// Complete Shadcn/Tailwind-compatible token system (v1.1.0)
///
/// This barrel file exports all design tokens for easy access:
/// - Colors (64 tokens)
/// - Typography (15 tokens)
/// - Spacing (12 tokens)
/// - Radius (7 tokens)
/// - Shadows (12 tokens)
/// - Borders (4 tokens)
/// - Animation (11 tokens)
/// - Z-Index (9 tokens)
///
/// Total: 134 tokens
///
/// Usage:
/// ```dart
/// import 'package:mastery/core/theme/tokens.dart';
///
/// Container(
///   padding: EdgeInsets.all(AppSpacing.s4),
///   decoration: BoxDecoration(
///     color: context.masteryColors.cardBackground,
///     borderRadius: BorderRadius.circular(AppRadius.md),
///     boxShadow: AppShadows.sm(context),
///     border: Border.all(
///       color: context.masteryColors.border,
///       width: AppBorderWidth.thin,
///     ),
///   ),
///   child: Text(
///     'Hello',
///     style: TextStyle(
///       fontFamily: AppTypography.fontFamilySans,
///       fontSize: AppTypography.fontSizeBase,
///       fontWeight: AppTypography.fontWeightMedium,
///       color: context.masteryColors.foreground,
///     ),
///   ),
/// )
/// ```
library;

// Core token exports
export 'animation_tokens.dart';
export 'border_tokens.dart';
export 'color_tokens.dart';
export 'radius_tokens.dart';
export 'shadow_tokens.dart';
export 'spacing.dart';
export 'text_styles.dart';
export 'typography_tokens.dart';
export 'z_index_tokens.dart';
