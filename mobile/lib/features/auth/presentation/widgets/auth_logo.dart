import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Logo widget with title and optional subtitle for auth screens
class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon - brain with sparkle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: MasteryColors.accentLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_stories,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          title,
          textAlign: TextAlign.center,
          style: MasteryTextStyles.displayLarge.copyWith(
            color: isDark ? Colors.white : const Color(0xFF0A0A0A),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
