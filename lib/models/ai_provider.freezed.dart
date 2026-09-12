// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiProvider {
  String get id; // UUID for custom providers, fixed id for built-in ones
  String get title; // Display name
  String? get logoAsset; // Asset path for built-in providers
  String get url; // API endpoint URL
  AiProtocol get protocol; // Protocol type
  bool get enabled; // Whether this provider is enabled
  bool get isBuiltin; // Whether this is a built-in provider (cannot be deleted)
  List<AiApiKey> get apiKeys; // List of API keys
  String get model; // Current selected model
  AiReasoningEffort get reasoningEffort; // OpenAI reasoning effort
  int get keyIndex; // Current round-robin key index
  DateTime? get createdAt; // Creation time
  DateTime? get updatedAt;

  /// Create a copy of AiProvider
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiProviderCopyWith<AiProvider> get copyWith =>
      _$AiProviderCopyWithImpl<AiProvider>(this as AiProvider, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiProvider &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.logoAsset, logoAsset) ||
                other.logoAsset == logoAsset) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.isBuiltin, isBuiltin) ||
                other.isBuiltin == isBuiltin) &&
            const DeepCollectionEquality().equals(other.apiKeys, apiKeys) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.reasoningEffort, reasoningEffort) ||
                other.reasoningEffort == reasoningEffort) &&
            (identical(other.keyIndex, keyIndex) ||
                other.keyIndex == keyIndex) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      logoAsset,
      url,
      protocol,
      enabled,
      isBuiltin,
      const DeepCollectionEquality().hash(apiKeys),
      model,
      reasoningEffort,
      keyIndex,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'AiProvider(id: $id, title: $title, logoAsset: $logoAsset, url: $url, protocol: $protocol, enabled: $enabled, isBuiltin: $isBuiltin, apiKeys: $apiKeys, model: $model, reasoningEffort: $reasoningEffort, keyIndex: $keyIndex, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $AiProviderCopyWith<$Res> {
  factory $AiProviderCopyWith(
          AiProvider value, $Res Function(AiProvider) _then) =
      _$AiProviderCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String title,
      String? logoAsset,
      String url,
      AiProtocol protocol,
      bool enabled,
      bool isBuiltin,
      List<AiApiKey> apiKeys,
      String model,
      AiReasoningEffort reasoningEffort,
      int keyIndex,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$AiProviderCopyWithImpl<$Res> implements $AiProviderCopyWith<$Res> {
  _$AiProviderCopyWithImpl(this._self, this._then);

  final AiProvider _self;
  final $Res Function(AiProvider) _then;

  /// Create a copy of AiProvider
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? logoAsset = freezed,
    Object? url = null,
    Object? protocol = null,
    Object? enabled = null,
    Object? isBuiltin = null,
    Object? apiKeys = null,
    Object? model = null,
    Object? reasoningEffort = null,
    Object? keyIndex = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      logoAsset: freezed == logoAsset
          ? _self.logoAsset
          : logoAsset // ignore: cast_nullable_to_non_nullable
              as String?,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      protocol: null == protocol
          ? _self.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as AiProtocol,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isBuiltin: null == isBuiltin
          ? _self.isBuiltin
          : isBuiltin // ignore: cast_nullable_to_non_nullable
              as bool,
      apiKeys: null == apiKeys
          ? _self.apiKeys
          : apiKeys // ignore: cast_nullable_to_non_nullable
              as List<AiApiKey>,
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      reasoningEffort: null == reasoningEffort
          ? _self.reasoningEffort
          : reasoningEffort // ignore: cast_nullable_to_non_nullable
              as AiReasoningEffort,
      keyIndex: null == keyIndex
          ? _self.keyIndex
          : keyIndex // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _AiProvider extends AiProvider {
  const _AiProvider(
      {required this.id,
      required this.title,
      this.logoAsset,
      required this.url,
      required this.protocol,
      this.enabled = true,
      this.isBuiltin = false,
      final List<AiApiKey> apiKeys = const [],
      this.model = '',
      this.reasoningEffort = AiReasoningEffort.auto,
      this.keyIndex = 0,
      this.createdAt,
      this.updatedAt})
      : _apiKeys = apiKeys,
        super._();

  @override
  final String id;
// UUID for custom providers, fixed id for built-in ones
  @override
  final String title;
// Display name
  @override
  final String? logoAsset;
// Asset path for built-in providers
  @override
  final String url;
// API endpoint URL
  @override
  final AiProtocol protocol;
// Protocol type
  @override
  @JsonKey()
  final bool enabled;
// Whether this provider is enabled
  @override
  @JsonKey()
  final bool isBuiltin;
// Whether this is a built-in provider (cannot be deleted)
  final List<AiApiKey> _apiKeys;
// Whether this is a built-in provider (cannot be deleted)
  @override
  @JsonKey()
  List<AiApiKey> get apiKeys {
    if (_apiKeys is EqualUnmodifiableListView) return _apiKeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_apiKeys);
  }

// List of API keys
  @override
  @JsonKey()
  final String model;
// Current selected model
  @override
  @JsonKey()
  final AiReasoningEffort reasoningEffort;
// OpenAI reasoning effort
  @override
  @JsonKey()
  final int keyIndex;
// Current round-robin key index
  @override
  final DateTime? createdAt;
