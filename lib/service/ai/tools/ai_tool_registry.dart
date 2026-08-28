import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/service/ai/tools/apply_book_tags_tool.dart';
import 'package:anx_reader/service/ai/tools/book_content_search_tool.dart';
import 'package:anx_reader/service/ai/tools/books_tags_list_tool.dart';
import 'package:anx_reader/service/ai/tools/bookshelf_lookup_tool.dart';
import 'package:anx_reader/service/ai/tools/bookshelf_organize_tool.dart';
import 'package:anx_reader/service/ai/tools/calculator_tool.dart';
import 'package:anx_reader/service/ai/tools/chapter_content_by_href_tool.dart';
import 'package:anx_reader/service/ai/tools/current_book_toc_tool.dart';
import 'package:anx_reader/service/ai/tools/current_chapter_content_tool.dart';
import 'package:anx_reader/service/ai/tools/current_reading_metadata_tool.dart';
import 'package:anx_reader/service/ai/tools/current_time_tool.dart';
import 'package:anx_reader/service/ai/tools/mindmap_tool.dart';
import 'package:anx_reader/service/ai/tools/notes_search_tool.dart';
import 'package:anx_reader/service/ai/tools/reading_history_tool.dart';
import 'package:anx_reader/service/ai/tools/reading_agent_tools.dart';
import 'package:anx_reader/service/ai/tools/tags_list_tool.dart';
import 'package:anx_reader/service/ai/tools/repository/book_content_search_repository.dart';
import 'package:anx_reader/service/ai/tools/repository/books_repository.dart';
import 'package:anx_reader/service/ai/tools/repository/groups_repository.dart';
import 'package:anx_reader/service/ai/tools/repository/notes_repository.dart';
import 'package:anx_reader/service/ai/tools/repository/reading_history_repository.dart';
import 'package:anx_reader/service/ai/tools/repository/tag_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/tools.dart';

/// Context object shared by AI tools so builders don't need long constructors.
class AiToolContext {
  AiToolContext({required this.ref});

  final WidgetRef ref;

  late final NotesRepository notesRepository = NotesRepository();
  late final BooksRepository booksRepository = BooksRepository();
  late final BookContentSearchRepository bookContentSearchRepository =
      BookContentSearchRepository(booksRepository: booksRepository);
  late final GroupsRepository groupsRepository = GroupsRepository();
  late final ReadingHistoryRepository readingHistoryRepository =
      ReadingHistoryRepository();
  late final TagRepository tagRepository = TagRepository();

  bool get isReading => ref.read(currentReadingProvider).isReading;
}

class AiToolDefinition {
  const AiToolDefinition({
    required this.id,
    required this.displayNameBuilder,
    required this.descriptionBuilder,
    required this.build,
  });

  final String id;
  final String Function(L10n l10n) displayNameBuilder;
  final String Function(L10n l10n) descriptionBuilder;
  final Tool Function(AiToolContext context) build;

  String displayName(L10n l10n) => displayNameBuilder(l10n);

  String description(L10n l10n) => descriptionBuilder(l10n);

  String displayNameOrDefault([L10n? l10n]) =>
      l10n == null ? id : displayName(l10n);

  String descriptionOrDefault([L10n? l10n]) =>
      l10n == null ? '' : description(l10n);
}

class AiToolRegistry {
  static final List<AiToolDefinition> _definitions = [
    calculatorToolDefinition,
    currentTimeToolDefinition,
    mindmapToolDefinition,
    bookContentSearchToolDefinition,
    bookshelfLookupToolDefinition,
    bookshelfOrganizeToolDefinition,
    notesSearchToolDefinition,
    readingHistoryToolDefinition,
    currentReadingMetadataToolDefinition,
    currentBookTocToolDefinition,
    currentChapterContentToolDefinition,
    chapterContentByHrefToolDefinition,
    tagsListToolDefinition,
    booksTagsListToolDefinition,
    applyBookTagsToolDefinition,
    readerNavigateToolDefinition,
    readingNoteCreateToolDefinition,
    readingDifficultySaveToolDefinition,
    readingGoalSetToolDefinition,
    readingMemoryAppendToolDefinition,
    readingMemoryRecallToolDefinition,
    fictionArtifactSaveToolDefinition,
    fictionCharacterRecallToolDefinition,
  ];

  static final Map<String, AiToolDefinition> _definitionMap = {
    for (final def in _definitions) def.id: def,
  };

  static List<AiToolDefinition> get definitions =>
      List<AiToolDefinition>.unmodifiable(_definitions);

  static AiToolDefinition? byId(String id) => _definitionMap[id];

  static List<String> defaultEnabledToolIds() =>
      _definitions.map((def) => def.id).toList(growable: false);

  static List<String> sanitizeIds(List<String> ids) {
    final seen = <String>{};
    final filtered = <String>[];
    for (final id in ids) {
      if (_definitionMap.containsKey(id) && seen.add(id)) {
        filtered.add(id);
      }
    }
    return filtered;
  }

  static List<Tool> buildTools(
    AiToolContext context,
    List<String> enabledIds,
  ) {
    final enabled = enabledIds.toSet();
    return _definitions
        .where((def) => enabled.contains(def.id))
        .where((def) =>
            Prefs().readingAgentBetaEnabled ||
            !readingAgentToolIds.contains(def.id))
        .map((def) => def.build(context))
        .toList(growable: false);
  }

  static String displayNameForId(String id, {L10n? l10n}) =>
      _definitionMap[id]?.displayNameOrDefault(l10n) ?? id;

  static String descriptionForId(String id, {L10n? l10n}) =>
      _definitionMap[id]?.descriptionOrDefault(l10n) ?? '';
}
