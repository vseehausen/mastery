import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Logo widget with title and optional subtitle for auth screens
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon - brain with sparkle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.auto_stories,
            color: colors.accentForeground,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          title,
          textAlign: TextAlign.center,
          style: MasteryTextStyles.displayLarge.copyWith(
            color: colors.foreground,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}
