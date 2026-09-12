// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tagListHash() => r'0257b4cb5da659c20ae499cec5b8a0feb9e622b7';

/// See also [TagList].
@ProviderFor(TagList)
final tagListProvider =
    AutoDisposeAsyncNotifierProvider<TagList, List<Tag>>.internal(
  TagList.new,
  name: r'tagListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tagListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TagList = AutoDisposeAsyncNotifier<List<Tag>>;
String _$bookTagEditorHash() => r'7973cda7df2c5261387006cb563c93fc0e4f13a7';

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

abstract class _$BookTagEditor
    extends BuildlessAutoDisposeAsyncNotifier<BookTagState> {
  late final int bookId;

  FutureOr<BookTagState> build(
    int bookId,
  );
}

/// See also [BookTagEditor].
@ProviderFor(BookTagEditor)
const bookTagEditorProvider = BookTagEditorFamily();

/// See also [BookTagEditor].
class BookTagEditorFamily extends Family<AsyncValue<BookTagState>> {
  /// See also [BookTagEditor].
  const BookTagEditorFamily();

  /// See also [BookTagEditor].
  BookTagEditorProvider call(
    int bookId,
  ) {
    return BookTagEditorProvider(
      bookId,
    );
  }

  @override
  BookTagEditorProvider getProviderOverride(
    covariant BookTagEditorProvider provider,
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
  String? get name => r'bookTagEditorProvider';
}

/// See also [BookTagEditor].
class BookTagEditorProvider
    extends AutoDisposeAsyncNotifierProviderImpl<BookTagEditor, BookTagState> {
  /// See also [BookTagEditor].
  BookTagEditorProvider(
    int bookId,
  ) : this._internal(
          () => BookTagEditor()..bookId = bookId,
          from: bookTagEditorProvider,
          name: r'bookTagEditorProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookTagEditorHash,
          dependencies: BookTagEditorFamily._dependencies,
          allTransitiveDependencies:
              BookTagEditorFamily._allTransitiveDependencies,
          bookId: bookId,
        );

  BookTagEditorProvider._internal(
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
  FutureOr<BookTagState> runNotifierBuild(
    covariant BookTagEditor notifier,
  ) {
    return notifier.build(
      bookId,
    );
  }

  @override
  Override overrideWith(BookTagEditor Function() create) {
    return ProviderOverride(
      origin: this,
      override: BookTagEditorProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<BookTagEditor, BookTagState>
      createElement() {
    return _BookTagEditorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookTagEditorProvider && other.bookId == bookId;
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
mixin BookTagEditorRef on AutoDisposeAsyncNotifierProviderRef<BookTagState> {
  /// The parameter `bookId` of this provider.
  int get bookId;
}

class _BookTagEditorProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BookTagEditor, BookTagState>
    with BookTagEditorRef {
  _BookTagEditorProviderElement(super.provider);

  @override
  int get bookId => (origin as BookTagEditorProvider).bookId;
}

String _$tagSelectionHash() => r'b2f81b262db26fb9743c2402e6e677379f030cc3';

/// See also [TagSelection].
@ProviderFor(TagSelection)
final tagSelectionProvider =
    AutoDisposeNotifierProvider<TagSelection, Set<int>>.internal(
  TagSelection.new,
  name: r'tagSelectionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$tagSelectionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TagSelection = AutoDisposeNotifier<Set<int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
