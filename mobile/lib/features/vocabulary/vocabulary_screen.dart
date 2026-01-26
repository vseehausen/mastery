import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import 'vocabulary_detail_screen.dart';
import 'vocabulary_provider.dart';

/// Screen showing vocabulary list sorted newest first
class VocabularyScreen extends ConsumerWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabularyAsync = ref.watch(allVocabularyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: vocabularyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error, ref),
        data: (vocabulary) {
          if (vocabulary.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allVocabularyProvider);
            },
            child: _buildVocabularyList(context, vocabulary),
          );
        },
      ),
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

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
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

  Widget _buildVocabularyList(BuildContext context, List<Vocabulary> vocabulary) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: vocabulary.length,
      itemBuilder: (context, index) {
        final vocab = vocabulary[index];
        return _VocabularyCard(vocabulary: vocab);
      },
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  const _VocabularyCard({required this.vocabulary});

  final Vocabulary vocabulary;

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
                    child: Text(
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
}
