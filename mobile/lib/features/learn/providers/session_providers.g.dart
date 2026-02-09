// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dailyTimeTargetHash() => r'3fce2340076b90bae539fd3a4c7225334504dbc8';

/// Provides the user's daily time target in minutes
///
/// Copied from [dailyTimeTarget].
@ProviderFor(dailyTimeTarget)
final dailyTimeTargetProvider = AutoDisposeFutureProvider<int>.internal(
  dailyTimeTarget,
  name: r'dailyTimeTargetProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dailyTimeTargetHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DailyTimeTargetRef = AutoDisposeFutureProviderRef<int>;
String _$hasCompletedTodayHash() => r'33ff5036d6d4b3bf7e88f3ee354b3f7474624317';

/// Provides whether user has completed their session today
///
/// Copied from [hasCompletedToday].
@ProviderFor(hasCompletedToday)
final hasCompletedTodayProvider = AutoDisposeFutureProvider<bool>.internal(
  hasCompletedToday,
  name: r'hasCompletedTodayProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasCompletedTodayHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasCompletedTodayRef = AutoDisposeFutureProviderRef<bool>;
String _$todayProgressHash() => r'1efef7286383b0a6cda5e950a8faa5fdd10a80a2';

/// Provides today's progress (0.0 to 1.0)
///
/// Copied from [todayProgress].
@ProviderFor(todayProgress)
final todayProgressProvider = AutoDisposeFutureProvider<double>.internal(
  todayProgress,
  name: r'todayProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todayProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodayProgressRef = AutoDisposeFutureProviderRef<double>;
String _$hasItemsToReviewHash() => r'c3becbe6a47f60d41902bf505915a55ff87138bd';

/// Provides whether there are items available to review
///
/// Copied from [hasItemsToReview].
@ProviderFor(hasItemsToReview)
final hasItemsToReviewProvider = AutoDisposeFutureProvider<bool>.internal(
  hasItemsToReview,
  name: r'hasItemsToReviewProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasItemsToReviewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasItemsToReviewRef = AutoDisposeFutureProviderRef<bool>;
String _$dueItemCountHash() => r'da95732caa0fbc0b3d8942fa23836e097c6b3240';

/// Provides the count of items available for review (due + new cards)
///
/// Copied from [dueItemCount].
@ProviderFor(dueItemCount)
final dueItemCountProvider = AutoDisposeFutureProvider<int>.internal(
  dueItemCount,
  name: r'dueItemCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dueItemCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DueItemCountRef = AutoDisposeFutureProviderRef<int>;
String _$todaySessionStatsHash() => r'a6595556aa18e7b95d98b9a54ef38665fac1207f';

/// Provides today's session stats (items reviewed + accuracy)
///
/// Copied from [todaySessionStats].
@ProviderFor(todaySessionStats)
final todaySessionStatsProvider =
    AutoDisposeFutureProvider<
      ({int itemsReviewed, double? accuracyPercent})?
    >.internal(
      todaySessionStats,
      name: r'todaySessionStatsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$todaySessionStatsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodaySessionStatsRef =
    AutoDisposeFutureProviderRef<
      ({int itemsReviewed, double? accuracyPercent})?
    >;
String _$nextReviewLabelHash() => r'a7881cee9b550dd6c552dc39c2462e5e4f9d4b2a';

/// Provides the label for next review time (e.g. "Next review in 3 days")
///
/// Copied from [nextReviewLabel].
@ProviderFor(nextReviewLabel)
final nextReviewLabelProvider = AutoDisposeFutureProvider<String?>.internal(
  nextReviewLabel,
  name: r'nextReviewLabelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nextReviewLabelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NextReviewLabelRef = AutoDisposeFutureProviderRef<String?>;
String _$activeSessionHash() => r'9a67a4fc6f7b0026ac1b8372a03874cc33dbacea';

/// Provides the currently active session, if any
///
/// Copied from [activeSession].
@ProviderFor(activeSession)
final activeSessionProvider =
    AutoDisposeFutureProvider<LearningSessionModel?>.internal(
      activeSession,
      name: r'activeSessionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeSessionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveSessionRef = AutoDisposeFutureProviderRef<LearningSessionModel?>;
String _$sessionPlanHash() => r'12462dce13e700b129eade50f138f0be519514a7';

/// Provides the session plan for the current/new session
///
/// Copied from [sessionPlan].
@ProviderFor(sessionPlan)
final sessionPlanProvider = AutoDisposeFutureProvider<SessionPlan?>.internal(
  sessionPlan,
  name: r'sessionPlanProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionPlanHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SessionPlanRef = AutoDisposeFutureProviderRef<SessionPlan?>;
String _$activeSessionNotifierHash() =>
    r'7c10215b9a1ac70f33302ecc4bedb41632a01ee6';

/// Notifier for managing active session state
///
/// Copied from [ActiveSessionNotifier].
@ProviderFor(ActiveSessionNotifier)
final activeSessionNotifierProvider =
    AutoDisposeNotifierProvider<
      ActiveSessionNotifier,
      ActiveSessionState
    >.internal(
      ActiveSessionNotifier.new,
      name: r'activeSessionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeSessionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveSessionNotifier = AutoDisposeNotifier<ActiveSessionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
