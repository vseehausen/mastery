import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database/database.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning_providers.dart';

part 'learning_preferences_providers.g.dart';

// =============================================================================
// User Learning Preferences Providers
// =============================================================================

/// Provides the user's learning preferences
@riverpod
Future<UserLearningPreference?> userLearningPreferences(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return null;

  final userPrefsRepo = ref.watch(userPreferencesRepositoryProvider);
  return userPrefsRepo.getOrCreateWithDefaults(userId);
}

/// Notifier for managing user learning preferences
@riverpod
class LearningPreferencesNotifier extends _$LearningPreferencesNotifier {
  @override
  Future<UserLearningPreference?> build() async {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return null;

    final userPrefsRepo = ref.watch(userPreferencesRepositoryProvider);
    return userPrefsRepo.getOrCreateWithDefaults(userId);
  }

  /// Update daily time target (1-60 minutes)
  Future<void> updateDailyTimeTarget(int minutes) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final userPrefsRepo = ref.read(userPreferencesRepositoryProvider);
    final updated = await userPrefsRepo.updateDailyTimeTarget(userId, minutes);
    state = AsyncData(updated);

    // Invalidate related providers
    ref.invalidate(userLearningPreferencesProvider);
  }

  /// Update intensity (0=light, 1=normal, 2=intense)
  Future<void> updateIntensity(int intensity) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final userPrefsRepo = ref.read(userPreferencesRepositoryProvider);
    final updated = await userPrefsRepo.updateIntensity(userId, intensity);
    state = AsyncData(updated);

    // Invalidate related providers
    ref.invalidate(userLearningPreferencesProvider);
  }

  /// Update target retention (0.85-0.95)
  Future<void> updateTargetRetention(double retention) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final userPrefsRepo = ref.read(userPreferencesRepositoryProvider);
    final updated = await userPrefsRepo.updateTargetRetention(
      userId,
      retention,
    );
    state = AsyncData(updated);

    // Invalidate related providers
    ref.invalidate(userLearningPreferencesProvider);
  }
}
