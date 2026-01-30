// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$learningCardRepositoryHash() =>
    r'44c6cf9ecf76e35762f5965be3e19a86d1df352e';

/// See also [learningCardRepository].
@ProviderFor(learningCardRepository)
final learningCardRepositoryProvider =
    Provider<LearningCardRepository>.internal(
      learningCardRepository,
      name: r'learningCardRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$learningCardRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LearningCardRepositoryRef = ProviderRef<LearningCardRepository>;
String _$reviewLogRepositoryHash() =>
    r'36f441d272cb041c72ec7cfcd6dbe3eed7fabc70';

/// See also [reviewLogRepository].
@ProviderFor(reviewLogRepository)
final reviewLogRepositoryProvider = Provider<ReviewLogRepository>.internal(
  reviewLogRepository,
  name: r'reviewLogRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewLogRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReviewLogRepositoryRef = ProviderRef<ReviewLogRepository>;
String _$sessionRepositoryHash() => r'770c9ad799030c5b4d08961948ab98eeeb5451ee';

/// See also [sessionRepository].
@ProviderFor(sessionRepository)
final sessionRepositoryProvider = Provider<SessionRepository>.internal(
  sessionRepository,
  name: r'sessionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SessionRepositoryRef = ProviderRef<SessionRepository>;
String _$streakRepositoryHash() => r'111cb1618b5ee872f42d6925c7b8293d9c59aee8';

/// See also [streakRepository].
@ProviderFor(streakRepository)
final streakRepositoryProvider = Provider<StreakRepository>.internal(
  streakRepository,
  name: r'streakRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$streakRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StreakRepositoryRef = ProviderRef<StreakRepository>;
String _$userPreferencesRepositoryHash() =>
    r'26c56abcd5503c515e97c7dd89cc82b97b32fa85';

/// See also [userPreferencesRepository].
@ProviderFor(userPreferencesRepository)
final userPreferencesRepositoryProvider =
    Provider<UserPreferencesRepository>.internal(
      userPreferencesRepository,
      name: r'userPreferencesRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userPreferencesRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserPreferencesRepositoryRef = ProviderRef<UserPreferencesRepository>;
String _$srsSchedulerHash() => r'18ab2bfad219da17987466dde001336ccd82432c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [srsScheduler].
@ProviderFor(srsScheduler)
const srsSchedulerProvider = SrsSchedulerFamily();

/// See also [srsScheduler].
class SrsSchedulerFamily extends Family<SrsScheduler> {
  /// See also [srsScheduler].
  const SrsSchedulerFamily();

  /// See also [srsScheduler].
  SrsSchedulerProvider call({double targetRetention = 0.90}) {
    return SrsSchedulerProvider(targetRetention: targetRetention);
  }

  @override
  SrsSchedulerProvider getProviderOverride(
    covariant SrsSchedulerProvider provider,
  ) {
    return call(targetRetention: provider.targetRetention);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'srsSchedulerProvider';
}

/// See also [srsScheduler].
class SrsSchedulerProvider extends AutoDisposeProvider<SrsScheduler> {
  /// See also [srsScheduler].
  SrsSchedulerProvider({double targetRetention = 0.90})
    : this._internal(
        (ref) => srsScheduler(
          ref as SrsSchedulerRef,
          targetRetention: targetRetention,
        ),
        from: srsSchedulerProvider,
        name: r'srsSchedulerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$srsSchedulerHash,
        dependencies: SrsSchedulerFamily._dependencies,
        allTransitiveDependencies:
            SrsSchedulerFamily._allTransitiveDependencies,
        targetRetention: targetRetention,
      );

  SrsSchedulerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.targetRetention,
  }) : super.internal();

  final double targetRetention;

  @override
  Override overrideWith(
    SrsScheduler Function(SrsSchedulerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SrsSchedulerProvider._internal(
        (ref) => create(ref as SrsSchedulerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        targetRetention: targetRetention,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<SrsScheduler> createElement() {
    return _SrsSchedulerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SrsSchedulerProvider &&
        other.targetRetention == targetRetention;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, targetRetention.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SrsSchedulerRef on AutoDisposeProviderRef<SrsScheduler> {
  /// The parameter `targetRetention` of this provider.
  double get targetRetention;
}

class _SrsSchedulerProviderElement
    extends AutoDisposeProviderElement<SrsScheduler>
    with SrsSchedulerRef {
  _SrsSchedulerProviderElement(super.provider);

  @override
  double get targetRetention =>
      (origin as SrsSchedulerProvider).targetRetention;
}

String _$telemetryServiceHash() => r'4465779f0c89ee233356d8ec9b9a4d2b2e9f9b02';

/// See also [telemetryService].
@ProviderFor(telemetryService)
final telemetryServiceProvider = Provider<TelemetryService>.internal(
  telemetryService,
  name: r'telemetryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$telemetryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TelemetryServiceRef = ProviderRef<TelemetryService>;
String _$sessionPlannerHash() => r'c45700eda1697010cb96761ba2e77240a7588765';

/// See also [sessionPlanner].
@ProviderFor(sessionPlanner)
final sessionPlannerProvider = Provider<SessionPlanner>.internal(
  sessionPlanner,
  name: r'sessionPlannerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionPlannerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SessionPlannerRef = ProviderRef<SessionPlanner>;
String _$distractorServiceHash() => r'ad1ab42ba55d51c276aa12fe93f28709aab8fc23';

/// See also [distractorService].
@ProviderFor(distractorService)
final distractorServiceProvider = Provider<DistractorService>.internal(
  distractorService,
  name: r'distractorServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$distractorServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DistractorServiceRef = ProviderRef<DistractorService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
