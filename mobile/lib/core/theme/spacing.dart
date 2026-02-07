/// Spacing tokens - Shadcn/Tailwind compatible (complete scale)
///
/// Full spacing scale from 0 to 80px for consistent layout spacing.
///
/// Usage:
/// ```dart
/// Container(
///   padding: EdgeInsets.all(AppSpacing.s4),
///   margin: EdgeInsets.only(bottom: AppSpacing.s6),
/// )
/// ```
abstract final class AppSpacing {
  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING SCALE (Shadcn/Tailwind standard)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 0px - no spacing
  static const double s0 = 0.0;

  /// 4px - xs, minimal spacing
  static const double s1 = 4.0;

  /// 8px - sm, tight spacing
  static const double s2 = 8.0;

  /// 12px - md, comfortable spacing
  static const double s3 = 12.0;

  /// 16px - lg, standard spacing (most common)
  static const double s4 = 16.0;

  /// 20px - xl, generous spacing
  static const double s5 = 20.0;

  /// 24px - 2xl, large spacing
  static const double s6 = 24.0;

  /// 32px - 3xl, extra large spacing
  static const double s8 = 32.0;

  /// 40px - 4xl, section spacing
  static const double s10 = 40.0;

  /// 48px - 5xl, major section spacing
  static const double s12 = 48.0;

  /// 64px - 6xl, page-level spacing
  static const double s16 = 64.0;

  /// 80px - 7xl, maximum spacing
  static const double s20 = 80.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC SPACING (derived from scale)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Container padding - 20px
  static const double containerPadding = s5;

  /// Screen horizontal padding - 20px
  static const double screenPaddingX = s5;

  /// Screen vertical padding - 24px
  static const double screenPaddingY = s6;

}
