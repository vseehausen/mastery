import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/text_styles.dart';
import '../../domain/models/encounter.dart';
import '../../domain/models/meaning.dart';
import '../../domain/models/vocabulary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supabase_provider.dart';
import 'presentation/widgets/word_header.dart';
import 'presentation/widgets/context_card.dart';
import 'presentation/widgets/learning_stats.dart';
import 'presentation/widgets/meaning_card.dart';
import 'presentation/widgets/meaning_editor.dart';

/// Detail screen for a single vocabulary entry
class VocabularyDetailScreen extends ConsumerStatefulWidget {
  const VocabularyDetailScreen({super.key, required this.vocabularyId});

  final String vocabularyId;

  @override
  ConsumerState<VocabularyDetailScreen> createState() =>
      _VocabularyDetailScreenState();
}

class _VocabularyDetailScreenState
    extends ConsumerState<VocabularyDetailScreen> {
  String? _editingMeaningId;
  bool _enrichmentTriggered = false;

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(vocabularyByIdProvider(widget.vocabularyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Bookmarked')));
            },
          ),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (vocab) {
          if (vocab == null) {
            return const Center(child: Text('Vocabulary not found'));
          }
          return _buildContent(context, vocab);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, VocabularyModel vocab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final encounterAsync = ref.watch(mostRecentEncounterProvider(vocab.id));
    final meaningsAsync = ref.watch(meaningsProvider(vocab.id));

    // Trigger enrichment check for un-enriched words
    _triggerEnrichmentIfNeeded(meaningsAsync, vocab.id);

    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word header
            Padding(
              padding: const EdgeInsets.all(20),
              child: WordHeader(
                word: vocab.word,
                pronunciation: vocab.stem,
                status: LearningStatus.unknown,
              ),
            ),

            // Meanings section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: meaningsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
                data: (meanings) => _buildMeaningsSection(meanings, isDark),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Context from encounter
                  encounterAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                    data: (encounter) {
                      if (encounter == null ||
                          encounter.context == null ||
                          encounter.context!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _buildEncounterContext(encounter);
                    },
                  ),

                  // Learning stats
                  LearningStats(
                    timesReviewed: 0,
                    confidence: 3,
                    nextReview: DateTime.now().add(const Duration(days: 2)),
                  ),
                  const SizedBox(height: 24),

                  // Why now section (info box)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This word was shown because it\'s time to review based on your learning schedule.',
                            style: MasteryTextStyles.bodySmall.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeaningsSection(List<MeaningModel> meanings, bool isDark) {
    if (meanings.isEmpty) {
      return _buildEnrichmentPlaceholder(isDark);
    }

    // Show only the first (primary) meaning directly
    final meaning = meanings.first;

    if (_editingMeaningId == meaning.id) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeaningEditor(
            meaning: meaning,
            onSave: ({
              String? primaryTranslation,
              String? englishDefinition,
            }) {
              _handleMeaningSave(
                meaning,
                primaryTranslation: primaryTranslation,
                englishDefinition: englishDefinition,
              );
            },
            onCancel: () => setState(() => _editingMeaningId = null),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MeaningCard(
          meaning: meaning,
          onEdit: () => setState(() => _editingMeaningId = meaning.id),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEnrichmentPlaceholder(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Generating meanings...',
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerEnrichmentIfNeeded(
    AsyncValue<List<MeaningModel>> meaningsAsync,
    String vocabularyId,
  ) {
    if (_enrichmentTriggered) return;

    meaningsAsync.whenData((meanings) {
      if (meanings.isEmpty) {
        _enrichmentTriggered = true;
        // TODO: Trigger enrichment via Supabase edge function
        // For now, just log that enrichment would be triggered
        debugPrint('[VocabularyDetail] Would trigger enrichment for $vocabularyId');
      }
    });
  }

  Future<void> _handleMeaningSave(
    MeaningModel meaning, {
    String? primaryTranslation,
    String? englishDefinition,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final service = ref.read(supabaseDataServiceProvider);

    // Record edits
    if (primaryTranslation != null) {
      await service.createMeaningEdit(
        id: const Uuid().v4(),
        userId: userId,
        meaningId: meaning.id,
        fieldName: 'primary_translation',
        originalValue: meaning.primaryTranslation,
        userValue: primaryTranslation,
      );
    }
    if (englishDefinition != null) {
      await service.createMeaningEdit(
        id: const Uuid().v4(),
        userId: userId,
        meaningId: meaning.id,
        fieldName: 'english_definition',
        originalValue: meaning.englishDefinition,
        userValue: englishDefinition,
      );
    }

    // Apply the update
    await service.updateMeaning(
      id: meaning.id,
      primaryTranslation: primaryTranslation,
      englishDefinition: englishDefinition,
    );

    // Refresh meanings and exit edit mode
    ref.invalidate(meaningsProvider(widget.vocabularyId));
    setState(() => _editingMeaningId = null);
  }

  Widget _buildEncounterContext(EncounterModel encounter) {
    final sourceAsync = ref.watch(sourceByIdProvider(encounter.sourceId));

    return Column(
      children: [
        sourceAsync.when(
          loading: () => ContextCard(context: encounter.context),
          error: (e, s) => ContextCard(context: encounter.context),
          data: (source) => ContextCard(
            context: encounter.context,
            bookTitle: source?.title,
            author: source?.author,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
