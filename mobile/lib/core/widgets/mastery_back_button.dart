import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';

/// Standardized back/close button for top bars.
///
/// Two semantic variants:
/// - [MasteryBackButton.back] — chevron, for navigating to a previous screen
/// - [MasteryBackButton.close] — X icon, for dismissing modals/sheets/sessions
///
/// Uses `mutedForeground` from the design system for both variants.
class MasteryBackButton extends StatelessWidget {
  const MasteryBackButton._({
    required this.icon,
    required this.onPressed,
  });

  /// Back navigation (chevron left).
  const factory MasteryBackButton.back({
    required VoidCallback onPressed,
  }) = _BackVariant;

  /// Dismiss / close (X icon).
  const factory MasteryBackButton.close({
    required VoidCallback onPressed,
  }) = _CloseVariant;

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: colors.mutedForeground, size: 22),
    );
  }
}

class _BackVariant extends MasteryBackButton {
  const _BackVariant({required super.onPressed})
      : super._(icon: Icons.chevron_left);
}

class _CloseVariant extends MasteryBackButton {
  const _CloseVariant({required super.onPressed})
      : super._(icon: Icons.close);
}
