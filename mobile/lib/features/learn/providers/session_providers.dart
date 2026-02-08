import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/app_defaults.dart';
import '../../../domain/models/learning_session.dart';
import '../../../domain/models/planned_item.dart';
import '../../../domain/models/session_plan.dart';
import '../../../domain/models/stage_transition.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning_providers.dart';
import '../../../providers/supabase_provider.dart';

part 'session_providers.g.dart';

// =============================================================================
// User Preferences Providers
// =============================================================================

/// Provides the user's daily time target in minutes
@riverpod
Future<int> dailyTimeTarget(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return AppDefaults.dailyTimeTargetMinutes;

  final dataService = ref.watch(supabaseDataServiceProvider);
  final prefs = await dataService.getOrCreatePreferences(userId);
  return prefs['daily_time_target_minutes'] as int? ??
      AppDefaults.dailyTimeTargetMinutes;
}

/// Provides whether user has completed their session today
@riverpod
Future<bool> hasCompletedToday(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return false;

  final dataService = ref.watch(supabaseDataServiceProvider);
  final streak = await dataService.getOrCreateStreak(userId);
  final lastCompletedStr = streak['last_completed_date'] as String?;
  if (lastCompletedStr == null) return false;

  final lastCompleted = DateTime.parse(lastCompletedStr);
  final today = DateTime.now().toUtc();
  return lastCompleted.year == today.year &&
      lastCompleted.month == today.month &&
      lastCompleted.day == today.day;
}

/// Provides today's progress (0.0 to 1.0)
@riverpod
Future<double> todayProgress(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return 0.0;

  final dataService = ref.watch(supabaseDataServiceProvider);
  final activeSessionData = await dataService.getActiveSession(userId);

  if (activeSessionData == null) return 0.0;

  final elapsed = activeSessionData['elapsed_seconds'] as int? ?? 0;
  final plannedMinutes = activeSessionData['planned_minutes'] as int? ??
      AppDefaults.dailyTimeTargetMinutes;
  final planned = plannedMinutes * 60;

  if (planned <= 0) return 0.0;
  return (elapsed / planned).clamp(0.0, 1.0);
}

/// Provides whether there are items available to review
@riverpod
Future<bool> hasItemsToReview(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return false;

  final dataService = ref.watch(supabaseDataServiceProvider);

  // Check for due cards or new cards
  final dueCards = await dataService.getDueCards(userId, limit: 1);
  if (dueCards.isNotEmpty) return true;

  final newCards = await dataService.getNewCards(userId, limit: 1);
  if (newCards.isNotEmpty) return true;

  // Also check if there's vocabulary that doesn't have learning cards yet
  final vocabCount = await dataService.countVocabulary(userId);
  if (vocabCount > 0) {
    // There's vocabulary - cards will be created at import time on server
    final existingCards = await dataService.getLearningCards(userId);
    // If there are more vocab items than cards, we have items to review
    if (vocabCount > existingCards.length) return true;
  }

  return false;
}

// =============================================================================
// Active Session Providers
// =============================================================================

/// Provides the currently active session, if any
@riverpod
Future<LearningSessionModel?> activeSession(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return null;

  final dataService = ref.watch(supabaseDataServiceProvider);
  final sessionData = await dataService.getActiveSession(userId);
  if (sessionData == null) return null;
  return LearningSessionModel.fromJson(sessionData);
}

/// Provides the session plan for the current/new session
@riverpod
Future<SessionPlan?> sessionPlan(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser.valueOrNull?.id;
  if (userId == null) return null;

  final planner = ref.watch(sessionPlannerProvider);
  final dataService = ref.watch(supabaseDataServiceProvider);
  final prefs = await dataService.getOrCreatePreferences(userId);

  return planner.buildSessionPlan(
    userId: userId,
    timeTargetMinutes: prefs['daily_time_target_minutes'] as int? ??
        AppDefaults.dailyTimeTargetMinutes,
    intensity: prefs['intensity'] as int? ?? AppDefaults.intensity,
    targetRetention: (prefs['target_retention'] as num?)?.toDouble() ??
        AppDefaults.targetRetention,
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
    this.transitions = const [],
  });

  final LearningSessionModel? session;
  final SessionPlan? plan;
  final int currentItemIndex;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isComplete;
  final List<StageTransition> transitions;

  PlannedItem? get currentItem {
    if (plan == null || currentItemIndex >= plan!.items.length) return null;
    return plan!.items[currentItemIndex];
  }

  bool get hasMoreItems =>
      plan != null && currentItemIndex < plan!.items.length;

  int get remainingSeconds {
    if (session == null) return 0;
    final planned = session!.plannedMinutes * 60 + session!.bonusSeconds;
    return (planned - elapsedSeconds).clamp(0, planned);
  }

  ActiveSessionState copyWith({
    LearningSessionModel? session,
    SessionPlan? plan,
    int? currentItemIndex,
    int? elapsedSeconds,
    bool? isPaused,
    bool? isComplete,
    List<StageTransition>? transitions,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      plan: plan ?? this.plan,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      isComplete: isComplete ?? this.isComplete,
      transitions: transitions ?? this.transitions,
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
  void initialize(LearningSessionModel session, SessionPlan plan) {
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

  /// Record a stage transition for a word during the session.
  ///
  /// This should be called when a word's progress stage changes after a review.
  /// Transitions are used to display micro-feedback and session recaps.
  void recordTransition(StageTransition transition) {
    final updatedTransitions = [...state.transitions, transition];
    state = state.copyWith(transitions: updatedTransitions);
  }

  /// Clear all recorded transitions.
  ///
  /// Useful when resetting or restarting a session.
  void clearTransitions() {
    state = state.copyWith(transitions: const []);
  }

  /// Check if time has expired
  bool get isTimeExpired => state.remainingSeconds <= 0;
}
