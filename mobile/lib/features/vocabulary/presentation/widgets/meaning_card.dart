import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../domain/models/meaning.dart';

/// Displays a single meaning for a vocabulary word.
/// Shows translation and definition directly without accordion.
class MeaningCard extends StatelessWidget {
  const MeaningCard({
    super.key,
    required this.meaning,
    this.onEdit,
    this.displayMode = 'both',
  });

  final MeaningModel meaning;
  final VoidCallback? onEdit;
  final String displayMode; // 'native', 'english', 'both'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showTranslation = displayMode == 'native' || displayMode == 'both';
    final showDefinition = displayMode == 'english' || displayMode == 'both';
    final synonyms = meaning.synonyms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Part of speech (if available)
        if (meaning.partOfSpeech != null) ...[
          Text(
            meaning.partOfSpeech!,
            style: MasteryTextStyles.caption.copyWith(
              color: isDark ? Colors.white38 : Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Primary translation
        if (showTranslation)
          Text(
            meaning.primaryTranslation,
            style: MasteryTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

        if (showTranslation && showDefinition) const SizedBox(height: 8),

        // English definition
        if (showDefinition)
          Text(
            meaning.englishDefinition,
            style: MasteryTextStyles.body.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.4,
            ),
          ),

        // Synonyms (inline, subtle)
        if (synonyms.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            synonyms.join(' · '),
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],

        // Edit action
        if (onEdit != null) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                textStyle: MasteryTextStyles.caption,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
