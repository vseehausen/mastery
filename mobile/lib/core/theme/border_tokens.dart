/// Border width tokens - Shadcn/Tailwind compatible
///
/// Standard border widths for consistent UI styling.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     border: Border.all(
///       width: AppBorderWidth.thin,
///       color: Colors.grey,
///     ),
///   ),
/// )
/// ```
abstract final class AppBorderWidth {
  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER WIDTH SCALE
  // ═══════════════════════════════════════════════════════════════════════════

  /// 0px - no border
  static const double none = 0.0;

  /// 1px - default borders, dividers, subtle separation
  static const double thin = 1.0;

  /// 2px - focus rings, emphasis, active states
  static const double medium = 2.0;

  /// 4px - strong separation, decorative borders
  static const double thick = 4.0;
}
