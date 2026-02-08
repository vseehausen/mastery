import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/word_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../data/services/progress_stage_service.dart';
import '../../../../domain/models/progress_stage.dart';
import '../../../../providers/supabase_provider.dart';
import '../widgets/vocabulary_search_bar.dart';
import '../widgets/vocabulary_filter_chips.dart';
import '../../vocabulary_detail_screen.dart';

/// Vocabulary list screen with search and filtering
class VocabularyScreenNew extends ConsumerStatefulWidget {
  const VocabularyScreenNew({super.key});

  @override
  ConsumerState<VocabularyScreenNew> createState() =>
      _VocabularyScreenNewState();
}

class _VocabularyScreenNewState extends ConsumerState<VocabularyScreenNew> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  VocabularyFilter _selectedFilter = VocabularyFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.masteryColors;
    final vocabularyAsync = ref.watch(vocabularyListProvider);
    final enrichedIdsAsync = ref.watch(enrichedVocabularyIdsProvider);
    final learningCardsAsync = ref.watch(learningCardsProvider);
    final translationsAsync = ref.watch(primaryTranslationsMapProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Vocabulary',
                style: MasteryTextStyles.displayLarge.copyWith(
                  color: colors.foreground,
                ),
              ),
            ),

            // Search and filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  VocabularySearchBar(
                    controller: _searchController,
                    onChanged: (query) {
                      setState(() => _searchQuery = query);
                    },
                    onClear: () {
                      setState(() => _searchQuery = '');
                    },
                  ),
                  const SizedBox(height: 12),
                  VocabularyFilterChips(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() => _selectedFilter = filter);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Vocabulary list
            Expanded(
              child: vocabularyAsync.when(
                loading: () => _buildSkeletonLoader(),
                error: (error, stack) => _buildErrorState(error),
                data: (vocabulary) {
                  // Get enriched IDs (empty set if loading/error)
                  final enrichedIds =
                      enrichedIdsAsync.valueOrNull ?? <String>{};

                  // Get translations map (empty map if loading/error)
                  final translationsMap =
                      translationsAsync.valueOrNull ?? <String, String>{};

                  // Build progress stage map from learning cards
                  final stageService = ProgressStageService();
                  final stageMap = <String, ProgressStage>{};
                  final learningCards = learningCardsAsync.valueOrNull ?? [];
                  for (final card in learningCards) {
                    stageMap[card.vocabularyId] = stageService.calculateStage(
                      card: card,
                      // Conservative: without batch query, assume 0.
                      // Active/Mastered detection happens during sessions.
                      nonTranslationSuccessCount: 0,
                    );
                  }

                  // Filter by search query
                  var filtered = vocabulary
                      .where(
                        (v) => v.word.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

                  // Filter by enrichment status or progress stage
                  switch (_selectedFilter) {
                    case VocabularyFilter.all:
                      break;
                    case VocabularyFilter.enriched:
                      filtered = filtered
                          .where((v) => enrichedIds.contains(v.id))
                          .toList();
                    case VocabularyFilter.notEnriched:
                      filtered = filtered
                          .where((v) => !enrichedIds.contains(v.id))
                          .toList();
                    case VocabularyFilter.captured:
                      filtered = filtered
                          .where(
                            (v) =>
                                (stageMap[v.id] ?? ProgressStage.captured) ==
                                ProgressStage.captured,
                          )
                          .toList();
                    case VocabularyFilter.practicing:
                      filtered = filtered
                          .where(
                            (v) => stageMap[v.id] == ProgressStage.practicing,
                          )
                          .toList();
                    case VocabularyFilter.stabilizing:
                      filtered = filtered
                          .where(
                            (v) => stageMap[v.id] == ProgressStage.stabilizing,
                          )
                          .toList();
                    case VocabularyFilter.active:
                      filtered = filtered
                          .where((v) => stageMap[v.id] == ProgressStage.active)
                          .toList();
                    case VocabularyFilter.mastered:
                      filtered = filtered
                          .where(
                            (v) => stageMap[v.id] == ProgressStage.mastered,
                          )
                          .toList();
                  }

                  // Sort: enriched first, then by date (newest first)
                  filtered.sort((a, b) {
                    final aEnriched = enrichedIds.contains(a.id);
                    final bEnriched = enrichedIds.contains(b.id);

                    // Enriched items come first
                    if (aEnriched != bEnriched) {
                      return aEnriched ? -1 : 1;
                    }

                    // Then sort by date (newest first)
                    return b.createdAt.compareTo(a.createdAt);
                  });

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      // Invalidate providers to refetch from Supabase
                      ref.invalidate(vocabularyListProvider);
                      ref.invalidate(enrichedVocabularyIdsProvider);
                      ref.invalidate(learningCardsProvider);
                      ref.invalidate(primaryTranslationsMapProvider);
                    },
                    child: ListView.builder(
                      primary: false,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final vocab = filtered[index];
                        final isEnriched = enrichedIds.contains(vocab.id);
                        final stage = stageMap[vocab.id];
                        return WordCard(
                          word: vocab.word,
                          definition:
                              translationsMap[vocab.id] ??
                              vocab.stem ??
                              vocab.word,
                          isEnriched: isEnriched,
                          progressStage: stage,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => VocabularyDetailScreen(
                                  vocabularyId: vocab.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: LoadingSkeleton(
                        height: 20,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    LoadingSkeleton(
                      height: 20,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const LoadingSkeleton(height: 14, width: double.infinity),
                const SizedBox(height: 12),
                Divider(height: 1, color: context.masteryColors.border),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.masteryColors;

    // Show different messages based on filter
    String message;
    String subMessage;
    switch (_selectedFilter) {
      case VocabularyFilter.all:
        message = 'No vocabulary yet';
        subMessage = 'Import vocabulary from your Kindle using the desktop app';
      case VocabularyFilter.enriched:
        message = 'No enriched vocabulary';
        subMessage = 'Enriched words will appear here after processing';
      case VocabularyFilter.notEnriched:
        message = 'All vocabulary is enriched!';
        subMessage = 'Great job! All your words have been processed';
      case VocabularyFilter.captured:
      case VocabularyFilter.practicing:
      case VocabularyFilter.stabilizing:
      case VocabularyFilter.active:
      case VocabularyFilter.mastered:
        message = 'No words at this stage';
        subMessage = 'Words will appear here as they progress';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == VocabularyFilter.notEnriched
                ? Icons.check_circle_outline
                : Icons.book_outlined,
            size: 64,
            color: colors.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 18,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subMessage,
              textAlign: TextAlign.center,
              style: MasteryTextStyles.bodySmall.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ),
          if (_selectedFilter == VocabularyFilter.all) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                // Just refresh - Supabase handles the data
                ref.invalidate(vocabularyListProvider);
                ref.invalidate(enrichedVocabularyIdsProvider);
                ref.invalidate(learningCardsProvider);
                ref.invalidate(primaryTranslationsMapProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final colors = context.masteryColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.destructive),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              ref.invalidate(vocabularyListProvider);
              ref.invalidate(enrichedVocabularyIdsProvider);
              ref.invalidate(learningCardsProvider);
              ref.invalidate(primaryTranslationsMapProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
