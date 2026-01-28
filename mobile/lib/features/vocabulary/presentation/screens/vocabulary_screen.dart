import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/word_card.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../widgets/vocabulary_search_bar.dart';
import '../widgets/vocabulary_filter_chips.dart';
import '../../vocabulary_provider.dart';
import '../../vocabulary_detail_screen.dart';

/// Vocabulary list screen with search and filtering
class VocabularyScreenNew extends ConsumerStatefulWidget {
  const VocabularyScreenNew({
    super.key,
  });

  @override
  ConsumerState<VocabularyScreenNew> createState() =>
      _VocabularyScreenNewState();
}

class _VocabularyScreenNewState extends ConsumerState<VocabularyScreenNew> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vocabularyAsync = ref.watch(allVocabularyProvider);

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
                    onFilterChanged: (status) {
                      // TODO: Implement status filtering
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Vocabulary list
            Expanded(
              child: vocabularyAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => _buildErrorState(error),
                data: (vocabulary) {
                  // Filter by search query
                  var filtered = vocabulary
                      .where((v) => v.word
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();

                  // Filter by status (would need status field in Vocabulary model)
                  // For now, we'll show all since status isn't in the data model

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(allVocabularyProvider);
                    },
                    child: ListView.builder(
                      primary: false,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final vocab = filtered[index];
                        return WordCard(
                          word: vocab.word,
                          definition: vocab.context ?? 'No definition',
                          status: LearningStatus
                              .unknown, // Mock status for now
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    VocabularyDetailScreen(
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No vocabulary yet',
            style: MasteryTextStyles.bodyBold.copyWith(
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Import vocabulary from your Kindle using the desktop app',
              textAlign: TextAlign.center,
              style: MasteryTextStyles.bodySmall.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: MasteryTextStyles.bodySmall.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(allVocabularyProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
