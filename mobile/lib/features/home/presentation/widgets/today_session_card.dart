import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Card showing today's learning session
class TodaySessionCard extends StatelessWidget {
  final int wordsToReview;
  final VoidCallback onStart;

  const TodaySessionCard({
    super.key,
    required this.wordsToReview,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MasteryColors.accentLight,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Session",
                    style: MasteryTextStyles.bodyBold.copyWith(
                      color: MasteryColors.accentForegroundLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$wordsToReview words to review',
                    style: MasteryTextStyles.bodySmall.copyWith(
                      color: MasteryColors.accentForegroundLight,
                    ),
                  ),
                ],
              ),
              ShadButton.ghost(
                onPressed: onStart,
                size: ShadButtonSize.sm,
                child: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
