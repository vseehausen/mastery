import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/text_styles.dart';
import '../../domain/models/encounter.dart';
import '../../domain/models/learning_card.dart';
import '../../domain/models/meaning.dart';
import '../../domain/models/vocabulary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dev_mode_provider.dart';
import '../../providers/learning_providers.dart';
import '../../providers/supabase_provider.dart';
import 'presentation/widgets/card_preview_sheet.dart';
import 'presentation/widgets/dev_info_panel.dart';
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
    final meaningsAsync = ref.watch(meaningsProvider(widget.vocabularyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Details'),
        actions: [
          // Edit icon in header
          meaningsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (meanings) {
              if (meanings.isEmpty) return const SizedBox.shrink();
              final meaning = meanings.first;
              final isEditing = _editingMeaningId == meaning.id;
              return IconButton(
                icon: Icon(isEditing ? Icons.close : Icons.edit_outlined),
                onPressed: () {
                  setState(() {
                    _editingMeaningId = isEditing ? null : meaning.id;
                  });
                },
              );
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO AREA: Word + Stats (side by side)
            _buildHeroArea(vocab, learningCard),
            const SizedBox(height: 32),

            // MEANING AREA (no card, no label)
            meaningsAsync.when(
              loading: () => _buildLoadingIndicator(),
              error: (_, _) => _buildErrorMessage(
                'Couldn\'t load meaning. Please try again.',
                onRetry: () => ref.invalidate(meaningsProvider(vocab.id)),
              ),
              data: (meanings) => _buildMeaningContent(meanings),
            ),

            // Show context only if available
            encounterAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (encounter) {
                if (encounter == null ||
                    encounter.context == null ||
                    encounter.context!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DIVIDER before context
                    _buildDivider(),
                    const SizedBox(height: 32),

                    // CONTEXT AREA (no card, no label)
                    _buildContextContent(encounter),
                  ],
                );
              },
            ),

            // DIVIDER before actions
            _buildDivider(),
            const SizedBox(height: 32),

            // ACTION BAR (all subtle)
            _buildActionBar(meaningsAsync, vocab.id),
            const SizedBox(height: 24),

            // Dev info
            meaningsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (meanings) {
                if (meanings.isEmpty) return const SizedBox.shrink();
                return _buildDevInfoSection(meanings.first, vocab.id, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Hero area: Word + pronunciation on left, badge + stats on right
  Widget _buildHeroArea(
    VocabularyModel vocab,
    LearningCardModel? learningCard,
  ) {
    final colors = context.masteryColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Word + pronunciation
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vocab.word,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              if (vocab.stem != null) ...[
                const SizedBox(height: 4),
                Text(
                  vocab.stem!,
                  style: MasteryTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right: Badge + stats
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
              ),
              child: Text(
                'New',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Stats
            if (learningCard != null) ...[
              Text(
                '${learningCard.reps} reviews',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Next: ${_formatNextReview(learningCard.due)}',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.mutedForeground.withValues(alpha: 0.7),
                ),
              ),
            ] else ...[
              Text(
                'Not yet reviewed',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.mutedForeground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatNextReview(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 0) return 'Overdue';
    return 'In ${diff.inDays} days';
  }

  /// Meaning content (no card wrapper)
  Widget _buildMeaningContent(List<MeaningModel> meanings) {
    final colors = context.masteryColors;

    if (meanings.isEmpty) {
      return _buildEnrichmentPlaceholder();
    }

    final meaning = meanings.first;

    // If editing, show editor
    if (_editingMeaningId == meaning.id) {
      return MeaningEditor(
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
      );
    }

    // Normal view (no card)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Part of speech
        if (meaning.partOfSpeech != null) ...[
          Text(
            meaning.partOfSpeech!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.mutedForeground,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Translation (HERO)
        Text(
          meaning.primaryTranslation,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // Definition
        Text(
          meaning.englishDefinition,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),

        // Synonyms
        if (meaning.synonyms.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Similar: ${meaning.synonyms.join(' · ')}',
            style: TextStyle(fontSize: 13, color: colors.mutedForeground),
          ),
        ],
      ],
    );
  }

  /// Context content (no card wrapper, quote styling)
  Widget _buildContextContent(EncounterModel encounter) {
    final colors = context.masteryColors;
    final sourceAsync = ref.watch(sourceByIdProvider(encounter.sourceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quote text (italic)
        Text(
          '"${encounter.context}"',
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),

        // Source attribution
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 2),
              color: colors.border.withValues(alpha: 0.3),
            ),
            Expanded(
              child: sourceAsync.when(
                loading: () => Text(
                  'Loading source...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.mutedForeground.withValues(alpha: 0.6),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (source) {
                  if (source == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '— ${source.title}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (source.author != null)
                        Text(
                          'by ${source.author}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Simple divider
  Widget _buildDivider() {
    final colors = context.masteryColors;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 32),
      color: colors.border.withValues(alpha: 0.15),
    );
  }

  /// Action bar (all subtle)
  Widget _buildActionBar(
    AsyncValue<List<MeaningModel>> meaningsAsync,
    String vocabularyId,
  ) {
    final colors = context.masteryColors;
    return meaningsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (meanings) {
        final hasMeaning = meanings.isNotEmpty;
        final meaning = hasMeaning ? meanings.first : null;
        final userId = ref.watch(currentUserIdProvider);

        return Row(
          children: [
            // Preview Cards - outline (not primary)
            Expanded(
              child: ShadButton.outline(
                onPressed: hasMeaning
                    ? () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CardPreviewSheet(
                            vocabularyId: vocabularyId,
                            word:
                                ref
                                    .read(vocabularyByIdProvider(vocabularyId))
                                    .valueOrNull
                                    ?.word ??
                                '',
                          ),
                        );
                      }
                    : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Preview'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Actions menu (feedback + re-generate)
            if (hasMeaning && userId != null)
              IconButton(
                onPressed: () =>
                    _showActionMenu(vocabularyId, meaning!.id, userId),
                icon: const Icon(Icons.more_vert, size: 20),
                style: IconButton.styleFrom(
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Simple loading indicator
  Widget _buildLoadingIndicator() {
    final colors = context.masteryColors;
    return Row(
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
          'Loading...',
          style: TextStyle(fontSize: 14, color: colors.mutedForeground),
        ),
      ],
    );
  }

  /// Simple error message
  Widget _buildErrorMessage(String message, {required VoidCallback onRetry}) {
    final colors = context.masteryColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: 14, color: colors.mutedForeground),
        ),
        const SizedBox(height: 12),
        ShadButton.outline(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }

  /// Enrichment placeholder (simpler)
  Widget _buildEnrichmentPlaceholder() {
    final colors = context.masteryColors;
    return Row(
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
          'Generating meanings...',
          style: TextStyle(fontSize: 14, color: colors.mutedForeground),
        ),
      ],
    );
  }

  /// Submit feedback (thumbs up/down)
  Future<void> _submitFeedback(
    String meaningId,
    String userId,
    String rating,
  ) async {
    final service = ref.read(supabaseDataServiceProvider);
    try {
      await service.createEnrichmentFeedback(
        userId: userId,
        meaningId: meaningId,
        fieldName: 'translation',
        rating: rating,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Show flag sheet
  Future<void> _showFlagSheet(String meaningId, String userId) async {
    // Reuse existing FieldFeedback bottom sheet logic
    // For now, just show a simple dialog
    final category = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Incorrect translation'),
              onTap: () => Navigator.pop(context, 'incorrect_translation'),
            ),
            ListTile(
              title: const Text('Incorrect definition'),
              onTap: () => Navigator.pop(context, 'incorrect_definition'),
            ),
            ListTile(
              title: const Text('Incorrect part of speech'),
              onTap: () => Navigator.pop(context, 'incorrect_pos'),
            ),
            ListTile(
              title: const Text('Missing context'),
              onTap: () => Navigator.pop(context, 'missing_context'),
            ),
            ListTile(
              title: const Text('Inappropriate content'),
              onTap: () => Navigator.pop(context, 'inappropriate'),
            ),
            ListTile(
              title: const Text('Other'),
              onTap: () => Navigator.pop(context, 'other'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (category != null) {
      final service = ref.read(supabaseDataServiceProvider);
      try {
        await service.createEnrichmentFeedback(
          userId: userId,
          meaningId: meaningId,
          fieldName: 'translation',
          rating: 'flag',
          flagCategory: category,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Issue reported'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to report issue: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Show actions menu (feedback + re-generate)
  Future<void> _showActionMenu(
    String vocabularyId,
    String meaningId,
    String userId,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.thumb_up_outlined),
              title: const Text('This meaning is helpful'),
              onTap: () => Navigator.pop(context, 'positive'),
            ),
            ListTile(
              leading: const Icon(Icons.thumb_down_outlined),
              title: const Text('This meaning is not helpful'),
              onTap: () => Navigator.pop(context, 'negative'),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report an issue'),
              onTap: () => Navigator.pop(context, 'flag'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Re-generate AI Enrichment'),
              onTap: () => Navigator.pop(context, 're-generate'),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == 'positive' || action == 'negative') {
      await _submitFeedback(meaningId, userId, action);
    } else if (action == 'flag') {
      if (mounted) {
        await _showFlagSheet(meaningId, userId);
      }
    } else if (action == 're-generate') {
      await _showReEnrichDialog(vocabularyId);
    }
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
