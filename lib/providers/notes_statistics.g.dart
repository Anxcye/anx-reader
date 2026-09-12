// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_statistics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesStatisticsHash() => r'ce7e3302bca01d6d95ff59b77ee93f79fa3bb86a';

/// See also [NotesStatistics].
@ProviderFor(NotesStatistics)
final notesStatisticsProvider = AutoDisposeAsyncNotifierProvider<
    NotesStatistics, Map<String, int>>.internal(
  NotesStatistics.new,
  name: r'notesStatisticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notesStatisticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotesStatistics = AutoDisposeAsyncNotifier<Map<String, int>>;
String _$bookIdAndNotesHash() => r'cc12bbc2395860350fecc4c3b9d92af976a69dbc';

/// See also [BookIdAndNotes].
@ProviderFor(BookIdAndNotes)
final bookIdAndNotesProvider = AutoDisposeAsyncNotifierProvider<BookIdAndNotes,
    List<Map<String, dynamic>>>.internal(
  BookIdAndNotes.new,
  name: r'bookIdAndNotesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bookIdAndNotesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BookIdAndNotes = AutoDisposeAsyncNotifier<List<Map<String, dynamic>>>;
String _$bookReadingTimeHash() => r'a6665ce9b9a5565734e70cc11b5ef236d2deab19';

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

abstract class _$BookReadingTime
    extends BuildlessAutoDisposeAsyncNotifier<int> {
  late final int bookId;

  FutureOr<int> build(
    int bookId,
  );
}

/// See also [BookReadingTime].
@ProviderFor(BookReadingTime)
const bookReadingTimeProvider = BookReadingTimeFamily();

/// See also [BookReadingTime].
class BookReadingTimeFamily extends Family<AsyncValue<int>> {
  /// See also [BookReadingTime].
  const BookReadingTimeFamily();

  /// See also [BookReadingTime].
  BookReadingTimeProvider call(
    int bookId,
  ) {
    return BookReadingTimeProvider(
      bookId,
    );
  }

  @override
  BookReadingTimeProvider getProviderOverride(
    covariant BookReadingTimeProvider provider,
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
  String? get name => r'bookReadingTimeProvider';
}

/// See also [BookReadingTime].
class BookReadingTimeProvider
    extends AutoDisposeAsyncNotifierProviderImpl<BookReadingTime, int> {
  /// See also [BookReadingTime].
  BookReadingTimeProvider(
    int bookId,
  ) : this._internal(
          () => BookReadingTime()..bookId = bookId,
          from: bookReadingTimeProvider,
          name: r'bookReadingTimeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookReadingTimeHash,
          dependencies: BookReadingTimeFamily._dependencies,
          allTransitiveDependencies:
              BookReadingTimeFamily._allTransitiveDependencies,
          bookId: bookId,
        );

  BookReadingTimeProvider._internal(
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
  FutureOr<int> runNotifierBuild(
    covariant BookReadingTime notifier,
  ) {
    return notifier.build(
      bookId,
    );
  }

  @override
  Override overrideWith(BookReadingTime Function() create) {
    return ProviderOverride(
      origin: this,
      override: BookReadingTimeProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<BookReadingTime, int>
      createElement() {
    return _BookReadingTimeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookReadingTimeProvider && other.bookId == bookId;
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
mixin BookReadingTimeRef on AutoDisposeAsyncNotifierProviderRef<int> {
  /// The parameter `bookId` of this provider.
  int get bookId;
}

class _BookReadingTimeProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BookReadingTime, int>
    with BookReadingTimeRef {
  _BookReadingTimeProviderElement(super.provider);

  @override
  int get bookId => (origin as BookReadingTimeProvider).bookId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
