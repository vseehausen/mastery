import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/text_styles.dart';
import '../../domain/models/encounter.dart';
import '../../domain/models/meaning.dart';
import '../../domain/models/vocabulary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dev_mode_provider.dart';
import '../../providers/learning_providers.dart';
import '../../providers/supabase_provider.dart';
import 'presentation/widgets/word_header.dart';
import 'presentation/widgets/context_card.dart';
import 'presentation/widgets/cue_preview_card.dart';
import 'presentation/widgets/dev_info_panel.dart';
import 'presentation/widgets/field_feedback.dart';
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

            // Quiz Preview section
            meaningsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
              data: (meanings) {
                if (meanings.isEmpty) return const SizedBox.shrink();
                return _buildQuizPreviewSection(
                  meanings.first.id,
                  isDark,
                );
              },
            ),

            // Re-enrich button
            meaningsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
              data: (meanings) {
                if (meanings.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showReEnrichDialog(vocab.id),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Re-generate AI Enrichment'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),

            // Dev Info Panel
            meaningsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
              data: (meanings) {
                if (meanings.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildDevInfoSection(meanings.first, vocab.id, ref),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
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

    final userId = ref.watch(currentUserIdProvider);

    if (_editingMeaningId == meaning.id) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeaningEditor(
            meaning: meaning,
            onSave: ({
              required String translation,
              required String definition,
              required String partOfSpeech,
              required List<String> synonyms,
              required List<String> alternativeTranslations,
            }) {
              _handleMeaningSave(
                meaning,
                translation: translation,
                definition: definition,
                partOfSpeech: partOfSpeech,
                synonyms: synonyms,
                alternativeTranslations: alternativeTranslations,
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
        if (userId != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FieldFeedback(
                meaningId: meaning.id,
                fieldName: 'translation',
                userId: userId,
              ),
            ],
          ),
        ],
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
        debugPrint('[VocabularyDetail] Triggering enrichment for $vocabularyId');
        _requestEnrichment(vocabularyId);
      }
    });
  }

  Future<void> _requestEnrichment(String vocabularyId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final enrichmentService = ref.read(enrichmentServiceProvider);
      final result = await enrichmentService.requestEnrichment(
        userId: userId,
        vocabularyIds: [vocabularyId],
        batchSize: 1,
        languageCode: 'de',
      );
      debugPrint('[VocabularyDetail] Enrichment result: ${result.enrichedCount} enriched, ${result.failedCount} failed');

      // Refresh the meanings after enrichment
      if (result.enrichedCount > 0) {
        ref.invalidate(meaningsProvider(vocabularyId));
      }
    } catch (e) {
      debugPrint('[VocabularyDetail] Enrichment error: $e');
    }
  }

  Future<void> _handleMeaningSave(
    MeaningModel meaning, {
    required String translation,
    required String definition,
    required String partOfSpeech,
    required List<String> synonyms,
    required List<String> alternativeTranslations,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final service = ref.read(supabaseDataServiceProvider);

    // Record edits for changed fields
    if (translation != meaning.primaryTranslation) {
      await service.createMeaningEdit(
        id: const Uuid().v4(),
        userId: userId,
        meaningId: meaning.id,
        fieldName: 'primary_translation',
        originalValue: meaning.primaryTranslation,
        userValue: translation,
      );
    }
    if (definition != meaning.englishDefinition) {
      await service.createMeaningEdit(
        id: const Uuid().v4(),
        userId: userId,
        meaningId: meaning.id,
        fieldName: 'english_definition',
        originalValue: meaning.englishDefinition,
        userValue: definition,
      );
    }
    if (partOfSpeech != (meaning.partOfSpeech ?? 'other')) {
      await service.createMeaningEdit(
        id: const Uuid().v4(),
        userId: userId,
        meaningId: meaning.id,
        fieldName: 'part_of_speech',
        originalValue: meaning.partOfSpeech ?? 'other',
        userValue: partOfSpeech,
      );
    }
    if (synonyms.join(',') != meaning.synonyms.join(',')) {
      await service.createMeaningEdit(
        id: const Uuid().v4(),
        userId: userId,
        meaningId: meaning.id,
        fieldName: 'synonyms',
        originalValue: meaning.synonyms.join(','),
        userValue: synonyms.join(','),
      );
    }
    if (alternativeTranslations.join(',') !=
        meaning.alternativeTranslations.join(',')) {
      await service.createMeaningEdit(
        id: const Uuid().v4(),
        userId: userId,
        meaningId: meaning.id,
        fieldName: 'alternative_translations',
        originalValue: meaning.alternativeTranslations.join(','),
        userValue: alternativeTranslations.join(','),
      );
    }

    // Apply the update
    await service.updateMeaning(
      id: meaning.id,
      primaryTranslation: translation,
      englishDefinition: definition,
      partOfSpeech: partOfSpeech,
      synonyms: synonyms,
      alternativeTranslations: alternativeTranslations,
    );

    // Auto-update related cues
    await _autoUpdateCues(
      meaningId: meaning.id,
      translationChanged: translation != meaning.primaryTranslation,
      newTranslation: translation,
      definitionChanged: definition != meaning.englishDefinition,
      newDefinition: definition,
      synonymsChanged: synonyms.join(',') != meaning.synonyms.join(','),
      newSynonyms: synonyms,
    );

    // Refresh meanings, cues, and exit edit mode
    ref.invalidate(meaningsProvider(widget.vocabularyId));
    ref.invalidate(cuesForVocabularyProvider(widget.vocabularyId));
    setState(() => _editingMeaningId = null);
  }

  Future<void> _autoUpdateCues({
    required String meaningId,
    required bool translationChanged,
    required String newTranslation,
    required bool definitionChanged,
    required String newDefinition,
    required bool synonymsChanged,
    required List<String> newSynonyms,
  }) async {
    final service = ref.read(supabaseDataServiceProvider);
    final cues = await service.getCuesForMeaning(meaningId);

    for (final cue in cues) {
      final cueType = cue['cue_type'] as String?;
      final cueId = cue['id'] as String;

      if (translationChanged && cueType == 'translation') {
        await service.updateCue(cueId, answerText: newTranslation);
      } else if (definitionChanged && cueType == 'definition') {
        await service.updateCue(cueId, promptText: newDefinition);
      } else if (synonymsChanged && cueType == 'synonym') {
        final synonymsText = newSynonyms.join(', ');
        await service.updateCue(cueId, promptText: synonymsText);
      }
    }
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

  Widget _buildQuizPreviewSection(String meaningId, bool isDark) {
    final cuesAsync = ref.watch(cuesForMeaningProvider(meaningId));

    return cuesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (cues) {
        if (cues.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quiz Preview',
                style: MasteryTextStyles.bodyBold.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...cues.map((cue) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CuePreviewCard(cue: cue),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDevInfoSection(
    MeaningModel meaning,
    String vocabularyId,
    WidgetRef ref,
  ) {
    final userId = ref.watch(currentUserIdProvider);
    final devMode = ref.watch(devModeProvider);

    if (!devMode || userId == null) {
      return const SizedBox.shrink();
    }

    final queueStatusAsync = ref.watch(
      FutureProvider.autoDispose((ref) async {
        final service = ref.watch(supabaseDataServiceProvider);
        return service.getEnrichmentQueueStatus(userId, vocabularyId);
      }).future,
    );

    return FutureBuilder<Map<String, dynamic>?>(
      future: queueStatusAsync,
      builder: (context, snapshot) {
        return DevInfoPanel(
          meaning: {
            'confidence': meaning.confidence,
            'source': meaning.source,
            'created_at': meaning.createdAt.toIso8601String(),
            'updated_at': meaning.updatedAt.toIso8601String(),
          },
          queueStatus: snapshot.data,
        );
      },
    );
  }

  Future<void> _showReEnrichDialog(String vocabularyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-generate Enrichment'),
        content: const Text(
          'This will generate new AI translations, definitions, and quiz cues. '
          'Current data will be replaced. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Re-generate',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final enrichmentService = ref.read(enrichmentServiceProvider);
      await enrichmentService.reEnrich(
        userId: userId,
        vocabularyId: vocabularyId,
      );

      // Refresh meanings and cues
      ref.invalidate(meaningsProvider(vocabularyId));
      ref.invalidate(cuesForVocabularyProvider(vocabularyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Re-enrichment started'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Re-enrichment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
