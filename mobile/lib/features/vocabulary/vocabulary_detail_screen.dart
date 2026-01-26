import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import 'vocabulary_provider.dart';

/// Detail screen for a single vocabulary entry
class VocabularyDetailScreen extends ConsumerWidget {
  const VocabularyDetailScreen({super.key, required this.vocabularyId});

  final String vocabularyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyByIdProvider(vocabularyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Details'),
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

  Widget _buildContent(BuildContext context, Vocabulary vocab) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word
          Center(
            child: Text(
              vocab.word,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Stem (if different from word)
          if (vocab.stem != null && vocab.stem != vocab.word) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Root: ${vocab.stem}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Context section
          if (vocab.context != null && vocab.context!.isNotEmpty) ...[
            const _SectionHeader(icon: Icons.format_quote, title: 'Context'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${vocab.context}"',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Book section
          if (vocab.bookTitle != null && vocab.bookTitle!.isNotEmpty) ...[
            const _SectionHeader(icon: Icons.book, title: 'Source'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocab.bookTitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (vocab.bookAuthor != null && vocab.bookAuthor!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'by ${vocab.bookAuthor}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Metadata section
          const _SectionHeader(icon: Icons.info_outline, title: 'Details'),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Looked up',
            value: vocab.lookupTimestamp != null
                ? _formatFullDate(vocab.lookupTimestamp!)
                : 'Unknown',
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Added to Mastery',
            value: _formatFullDate(vocab.createdAt),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
