import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/models/streak.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/supabase_provider.dart';

part 'streak_providers.g.dart';

/// Provides the current streak count for the logged-in user
@riverpod
Future<int> currentStreak(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return 0;

  final dataService = ref.watch(supabaseDataServiceProvider);

  // First, check if streak needs to be reset (missed a day)
  final streakData = await dataService.getOrCreateStreak(userId);
  final streak = StreakModel.fromJson(streakData);

  // Check if we need to reset - if last completed was not today or yesterday
  if (streak.lastCompletedDate != null) {
    final today = DateTime.now().toUtc();
    final yesterday = today.subtract(const Duration(days: 1));
    final lastCompleted = streak.lastCompletedDate!;

    final isToday = lastCompleted.year == today.year &&
        lastCompleted.month == today.month &&
        lastCompleted.day == today.day;
    final isYesterday = lastCompleted.year == yesterday.year &&
        lastCompleted.month == yesterday.month &&
        lastCompleted.day == yesterday.day;

    if (!isToday && !isYesterday) {
      // Reset streak
      await dataService.updateStreak(
        id: streak.id,
        currentCount: 0,
        longestCount: streak.longestCount,
        lastCompletedDate: null,
      );
      return 0;
    }
  }

  return streak.currentCount;
}

/// Provides the longest streak count for the logged-in user
@riverpod
Future<int> longestStreak(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return 0;

  final dataService = ref.watch(supabaseDataServiceProvider);
  final streakData = await dataService.getOrCreateStreak(userId);
  final streak = StreakModel.fromJson(streakData);
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

    final dataService = ref.watch(supabaseDataServiceProvider);
    final streakData = await dataService.getOrCreateStreak(userId);
    final streak = StreakModel.fromJson(streakData);
    return streak.currentCount;
  }

  /// Increment the streak (call when session is completed)
  Future<void> incrementStreak() async {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final dataService = ref.watch(supabaseDataServiceProvider);
    final streakData = await dataService.getOrCreateStreak(userId);
    final streak = StreakModel.fromJson(streakData);

    final today = DateTime.now().toUtc();
    final lastCompleted = streak.lastCompletedDate;

    // Check if already completed today
    if (lastCompleted != null &&
        lastCompleted.year == today.year &&
        lastCompleted.month == today.month &&
        lastCompleted.day == today.day) {
      // Already counted today, don't increment again
      return;
    }

    // Increment streak
    final newCount = streak.currentCount + 1;
    final newLongest =
        newCount > streak.longestCount ? newCount : streak.longestCount;

    await dataService.updateStreak(
      id: streak.id,
      currentCount: newCount,
      longestCount: newLongest,
      lastCompletedDate: today,
    );

    state = AsyncValue.data(newCount);

    // Invalidate related providers to refresh UI
    ref.invalidate(currentStreakProvider);
    ref.invalidate(longestStreakProvider);
  }

  /// Reset the streak (call when user misses a day)
  Future<void> resetStreak() async {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final dataService = ref.watch(supabaseDataServiceProvider);
    final streakData = await dataService.getOrCreateStreak(userId);
    final streak = StreakModel.fromJson(streakData);

    await dataService.updateStreak(
      id: streak.id,
      currentCount: 0,
      longestCount: streak.longestCount,
      lastCompletedDate: null,
    );

    state = const AsyncValue.data(0);

    // Invalidate related providers to refresh UI
    ref.invalidate(currentStreakProvider);
  }
}
