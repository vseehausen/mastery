import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/progress_stage_badge.dart';
import '../../data/services/progress_stage_service.dart';
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
      child: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5, AppSpacing.s2, AppSpacing.s5, AppSpacing.s5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HERO AREA: Word + Stats (side by side)
                  _buildHeroArea(vocab, learningCard),
                  const SizedBox(height: AppSpacing.s10), // 40

                  // MEANING AREA (sectioned)
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
                          const SizedBox(height: AppSpacing.s12), // 48
                          _buildContextContent(encounter),
                        ],
                      );
                    },
                  ),

                  // Dev info
                  meaningsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (meanings) {
                      if (meanings.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s8),
                        child: _buildDevInfoSection(meanings.first, vocab.id, ref),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Fixed bottom bar
          _buildBottomBar(meaningsAsync, vocab.id),
        ],
      ),
    );
  }

  /// Hero area: Word + pronunciation on left, badge + stats on right
  Widget _buildHeroArea(
    VocabularyModel vocab,
    LearningCardModel? learningCard,
  ) {
    final colors = context.masteryColors;

    // Calculate progress stage if learning card exists
    final stageService = ProgressStageService();
    final stage = stageService.calculateStage(
      card: learningCard,
      nonTranslationSuccessCount: 0, // Conservative estimate
    );

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
                  fontSize: AppTypography.fontSize2xl,
                  fontWeight: AppTypography.fontWeightSemibold,
                  letterSpacing: AppTypography.letterSpacingTight,
                  height: AppTypography.lineHeightTight,
                ),
              ),
              if (vocab.stem != null) ...[
                const SizedBox(height: AppSpacing.s1), // 4
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
        const SizedBox(width: AppSpacing.s4), // 16
        // Right: Badge + stats
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status/Stage badge
            ProgressStageBadge(
              stage: stage,
              compact: false,
            ),
            const SizedBox(height: AppSpacing.s2), // 8 (closest to 6)
            // Stats
            if (learningCard != null) ...[
              Text(
                '${learningCard.reps} reviews',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeXs,
                  fontWeight: AppTypography.fontWeightMedium,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                'Next: ${_formatNextReview(learningCard.due)}',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeXs,
                  fontWeight: AppTypography.fontWeightMedium,
                  color: colors.mutedForeground,
                ),
              ),
            ] else ...[
              Text(
                'Not yet reviewed',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeXs,
                  fontWeight: AppTypography.fontWeightMedium,
                  color: colors.mutedForeground,
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

  /// Translation section — translation + alternatives + suggest edit
  Widget _buildTranslationSection(MeaningModel meaning) {
    final colors = context.masteryColors;

    return Column(
      key: ValueKey(meaning.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Part of speech as uppercase label
        if (meaning.partOfSpeech != null) ...[
          Text(
            meaning.partOfSpeech!.toUpperCase(),
            style: TextStyle(
              fontSize: AppTypography.fontSizeXs,
              fontWeight: AppTypography.fontWeightMedium,
              color: colors.mutedForeground,
              letterSpacing: AppTypography.letterSpacingWide,
            ),
          ),
          const SizedBox(height: AppSpacing.s3), // 12
        ],

        // Primary translation
        Text(
          meaning.primaryTranslation,
          style: const TextStyle(
            fontSize: AppTypography.fontSize2xl, // 28
            fontWeight: AppTypography.fontWeightSemibold,
            letterSpacing: AppTypography.letterSpacingTight,
            height: AppTypography.lineHeightTight,
          ),
        ),

        // Alternative translations
        if (meaning.alternativeTranslations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s1), // 4
          Text(
            meaning.alternativeTranslations.join(' · '),
            style: TextStyle(
              fontSize: AppTypography.fontSizeBase, // 16
              color: colors.mutedForeground,
            ),
          ),
        ],

        // Suggest edit button
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s1),
          child: TextButton(
            onPressed: () {
              setState(() {
                _editingMeaningId = meaning.id;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: colors.mutedForeground,
            ),
            child: Text(
              'Suggest edit',
              style: TextStyle(
                fontSize: AppTypography.fontSizeXs,
                fontWeight: AppTypography.fontWeightMedium,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Definition section — label + definition + synonyms
  Widget _buildDefinitionSection(MeaningModel meaning) {
    final colors = context.masteryColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Definition text
        Text(
          meaning.englishDefinition,
          style: TextStyle(
            fontSize: AppTypography.fontSizeLg,
            fontWeight: AppTypography.fontWeightMedium,
            height: AppTypography.lineHeightRelaxed,
            color: colors.foreground,
          ),
        ),

        // Synonyms with "Similar:" label
        if (meaning.synonyms.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4), // 16
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Similar: ',
                  style: TextStyle(
                    fontSize: AppTypography.fontSizeSm, // 14
                    color: colors.mutedForeground,
                  ),
                ),
                TextSpan(
                  text: meaning.synonyms.join(', '),
                  style: TextStyle(
                    fontSize: AppTypography.fontSizeSm, // 14
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Meaning content (no card wrapper)
  Widget _buildMeaningContent(List<MeaningModel> meanings) {
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

    // Normal view with sections
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Translation section
        AnimatedSwitcher(
          duration: AppAnimation.duration300,
          child: _buildTranslationSection(meaning),
        ),
        const SizedBox(height: AppSpacing.s12), // 48

        // Definition section
        _buildDefinitionSection(meaning),
      ],
    );
  }

  /// Context content — label + full left-bordered block
  Widget _buildContextContent(EncounterModel encounter) {
    final colors = context.masteryColors;
    final sourceAsync = ref.watch(sourceByIdProvider(encounter.sourceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left-bordered block with quote + citation
        Container(
          padding: const EdgeInsets.only(left: AppSpacing.s5), // 20
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: AppBorderWidth.medium, // 2
                color: colors.border,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote text
              Text(
                '"${encounter.context}"',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeLg, // 18
                  fontStyle: FontStyle.italic,
                  color: colors.mutedForeground,
                  height: AppTypography.lineHeightRelaxed,
                ),
              ),

              // Source attribution
              sourceAsync.when(
                loading: () => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s3),
                  child: Text(
                    'Loading source...',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeXs,
                      fontWeight: AppTypography.fontWeightMedium,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (source) {
                  if (source == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (source.author != null)
                          Text(
                            '— ${source.author}',
                            style: TextStyle(
                              fontSize: AppTypography.fontSizeXs,
                              fontWeight: AppTypography.fontWeightMedium,
                              color: colors.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          source.title,
                          style: TextStyle(
                            fontSize: AppTypography.fontSizeXs,
                            fontWeight: AppTypography.fontWeightMedium,
                            color: colors.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Fixed bottom bar with action buttons
  Widget _buildBottomBar(
    AsyncValue<List<MeaningModel>> meaningsAsync,
    String vocabularyId,
  ) {
    final colors = context.masteryColors;
    return BottomAppBar(
      elevation: 0,
      child: meaningsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (meanings) {
          final hasMeaning = meanings.isNotEmpty;
          final meaning = hasMeaning ? meanings.first : null;
          final userId = ref.watch(currentUserIdProvider);

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Preview Cards - outlined button
              OutlinedButton(
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
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                      vertical: AppSpacing.s3,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: AppTypography.fontSizeLg),
                      SizedBox(width: AppSpacing.s2),
                      Text('Preview'),
                    ],
                  ),
                ),
              const SizedBox(width: AppSpacing.s3),

              // Actions menu (feedback + re-generate)
              if (hasMeaning && userId != null)
                IconButton(
                  onPressed: () =>
                      _showActionMenu(vocabularyId, meaning!.id, userId),
                  icon: const Icon(Icons.more_vert, size: AppSpacing.s5),
                  style: IconButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Simple loading indicator
  Widget _buildLoadingIndicator() {
    final colors = context.masteryColors;
    return Row(
      children: [
        SizedBox(
          width: AppSpacing.s4,
          height: AppSpacing.s4,
          child: CircularProgressIndicator(
            strokeWidth: AppBorderWidth.medium,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Text(
          'Loading...',
          style: TextStyle(
            fontSize: AppTypography.fontSizeSm,
            color: colors.mutedForeground,
          ),
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
          style: TextStyle(
            fontSize: AppTypography.fontSizeSm,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
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
          width: AppSpacing.s4,
          height: AppSpacing.s4,
          child: CircularProgressIndicator(
            strokeWidth: AppBorderWidth.medium,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Text(
          'Generating meanings...',
          style: TextStyle(
            fontSize: AppTypography.fontSizeSm,
            color: colors.mutedForeground,
          ),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
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
