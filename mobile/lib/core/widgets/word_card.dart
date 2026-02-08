import 'package:flutter/material.dart';
import '../../domain/models/progress_stage.dart';
import '../theme/text_styles.dart';
import '../theme/color_tokens.dart';
import 'progress_stage_badge.dart';

/// Card widget for displaying vocabulary word in list
class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.definition,
    required this.onTap,
    this.isEnriched = false,
    this.progressStage,
  });

  final String word;
  final String definition;
  final VoidCallback onTap;
  final bool isEnriched;
  final ProgressStage? progressStage;

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              word,
                              style: MasteryTextStyles.bodyBold.copyWith(
                                color: colors.foreground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isEnriched) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: colors.warning,
                            ),
                          ],
                          if (progressStage != null) ...[
                            const SizedBox(width: 6),
                            ProgressStageBadge(
                              stage: progressStage!,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        definition,
                        style: MasteryTextStyles.bodySmall.copyWith(
                          color: colors.mutedForeground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right, color: colors.mutedForeground),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border, indent: 16, endIndent: 16),
        ],
      ),
    );
  }
}
