// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookmarkHash() => r'77a8a821610c7e200c970626a6aa8c668779c158';

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

abstract class _$Bookmark extends BuildlessAsyncNotifier<List<BookmarkModel>> {
  late final int bookId;

  FutureOr<List<BookmarkModel>> build(
    int bookId,
  );
}

/// See also [Bookmark].
@ProviderFor(Bookmark)
const bookmarkProvider = BookmarkFamily();

/// See also [Bookmark].
class BookmarkFamily extends Family<AsyncValue<List<BookmarkModel>>> {
  /// See also [Bookmark].
  const BookmarkFamily();

  /// See also [Bookmark].
  BookmarkProvider call(
    int bookId,
  ) {
    return BookmarkProvider(
      bookId,
    );
  }

  @override
  BookmarkProvider getProviderOverride(
    covariant BookmarkProvider provider,
  ) {
    return call(
      provider.bookId,
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
  String? get name => r'bookmarkProvider';
}

/// See also [Bookmark].
class BookmarkProvider
    extends AsyncNotifierProviderImpl<Bookmark, List<BookmarkModel>> {
  /// See also [Bookmark].
  BookmarkProvider(
    int bookId,
  ) : this._internal(
          () => Bookmark()..bookId = bookId,
          from: bookmarkProvider,
          name: r'bookmarkProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookmarkHash,
          dependencies: BookmarkFamily._dependencies,
          allTransitiveDependencies: BookmarkFamily._allTransitiveDependencies,
          bookId: bookId,
        );

  BookmarkProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
  }) : super.internal();

  final int bookId;

  @override
  FutureOr<List<BookmarkModel>> runNotifierBuild(
    covariant Bookmark notifier,
  ) {
    return notifier.build(
      bookId,
    );
  }

  @override
  Override overrideWith(Bookmark Function() create) {
    return ProviderOverride(
      origin: this,
      override: BookmarkProvider._internal(
        () => create()..bookId = bookId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<Bookmark, List<BookmarkModel>> createElement() {
    return _BookmarkProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookmarkProvider && other.bookId == bookId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookmarkRef on AsyncNotifierProviderRef<List<BookmarkModel>> {
  /// The parameter `bookId` of this provider.
  int get bookId;
}

class _BookmarkProviderElement
    extends AsyncNotifierProviderElement<Bookmark, List<BookmarkModel>>
    with BookmarkRef {
  _BookmarkProviderElement(super.provider);

  @override
  int get bookId => (origin as BookmarkProvider).bookId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
