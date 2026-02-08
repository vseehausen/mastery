import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
import '../learn/screens/session_screen.dart';
import 'presentation/widgets/word_header.dart';
import 'presentation/widgets/context_card.dart';
import 'presentation/widgets/card_preview_sheet.dart';
import 'presentation/widgets/dev_info_panel.dart';
import 'presentation/widgets/field_feedback.dart';
import 'presentation/widgets/learning_stats.dart';
import 'presentation/widgets/meaning_card.dart';
import 'presentation/widgets/meaning_editor.dart';

/// Provider for enrichment queue status
final enrichmentQueueStatusProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, (String, String)>((ref, params) async {
      final (userId, vocabularyId) = params;
      final service = ref.watch(supabaseDataServiceProvider);
      return service.getEnrichmentQueueStatus(userId, vocabularyId);
    });

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
      appBar: AppBar(title: const Text('Word Details')),
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
    final learningCardAsync = ref.watch(
      learningCardByVocabularyIdProvider(vocab.id),
    );
    final learningCard = learningCardAsync.valueOrNull;

    // Trigger enrichment check for un-enriched words
    _triggerEnrichmentIfNeeded(meaningsAsync, vocab.id);

    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            WordHeader(
              word: vocab.word,
              pronunciation: vocab.stem,
              status: LearningStatus.unknown,
            ),
            const SizedBox(height: 16),

            _buildPrimaryActionCard(context, isDark),
            const SizedBox(height: 24),

            // Meaning
            _buildMeaningHeader(meaningsAsync, isDark),
            const SizedBox(height: 12),
            meaningsAsync.when(
              loading: () => _buildLoadingCard(
                message: 'Loading meaning...',
                isDark: isDark,
              ),
              error: (_, _) => _buildStateCard(
                title: 'Couldn\'t load meaning',
                message: 'Please try again.',
                isDark: isDark,
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(meaningsProvider(vocab.id)),
              ),
              data: (meanings) => _buildMeaningsSection(meanings, isDark),
            ),
            const SizedBox(height: 24),

            // Context
            _buildSectionTitle('Context', isDark),
            const SizedBox(height: 12),
            encounterAsync.when(
              loading: () => _buildLoadingCard(
                message: 'Loading context...',
                isDark: isDark,
              ),
              error: (_, _) => _buildStateCard(
                title: 'Couldn\'t load context',
                message: 'Context details are temporarily unavailable.',
                isDark: isDark,
              ),
              data: (encounter) {
                if (encounter == null ||
                    encounter.context == null ||
                    encounter.context!.isEmpty) {
                  return _buildStateCard(
                    title: 'No context available',
                    message: 'This word has no source excerpt yet.',
                    isDark: isDark,
                  );
                }
                return _buildEncounterContext(encounter);
              },
            ),
            const SizedBox(height: 24),

            _buildExpandableSection(
              title: 'Practice details',
              isDark: isDark,
              child: meaningsAsync.when(
                loading: () => _buildLoadingCard(
                  message: 'Loading quiz preview...',
                  isDark: isDark,
                ),
                error: (_, _) => _buildStateCard(
                  title: 'Couldn\'t load quiz preview',
                  message: 'Try refreshing meaning data.',
                  isDark: isDark,
                ),
                data: (meanings) {
                  if (meanings.isEmpty) {
                    return _buildStateCard(
                      title: 'Quiz preview unavailable',
                      message: 'Generate enrichment to create practice cues.',
                      isDark: isDark,
                    );
                  }
                  return _buildQuizPreviewSection(meanings.first.id, isDark);
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandableSection(
              title: 'Learning details',
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LearningStats(
                    timesReviewed: learningCard?.reps,
                    confidence: null,
                    nextReview: learningCard?.due,
                  ),
                  const SizedBox(height: 12),
                  _buildWhyNowCard(isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandableSection(
              title: 'Advanced actions',
              isDark: isDark,
              child: _buildActionsSection(meaningsAsync, vocab.id, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionCard(BuildContext context, bool isDark) {
    final colors = context.masteryColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next best action',
            style: MasteryTextStyles.bodyBold.copyWith(
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Practice this word now to reinforce memory.',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const SessionScreen(),
                  ),
                );
              },
              child: const Text('Practice now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    final colors = context.masteryColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: MasteryTextStyles.bodyBold.copyWith(
            color: isDark
                ? MasteryColors.foregroundDark
                : MasteryColors.foregroundLight,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        collapsedIconColor: isDark
            ? MasteryColors.mutedForegroundDark
            : MasteryColors.mutedForegroundLight,
        iconColor: isDark
            ? MasteryColors.mutedForegroundDark
            : MasteryColors.mutedForegroundLight,
        children: [child],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: MasteryTextStyles.bodyBold.copyWith(
        color: isDark
            ? MasteryColors.foregroundDark
            : MasteryColors.foregroundLight,
      ),
    );
  }

  Widget _buildMeaningHeader(
    AsyncValue<List<MeaningModel>> meaningsAsync,
    bool isDark,
  ) {
    return Row(
      children: [
        _buildSectionTitle('Meaning', isDark),
        const Spacer(),
        meaningsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (meanings) {
            if (meanings.isEmpty) return const SizedBox.shrink();
            final meaning = meanings.first;
            final isEditing = _editingMeaningId == meaning.id;
            return TextButton.icon(
              onPressed: () {
                setState(() {
                  _editingMeaningId = isEditing ? null : meaning.id;
                });
              },
              icon: Icon(
                isEditing ? Icons.close : Icons.edit_outlined,
                size: 16,
              ),
              label: Text(isEditing ? 'Close' : 'Edit'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingCard({required String message, required bool isDark}) {
    final colors = context.masteryColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryAction,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard({
    required String title,
    required String message,
    required bool isDark,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = context.masteryColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryAction,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MasteryTextStyles.bodyBold.copyWith(
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            ShadButton.outline(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  Widget _buildWhyNowCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? MasteryColors.cardDark
            : MasteryColors.warningMutedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? MasteryColors.borderDark
              : MasteryColors.warningLight.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 20,
            color: isDark
                ? MasteryColors.warningDark
                : MasteryColors.warningLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This word was shown because it\'s time to review based on your learning schedule.',
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark
                    ? MasteryColors.foregroundDark
                    : MasteryColors.foregroundLight,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
    AsyncValue<List<MeaningModel>> meaningsAsync,
    String vocabularyId,
    bool isDark,
  ) {
    final userId = ref.watch(currentUserIdProvider);

    return meaningsAsync.when(
      loading: () =>
          _buildLoadingCard(message: 'Preparing actions...', isDark: isDark),
      error: (_, _) => _buildStateCard(
        title: 'Actions unavailable',
        message: 'Try reloading meaning data first.',
        isDark: isDark,
      ),
      data: (meanings) {
        final hasMeaning = meanings.isNotEmpty;
        final primaryMeaning = hasMeaning ? meanings.first : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ShadButton.outline(
                onPressed: hasMeaning
                    ? () => _showReEnrichDialog(vocabularyId)
                    : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Re-generate AI Enrichment'),
                  ],
                ),
              ),
            ),
            if (hasMeaning && userId != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? MasteryColors.cardDark
                      : MasteryColors.secondaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? MasteryColors.borderDark
                        : MasteryColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Meaning quality',
                        style: MasteryTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? MasteryColors.mutedForegroundDark
                              : MasteryColors.mutedForegroundLight,
                        ),
                      ),
                    ),
                    FieldFeedback(
                      meaningId: primaryMeaning!.id,
                      fieldName: 'translation',
                      userId: userId,
                    ),
                  ],
                ),
              ),
            ],
            if (hasMeaning) ...[
              const SizedBox(height: 16),
              _buildDevInfoSection(primaryMeaning!, vocabularyId, ref),
            ],
          ],
        );
      },
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
            onSave:
                ({
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
      children: [MeaningCard(meaning: meaning)],
    );
  }

  Widget _buildEnrichmentPlaceholder(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? MasteryColors.secondaryDark
              : MasteryColors.secondaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? MasteryColors.borderDark
                : MasteryColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark
                    ? MasteryColors.mutedForegroundDark
                    : MasteryColors.mutedForegroundLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Generating meanings...',
                style: MasteryTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? MasteryColors.mutedForegroundDark
                      : MasteryColors.mutedForegroundLight,
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
        debugPrint(
          '[VocabularyDetail] Triggering enrichment for $vocabularyId',
        );
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
      debugPrint(
        '[VocabularyDetail] Enrichment result: ${result.enrichedCount} enriched, ${result.failedCount} failed',
      );

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
      partOfSpeech: partOfSpeech != (meaning.partOfSpeech ?? 'other')
          ? partOfSpeech
          : meaning.partOfSpeech,
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
        await service.updateCue(cueId, promptText: newTranslation);
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

    return sourceAsync.when(
      loading: () => ContextCard(context: encounter.context),
      error: (_, _) => ContextCard(context: encounter.context),
      data: (source) => ContextCard(
        context: encounter.context,
        bookTitle: source?.title,
        author: source?.author,
      ),
    );
  }

  Widget _buildQuizPreviewSection(String meaningId, bool isDark) {
    final vocabAsync = ref.watch(vocabularyByIdProvider(widget.vocabularyId));
    final word = vocabAsync.valueOrNull?.word ?? '';

    // Preview as cards button
    return SizedBox(
      width: double.infinity,
      child: ShadButton.outline(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CardPreviewSheet(
              vocabularyId: widget.vocabularyId,
              word: word,
            ),
          );
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.preview, size: 18),
            SizedBox(width: 8),
            Text('Preview as cards'),
          ],
        ),
      ),
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
      enrichmentQueueStatusProvider((userId, vocabularyId)),
    );

    return queueStatusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (queueStatus) => DevInfoPanel(
        meaning: {
          'confidence': meaning.confidence,
          'source': meaning.source,
          'created_at': meaning.createdAt.toIso8601String(),
          'updated_at': meaning.updatedAt.toIso8601String(),
        },
        queueStatus: queueStatus,
      ),
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
            child: Text(
              'Re-generate',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? MasteryColors.warningDark
                    : MasteryColors.warningLight,
              ),
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
