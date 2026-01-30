// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentStreakHash() => r'edd041b18426e0767359f74fdac29df699f0829e';

/// Provides the current streak count for the logged-in user
///
/// Copied from [currentStreak].
@ProviderFor(currentStreak)
final currentStreakProvider = AutoDisposeFutureProvider<int>.internal(
  currentStreak,
  name: r'currentStreakProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentStreakRef = AutoDisposeFutureProviderRef<int>;
String _$longestStreakHash() => r'8f78edc5bf42c0cf6215e11dc56c7bf5ccceba2f';

/// Provides the longest streak count for the logged-in user
///
/// Copied from [longestStreak].
@ProviderFor(longestStreak)
final longestStreakProvider = AutoDisposeFutureProvider<int>.internal(
  longestStreak,
  name: r'longestStreakProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$longestStreakHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LongestStreakRef = AutoDisposeFutureProviderRef<int>;
String _$streakNotifierHash() => r'f89ee600a65eb453a49308bf6e02576a886a6493';

/// Notifier for updating streak
///
/// Copied from [StreakNotifier].
@ProviderFor(StreakNotifier)
final streakNotifierProvider =
    AutoDisposeAsyncNotifierProvider<StreakNotifier, int>.internal(
      StreakNotifier.new,
      name: r'streakNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$streakNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StreakNotifier = AutoDisposeAsyncNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
