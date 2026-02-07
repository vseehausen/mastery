import 'package:flutter/material.dart';

/// Shadow elevation tokens - Shadcn/Tailwind compatible
///
/// Complete shadow system with light and dark mode variants.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.md(context),
///   ),
/// )
/// ```
abstract final class AppShadows {
  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extra small - Subtle lift (1px blur)
  static const List<BoxShadow> xsLight = [
    BoxShadow(
      color: Color(0x0D000000), // rgba(0,0,0,0.05)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Small - Default cards (3px blur)
  static const List<BoxShadow> smLight = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.1)
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Medium - Hover states, dropdowns (6px blur)
  static const List<BoxShadow> mdLight = [
    BoxShadow(
      color: Color(0x12000000), // rgba(0,0,0,0.07)
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  /// Large - Modals, dialogs (15px blur)
  static const List<BoxShadow> lgLight = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.1)
      offset: Offset(0, 10),
      blurRadius: 15,
    ),
    BoxShadow(
      color: Color(0x0D000000), // rgba(0,0,0,0.05)
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
  ];

  /// Extra large - Sheets, large overlays (25px blur)
  static const List<BoxShadow> xlLight = [
    BoxShadow(
      color: Color(0x1A000000), // rgba(0,0,0,0.1)
      offset: Offset(0, 20),
      blurRadius: 25,
    ),
    BoxShadow(
      color: Color(0x0A000000), // rgba(0,0,0,0.04)
      offset: Offset(0, 10),
      blurRadius: 10,
    ),
  ];

  /// 2XL - Maximum elevation (50px blur)
  static const List<BoxShadow> xxlLight = [
    BoxShadow(
      color: Color(0x26000000), // rgba(0,0,0,0.15)
      offset: Offset(0, 25),
      blurRadius: 50,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK MODE SHADOWS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extra small - Subtle lift (dark mode)
  static const List<BoxShadow> xsDark = [
    BoxShadow(
      color: Color(0x4D000000), // rgba(0,0,0,0.3)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Small - Default cards (dark mode)
  static const List<BoxShadow> smDark = [
    BoxShadow(
      color: Color(0x66000000), // rgba(0,0,0,0.4)
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x4D000000), // rgba(0,0,0,0.3)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Medium - Hover states, dropdowns (dark mode)
  static const List<BoxShadow> mdDark = [
    BoxShadow(
      color: Color(0x66000000), // rgba(0,0,0,0.4)
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Color(0x4D000000), // rgba(0,0,0,0.3)
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  /// Large - Modals, dialogs (dark mode)
  static const List<BoxShadow> lgDark = [
    BoxShadow(
      color: Color(0x80000000), // rgba(0,0,0,0.5)
      offset: Offset(0, 10),
      blurRadius: 15,
    ),
    BoxShadow(
      color: Color(0x66000000), // rgba(0,0,0,0.4)
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
  ];

  /// Extra large - Sheets, large overlays (dark mode)
  static const List<BoxShadow> xlDark = [
    BoxShadow(
      color: Color(0x80000000), // rgba(0,0,0,0.5)
      offset: Offset(0, 20),
      blurRadius: 25,
    ),
    BoxShadow(
      color: Color(0x66000000), // rgba(0,0,0,0.4)
      offset: Offset(0, 10),
      blurRadius: 10,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTEXT-AWARE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get theme-appropriate extra small shadow
  static List<BoxShadow> xs(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? xsDark : xsLight;
  }

  /// Get theme-appropriate small shadow
  static List<BoxShadow> sm(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? smDark : smLight;
  }

  /// Get theme-appropriate medium shadow
  static List<BoxShadow> md(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? mdDark : mdLight;
  }

  /// Get theme-appropriate large shadow
  static List<BoxShadow> lg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? lgDark : lgLight;
  }

  /// Get theme-appropriate extra large shadow
  static List<BoxShadow> xl(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? xlDark : xlLight;
  }

  /// Get theme-appropriate 2XL shadow
  static List<BoxShadow> xxl(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? xlDark // Dark mode doesn't have xxl variant, use xl
        : xxlLight;
  }
}
