import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';

/// Card showing context where word was found
class ContextCard extends StatelessWidget {
  const ContextCard({
    super.key,
    this.context,
    this.bookTitle,
    this.author,
    this.chapter,
  });

  final String? context;
  final String? bookTitle;
  final String? author;
  final int? chapter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? MasteryColors.cardDark
        : MasteryColors.secondaryLight;

    if (this.context == null || this.context!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? MasteryColors.borderDark : MasteryColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${this.context}"',
            style: MasteryTextStyles.body.copyWith(
              color: isDark
                  ? MasteryColors.foregroundDark
                  : MasteryColors.foregroundLight,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          if (bookTitle != null && bookTitle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 16,
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bookTitle!,
                    style: MasteryTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? MasteryColors.mutedForegroundDark
                          : MasteryColors.mutedForegroundLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (author != null && author!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'by $author',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