// Creation time
  @override
  final DateTime? updatedAt;

  /// Create a copy of AiProvider
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiProviderCopyWith<_AiProvider> get copyWith =>
      __$AiProviderCopyWithImpl<_AiProvider>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiProvider &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.logoAsset, logoAsset) ||
                other.logoAsset == logoAsset) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.isBuiltin, isBuiltin) ||
                other.isBuiltin == isBuiltin) &&
            const DeepCollectionEquality().equals(other._apiKeys, _apiKeys) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.reasoningEffort, reasoningEffort) ||
                other.reasoningEffort == reasoningEffort) &&
            (identical(other.keyIndex, keyIndex) ||
                other.keyIndex == keyIndex) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      logoAsset,
      url,
      protocol,
      enabled,
      isBuiltin,
      const DeepCollectionEquality().hash(_apiKeys),
      model,
      reasoningEffort,
      keyIndex,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'AiProvider(id: $id, title: $title, logoAsset: $logoAsset, url: $url, protocol: $protocol, enabled: $enabled, isBuiltin: $isBuiltin, apiKeys: $apiKeys, model: $model, reasoningEffort: $reasoningEffort, keyIndex: $keyIndex, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$AiProviderCopyWith<$Res>
    implements $AiProviderCopyWith<$Res> {
  factory _$AiProviderCopyWith(
          _AiProvider value, $Res Function(_AiProvider) _then) =
      __$AiProviderCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? logoAsset,
      String url,
      AiProtocol protocol,
      bool enabled,
      bool isBuiltin,
      List<AiApiKey> apiKeys,
      String model,
      AiReasoningEffort reasoningEffort,
      int keyIndex,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$AiProviderCopyWithImpl<$Res> implements _$AiProviderCopyWith<$Res> {
  __$AiProviderCopyWithImpl(this._self, this._then);

  final _AiProvider _self;
  final $Res Function(_AiProvider) _then;

  /// Create a copy of AiProvider
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? logoAsset = freezed,
    Object? url = null,
    Object? protocol = null,
    Object? enabled = null,
    Object? isBuiltin = null,
    Object? apiKeys = null,
    Object? model = null,
    Object? reasoningEffort = null,
    Object? keyIndex = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_AiProvider(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      logoAsset: freezed == logoAsset
          ? _self.logoAsset
          : logoAsset // ignore: cast_nullable_to_non_nullable
              as String?,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      protocol: null == protocol
          ? _self.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as AiProtocol,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isBuiltin: null == isBuiltin
          ? _self.isBuiltin
          : isBuiltin // ignore: cast_nullable_to_non_nullable
              as bool,
      apiKeys: null == apiKeys
          ? _self._apiKeys
          : apiKeys // ignore: cast_nullable_to_non_nullable
              as List<AiApiKey>,
      model: null == model
          ? _self.model
          : model // ignore: cast_nullable_to_non_nullable
              as String,
      reasoningEffort: null == reasoningEffort
          ? _self.reasoningEffort
          : reasoningEffort // ignore: cast_nullable_to_non_nullable
              as AiReasoningEffort,
      keyIndex: null == keyIndex
          ? _self.keyIndex
          : keyIndex // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
mixin _$AiApiKey {
  String get id; // UUID
  String get key; // API key value
  bool get enabled; // Whether this key is enabled
  String? get label; // Optional label/note for this key
  DateTime? get createdAt;

  /// Create a copy of AiApiKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiApiKeyCopyWith<AiApiKey> get copyWith =>
      _$AiApiKeyCopyWithImpl<AiApiKey>(this as AiApiKey, _$identity);

  /// Serializes this AiApiKey to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiApiKey &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, key, enabled, label, createdAt);

  @override
  String toString() {
    return 'AiApiKey(id: $id, key: $key, enabled: $enabled, label: $label, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $AiApiKeyCopyWith<$Res> {
  factory $AiApiKeyCopyWith(AiApiKey value, $Res Function(AiApiKey) _then) =
      _$AiApiKeyCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String key,
      bool enabled,
      String? label,
      DateTime? createdAt});
}

/// @nodoc
class _$AiApiKeyCopyWithImpl<$Res> implements $AiApiKeyCopyWith<$Res> {
  _$AiApiKeyCopyWithImpl(this._self, this._then);

  final AiApiKey _self;
  final $Res Function(AiApiKey) _then;

  /// Create a copy of AiApiKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? key = null,
    Object? enabled = null,
    Object? label = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _self.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _AiApiKey extends AiApiKey {
  const _AiApiKey(
      {required this.id,
      required this.key,
      this.enabled = true,
      this.label,
      this.createdAt})
      : super._();
  factory _AiApiKey.fromJson(Map<String, dynamic> json) =>
      _$AiApiKeyFromJson(json);

  @override
  final String id;
// UUID
  @override
  final String key;
// API key value
  @override
  @JsonKey()
  final bool enabled;
// Whether this key is enabled
  @override
  final String? label;
// Optional label/note for this key
  @override
  final DateTime? createdAt;

  /// Create a copy of AiApiKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiApiKeyCopyWith<_AiApiKey> get copyWith =>
      __$AiApiKeyCopyWithImpl<_AiApiKey>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AiApiKeyToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiApiKey &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, key, enabled, label, createdAt);

  @override
  String toString() {
    return 'AiApiKey(id: $id, key: $key, enabled: $enabled, label: $label, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$AiApiKeyCopyWith<$Res>
    implements $AiApiKeyCopyWith<$Res> {
  factory _$AiApiKeyCopyWith(_AiApiKey value, $Res Function(_AiApiKey) _then) =
      __$AiApiKeyCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String key,
      bool enabled,
      String? label,
      DateTime? createdAt});
}

/// @nodoc
class __$AiApiKeyCopyWithImpl<$Res> implements _$AiApiKeyCopyWith<$Res> {
  __$AiApiKeyCopyWithImpl(this._self, this._then);

  final _AiApiKey _self;
  final $Res Function(_AiApiKey) _then;

  /// Create a copy of AiApiKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? key = null,
    Object? enabled = null,
    Object? label = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_AiApiKey(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      key: null == key
          ? _self.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
