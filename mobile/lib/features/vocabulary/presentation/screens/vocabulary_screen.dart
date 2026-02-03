import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/word_card.dart';
import '../../../../core/theme/text_styles.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vocabularyAsync = ref.watch(vocabularyListProvider);
    final enrichedIdsAsync = ref.watch(enrichedVocabularyIdsProvider);

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
                  color: isDark ? Colors.white : Colors.black,
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error),
                data: (vocabulary) {
                  // Get enriched IDs (empty set if loading/error)
                  final enrichedIds = enrichedIdsAsync.valueOrNull ?? <String>{};

                  // Filter by search query
                  var filtered = vocabulary
                      .where(
                        (v) => v.word.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

                  // Filter by enrichment status
                  switch (_selectedFilter) {
                    case VocabularyFilter.all:
                      // No additional filtering
                      break;
                    case VocabularyFilter.enriched:
                      filtered = filtered
                          .where((v) => enrichedIds.contains(v.id))
                          .toList();
                      break;
                    case VocabularyFilter.notEnriched:
                      filtered = filtered
                          .where((v) => !enrichedIds.contains(v.id))
                          .toList();
                      break;
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
                    },
                    child: ListView.builder(
                      primary: false,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final vocab = filtered[index];
                        final isEnriched = enrichedIds.contains(vocab.id);
                        return WordCard(
                          word: vocab.word,
                          definition: vocab.stem ?? vocab.word,
                          isEnriched: isEnriched,
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

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show different messages based on filter
    String message;
    String subMessage;
    switch (_selectedFilter) {
      case VocabularyFilter.all:
        message = 'No vocabulary yet';
        subMessage = 'Import vocabulary from your Kindle using the desktop app';
        break;
      case VocabularyFilter.enriched:
        message = 'No enriched vocabulary';
        subMessage = 'Enriched words will appear here after processing';
        break;
      case VocabularyFilter.notEnriched:
        message = 'All vocabulary is enriched!';
        subMessage = 'Great job! All your words have been processed';
        break;
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
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subMessage,
              textAlign: TextAlign.center,
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          if (_selectedFilter == VocabularyFilter.all) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                // Just refresh - Supabase handles the data
                ref.invalidate(vocabularyListProvider);
                ref.invalidate(enrichedVocabularyIdsProvider);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(vocabularyListProvider);
              ref.invalidate(enrichedVocabularyIdsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
