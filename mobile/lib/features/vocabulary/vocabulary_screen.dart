import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import 'vocabulary_detail_screen.dart';
import 'vocabulary_provider.dart';

/// Screen showing vocabulary list with integrated search
class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _isSearching && _searchQuery.isNotEmpty
          ? _buildSearchResults()
          : _buildVocabularyList(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _stopSearch,
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search vocabulary...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      );
    }

    return AppBar(
      title: const Text('Vocabulary'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _startSearch,
          tooltip: 'Search',
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchResults = ref.watch(vocabularySearchProvider(_searchQuery));

    return searchResults.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (vocabulary) {
        if (vocabulary.isEmpty) {
          return _buildNoResultsState();
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: vocabulary.length,
          itemBuilder: (context, index) {
            final vocab = vocabulary[index];
            return _VocabularyCard(
              vocabulary: vocab,
              highlightQuery: _searchQuery,
            );
          },
        );
      },
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No results for "$_searchQuery"',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyList() {
    final vocabularyAsync = ref.watch(allVocabularyProvider);

    return vocabularyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
      data: (vocabulary) {
        if (vocabulary.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allVocabularyProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: vocabulary.length,
            itemBuilder: (context, index) {
              final vocab = vocabulary[index];
              return _VocabularyCard(vocabulary: vocab);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.abc, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No vocabulary yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Import vocabulary from your Kindle using the desktop app',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(allVocabularyProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  const _VocabularyCard({
    required this.vocabulary,
    this.highlightQuery,
  });

  final Vocabulary vocabulary;
  final String? highlightQuery;

  String _truncateContext(String? context, {int maxLength = 60}) {
    if (context == null || context.isEmpty) return '';
    if (context.length <= maxLength) return context;
    return '${context.substring(0, maxLength - 3)}...';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => VocabularyDetailScreen(
                vocabularyId: vocabulary.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: highlightQuery != null && highlightQuery!.isNotEmpty
                        ? _buildHighlightedText(vocabulary.word, highlightQuery!)
                        : Text(
                            vocabulary.word,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  if (vocabulary.lookupTimestamp != null)
                    Text(
                      _formatDate(vocabulary.lookupTimestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              if (vocabulary.context != null &&
                  vocabulary.context!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"${_truncateContext(vocabulary.context)}"',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = textLower.indexOf(queryLower, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        children: spans,
      ),
    );
  }
}
