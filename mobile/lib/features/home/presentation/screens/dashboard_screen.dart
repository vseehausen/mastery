import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../providers/auth_provider.dart';
import '../../../learn/screens/session_screen.dart';
import '../../../vocabulary/vocabulary_detail_screen.dart';
import '../../../vocabulary/vocabulary_provider.dart';
import '../widgets/recent_words_section.dart';
import '../widgets/shadow_brain_card.dart';
import '../widgets/today_session_card.dart';

/// Main dashboard screen with vocabulary overview
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key, required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final vocabularyAsync = ref.watch(allVocabularyProvider);

    // Get avatar URL from user metadata
    final avatarUrl =
        currentUser.valueOrNull?.userMetadata?['avatar_url'] as String?;

    // Convert vocabulary to recent words format
    final recentWords = vocabularyAsync.when(
      data: (vocabs) => vocabs
          .take(2)
          .map(
            (v) => {
              'id': v.id,
              'word': v.word,
              'definition': v.stem ?? v.word,
              'status': LearningStatus.unknown,
            },
          )
          .toList(),
      loading: () => <Map<String, dynamic>>[],
      error: (_, _) => <Map<String, dynamic>>[],
    );

    // Mock stats - TODO: replace with real data from providers
    const wordsToReview = 12;
    const totalWords = 127;
    const activeWords = 45;
    const progressPercent = 27.5;

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
                          (user?.userMetadata?['full_name'] as String?) ??
                              'Learner',
                          style: MasteryTextStyles.displayLarge.copyWith(
                            fontSize: 24,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  // Avatar with image and tap to settings
                  GestureDetector(
                    onTap: () => onSwitchTab(3),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
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
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SessionScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Shadow brain stats
                    // ignore: prefer_const_constructors
                    ShadowBrainCard(
                      totalWords: totalWords,
                      activeWords: activeWords,
                      progressPercent: progressPercent,
                    ),
                    const SizedBox(height: 24),

                    // Recent words
                    RecentWordsSection(
                      words: recentWords,
                      onSeeAll: () => onSwitchTab(2),
                      onWordTap: (word) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => VocabularyDetailScreen(
                              vocabularyId: word['id'] as String,
                            ),
                          ),
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
