/// Z-index layer tokens - Shadcn/Tailwind compatible
///
/// Stacking order system for overlays, modals, and floating elements.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     // Base content (z: 0)
///     MyContent(),
///
///     // Dropdown menu (z: 1000)
///     Positioned(
///       child: MyDropdown(),
///     ),
///   ],
/// )
/// ```
///
/// Note: In Flutter, use Stack widget ordering instead of explicit z-index.
/// These values are provided for reference and potential web/platform channel use.
abstract final class AppZIndex {
  // ═══════════════════════════════════════════════════════════════════════════
  // LAYER ORDERING SCALE
  // ═══════════════════════════════════════════════════════════════════════════

  /// 0 - Base content layer
  static const int base = 0;

  /// 1000 - Dropdown menus, select options, tooltips
  static const int dropdown = 1000;

  /// 1100 - Sticky headers, persistent navigation
  static const int sticky = 1100;

  /// 1200 - Fixed elements, floating action buttons
  static const int fixed = 1200;

  /// 1300 - Modal backdrop overlays
  static const int modalBackdrop = 1300;

  /// 1400 - Dialogs, sheets, modal content
  static const int modal = 1400;

  /// 1500 - Popovers over modals
  static const int popover = 1500;

  /// 1600 - Toast notifications, snackbars
  static const int toast = 1600;

  /// 1700 - Tooltips (highest layer)
  static const int tooltip = 1700;
}
