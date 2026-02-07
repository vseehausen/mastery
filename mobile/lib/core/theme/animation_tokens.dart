import 'package:flutter/animation.dart';

/// Animation timing tokens - Shadcn/Tailwind compatible
///
/// Complete animation system with durations and easing curves.
///
/// Usage:
/// ```dart
/// AnimatedContainer(
///   duration: AppAnimation.duration200,
///   curve: AppAnimation.easeOut,
/// )
/// ```
abstract final class AppAnimation {
  // ═══════════════════════════════════════════════════════════════════════════
  // DURATION SCALE
  // ═══════════════════════════════════════════════════════════════════════════

  /// 75ms - instant feedback, micro-interactions
  static const Duration duration75 = Duration(milliseconds: 75);

  /// 100ms - very quick state changes
  static const Duration duration100 = Duration(milliseconds: 100);

  /// 150ms - hover, active states (recommended for most interactions)
  static const Duration duration150 = Duration(milliseconds: 150);

  /// 200ms - quick transitions, tooltips
  static const Duration duration200 = Duration(milliseconds: 200);

  /// 300ms - default transitions, modals
  static const Duration duration300 = Duration(milliseconds: 300);

  /// 500ms - complex animations, page transitions
  static const Duration duration500 = Duration(milliseconds: 500);

  /// 700ms - slow, dramatic effects
  static const Duration duration700 = Duration(milliseconds: 700);

  // ═══════════════════════════════════════════════════════════════════════════
  // EASING CURVES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Linear - constant speed (rarely used)
  static const Curve easeLinear = Curves.linear;

  /// Ease In - slow start, quick end
  static const Curve easeIn = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Ease Out - quick start, slow end (most common for UI)
  static const Curve easeOut = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Ease In-Out - smooth both ways
  static const Curve easeInOut = Cubic(0.4, 0.0, 0.2, 1.0);
}
