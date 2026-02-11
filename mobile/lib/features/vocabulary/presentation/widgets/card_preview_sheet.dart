import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/mastery_back_button.dart';
import '../../../../domain/models/global_dictionary.dart';
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
    final globalDictAsync = ref.watch(globalDictionaryProvider(widget.vocabularyId));

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
                MasteryBackButton.close(
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
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colors.mutedForeground,
                ),
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
            child: globalDictAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Failed to load cards',
                  style: MasteryTextStyles.body.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              data: (globalDict) {
                if (globalDict == null) {
                  return Center(
                    child: Text(
                      'No meaning data available',
                      style: MasteryTextStyles.body.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  );
                }

                final cards = _buildCardList(globalDict);

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
                                    color: cardData.color.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: cardData.color.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    cardData.label,
                                    style: MasteryTextStyles.bodySmall
                                        .copyWith(
                                          color: cardData.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),

                              // Card widget
                              Expanded(
                                child: ClipRect(child: cardData.widget),
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
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
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
            ),
          ),
        ],
      ),
    );
  }

  List<_CardData> _buildCardList(GlobalDictionaryModel globalDict) {
    final cards = <_CardData>[];

    // Get translation data
    final langTranslations = globalDict.translations.isNotEmpty
        ? globalDict.translations.values.first
        : null;
    final primaryTranslation = langTranslations?.primary ?? '';
    final alternatives = langTranslations?.alternatives ?? [];

    // 1. Recall Card (translation)
    cards.add(
      _CardData(
        label: 'Recall',
        color: MasteryColors.getCueColor(context, 'translation'),
        widget: RecallCard(
          word: widget.word,
          answer: primaryTranslation,
          onGrade: (_) {}, // No-op in preview mode
          isPreview: true,
        ),
      ),
    );

    // 2. Recognition Card (translation + distractors)
    final recognitionDistractors = _generateFallbackDistractors(alternatives);
    cards.add(
      _CardData(
        label: 'Recognition',
        color: MasteryColors.getCueColor(context, 'multiple_choice'),
        widget: RecognitionCard(
          word: widget.word,
          correctAnswer: primaryTranslation,
          distractors: recognitionDistractors,
          onAnswer: (selected, isCorrect) {}, // No-op in preview mode
          isPreview: true,
        ),
      ),
    );

    // 3. Definition Cue Card
    cards.add(
      _CardData(
        label: 'Definition',
        color: MasteryColors.getCueColor(context, 'definition'),
        widget: DefinitionCueCard(
          definition: globalDict.englishDefinition ?? '',
          targetWord: widget.word,
          onGrade: (_) {}, // No-op in preview mode
          isPreview: true,
        ),
      ),
    );

    // 4. Synonym Cue Card
    final synonymPhrase = globalDict.synonyms.isNotEmpty
        ? globalDict.synonyms.join(', ')
        : 'Similar word or phrase';
    cards.add(
      _CardData(
        label: 'Synonym',
        color: MasteryColors.getCueColor(context, 'synonym'),
        widget: SynonymCueCard(
          synonymPhrase: synonymPhrase,
          targetWord: widget.word,
          onGrade: (_) {}, // No-op in preview mode
          isPreview: true,
        ),
      ),
    );

    // 5. Cloze Cue Card
    if (globalDict.exampleSentences.isNotEmpty) {
      final example = globalDict.exampleSentences.first;
      final clozeSentence = '${example.before}_____${example.after}';
      cards.add(
        _CardData(
          label: 'Context Cloze',
          color: MasteryColors.getCueColor(context, 'cloze'),
          widget: ClozeCueCard(
            sentenceWithBlank: clozeSentence,
            targetWord: widget.word,
            hintText: primaryTranslation,
            onGrade: (_) {}, // No-op in preview mode
            isPreview: true,
          ),
        ),
      );
    }

    // 6. Disambiguation Card
    if (globalDict.confusables.isNotEmpty) {
      final confusable = globalDict.confusables.first;
      final disambig = confusable.disambiguationSentence;
      if (disambig != null) {
        cards.add(
          _CardData(
            label: 'Disambiguation',
            color: MasteryColors.getCueColor(context, 'disambiguation'),
            widget: DisambiguationCard(
              clozeSentence: '${disambig.before}_____${disambig.after}',
              options: [widget.word, confusable.word],
              correctIndex: 0,
              explanation: '',
              onGrade: (_) {}, // No-op in preview mode
              isPreview: true,
            ),
          ),
        );
      }
    }

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
    required this.widget,
  });

  final String label;
  final Color color;
  final Widget widget;
}
