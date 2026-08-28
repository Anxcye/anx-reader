import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/reading_note/reading_note_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReadingNoteCollection {
  recent,
  allBooks,
  inbox,
  questions,
  activeReading,
  favorites,
  tag,
  trash,
}

enum ReadingNoteBookView { timeline, chapters, topics, outcomes }

class ReadingNoteWorkspaceState {
  const ReadingNoteWorkspaceState({
    this.items = const [],
    this.books = const [],
    this.tags = const [],
    this.collection = ReadingNoteCollection.recent,
    this.bookView = ReadingNoteBookView.timeline,
    this.search = '',
    this.bookId,
    this.tagId,
    this.selectedIdentity,
  });

  final List<ReadingNoteListItem> items;
  final List<Book> books;
  final List<ReadingNoteTag> tags;
  final ReadingNoteCollection collection;
  final ReadingNoteBookView bookView;
  final String search;
  final int? bookId;
  final String? tagId;
  final String? selectedIdentity;

  ReadingNoteListItem? get selected =>
      items.where((item) => item.identity == selectedIdentity).firstOrNull;

  ReadingNoteWorkspaceState copyWith({
    List<ReadingNoteListItem>? items,
    List<Book>? books,
    List<ReadingNoteTag>? tags,
    ReadingNoteCollection? collection,
    ReadingNoteBookView? bookView,
    String? search,
    int? bookId,
    bool clearBook = false,
    String? tagId,
    bool clearTag = false,
    String? selectedIdentity,
    bool clearSelection = false,
  }) =>
      ReadingNoteWorkspaceState(
        items: items ?? this.items,
        books: books ?? this.books,
        tags: tags ?? this.tags,
        collection: collection ?? this.collection,
        bookView: bookView ?? this.bookView,
        search: search ?? this.search,
        bookId: clearBook ? null : bookId ?? this.bookId,
        tagId: clearTag ? null : tagId ?? this.tagId,
        selectedIdentity:
            clearSelection ? null : selectedIdentity ?? this.selectedIdentity,
      );
}

final readingNoteRepositoryProvider =
    Provider<ReadingNoteRepository>((_) => ReadingNoteRepository());

final readingNoteWorkspaceProvider = AsyncNotifierProvider<
    ReadingNoteWorkspaceController,
    ReadingNoteWorkspaceState>(ReadingNoteWorkspaceController.new);

class ReadingNoteWorkspaceController
    extends AsyncNotifier<ReadingNoteWorkspaceState> {
  late final ReadingNoteRepository _repository;

  @override
  Future<ReadingNoteWorkspaceState> build() async {
    _repository = ref.read(readingNoteRepositoryProvider);
    return _load(const ReadingNoteWorkspaceState());
  }

  Future<ReadingNoteWorkspaceState> _load(
      ReadingNoteWorkspaceState current) async {
    final query = ReadingNoteQuery(
      bookId: current.bookId,
      search: current.search,
      status: switch (current.collection) {
        ReadingNoteCollection.inbox => ReadingNoteStatus.inbox,
        ReadingNoteCollection.trash => ReadingNoteStatus.trashed,
        _ => null,
      },
      captureKind: current.collection == ReadingNoteCollection.questions
          ? ReadingNoteCaptureKind.question
          : null,
      tagId: current.collection == ReadingNoteCollection.tag
          ? current.tagId
          : null,
      activeReadingOnly:
          current.collection == ReadingNoteCollection.activeReading,
      favoritesOnly: current.collection == ReadingNoteCollection.favorites,
    );
    final values = await Future.wait(
        [_repository.list(query), _repository.tags(), _repository.books()]);
    final items = values[0] as List<ReadingNoteListItem>;
    final selectedStillExists =
        items.any((item) => item.identity == current.selectedIdentity);
    return current.copyWith(
      items: items,
      tags: values[1] as List<ReadingNoteTag>,
      books: values[2] as List<Book>,
      clearSelection: !selectedStillExists,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const ReadingNoteWorkspaceState();
    state = AsyncValue.data(await _load(current));
  }

  Future<void> setCollection(ReadingNoteCollection collection,
      {String? tagId}) async {
    final current = state.valueOrNull ?? const ReadingNoteWorkspaceState();
    final next = current.copyWith(
      collection: collection,
      tagId: tagId,
      clearTag: collection != ReadingNoteCollection.tag,
      clearSelection: true,
    );
    state = AsyncValue.data(await _load(next));
  }

  Future<void> setBook(int? bookId) async {
    final current = state.valueOrNull ?? const ReadingNoteWorkspaceState();
    final next = current.copyWith(
      bookId: bookId,
      clearBook: bookId == null,
      clearSelection: true,
    );
    state = AsyncValue.data(await _load(next));
  }

  Future<void> setSearch(String value) async {
    final current = state.valueOrNull ?? const ReadingNoteWorkspaceState();
    state = AsyncValue.data(await _load(current.copyWith(search: value)));
  }

  void setBookView(ReadingNoteBookView value) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(bookView: value));
    }
  }

  void select(String? identity) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(
      selectedIdentity: identity,
      clearSelection: identity == null,
    ));
  }

  Future<ReadingNoteDocument> ensureDocument(ReadingNoteListItem item) async {
    if (item.document != null) {
      return item.document!;
    }
    final document = await _repository.mapLegacy(item.legacyAnnotation!);
    await refresh();
    select(document.note.id);
    return document;
  }

  Future<ReadingNoteDocument> save({
    required ReadingNoteDocument document,
    required String title,
    required String body,
    required ReadingNoteStatus status,
    required bool favorite,
    required List<String> tags,
    bool recordRevision = false,
  }) async {
    final saved = await _repository.save(
      currentDocument: document,
      title: title,
      body: body,
      status: status,
      favorite: favorite,
      tagNames: tags,
      recordRevision: recordRevision,
    );
    await refresh();
    select(saved.note.id);
    return saved;
  }

  Future<void> trash(ReadingNote note) async {
    await _repository.trash(note);
    await refresh();
  }

  Future<void> restore(ReadingNote note) async {
    await _repository.restore(note);
    await refresh();
  }

  Future<void> deletePermanently(String id) async {
    await _repository.deletePermanently(id);
    await refresh();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
