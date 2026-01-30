import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database/database.dart';
import '../../../domain/models/planned_item.dart';
import '../../../domain/models/session_plan.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning_providers.dart';

part 'session_providers.g.dart';

// =============================================================================
// User Preferences Providers
// =============================================================================

/// Provides the user's daily time target in minutes
@riverpod
Future<int> dailyTimeTarget(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return 10;

  final userPrefsRepo = ref.watch(userPreferencesRepositoryProvider);
  final prefs = await userPrefsRepo.getOrCreateWithDefaults(userId);
  return prefs.dailyTimeTargetMinutes;
}

/// Provides whether user has completed their session today
@riverpod
Future<bool> hasCompletedToday(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return false;

  final streakRepo = ref.watch(streakRepositoryProvider);
  return streakRepo.hasCompletedToday(userId);
}

/// Provides today's progress (0.0 to 1.0)
@riverpod
Future<double> todayProgress(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return 0.0;

  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final activeSession = await sessionRepo.getActiveSession(userId);

  if (activeSession == null) return 0.0;

  final elapsed = activeSession.elapsedSeconds;
  final planned = activeSession.plannedMinutes * 60;

  if (planned <= 0) return 0.0;
  return (elapsed / planned).clamp(0.0, 1.0);
}

/// Provides whether there are items available to review
@riverpod
Future<bool> hasItemsToReview(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return false;

  final learningCardRepo = ref.watch(learningCardRepositoryProvider);

  // Check for due cards or new cards
  final dueCards = await learningCardRepo.getDueCards(userId, limit: 1);
  if (dueCards.isNotEmpty) return true;

  final newCards = await learningCardRepo.getNewCards(userId, limit: 1);
  return newCards.isNotEmpty;
}

// =============================================================================
// Active Session Providers
// =============================================================================

/// Provides the currently active session, if any
@riverpod
Future<LearningSession?> activeSession(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return null;

  final sessionRepo = ref.watch(sessionRepositoryProvider);
  return sessionRepo.getActiveSession(userId);
}

/// Provides the session plan for the current/new session
@riverpod
Future<SessionPlan?> sessionPlan(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return null;

  final planner = ref.watch(sessionPlannerProvider);
  final userPrefsRepo = ref.watch(userPreferencesRepositoryProvider);
  final prefs = await userPrefsRepo.getOrCreateWithDefaults(userId);

  return planner.buildSessionPlan(
    userId: userId,
    timeTargetMinutes: prefs.dailyTimeTargetMinutes,
    intensity: prefs.intensity,
    targetRetention: prefs.targetRetention,
  );
}

// =============================================================================
// Session State Notifier
// =============================================================================

/// State class for active session
class ActiveSessionState {
  const ActiveSessionState({
    this.session,
    this.plan,
    this.currentItemIndex = 0,
    this.elapsedSeconds = 0,
    this.isPaused = false,
    this.isComplete = false,
  });

  final LearningSession? session;
  final SessionPlan? plan;
  final int currentItemIndex;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isComplete;

  PlannedItem? get currentItem {
    if (plan == null || currentItemIndex >= plan!.items.length) return null;
    return plan!.items[currentItemIndex];
  }

  bool get hasMoreItems =>
      plan != null && currentItemIndex < plan!.items.length;

  int get remainingSeconds {
    if (session == null) return 0;
    final planned = session!.plannedMinutes * 60 + (session!.bonusSeconds);
    return (planned - elapsedSeconds).clamp(0, planned);
  }

  ActiveSessionState copyWith({
    LearningSession? session,
    SessionPlan? plan,
    int? currentItemIndex,
    int? elapsedSeconds,
    bool? isPaused,
    bool? isComplete,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      plan: plan ?? this.plan,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Notifier for managing active session state
@riverpod
class ActiveSessionNotifier extends _$ActiveSessionNotifier {
  @override
  ActiveSessionState build() {
    return const ActiveSessionState();
  }

  /// Initialize the session with a plan
  void initialize(LearningSession session, SessionPlan plan) {
    state = ActiveSessionState(
      session: session,
      plan: plan,
      currentItemIndex: 0,
      elapsedSeconds: session.elapsedSeconds,
      isPaused: false,
      isComplete: false,
    );
  }

  /// Move to the next item
  void nextItem() {
    if (!state.hasMoreItems) {
      state = state.copyWith(isComplete: true);
      return;
    }
    state = state.copyWith(currentItemIndex: state.currentItemIndex + 1);
  }

  /// Update elapsed time
  void updateElapsedTime(int seconds) {
    state = state.copyWith(elapsedSeconds: seconds);
  }

  /// Pause the session
  void pause() {
    state = state.copyWith(isPaused: true);
  }

  /// Resume the session
  void resume() {
    state = state.copyWith(isPaused: false);
  }

  /// Mark session as complete
  void complete() {
    state = state.copyWith(isComplete: true);
  }

  /// Check if time has expired
  bool get isTimeExpired => state.remainingSeconds <= 0;
}
