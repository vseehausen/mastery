import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/color_tokens.dart';
import 'vocabulary_provider.dart';
import 'presentation/widgets/word_header.dart';
import 'presentation/widgets/context_card.dart';
import 'presentation/widgets/learning_stats.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmarked')),
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

  Widget _buildContent(BuildContext context, Vocabulary vocab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word header
            Padding(
              padding: const EdgeInsets.all(20),
              child: WordHeader(
                word: vocab.word,
                pronunciation: vocab.stem,
                status: LearningStatus.unknown, // Mock for now
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Definition/Context section
                  if (vocab.context != null && vocab.context!.isNotEmpty) ...[
                    ContextCard(
                      context: vocab.context,
                      bookTitle: vocab.bookTitle,
                      author: vocab.bookAuthor,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Learning stats
                  LearningStats(
                    timesReviewed: 0, // Mock data
                    confidence: 3,
                    nextReview: DateTime.now().add(const Duration(days: 2)),
                  ),
                  const SizedBox(height: 24),

                  // Why now section (info box)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This word was shown because it\'s time to review based on your learning schedule.',
                            style: MasteryTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
