import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../books/books_provider.dart';
import 'highlights_provider.dart';

/// Screen showing highlights for a specific book
class HighlightsScreen extends ConsumerWidget {
  final String bookId;

  const HighlightsScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));
    final highlightsAsync = ref.watch(highlightsForBookProvider(bookId));

    return Scaffold(
      appBar: AppBar(
        title: bookAsync.when(
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Book'),
          data: (book) => Text(
            book?.title ?? 'Book',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: highlightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (highlights) {
          if (highlights.isEmpty) {
            return _buildEmptyState();
          }
          return _buildHighlightsList(highlights);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.highlight_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No highlights yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsList(List highlights) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: highlights.length,
      itemBuilder: (context, index) {
        final highlight = highlights[index];
        return _HighlightCard(highlight: highlight);
      },
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final dynamic highlight;

  const _HighlightCard({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final isNote = highlight.type == 'note';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isNote ? Icons.note : Icons.format_quote,
                  size: 16,
                  color: isNote ? Colors.orange : Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  isNote ? 'Note' : 'Highlight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isNote ? Colors.orange : Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                if (highlight.page != null)
                  Text(
                    'Page ${highlight.page}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                if (highlight.location != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Loc ${highlight.location}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              highlight.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            if (highlight.note != null && highlight.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        highlight.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
