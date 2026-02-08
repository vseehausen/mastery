import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import '../theme/color_tokens.dart';

/// Card for displaying statistics
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.backgroundColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final bgColor = backgroundColor ?? colors.secondaryAction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: colors.foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: colors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: MasteryTextStyles.displayLarge.copyWith(
              fontSize: 24,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
