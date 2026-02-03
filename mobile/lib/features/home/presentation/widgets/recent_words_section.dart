import 'package:flutter/material.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/word_card.dart';

/// Recent words section for dashboard
class RecentWordsSection extends StatelessWidget {
  const RecentWordsSection({
    super.key,
    required this.words,
    this.onSeeAll,
    this.onWordTap,
  });

  final List<Map<String, dynamic>> words; // [{word, definition, isEnriched}, ...]
  final VoidCallback? onSeeAll;
  final ValueChanged<Map<String, dynamic>>? onWordTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Recent Words', onSeeAll: onSeeAll),
        const SizedBox(height: 12),
        if (words.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No words yet. Import your first Kindle highlights!'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: words.length > 2 ? 2 : words.length,
            itemBuilder: (context, index) {
              final word = words[index];
              return WordCard(
                word: word['word'] as String,
                definition: word['definition'] as String,
                isEnriched: word['isEnriched'] as bool? ?? false,
                onTap: () => onWordTap?.call(word),
              );
            },
          ),
      ],
    );
  }
}
