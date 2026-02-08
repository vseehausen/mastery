import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../domain/models/cue.dart';
import '../../../../domain/models/meaning.dart';
import '../../../../providers/supabase_provider.dart';
import '../../../learn/widgets/cloze_cue_card.dart';
import '../../../learn/widgets/definition_cue_card.dart';
import '../../../learn/widgets/disambiguation_card.dart';
import '../../../learn/widgets/recall_card.dart';
import '../../../learn/widgets/recognition_card.dart';
import '../../../learn/widgets/synonym_cue_card.dart';

/// Modal bottom sheet showing all card types for a vocabulary word
/// Interactive preview mode - tap to reveal, but no grading saved
class CardPreviewSheet extends ConsumerStatefulWidget {
  const CardPreviewSheet({
    super.key,
    required this.vocabularyId,
    required this.word,
  });

  final String vocabularyId;
  final String word;

  @override
  ConsumerState<CardPreviewSheet> createState() => _CardPreviewSheetState();
}

class _CardPreviewSheetState extends ConsumerState<CardPreviewSheet> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final meaningsAsync = ref.watch(meaningsProvider(widget.vocabularyId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card Preview',
                  style: MasteryTextStyles.h3.copyWith(
                    color: colors.foreground,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Banner notice
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.mutedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preview — answers are not saved',
                    style: MasteryTextStyles.caption.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card content
          Expanded(
            child: meaningsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Failed to load cards',
                  style: MasteryTextStyles.body.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              data: (meanings) {
                if (meanings.isEmpty) {
                  return Center(
                    child: Text(
                      'No meaning data available',
                      style: MasteryTextStyles.body.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  );
                }

                final meaning = meanings.first;
                final cuesAsync = ref.watch(cuesForMeaningProvider(meaning.id));

                return cuesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to load cues',
                      style: MasteryTextStyles.body.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ),
                  data: (cues) {
                    final cards = _buildCardList(meaning, cues);

                    return Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemCount: cards.length,
                            itemBuilder: (context, index) {
                              final cardData = cards[index];
                              return Column(
                                children: [
                                  // Card type label chip
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardData.color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: cardData.color.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            cardData.label,
                                            style: MasteryTextStyles.bodySmall.copyWith(
                                              color: cardData.color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (cardData.isSample) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colors.muted,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'sample',
                                                style: MasteryTextStyles.caption.copyWith(
                                                  fontSize: 10,
                                                  color: colors.mutedForeground,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Card widget
                                  Expanded(
                                    child: ClipRect(
                                      child: cardData.widget,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Dot indicator
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24, top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              cards.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _currentPage
                                      ? colors.primaryAction
                                      : colors.border,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_CardData> _buildCardList(MeaningModel meaning, List<dynamic> cues) {
    final cards = <_CardData>[];

    // Convert maps to CueModel objects
    final cueModels = cues
        .map((c) => c is CueModel ? c : CueModel.fromJson(c as Map<String, dynamic>))
        .toList();

    // 1. Recall Card (translation cue)
    final translationCue = cueModels.where((c) => c.cueType == 'translation').firstOrNull;
    cards.add(_CardData(
      label: 'Recall',
      color: MasteryColors.getCueColor(context, 'translation'),
      isSample: translationCue == null,
      widget: RecallCard(
        word: widget.word,
        answer: translationCue?.answerText ?? meaning.primaryTranslation,
        context: translationCue?.metadata['context_sentence'] as String?,
        onGrade: (_) {}, // No-op in preview mode
        isPreview: true,
      ),
    ));

    // 2. Recognition Card (translation + distractors)
    final distractors = translationCue?.metadata['distractors'] as List?;
    final recognitionDistractors = distractors?.cast<String>() ??
        _generateFallbackDistractors(meaning.alternativeTranslations);
    cards.add(_CardData(
      label: 'Recognition',
      color: MasteryColors.getCueColor(context, 'multiple_choice'),
      isSample: translationCue == null || distractors == null,
      widget: RecognitionCard(
        word: widget.word,
        correctAnswer: translationCue?.answerText ?? meaning.primaryTranslation,
        distractors: recognitionDistractors,
        context: translationCue?.metadata['context_sentence'] as String?,
        onAnswer: (selected, isCorrect) {}, // No-op in preview mode
      ),
    ));

    // 3. Definition Cue Card
    final definitionCue = cueModels.where((c) => c.cueType == 'definition').firstOrNull;
    cards.add(_CardData(
      label: 'Definition',
      color: MasteryColors.getCueColor(context, 'definition'),
      isSample: definitionCue == null,
      widget: DefinitionCueCard(
        definition: definitionCue?.promptText ?? meaning.englishDefinition,
        targetWord: widget.word,
        hintText: definitionCue?.hintText,
        onGrade: (_) {}, // No-op in preview mode
        isPreview: true,
      ),
    ));

    // 4. Synonym Cue Card
    final synonymCue = cueModels.where((c) => c.cueType == 'synonym').firstOrNull;
    final synonymPhrase = synonymCue?.promptText ??
        (meaning.synonyms.isNotEmpty
            ? meaning.synonyms.join(', ')
            : 'Similar word or phrase');
    cards.add(_CardData(
      label: 'Synonym',
      color: MasteryColors.getCueColor(context, 'synonym'),
      isSample: synonymCue == null,
      widget: SynonymCueCard(
        synonymPhrase: synonymPhrase,
        targetWord: widget.word,
        onGrade: (_) {}, // No-op in preview mode
        isPreview: true,
      ),
    ));

    // 5. Cloze Cue Card
    final clozeCue = cueModels.where((c) => c.cueType == 'context_cloze').firstOrNull;
    final clozeSentence = clozeCue?.promptText ??
        'The _______ was used in a sentence.';
    cards.add(_CardData(
      label: 'Context Cloze',
      color: MasteryColors.getCueColor(context, 'cloze'),
      isSample: clozeCue == null,
      widget: ClozeCueCard(
        sentenceWithBlank: clozeSentence,
        targetWord: widget.word,
        hintText: clozeCue?.hintText ?? meaning.primaryTranslation,
        onGrade: (_) {}, // No-op in preview mode
        isPreview: true,
      ),
    ));

    // 6. Disambiguation Card
    final disambiguationCue = cueModels.where((c) => c.cueType == 'disambiguation').firstOrNull;
    final disambiguationOptions = disambiguationCue?.metadata['options'] as List? ??
        [widget.word, meaning.synonyms.firstOrNull ?? 'alternative'];
    final correctIndex = disambiguationCue?.metadata['correct_index'] as int? ?? 0;
    final explanation = disambiguationCue?.metadata['explanation'] as String? ??
        'Explanation of the distinction';

    cards.add(_CardData(
      label: 'Disambiguation',
      color: MasteryColors.getCueColor(context, 'disambiguation'),
      isSample: disambiguationCue == null,
      widget: DisambiguationCard(
        clozeSentence: disambiguationCue?.promptText ?? 'The ___ was in the text.',
        options: disambiguationOptions.cast<String>(),
        correctIndex: correctIndex,
        explanation: explanation,
        onGrade: (_) {}, // No-op in preview mode
      ),
    ));

    return cards;
  }

  List<String> _generateFallbackDistractors(List<String> alternatives) {
    // Use alternative translations as distractors, pad if needed
    final distractors = alternatives.take(3).toList();
    while (distractors.length < 3) {
      distractors.add('alternative ${distractors.length + 1}');
    }
    return distractors;
  }
}

/// Data class for card metadata
class _CardData {
  const _CardData({
    required this.label,
    required this.color,
    required this.isSample,
    required this.widget,
  });

  final String label;
  final Color color;
  final bool isSample; // True if using fallback/placeholder data
  final Widget widget;
}
