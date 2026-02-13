import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/mastery_back_button.dart';
import '../../core/widgets/progress_stage_badge.dart';
import '../../data/services/progress_stage_service.dart';
import '../../domain/models/encounter.dart';
import '../../domain/models/global_dictionary.dart';
import '../../domain/models/learning_card.dart';
import '../../domain/models/vocabulary.dart';
import '../../domain/services/audio_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dev_mode_provider.dart';
import '../../providers/learning_providers.dart';
import '../../providers/supabase_provider.dart';
import '../learn/providers/learning_preferences_providers.dart';
import 'presentation/widgets/card_preview_sheet.dart';
import 'presentation/widgets/dev_info_panel.dart';
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
  bool _enrichmentTriggered = false;
  bool _isReEnriching = false;
  bool _enrichmentFailed = false;
  final AudioService _audioService = AudioService();

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(vocabularyByIdProvider(widget.vocabularyId));
    final globalDictAsync = ref.watch(
      globalDictionaryProvider(widget.vocabularyId),
    );

    return Scaffold(
      appBar: AppBar(
        leading: MasteryBackButton.back(
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Edit icon in header
          globalDictAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (globalDict) {
              if (globalDict == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openMeaningEditor(globalDict),
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
    final colors = context.masteryColors;
    final encounterAsync = ref.watch(mostRecentEncounterProvider(vocab.id));
    final globalDictAsync = ref.watch(globalDictionaryProvider(vocab.id));
    final learningCardAsync = ref.watch(
      learningCardByVocabularyIdProvider(vocab.id),
    );
    final learningCard = learningCardAsync.valueOrNull;

    // Trigger enrichment check for un-enriched words
    _triggerEnrichmentIfNeeded(globalDictAsync, vocab.id);

    return SafeArea(
      child: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                AppSpacing.s0,
                AppSpacing.s5,
                AppSpacing.s5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Headword + Badge/Meta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Headword
                      Expanded(
                        child: Text(
                          vocab.displayWord,
                          style: GoogleFonts.literata(
                            fontSize: 30,
                            fontWeight: AppTypography.fontWeightMedium,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                      // Right: Badge + metadata
                      Transform.translate(
                        offset: const Offset(0, 8),
                        child: _buildHeaderMetadata(vocab, learningCard),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),

                  // L2 synonyms (if available)
                  globalDictAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (globalDict) {
                      if (globalDict == null || globalDict.synonyms.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                        child: Text(
                          globalDict.synonyms.join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground,
                          ),
                        ),
                      );
                    },
                  ),

                  // IPA + POS + Audio line (if available)
                  globalDictAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (globalDict) {
                      if (globalDict == null) return const SizedBox.shrink();

                      final hasIpa =
                          globalDict.pronunciationIpa != null &&
                          globalDict.pronunciationIpa!.isNotEmpty;
                      final hasPos =
                          globalDict.partOfSpeech != null &&
                          globalDict.partOfSpeech!.isNotEmpty;
                      final prefs = ref.watch(
                        userLearningPreferencesProvider,
                      );
                      final audioEnabled =
                          prefs.valueOrNull?.audioEnabled ?? true;
                      final audioAccent =
                          prefs.valueOrNull?.audioAccent ?? 'us';
                      final audioUrl = audioEnabled
                          ? globalDict.audioUrlFor(audioAccent)
                          : null;

                      if (!hasIpa && !hasPos && audioUrl == null) {
                        return const SizedBox.shrink();
                      }

                      final parts = <InlineSpan>[];

                      if (hasIpa) {
                        parts.add(
                          TextSpan(
                            text: globalDict.pronunciationIpa,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamilyMono,
                              fontSize: 12,
                              color: colors.subtleForeground,
                            ),
                          ),
                        );
                      }

                      if (hasIpa && hasPos) {
                        parts.add(
                          TextSpan(
                            text: ' · ',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.subtleForeground,
                            ),
                          ),
                        );
                      }

                      if (hasPos) {
                        parts.add(
                          TextSpan(
                            text: globalDict.partOfSpeech!.toLowerCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.subtleForeground,
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                        child: Row(
                          children: [
                            if (audioUrl != null)
                              IconButton(
                                onPressed: () =>
                                    _audioService.play(audioUrl),
                                icon: Icon(
                                  Icons.volume_up,
                                  size: 18,
                                  color: colors.subtleForeground,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                            if (parts.isNotEmpty)
                              Text.rich(TextSpan(children: parts)),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.s5), // 20
                  // MEANING AREA (sectioned)
                  if (_isReEnriching)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: const LinearProgressIndicator(minHeight: 2),
                      ),
                    ),
                  globalDictAsync.when(
                    loading: () => _buildLoadingIndicator(),
                    error: (_, _) => _buildErrorMessage(
                      'Couldn\'t load meaning. Please try again.',
                      onRetry: () =>
                          ref.invalidate(globalDictionaryProvider(vocab.id)),
                    ),
                    data: (globalDict) => _buildMeaningContent(globalDict),
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
                          const SizedBox(height: AppSpacing.s5), // 20
                          _buildContextContent(encounter),
                        ],
                      );
                    },
                  ),

                  // Dev info
                  globalDictAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (globalDict) {
                      if (globalDict == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s8),
                        child: _buildDevInfoSection(globalDict, ref),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Fixed bottom bar
          _buildBottomBar(globalDictAsync, vocab),
        ],
      ),
    );
  }

  /// Header metadata: badge + compact stats on the right
  Widget _buildHeaderMetadata(
    VocabularyModel vocab,
    LearningCardModel? learningCard,
  ) {
    final colors = context.masteryColors;
    final stageService = ProgressStageService();
    final stage = learningCard?.progressStage ?? stageService.calculateStage(
      card: learningCard,
      nonTranslationSuccessCount: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressStageBadge(stage: stage, compact: true),
        if (learningCard != null) ...[
          const SizedBox(height: AppSpacing.s1),
          Text(
            '${learningCard.reps} reviews · ${_formatNextReview(learningCard.due)}',
            style: TextStyle(fontSize: 10, color: colors.subtleForeground),
          ),
        ],
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
  Widget _buildTranslationSection(GlobalDictionaryModel globalDict) {
    final colors = context.masteryColors;

    // Get first available language translations
    final langTranslations = globalDict.translations.isNotEmpty
        ? globalDict.translations.values.first
        : null;
    final primaryTranslation = langTranslations?.primary ?? '';
    final alternatives = langTranslations?.alternatives ?? [];

    return Column(
      key: ValueKey(globalDict.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary translation
        Text(
          primaryTranslation,
          style: GoogleFonts.literata(
            fontSize: AppTypography.fontSizeXl, // 24
            fontWeight: AppTypography.fontWeightSemibold,
            color: colors.foreground,
            height: 1.2,
          ),
        ),

        // Alternative translations
        if (alternatives.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s1), // 4
          Text(
            alternatives.join(' · '),
            style: TextStyle(fontSize: 13, color: colors.mutedForeground),
          ),
        ],
      ],
    );
  }

  /// Definition section — definition only
  Widget _buildDefinitionSection(GlobalDictionaryModel globalDict) {
    final colors = context.masteryColors;

    return Column(
      key: ValueKey(globalDict.englishDefinition),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Definition text
        if (globalDict.englishDefinition != null)
          Text(
            globalDict.englishDefinition!,
            style: TextStyle(
              fontSize: AppTypography.fontSizeSm, // 14
              color: colors.mutedForeground,
              height: 1.7,
            ),
          ),
      ],
    );
  }

  /// Meaning content (no card wrapper)
  Widget _buildMeaningContent(GlobalDictionaryModel? globalDict) {
    if (globalDict == null) {
      return _buildEnrichmentPlaceholder();
    }

    final colors = context.masteryColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Translation section
        AnimatedSwitcher(
          duration: AppAnimation.duration300,
          child: _buildTranslationSection(globalDict),
        ),
        const SizedBox(height: AppSpacing.s4), // 16
        // Separator
        Container(height: 1, color: colors.border),
        const SizedBox(height: AppSpacing.s4), // 16
        // Definition section
        AnimatedSwitcher(
          duration: AppAnimation.duration300,
          child: _buildDefinitionSection(globalDict),
        ),
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
                style: GoogleFonts.literata(
                  fontSize: AppTypography.fontSizeSm, // 14
                  fontStyle: FontStyle.italic,
                  color: colors.mutedForeground,
                  height: 1.7,
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
                      color: colors.subtleForeground,
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
                              fontWeight: AppTypography.fontWeightNormal,
                              color: colors.subtleForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          source.title,
                          style: TextStyle(
                            fontSize: AppTypography.fontSizeXs,
                            fontStyle: FontStyle.italic,
                            fontWeight: AppTypography.fontWeightNormal,
                            color: colors.subtleForeground,
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
    AsyncValue<GlobalDictionaryModel?> globalDictAsync,
    VocabularyModel vocab,
  ) {
    final colors = context.masteryColors;
    return BottomAppBar(
      elevation: 0,
      child: globalDictAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (globalDict) {
          final hasDict = globalDict != null;
          final userId = ref.watch(currentUserIdProvider);

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Preview Cards - outlined button
              OutlinedButton(
                onPressed: hasDict
                    ? () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CardPreviewSheet(
                            vocabularyId: vocab.id,
                            word: vocab.displayWord,
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
                    Icon(
                      Icons.visibility_outlined,
                      size: AppTypography.fontSizeLg,
                    ),
                    SizedBox(width: AppSpacing.s2),
                    Text('Preview'),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s3),

              // Actions menu (feedback + re-generate)
              if (hasDict && userId != null)
                IconButton(
                  onPressed: () =>
                      _showActionMenu(vocab.id, globalDict.id, userId),
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

    if (_enrichmentFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrichment failed',
            style: TextStyle(
              fontSize: AppTypography.fontSizeSm,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          ShadButton.outline(
            onPressed: () {
              setState(() {
                _enrichmentTriggered = false;
                _enrichmentFailed = false;
              });
              _requestEnrichment(widget.vocabularyId);
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppSpacing.s10,
            height: AppSpacing.s10,
            child: CircularProgressIndicator(
              strokeWidth: AppBorderWidth.thick,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          Text(
            'Enriching...',
            style: TextStyle(
              fontSize: AppTypography.fontSizeBase,
              fontWeight: AppTypography.fontWeightMedium,
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  /// Submit feedback (thumbs up/down)
  Future<void> _submitFeedback(
    String globalDictionaryId,
    String userId,
    String rating,
  ) async {
    final service = ref.read(supabaseDataServiceProvider);
    try {
      await service.createEnrichmentFeedback(
        userId: userId,
        globalDictionaryId: globalDictionaryId,
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
  Future<void> _showFlagSheet(String globalDictionaryId, String userId) async {
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
          globalDictionaryId: globalDictionaryId,
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
    String globalDictionaryId,
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
      await _submitFeedback(globalDictionaryId, userId, action);
    } else if (action == 'flag') {
      if (mounted) {
        await _showFlagSheet(globalDictionaryId, userId);
      }
    } else if (action == 're-generate') {
      await _showReEnrichDialog(vocabularyId);
    }
  }

  void _triggerEnrichmentIfNeeded(
    AsyncValue<GlobalDictionaryModel?> globalDictAsync,
    String vocabularyId,
  ) {
    if (_enrichmentTriggered) return;

    globalDictAsync.whenData((globalDict) {
      if (globalDict == null) {
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

      // Refresh the global dictionary data after enrichment
      if (result.enrichedCount > 0) {
        ref.invalidate(globalDictionaryProvider(vocabularyId));
      } else if (result.enrichedCount == 0 && result.failedCount > 0) {
        setState(() => _enrichmentFailed = true);
      }
    } catch (e) {
      debugPrint('[VocabularyDetail] Enrichment error: $e');
      setState(() => _enrichmentFailed = true);
    }
  }

  void _openMeaningEditor(GlobalDictionaryModel globalDict) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MeaningEditor(
          globalDict: globalDict,
          onSave:
              ({
                required String translation,
                required String definition,
                required String partOfSpeech,
                required List<String> synonyms,
                required List<String> alternativeTranslations,
              }) {
                Navigator.of(context).pop();
                _handleOverrideSave(
                  translation: translation,
                  definition: definition,
                  partOfSpeech: partOfSpeech,
                  synonyms: synonyms,
                  alternativeTranslations: alternativeTranslations,
                );
              },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _handleOverrideSave({
    required String translation,
    required String definition,
    required String partOfSpeech,
    required List<String> synonyms,
    required List<String> alternativeTranslations,
  }) async {
    final service = ref.read(supabaseDataServiceProvider);

    // Build overrides map with only changed fields
    final overrides = <String, dynamic>{
      'primary_translation': translation,
      'english_definition': definition,
      'part_of_speech': partOfSpeech,
      'synonyms': synonyms,
      'alternative_translations': alternativeTranslations,
    };

    await service.updateVocabularyOverrides(widget.vocabularyId, overrides);

    // Refresh data
    ref.invalidate(globalDictionaryProvider(widget.vocabularyId));
    ref.invalidate(primaryTranslationsMapProvider);
  }

  Widget _buildDevInfoSection(GlobalDictionaryModel globalDict, WidgetRef ref) {
    final devMode = ref.watch(devModeProvider);

    if (!devMode) {
      return const SizedBox.shrink();
    }

    return DevInfoPanel(
      meaning: {
        'confidence': globalDict.confidence,
        'source': 'global_dictionary',
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

    setState(() => _isReEnriching = true);

    try {
      final enrichmentService = ref.read(enrichmentServiceProvider);
      await enrichmentService.reEnrich(
        userId: userId,
        vocabularyId: vocabularyId,
      );

      // Refresh data
      ref.invalidate(globalDictionaryProvider(vocabularyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enrichment updated'),
            duration: Duration(seconds: 2),
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
    } finally {
      if (mounted) {
        setState(() => _isReEnriching = false);
      }
    }
  }
}
