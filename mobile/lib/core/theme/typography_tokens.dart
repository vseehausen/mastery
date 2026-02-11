import 'package:flutter/material.dart';

/// Typography tokens - Shadcn/Tailwind compatible
///
/// Complete token-based system for font families, sizes, weights,
/// line heights, and letter spacing.
///
/// Usage:
/// ```dart
/// Text(
///   'Hello',
///   style: TextStyle(
///     fontFamily: AppTypography.fontFamilySans,
///     fontSize: AppTypography.fontSizeBase,
///     fontWeight: AppTypography.fontWeightMedium,
///     height: AppTypography.lineHeightRelaxed,
///   ),
/// )
/// ```
abstract final class AppTypography {
  // ═══════════════════════════════════════════════════════════════════════════
  // FONT FAMILY
  // ═══════════════════════════════════════════════════════════════════════════

  static const String fontFamilySans = 'Plus Jakarta Sans';
  static const String fontFamilyMono = 'JetBrains Mono';
  static const String fontFamilySerif = 'Literata';

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT SIZE
  // ═══════════════════════════════════════════════════════════════════════════

  /// 11px - captions, nav labels
  static const double fontSizeXs = 11.0;

  /// 14px - body small, secondary text
  static const double fontSizeSm = 14.0;

  /// 16px - body, form fields (default)
  static const double fontSizeBase = 16.0;

  /// 18px - body large, definitions
  static const double fontSizeLg = 18.0;

  /// 24px - h3, section headers
  static const double fontSizeXl = 24.0;

  /// 28px - h2, display text
  static const double fontSize2xl = 28.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT WEIGHT
  // ═══════════════════════════════════════════════════════════════════════════

  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // ═══════════════════════════════════════════════════════════════════════════
  // LINE HEIGHT
  // ═══════════════════════════════════════════════════════════════════════════

  /// 1.2 - headings, tight display text
  static const double lineHeightTight = 1.2;

  /// 1.3 - captions, small labels
  static const double lineHeightSnug = 1.3;

  /// 1.4 - body small, compact reading
  static const double lineHeightNormal = 1.4;

  /// 1.5 - body, comfortable reading
  static const double lineHeightRelaxed = 1.5;

  // ═══════════════════════════════════════════════════════════════════════════
  // LETTER SPACING
  // ═══════════════════════════════════════════════════════════════════════════

  /// -0.025em - headlines, display text
  static const double letterSpacingTight = -0.025;

  /// 0em - body text (default)
  static const double letterSpacingNormal = 0.0;

  /// 0.025em - labels, uppercase text
  static const double letterSpacingWide = 0.025;
}
