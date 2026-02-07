/// Border radius tokens - Shadcn/Tailwind compatible
///
/// Complete radius scale from none to full pill shape.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(AppRadius.md),
///   ),
/// )
/// ```
abstract final class AppRadius {
  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS SCALE
  // ═══════════════════════════════════════════════════════════════════════════

  /// 0px - sharp corners
  static const double none = 0.0;

  /// 6px - buttons, chips, small elements
  static const double sm = 6.0;

  /// 8px - cards, inputs (default)
  static const double md = 8.0;

  /// 12px - modals, larger cards
  static const double lg = 12.0;

  /// 16px - sheets, large containers
  static const double xl = 16.0;

  /// 24px - very large containers, decorative elements
  static const double xxl = 24.0;

  /// 9999px - pills, avatars, fully rounded
  static const double full = 9999.0;
}
