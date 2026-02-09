import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/models/user_preferences.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/supabase_provider.dart';

part 'learning_preferences_providers.g.dart';

// =============================================================================
// User Learning Preferences Providers
// =============================================================================

/// Provides the user's learning preferences
@riverpod
Future<UserPreferencesModel?> userLearningPreferences(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return null;

  final dataService = ref.watch(supabaseDataServiceProvider);
  final prefsData = await dataService.getOrCreatePreferences(userId);
  return UserPreferencesModel.fromJson(prefsData);
}

/// Notifier for managing user learning preferences
@riverpod
class LearningPreferencesNotifier extends _$LearningPreferencesNotifier {
  @override
  Future<UserPreferencesModel?> build() async {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return null;

    final dataService = ref.watch(supabaseDataServiceProvider);
    final prefsData = await dataService.getOrCreatePreferences(userId);
    return UserPreferencesModel.fromJson(prefsData);
  }

  /// Update daily time target (1-60 minutes)
  Future<void> updateDailyTimeTarget(int minutes) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final dataService = ref.read(supabaseDataServiceProvider);
    await dataService.updatePreferences(
      userId: userId,
      dailyTimeTargetMinutes: minutes,
    );

    // Refresh state
    final prefsData = await dataService.getOrCreatePreferences(userId);
    state = AsyncData(UserPreferencesModel.fromJson(prefsData));

    // Invalidate related providers
    ref.invalidate(userLearningPreferencesProvider);
  }

  /// Update new words per session preset (3=few, 5=normal, 8=many)
  Future<void> updateNewWordsPerSession(int newWordsPerSession) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final dataService = ref.read(supabaseDataServiceProvider);
    await dataService.updatePreferences(
      userId: userId,
      newWordsPerSession: newWordsPerSession,
    );

    // Refresh state
    final prefsData = await dataService.getOrCreatePreferences(userId);
    state = AsyncData(UserPreferencesModel.fromJson(prefsData));

    // Invalidate related providers
    ref.invalidate(userLearningPreferencesProvider);
  }

  /// Update target retention (presets: 0.85, 0.90, 0.93)
  Future<void> updateTargetRetention(double retention) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final dataService = ref.read(supabaseDataServiceProvider);
    await dataService.updatePreferences(
      userId: userId,
      targetRetention: retention,
    );

    // Refresh state
    final prefsData = await dataService.getOrCreatePreferences(userId);
    state = AsyncData(UserPreferencesModel.fromJson(prefsData));

    // Invalidate related providers
    ref.invalidate(userLearningPreferencesProvider);
  }

  /// Update native language code
  Future<void> updateNativeLanguage(String code) async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser.valueOrNull?.id;
    if (userId == null) return;

    final dataService = ref.read(supabaseDataServiceProvider);
    await dataService.updatePreferences(
      userId: userId,
      nativeLanguageCode: code,
    );

    // Refresh state
    final prefsData = await dataService.getOrCreatePreferences(userId);
    state = AsyncData(UserPreferencesModel.fromJson(prefsData));

    // Invalidate related providers
    ref.invalidate(userLearningPreferencesProvider);
  }
}
