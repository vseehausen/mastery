// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_preferences_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userLearningPreferencesHash() =>
    r'b2ba6de129c7f3ae27170a833f75f95711d2c9b9';

/// Provides the user's learning preferences
///
/// Copied from [userLearningPreferences].
@ProviderFor(userLearningPreferences)
final userLearningPreferencesProvider =
    AutoDisposeFutureProvider<UserPreferencesModel?>.internal(
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
    AutoDisposeFutureProviderRef<UserPreferencesModel?>;
String _$learningPreferencesNotifierHash() =>
    r'14e26ea58287cb3e35ea35e4279060de89a1e3b5';

/// Notifier for managing user learning preferences
///
/// Copied from [LearningPreferencesNotifier].
@ProviderFor(LearningPreferencesNotifier)
final learningPreferencesNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      LearningPreferencesNotifier,
      UserPreferencesModel?
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
    AutoDisposeAsyncNotifier<UserPreferencesModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
