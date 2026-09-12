// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_notes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookNotesControllerHash() =>
    r'f883d5415be769a5c741f3f6fb36ba2341e3eefd';

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

abstract class _$BookNotesController
    extends BuildlessAutoDisposeAsyncNotifier<BookNotesState> {
  late final Book book;

  FutureOr<BookNotesState> build(
    Book book,
  );
}

/// See also [BookNotesController].
@ProviderFor(BookNotesController)
const bookNotesControllerProvider = BookNotesControllerFamily();

/// See also [BookNotesController].
class BookNotesControllerFamily extends Family<AsyncValue<BookNotesState>> {
  /// See also [BookNotesController].
  const BookNotesControllerFamily();

  /// See also [BookNotesController].
  BookNotesControllerProvider call(
    Book book,
  ) {
    return BookNotesControllerProvider(
      book,
    );
  }

  @override
  BookNotesControllerProvider getProviderOverride(
    covariant BookNotesControllerProvider provider,
  ) {
    return call(
      provider.book,
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
  String? get name => r'bookNotesControllerProvider';
}

/// See also [BookNotesController].
class BookNotesControllerProvider extends AutoDisposeAsyncNotifierProviderImpl<
    BookNotesController, BookNotesState> {
  /// See also [BookNotesController].
  BookNotesControllerProvider(
    Book book,
  ) : this._internal(
          () => BookNotesController()..book = book,
          from: bookNotesControllerProvider,
          name: r'bookNotesControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookNotesControllerHash,
          dependencies: BookNotesControllerFamily._dependencies,
          allTransitiveDependencies:
              BookNotesControllerFamily._allTransitiveDependencies,
          book: book,
        );

  BookNotesControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.book,
  }) : super.internal();

  final Book book;

  @override
  FutureOr<BookNotesState> runNotifierBuild(
    covariant BookNotesController notifier,
  ) {
    return notifier.build(
      book,
    );
  }

  @override
  Override overrideWith(BookNotesController Function() create) {
    return ProviderOverride(
      origin: this,
      override: BookNotesControllerProvider._internal(
        () => create()..book = book,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        book: book,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<BookNotesController, BookNotesState>
      createElement() {
    return _BookNotesControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookNotesControllerProvider && other.book == book;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, book.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookNotesControllerRef
    on AutoDisposeAsyncNotifierProviderRef<BookNotesState> {
  /// The parameter `book` of this provider.
  Book get book;
}

class _BookNotesControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BookNotesController,
        BookNotesState> with BookNotesControllerRef {
  _BookNotesControllerProviderElement(super.provider);

  @override
  Book get book => (origin as BookNotesControllerProvider).book;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
