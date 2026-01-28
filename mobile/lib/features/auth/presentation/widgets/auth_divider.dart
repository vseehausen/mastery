import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';

/// Divider with centered "or" text for auth screens
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300];

    return Row(
      children: [
        Expanded(
          child: Divider(color: borderColor, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'or',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Divider(color: borderColor, thickness: 1),
        ),
      ],
    );
  }
}
