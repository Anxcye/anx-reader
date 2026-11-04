import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';

/// Presentation categories only. Persisted Wiki/Artifact kinds keep their IDs.
enum BookMaterialSection { chapters, characters, plot, concepts, records }

class BookMaterialItem {
  const BookMaterialItem({
    required this.id,
    required this.sourceId,
    required this.section,
    required this.title,
    required this.summary,
    this.wikiEntry,
    this.noteItem,
    this.difficulty,
  });

  final String id;
  final String sourceId;
  final BookMaterialSection section;
  final String title;
  final String summary;
  final BookWikiEntry? wikiEntry;
  final ReadingNoteListItem? noteItem;
  final ReadingDifficulty? difficulty;

  String? get location {
    if (noteItem != null) return noteItem!.cfi;
    if (difficulty != null) return difficulty!.cfi;
    final source = wikiEntry?.sources.firstOrNull;
    return source?.cfi ?? source?.chapterHref;
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        [title, summary, wikiEntry?.contentMarkdown ?? '']
            .any((value) => value.toLowerCase().contains(normalized));
  }
}

/// A book-scoped, spoiler-filtered view of existing sources. Search never
/// accesses chapter text, providers, or persistence.
class BookMaterialsSnapshot {
  const BookMaterialsSnapshot({
    required this.bookId,
    required this.visibleAtProgress,
    this.currentCfi,
    this.outcomes,
    this.sourceBoundaries = const {},
    this.items = const [],
    this.availableSections = const {
      BookMaterialSection.chapters,
      BookMaterialSection.concepts,
      BookMaterialSection.records,
    },
  });

  final int bookId;
  final double visibleAtProgress;
  final String? currentCfi;
  final ReadingOutcomesSnapshot? outcomes;
  final Map<String, double> sourceBoundaries;
  final List<BookMaterialItem> items;
  final Set<BookMaterialSection> availableSections;

  Map<BookMaterialSection, List<BookMaterialItem>> get sections => {
        for (final section in BookMaterialSection.values)
          if (items.any((item) => item.section == section))
            section: items
                .where((item) => item.section == section)
                .toList(growable: false),
      };

  List<BookMaterialItem> search(String query) =>
      items.where((item) => item.matches(query)).toList(growable: false);
}
