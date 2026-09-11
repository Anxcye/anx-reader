/// Generic paginated response.
///
/// Used by the [Paginator] to handle different types of paginated responses.
class PaginatedResponse<T> {
  /// The items in this page.
  final List<T> items;

  /// Token for fetching the next page, or null if this is the last page.
  final String? nextPageToken;

  /// Creates a [PaginatedResponse].
  const PaginatedResponse({required this.items, this.nextPageToken});
}

/// Helper for paginated API responses.
///
/// Automatically handles page tokens and yields all results from a paginated
/// API endpoint.
///
/// Example:
/// ```dart
/// final paginator = Paginator<Model>(
///   fetcher: (pageToken) async {
///     final response = await client.listModels(pageToken: pageToken);
///     return PaginatedResponse(
///       items: response.models,
///       nextPageToken: response.nextPageToken,
///     );
///   },
/// );
///
/// // Iterate through all items across all pages
/// await for (final model in paginator.items()) {
///   print(model.displayName);
/// }
/// ```
class Paginator<T> {
  /// Function to fetch a page of results given a page token.
  final Future<PaginatedResponse<T>> Function(String? pageToken) fetcher;

  /// Creates a [Paginator].
  const Paginator({required this.fetcher});

  /// Stream of all pages.
  ///
  /// Each emission contains a full page of items as a list.
  Stream<List<T>> pages() async* {
    String? pageToken;
    do {
      final response = await fetcher(pageToken);
      yield response.items;
      pageToken = response.nextPageToken;
    } while (pageToken != null);
  }

  /// Stream of all individual items.
  ///
  /// Flattens all pages into a single stream of items. This is more
  /// convenient than [pages] when you want to process items one by one.
  Stream<T> items() async* {
    await for (final page in pages()) {
      for (final item in page) {
        yield item;
      }
    }
  }
}
