import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../widgets/today_session_card.dart';
import '../widgets/shadow_brain_card.dart';
import '../widgets/recent_words_section.dart';
import '../../../../core/theme/color_tokens.dart';

/// Main dashboard screen with vocabulary overview
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    // Mock data - replace with actual data from providers
    const wordsToReview = 12;
    const totalWords = 127;
    const activeWords = 45;
    const progressPercent = 27.5;
    final recentWords = [
      {
        'word': 'Ephemeral',
        'definition': 'Lasting for a very short time',
        'status': LearningStatus.learning,
      },
      {
        'word': 'Serendipity',
        'definition': 'The occurrence of events by chance',
        'status': LearningStatus.learning,
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  currentUser.when(
                    data: (user) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning',
                          style: MasteryTextStyles.bodySmall.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          (user?.userMetadata?['full_name'] as String?) ?? 'Learner',
                          style: MasteryTextStyles.displayLarge.copyWith(
                            fontSize: 24,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's session card
                    TodaySessionCard(
                      wordsToReview: wordsToReview,
                      onStart: () {
                        // Navigate to learning session
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Learning session not yet implemented'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Shadow brain stats
                    ShadowBrainCard(
                      totalWords: totalWords,
                      activeWords: activeWords,
                      progressPercent: progressPercent,
                    ),
                    const SizedBox(height: 24),

                    // Recent words
                    RecentWordsSection(
                      words: recentWords,
                      onSeeAll: () {
                        // Navigate to full vocabulary list
                        // (handled by parent bottom nav)
                      },
                      onWordTap: (word) {
                        // Navigate to word detail
                        Navigator.of(context).pushNamed(
                          '/vocabulary/${word['word']}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
