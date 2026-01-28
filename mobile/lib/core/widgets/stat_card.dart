import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

/// Card for displaying statistics
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? backgroundColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? Colors.grey[900] : const Color(0xFFF5F5F5));
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: MasteryTextStyles.bodySmall.copyWith(color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: MasteryTextStyles.displayLarge.copyWith(
              fontSize: 24,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
