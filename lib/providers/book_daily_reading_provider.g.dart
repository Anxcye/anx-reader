// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_daily_reading_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookDailyReadingHash() => r'0cbdcd3054090c296deacc28328096d18d265026';

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

abstract class _$BookDailyReading
    extends BuildlessAutoDisposeAsyncNotifier<BookDailyReadingData> {
  late final int bookId;
  late final int days;

  FutureOr<BookDailyReadingData> build({
    required int bookId,
    int days = 30,
  });
}

/// See also [BookDailyReading].
@ProviderFor(BookDailyReading)
const bookDailyReadingProvider = BookDailyReadingFamily();

/// See also [BookDailyReading].
class BookDailyReadingFamily extends Family<AsyncValue<BookDailyReadingData>> {
  /// See also [BookDailyReading].
  const BookDailyReadingFamily();

  /// See also [BookDailyReading].
  BookDailyReadingProvider call({
    required int bookId,
    int days = 30,
  }) {
    return BookDailyReadingProvider(
      bookId: bookId,
      days: days,
    );
  }

  @override
  BookDailyReadingProvider getProviderOverride(
    covariant BookDailyReadingProvider provider,
  ) {
    return call(
      bookId: provider.bookId,
      days: provider.days,
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
  String? get name => r'bookDailyReadingProvider';
}

/// See also [BookDailyReading].
class BookDailyReadingProvider extends AutoDisposeAsyncNotifierProviderImpl<
    BookDailyReading, BookDailyReadingData> {
  /// See also [BookDailyReading].
  BookDailyReadingProvider({
    required int bookId,
    int days = 30,
  }) : this._internal(
          () => BookDailyReading()
            ..bookId = bookId
            ..days = days,
          from: bookDailyReadingProvider,
          name: r'bookDailyReadingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bookDailyReadingHash,
          dependencies: BookDailyReadingFamily._dependencies,
          allTransitiveDependencies:
              BookDailyReadingFamily._allTransitiveDependencies,
          bookId: bookId,
          days: days,
        );

  BookDailyReadingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
    required this.days,
  }) : super.internal();

  final int bookId;
  final int days;

  @override
  FutureOr<BookDailyReadingData> runNotifierBuild(
    covariant BookDailyReading notifier,
  ) {
    return notifier.build(
      bookId: bookId,
      days: days,
    );
  }

  @override
  Override overrideWith(BookDailyReading Function() create) {
    return ProviderOverride(
      origin: this,
      override: BookDailyReadingProvider._internal(
        () => create()
          ..bookId = bookId
          ..days = days,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
        days: days,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<BookDailyReading,
      BookDailyReadingData> createElement() {
    return _BookDailyReadingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookDailyReadingProvider &&
        other.bookId == bookId &&
        other.days == days;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);
    hash = _SystemHash.combine(hash, days.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookDailyReadingRef
    on AutoDisposeAsyncNotifierProviderRef<BookDailyReadingData> {
  /// The parameter `bookId` of this provider.
  int get bookId;

  /// The parameter `days` of this provider.
  int get days;
}

class _BookDailyReadingProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<BookDailyReading,
        BookDailyReadingData> with BookDailyReadingRef {
  _BookDailyReadingProviderElement(super.provider);

  @override
  int get bookId => (origin as BookDailyReadingProvider).bookId;
  @override
  int get days => (origin as BookDailyReadingProvider).days;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
