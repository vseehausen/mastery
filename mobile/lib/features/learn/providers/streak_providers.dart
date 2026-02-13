import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/effective_day.dart';
import '../../../core/logging/decision_log.dart';
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
    final now = DateTime.now();
    final today = effectiveToday();
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    final isToday = isSameEffectiveDay(streak.lastCompletedDate!, now);
    final lastEffective = effectiveDate(streak.lastCompletedDate!);
    final isYesterday =
        lastEffective.year == yesterday.year &&
        lastEffective.month == yesterday.month &&
        lastEffective.day == yesterday.day;

    if (!isToday && !isYesterday) {
      // Reset streak
      await dataService.updateStreak(
        id: streak.id,
        currentCount: 0,
        longestCount: streak.longestCount,
        lastCompletedDate: null,
      );
      DecisionLog.log('streak_check', {
        'result': 0,
        'action': 'reset',
        'last_completed_date': streak.lastCompletedDate?.toIso8601String(),
        'is_today': false,
        'is_yesterday': false,
      });
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'streak_check: reset')));
      return 0;
    }

    DecisionLog.log('streak_check', {
      'result': streak.currentCount,
      'action': 'maintained',
      'last_completed_date': streak.lastCompletedDate?.toIso8601String(),
      'is_today': isToday,
      'is_yesterday': isYesterday,
    });
    unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'streak_check: maintained (${streak.currentCount})')));
  } else {
    DecisionLog.log('streak_check', {
      'result': streak.currentCount,
      'action': 'no_history',
      'last_completed_date': null,
    });
    unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'streak_check: no_history')));
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

    final now = DateTime.now();
    final lastCompleted = streak.lastCompletedDate;

    // Check if already completed today
    if (lastCompleted != null && isSameEffectiveDay(lastCompleted, now)) {
      DecisionLog.log('streak_increment', {
        'action': 'already_counted',
        'old_count': streak.currentCount,
        'new_count': streak.currentCount,
      });
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'streak_increment: already_counted')));
      return;
    }

    // Increment streak
    final newCount = streak.currentCount + 1;
    final newLongest = newCount > streak.longestCount
        ? newCount
        : streak.longestCount;

    await dataService.updateStreak(
      id: streak.id,
      currentCount: newCount,
      longestCount: newLongest,
      lastCompletedDate: now,
    );

    DecisionLog.log('streak_increment', {
      'action': 'incremented',
      'old_count': streak.currentCount,
      'new_count': newCount,
    });
    unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'streak_increment: ${streak.currentCount} -> $newCount')));

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

