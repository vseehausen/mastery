import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

/// Card widget for displaying vocabulary word in list
class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.word,
    required this.definition,
    required this.onTap,
    this.isEnriched = false,
  });

  final String word;
  final String definition;
  final VoidCallback onTap;
  final bool isEnriched;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey[300];

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
                                color: isDark ? Colors.white : Colors.black,
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
                              color: isDark
                                  ? Colors.amber[300]
                                  : Colors.amber[700],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        definition,
                        style: MasteryTextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
        ],
      ),
    );
  }
}
