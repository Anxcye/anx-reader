// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statictics_summary_value.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staticticsSummaryValueHash() =>
    r'ec3412403eb14bd16b79d862df13af72412b1756';

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

abstract class _$StaticticsSummaryValue
    extends BuildlessAutoDisposeAsyncNotifier<int> {
  late final StatisticType type;

  FutureOr<int> build(
    StatisticType type,
  );
}

/// See also [StaticticsSummaryValue].
@ProviderFor(StaticticsSummaryValue)
const staticticsSummaryValueProvider = StaticticsSummaryValueFamily();

/// See also [StaticticsSummaryValue].
class StaticticsSummaryValueFamily extends Family<AsyncValue<int>> {
  /// See also [StaticticsSummaryValue].
  const StaticticsSummaryValueFamily();

  /// See also [StaticticsSummaryValue].
  StaticticsSummaryValueProvider call(
    StatisticType type,
  ) {
    return StaticticsSummaryValueProvider(
      type,
    );
  }

  @override
  StaticticsSummaryValueProvider getProviderOverride(
    covariant StaticticsSummaryValueProvider provider,
  ) {
    return call(
      provider.type,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'staticticsSummaryValueProvider';
}

/// See also [StaticticsSummaryValue].
class StaticticsSummaryValueProvider
    extends AutoDisposeAsyncNotifierProviderImpl<StaticticsSummaryValue, int> {
  /// See also [StaticticsSummaryValue].
  StaticticsSummaryValueProvider(
    StatisticType type,
  ) : this._internal(
          () => StaticticsSummaryValue()..type = type,
          from: staticticsSummaryValueProvider,
          name: r'staticticsSummaryValueProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$staticticsSummaryValueHash,
          dependencies: StaticticsSummaryValueFamily._dependencies,
          allTransitiveDependencies:
              StaticticsSummaryValueFamily._allTransitiveDependencies,
          type: type,
        );

  StaticticsSummaryValueProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
  }) : super.internal();

  final StatisticType type;

  @override
  FutureOr<int> runNotifierBuild(
    covariant StaticticsSummaryValue notifier,
  ) {
    return notifier.build(
      type,
    );
  }

  @override
  Override overrideWith(StaticticsSummaryValue Function() create) {
    return ProviderOverride(
      origin: this,
      override: StaticticsSummaryValueProvider._internal(
        () => create()..type = type,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<StaticticsSummaryValue, int>
      createElement() {
    return _StaticticsSummaryValueProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StaticticsSummaryValueProvider && other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StaticticsSummaryValueRef on AutoDisposeAsyncNotifierProviderRef<int> {
  /// The parameter `type` of this provider.
  StatisticType get type;
}

class _StaticticsSummaryValueProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<StaticticsSummaryValue, int>
    with StaticticsSummaryValueRef {
  _StaticticsSummaryValueProviderElement(super.provider);

  @override
  StatisticType get type => (origin as StaticticsSummaryValueProvider).type;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
