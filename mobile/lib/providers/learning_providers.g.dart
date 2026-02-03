// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

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

String _$telemetryServiceHash() => r'2a8df2ee4fa895b4010ae3af77b0e96deed5b100';

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
String _$sessionPlannerHash() => r'fedfc24525478a1aab28b83909f4cd5b42be5022';

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
String _$distractorServiceHash() => r'f1f2b9c0af8aa246d2734d5f68b7c06059f82b47';

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
String _$enrichmentServiceHash() => r'729d9488d8f52e7ccfdcc72a40418ab1a40ca421';

/// See also [enrichmentService].
@ProviderFor(enrichmentService)
final enrichmentServiceProvider = Provider<EnrichmentService>.internal(
  enrichmentService,
  name: r'enrichmentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$enrichmentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EnrichmentServiceRef = ProviderRef<EnrichmentService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
