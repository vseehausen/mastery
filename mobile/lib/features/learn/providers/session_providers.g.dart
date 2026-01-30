// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dailyTimeTargetHash() => r'0053924b0f4a5904ba70d4c07db8e16095dcd34e';

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
String _$hasCompletedTodayHash() => r'8972036d3d80f0b29f57b97bff3073d517c770b4';

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
String _$todayProgressHash() => r'f77139975925c8d3f1b2ac1843bafaed48c9a9d4';

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
String _$hasItemsToReviewHash() => r'3a3d0c5c6639762fc5ff5ad9420aef183424777f';

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
String _$activeSessionHash() => r'acd5c68b894a1be6c7161932e458ea6f82518850';

/// Provides the currently active session, if any
///
/// Copied from [activeSession].
@ProviderFor(activeSession)
final activeSessionProvider =
    AutoDisposeFutureProvider<LearningSession?>.internal(
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
typedef ActiveSessionRef = AutoDisposeFutureProviderRef<LearningSession?>;
String _$sessionPlanHash() => r'01f26fdca1682c37599a644e237940fd72957428';

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
    r'866378928f95639dea76c70619050316af7a7d12';

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
