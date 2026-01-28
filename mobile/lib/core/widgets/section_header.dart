import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../theme/text_styles.dart';

/// Section header with title and optional "See all" link
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: MasteryTextStyles.bodyBold.copyWith(
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        if (onSeeAll != null)
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: onSeeAll,
            child: Text(
              'See all',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: ShadTheme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
