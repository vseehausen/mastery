import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Individual settings list item
class SettingsListItem extends StatelessWidget {
  const SettingsListItem({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.isDanger = false,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final labelColor = isDanger
        ? context.masteryColors.destructive
        : context.masteryColors.foreground;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            // Label on the left
            Expanded(
              child: Text(
                label,
                style: MasteryTextStyles.body.copyWith(
                  fontSize: 14,
                  color: labelColor,
                  fontWeight: isDanger ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            // Value + chevron on the right
            if (value != null) ...[
              const SizedBox(width: 12),
              Text(
                value!,
                style: MasteryTextStyles.body.copyWith(
                  fontSize: 14,
                  color: context.masteryColors.mutedForeground,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (!isDanger) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: context.masteryColors.border,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
