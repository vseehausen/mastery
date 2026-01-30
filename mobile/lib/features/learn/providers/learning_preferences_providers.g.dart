// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_preferences_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userLearningPreferencesHash() =>
    r'63460c57ab722ee48cff55ab2cd73e5d4b72682b';

/// Provides the user's learning preferences
///
/// Copied from [userLearningPreferences].
@ProviderFor(userLearningPreferences)
final userLearningPreferencesProvider =
    AutoDisposeFutureProvider<UserLearningPreference?>.internal(
      userLearningPreferences,
      name: r'userLearningPreferencesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userLearningPreferencesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserLearningPreferencesRef =
    AutoDisposeFutureProviderRef<UserLearningPreference?>;
String _$learningPreferencesNotifierHash() =>
    r'137888523258e2b89d7dbd30162926e25b1d5523';

/// Notifier for managing user learning preferences
///
/// Copied from [LearningPreferencesNotifier].
@ProviderFor(LearningPreferencesNotifier)
final learningPreferencesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      LearningPreferencesNotifier,
      UserLearningPreference?
    >.internal(
      LearningPreferencesNotifier.new,
      name: r'learningPreferencesNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$learningPreferencesNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LearningPreferencesNotifier =
    AutoDisposeAsyncNotifier<UserLearningPreference?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
