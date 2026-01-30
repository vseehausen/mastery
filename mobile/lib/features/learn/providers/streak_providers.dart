import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/learning_providers.dart';

part 'streak_providers.g.dart';

/// Provides the current streak count for the logged-in user
@riverpod
Future<int> currentStreak(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return 0;

  final streakRepo = ref.watch(streakRepositoryProvider);

  // First, check if streak needs to be reset (missed a day)
  await streakRepo.checkAndResetIfNeeded(userId);

  // Then get the current streak
  final streak = await streakRepo.get(userId);
  return streak.currentCount;
}

/// Provides the longest streak count for the logged-in user
@riverpod
Future<int> longestStreak(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return 0;

  final streakRepo = ref.watch(streakRepositoryProvider);
  final streak = await streakRepo.get(userId);
  return streak.longestCount;
}

/// Notifier for updating streak
@riverpod
class StreakNotifier extends _$StreakNotifier {
  @override
  Future<int> build() async {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return 0;

    final streakRepo = ref.watch(streakRepositoryProvider);
    final streak = await streakRepo.get(userId);
    return streak.currentCount;
  }

  /// Increment the streak (call when session is completed)
  Future<void> incrementStreak() async {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final streakRepo = ref.watch(streakRepositoryProvider);
    final updatedStreak = await streakRepo.increment(userId);

    state = AsyncValue.data(updatedStreak.currentCount);

    // Invalidate related providers to refresh UI
    ref.invalidate(currentStreakProvider);
    ref.invalidate(longestStreakProvider);
  }

  /// Reset the streak (call when user misses a day)
  Future<void> resetStreak() async {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final streakRepo = ref.watch(streakRepositoryProvider);
    await streakRepo.reset(userId);

    state = const AsyncValue.data(0);

    // Invalidate related providers to refresh UI
    ref.invalidate(currentStreakProvider);
  }
}
