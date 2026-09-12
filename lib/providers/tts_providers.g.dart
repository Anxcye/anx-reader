// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ttsVoicesHash() => r'effbc1f54d001f4709bd07665b7863a27b2db49d';

/// See also [ttsVoices].
@ProviderFor(ttsVoices)
final ttsVoicesProvider = AutoDisposeFutureProvider<List<TtsVoice>>.internal(
  ttsVoices,
  name: r'ttsVoicesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$ttsVoicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TtsVoicesRef = AutoDisposeFutureProviderRef<List<TtsVoice>>;
String _$ttsServiceHash() => r'a1191307165023818d86cbc7a98c6d9d79fc65a2';

/// See also [TtsService].
@ProviderFor(TtsService)
final ttsServiceProvider =
    AutoDisposeNotifierProvider<TtsService, String>.internal(
  TtsService.new,
  name: r'ttsServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$ttsServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TtsService = AutoDisposeNotifier<String>;
String _$onlineTtsConfigHash() => r'63890f4d67e985d9231fe74d00a66cfe893d8e73';

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

abstract class _$OnlineTtsConfig
    extends BuildlessAutoDisposeNotifier<Map<String, dynamic>> {
  late final String serviceId;

  Map<String, dynamic> build(
    String serviceId,
  );
}

/// See also [OnlineTtsConfig].
@ProviderFor(OnlineTtsConfig)
const onlineTtsConfigProvider = OnlineTtsConfigFamily();

/// See also [OnlineTtsConfig].
class OnlineTtsConfigFamily extends Family<Map<String, dynamic>> {
  /// See also [OnlineTtsConfig].
  const OnlineTtsConfigFamily();

  /// See also [OnlineTtsConfig].
  OnlineTtsConfigProvider call(
    String serviceId,
  ) {
    return OnlineTtsConfigProvider(
      serviceId,
    );
  }

  @override
  OnlineTtsConfigProvider getProviderOverride(
    covariant OnlineTtsConfigProvider provider,
  ) {
    return call(
      provider.serviceId,
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
  String? get name => r'onlineTtsConfigProvider';
}

/// See also [OnlineTtsConfig].
class OnlineTtsConfigProvider extends AutoDisposeNotifierProviderImpl<
    OnlineTtsConfig, Map<String, dynamic>> {
  /// See also [OnlineTtsConfig].
  OnlineTtsConfigProvider(
    String serviceId,
  ) : this._internal(
          () => OnlineTtsConfig()..serviceId = serviceId,
          from: onlineTtsConfigProvider,
          name: r'onlineTtsConfigProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$onlineTtsConfigHash,
          dependencies: OnlineTtsConfigFamily._dependencies,
          allTransitiveDependencies:
              OnlineTtsConfigFamily._allTransitiveDependencies,
          serviceId: serviceId,
        );

  OnlineTtsConfigProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.serviceId,
  }) : super.internal();

  final String serviceId;

  @override
  Map<String, dynamic> runNotifierBuild(
    covariant OnlineTtsConfig notifier,
  ) {
    return notifier.build(
      serviceId,
    );
  }

  @override
  Override overrideWith(OnlineTtsConfig Function() create) {
    return ProviderOverride(
      origin: this,
      override: OnlineTtsConfigProvider._internal(
        () => create()..serviceId = serviceId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        serviceId: serviceId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<OnlineTtsConfig, Map<String, dynamic>>
      createElement() {
    return _OnlineTtsConfigProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OnlineTtsConfigProvider && other.serviceId == serviceId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, serviceId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OnlineTtsConfigRef
    on AutoDisposeNotifierProviderRef<Map<String, dynamic>> {
  /// The parameter `serviceId` of this provider.
  String get serviceId;
}

class _OnlineTtsConfigProviderElement
    extends AutoDisposeNotifierProviderElement<OnlineTtsConfig,
        Map<String, dynamic>> with OnlineTtsConfigRef {
  _OnlineTtsConfigProviderElement(super.provider);

  @override
  String get serviceId => (origin as OnlineTtsConfigProvider).serviceId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
