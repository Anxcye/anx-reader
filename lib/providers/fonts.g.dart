// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fonts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LicenseModel _$LicenseModelFromJson(Map<String, dynamic> json) =>
    _LicenseModel(
      name: json['name'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$LicenseModelToJson(_LicenseModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
    };

_RemoteFontModel _$RemoteFontModelFromJson(Map<String, dynamic> json) =>
    _RemoteFontModel(
      id: json['id'] as String,
      name: json['name'] as String,
      files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
      size: (json['size'] as num).toInt(),
      preview: json['preview'] as String,
      desc: json['desc'] as String,
      official: json['official'] as String,
      license: LicenseModel.fromJson(json['license'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RemoteFontModelToJson(_RemoteFontModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'files': instance.files,
      'size': instance.size,
      'preview': instance.preview,
      'desc': instance.desc,
      'official': instance.official,
      'license': instance.license,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fontsHash() => r'3ec7a6e230ef8c4c793d142276822e7f1416663c';

/// See also [Fonts].
@ProviderFor(Fonts)
final fontsProvider =
    AsyncNotifierProvider<Fonts, List<RemoteFontModel>>.internal(
  Fonts.new,
  name: r'fontsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fontsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Fonts = AsyncNotifier<List<RemoteFontModel>>;
String _$fontDownloadsHash() => r'd051febd2b5ce09a3479234e9e1fcef844d13d1d';

/// See also [FontDownloads].
@ProviderFor(FontDownloads)
final fontDownloadsProvider =
    NotifierProvider<FontDownloads, Map<String, FontDownloadState>>.internal(
  FontDownloads.new,
  name: r'fontDownloadsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fontDownloadsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FontDownloads = Notifier<Map<String, FontDownloadState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
