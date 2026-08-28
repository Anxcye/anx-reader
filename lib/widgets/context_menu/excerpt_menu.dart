import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:anx_reader/constants/note_annotations.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/dao/vocabulary.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:anx_reader/service/reading_note/reading_note_capture_service.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/dictionary/chinese_dictionary.dart';
import 'package:anx_reader/service/dictionary/english_dictionary.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/tts/tts_handler.dart';
import 'package:anx_reader/service/vocabulary_capture_service.dart';
import 'package:anx_reader/service/web_search.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/book_share/excerpt_share_service.dart';
import 'package:anx_reader/widgets/context_menu/selection_action_policy.dart';
import 'package:anx_reader/widgets/common/axis_flex.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:anx_reader/widgets/reading_note/quick_capture_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ExcerptMenu extends StatefulWidget {
  final String annoCfi;
  final String annoContent;
  final String? contextText;
  final int? id;
  final Function() onClose;
  final bool footnote;
  final BoxDecoration decoration;
  final VoidCallback showTranslationMenu;
  final void Function({bool? show}) toggleReaderNoteMenu;
  final Future<void> Function(int noteId) openReaderNoteMenu;
  final void Function(int noteId) onNoteCreated;
  final VoidCallback onLayoutChanged;
  final Axis axis;
  final bool reverse;
  final SelectionSnapshot? selectionSnapshot;

  const ExcerptMenu({
    super.key,
    required this.annoCfi,
    required this.annoContent,
    this.contextText,
    this.id,
    required this.onClose,
    required this.footnote,
    required this.decoration,
    required this.showTranslationMenu,
    required this.toggleReaderNoteMenu,
    required this.openReaderNoteMenu,
    required this.onNoteCreated,
    required this.onLayoutChanged,
    required this.axis,
    required this.reverse,
    this.selectionSnapshot,
  });

  @override
  ExcerptMenuState createState() => ExcerptMenuState();
}

class ExcerptMenuState extends State<ExcerptMenu> {
  bool deleteConfirm = false;
  int? noteId;
  BookNote? _currentNote;
  bool _showMoreActions = false;
  bool _isAddingVocabulary = false;
  bool _isVocabularyAdded = false;
  late String annoType;
  late String annoColor;

  @override
  initState() {
    super.initState();
    annoType = Prefs().annotationType;
    annoColor = Prefs().annotationColor;
    _initializeExistingNote();
    if (_isDictionaryLookup && _isVocabularyEnabled) {
      _loadVocabularyState();
    }
  }

  bool get _isDictionaryLookup =>
      EnglishDictionaryService.isEnglishWord(widget.annoContent) ||
      ChineseDictionaryService.isLookupCandidate(widget.annoContent);

  bool get _isVocabularyEnabled => Prefs().bottomNavigatorShowVocabulary;

  SelectionActionPolicy get _actionPolicy => SelectionActionPolicy.forSelection(
        widget.annoContent,
        aiEnabled: EnvVar.enableAIFeature,
        vocabularyEnabled: _isVocabularyEnabled,
        footnote: widget.footnote,
        actionOrder: Prefs().selectionMenuActionOrder,
        enabledActions: Prefs().enabledSelectionMenuActions,
      );

  Future<void> _loadVocabularyState() async {
    final existing = await vocabularyDao.selectByWord(widget.annoContent);
    if (!mounted) return;
    setState(() {
      _isVocabularyAdded = existing != null;
    });
  }

  Future<void> _addToVocabulary() async {
    if (_isAddingVocabulary || _isVocabularyAdded) return;
    final player = epubPlayerKey.currentState;
    if (player == null) return;

    setState(() {
      _isAddingVocabulary = true;
    });

    try {
      final result = await VocabularyCaptureService.captureQuick(
        word: widget.annoContent,
        bookId: player.book.id.toString(),
        bookTitle: player.book.title,
        chapterId: player.chapterHref,
        chapterTitle: player.chapterTitle,
        contextText: widget.contextText,
        position: widget.annoCfi,
      );
      if (!mounted) return;
      setState(() {
        _isVocabularyAdded = true;
        _isAddingVocabulary = false;
      });
      AnxToast.show(result.created
          ? L10n.of(context).vocabularyAddedToast
          : L10n.of(context).vocabularyAlreadyExists);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAddingVocabulary = false;
      });
      AnxToast.show(L10n.of(context).commonFailed);
    }
  }

  Future<void> _showWebSearchEngines() async {
    final selectedEngine = WebSearchEngine.fromCode(
      Prefs().prefs.getString('webSearchEngine'),
    );
    final engine = await showDialog<WebSearchEngine>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(L10n.of(context).contextMenuWebSearch),
        children: WebSearchEngine.values
            .map(
              (item) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(item),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item == selectedEngine
                        ? Icons.check_circle
                        : Icons.language,
                  ),
                  title: Text(item.label),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (engine == null || !mounted) return;

    await Prefs().prefs.setString('webSearchEngine', engine.code);
    widget.onClose();
    await launchUrl(
      engine.buildSearchUri(widget.annoContent),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openAiWorkspace() {
    final player = epubPlayerKey.currentState;
    final readingPage = readingPageKey.currentState;
    if (player == null || readingPage == null) {
      AnxToast.show(L10n.of(context).commonFailed);
      return;
    }

    final snapshot = ReadingContextSnapshot(
      bookId: player.book.id.toString(),
      bookTitle: player.book.title,
      author: player.book.author,
      chapterTitle: player.chapterTitle,
      chapterHref: player.chapterHref,
      selectedText: widget.annoContent.trim(),
      surroundingText: widget.contextText?.trim(),
      capturedAt: DateTime.now().millisecondsSinceEpoch,
      metadata: {'cfi': widget.annoCfi},
    );
    widget.onClose();
    readingPage.showAiChat(sendImmediate: false, selection: snapshot);
  }

  Future<void> _initializeExistingNote() async {
    final existingId = widget.id;
    if (existingId == null) {
      return;
    }

    try {
      final note = await bookNoteDao.selectBookNoteById(existingId);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentNote = note;
        noteId = note.id;
        annoType = note.type;
        annoColor = note.color;
      });
      if (!widget.footnote &&
          note.readerNote != null &&
          note.readerNote!.isNotEmpty) {
        await widget.openReaderNoteMenu(note.id!);
      }
    } catch (_) {
      // When the note cannot be loaded we keep the defaults from Prefs.
    }
  }

  Future<BookNote?> _fetchLatestNote() async {
    final existingId = noteId ?? widget.id;
    if (existingId == null) {
      return null;
    }

    try {
      return await bookNoteDao.selectBookNoteById(existingId);
    } catch (_) {
      return null;
    }
  }

  Future<BookNote> _persistNote(
      {String? color, String? type, String? content}) async {
    final existingNote = await _fetchLatestNote() ?? _currentNote;
    final now = DateTime.now();

    final resolvedContent = (content ?? widget.annoContent).trim().isNotEmpty
        ? (content ?? widget.annoContent)
        : (existingNote?.content ?? widget.annoContent);
    final resolvedType = type ?? existingNote?.type ?? annoType;
    final resolvedColor = color ?? existingNote?.color ?? annoColor;

    final BookNote bookNote = BookNote(
      id: existingNote?.id ?? widget.id,
      bookId:
          existingNote?.bookId ?? epubPlayerKey.currentState!.widget.book.id,
      content: resolvedContent,
      cfi: existingNote?.cfi ?? widget.annoCfi,
      chapter:
          existingNote?.chapter ?? epubPlayerKey.currentState!.chapterTitle,
      type: resolvedType,
      color: resolvedColor,
      readerNote: existingNote?.readerNote,
      createTime: existingNote?.createTime ?? now,
      updateTime: now,
    );

    final id = await bookNoteDao.save(bookNote);
    bookNote.setId(id);
    widget.onNoteCreated(id);

    if (mounted) {
      setState(() {
        _currentNote = bookNote;
        noteId = id;
        annoType = resolvedType;
        annoColor = resolvedColor;
      });
    } else {
      _currentNote = bookNote;
      noteId = id;
      annoType = resolvedType;
      annoColor = resolvedColor;
    }

    return bookNote;
  }

  Future<void> _captureReadingNote() async {
    final player = epubPlayerKey.currentState;
    if (player == null) return;
    final choice = await showReadingNoteQuickCaptureSheet(context);
    if (choice == null || !mounted) return;
    final document = await ReadingNoteCaptureService().capture(
      bookId: player.book.id,
      text: widget.annoContent,
      cfi: widget.annoCfi,
      chapter: player.chapterTitle,
      chapterHref: player.chapterHref,
      annotationType: annoType,
      annotationColor: annoColor,
      annotationId: noteId ?? widget.id,
      kind: choice.kind,
      body: choice.body,
    );
    final annotationId = int.tryParse(document.sources.first.sourceRef);
    if (annotationId != null) {
      final annotation = await bookNoteDao.selectBookNoteById(annotationId);
      widget.onNoteCreated(annotationId);
      player.addAnnotation(annotation);
    }
    widget.onClose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('已保存到阅读笔记'),
      action: SnackBarAction(
        label: '撤销',
        onPressed: () => ReadingNoteCaptureService().undo(document.note.id),
      ),
    ));
  }

  Icon deleteIcon() {
    return deleteConfirm
        ? const Icon(
            EvaIcons.close_circle,
            color: Colors.red,
          )
        : const Icon(Icons.delete);
  }

  void deleteHandler() {
    if (deleteConfirm) {
      if (widget.id != null) {
        bookNoteDao.deleteBookNoteById(widget.id!);
        epubPlayerKey.currentState!.removeAnnotation(widget.annoCfi);
      }
      widget.onClose();
    } else {
      setState(() {
        deleteConfirm = true;
      });
    }
  }

  Future<void> onColorSelected(String color, {bool close = true}) async {
    Prefs().annotationColor = color;
    if (mounted) {
      setState(() {
        annoColor = color;
      });
    } else {
      annoColor = color;
    }
    final bookNote = await _persistNote(color: color);
    epubPlayerKey.currentState!.addAnnotation(bookNote);
    if (close) {
      widget.onClose();
    }
  }

  Future<void> onTypeSelected(String type) async {
    Prefs().annotationType = type;
    if (mounted) {
      setState(() {
        annoType = type;
      });
    } else {
      annoType = type;
    }
    final bookNote = await _persistNote(type: type);
    epubPlayerKey.currentState!.addAnnotation(bookNote);
  }

  Widget iconButton({required Icon icon, required Function() onPressed}) {
    return IconButton(
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: icon,
      onPressed: onPressed,
    );
  }

  Widget colorButton(String color) {
    return iconButton(
      icon: Icon(
        Icons.circle,
        color: Color(int.parse('0x88$color')),
      ),
      onPressed: () {
        onColorSelected(color);
      },
    );
  }

  Widget typeButton(String type, IconData icon) {
    return iconButton(
      icon: Icon(icon,
          color: annoType == type ? Color(int.parse('0xff$annoColor')) : null),
      onPressed: () {
        onTypeSelected(type);
      },
    );
  }

  Widget _rangeButton(SelectionRangeType type, String label) {
    final selected = widget.selectionSnapshot?.rangeType == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton.icon(
        onPressed: () => epubPlayerKey.currentState?.changeSelectionRange(type),
        icon: Icon(selected ? Icons.check : Icons.text_fields, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: Prefs().eInkMode ? Colors.black : null,
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
          textStyle: TextStyle(fontWeight: selected ? FontWeight.bold : null),
        ),
      ),
    );
  }

  Widget _sentenceButton(int direction, String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton.icon(
        onPressed: enabled
            ? () => epubPlayerKey.currentState?.moveSelectionSentence(direction)
            : null,
        icon: Icon(direction < 0 ? Icons.chevron_left : Icons.chevron_right),
        label: Text(label),
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }

  IconAndText _copyAction() => IconAndText(
        compact: true,
        onTap: () {
          Clipboard.setData(ClipboardData(text: widget.annoContent));
          AnxToast.show(L10n.of(context).notesPageCopied);
          widget.onClose();
        },
        icon: const Icon(EvaIcons.copy),
        text: L10n.of(context).contextMenuCopy,
      );

  IconAndText _lookupOrTranslateAction() => IconAndText(
        compact: true,
        onTap: widget.showTranslationMenu,
        icon: Icon(
            _isDictionaryLookup ? Icons.menu_book_outlined : Icons.translate),
        text: _isDictionaryLookup
            ? L10n.of(context).contextMenuLookup
            : L10n.of(context).contextMenuTranslate,
      );

  IconAndText _vocabularyAction() => IconAndText(
        compact: true,
        onTap: _isAddingVocabulary ? null : _addToVocabulary,
        icon: _isAddingVocabulary
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_isVocabularyAdded
                ? Icons.check_circle_outline
                : Icons.library_add_outlined),
        text: _isVocabularyAdded
            ? L10n.of(context).vocabularyAdded
            : L10n.of(context).contextMenuAddToVocabulary,
      );

  IconAndText _aiAction() => IconAndText(
        compact: true,
        onTap: _openAiWorkspace,
        icon: const Icon(EvaIcons.message_circle_outline),
        text: L10n.of(context).navBarAI,
      );

  IconAndText _moreAction() => IconAndText(
        compact: true,
        onTap: () {
          setState(() {
            _showMoreActions = !_showMoreActions;
          });
          widget.onLayoutChanged();
        },
        icon: Icon(_showMoreActions ? Icons.expand_less : Icons.more_horiz),
        text: L10n.of(context).contextMenuMore,
      );

  IconAndText _buildSelectionAction(SelectionMenuAction action) {
    return switch (action) {
      SelectionMenuAction.lookupOrTranslate => _lookupOrTranslateAction(),
      SelectionMenuAction.addToVocabulary => _vocabularyAction(),
      SelectionMenuAction.ai => _aiAction(),
      SelectionMenuAction.copy => _copyAction(),
      SelectionMenuAction.webSearch => IconAndText(
          compact: true,
          onTap: _showWebSearchEngines,
          icon: const Icon(EvaIcons.globe),
          text: L10n.of(context).contextMenuWebSearch,
        ),
      SelectionMenuAction.paragraphTranslate => IconAndText(
          compact: true,
          onTap: () {
            final player = epubPlayerKey.currentState;
            if (player == null) {
              AnxToast.show(L10n.of(context).commonFailed);
              return;
            }
            widget.onClose();
            player.translateSelectedParagraph(cfi: widget.annoCfi);
          },
          icon: const Icon(Icons.text_fields),
          text: L10n.of(context).contextMenuParagraphTranslate,
        ),
      SelectionMenuAction.narrate => IconAndText(
          compact: true,
          onTap: () async {
            final player = epubPlayerKey.currentState;
            if (player == null) {
              AnxToast.show(L10n.of(context).commonFailed);
              return;
            }
            final failureMessage = L10n.of(context).commonFailed;
            widget.onClose();
            try {
              await audioHandler.stop();
              await TtsHandler().init(
                () => player.initTts(fromCfi: widget.annoCfi),
                player.ttsNext,
                player.ttsPrev,
              );
              await audioHandler.play();
            } catch (_) {
              AnxToast.show(failureMessage);
            }
          },
          icon: const Icon(Icons.headphones),
          text: L10n.of(context).contextMenuNarrate,
        ),
      SelectionMenuAction.saveDifficulty => IconAndText(
          compact: true,
          onTap: () async {
            final player = epubPlayerKey.currentState;
            final readingPage = readingPageKey.currentState;
            if (player == null || readingPage == null) {
              AnxToast.show(L10n.of(context).commonFailed);
              return;
            }
            final snapshot = ReadingContextSnapshot(
              bookId: player.book.id.toString(),
              bookTitle: player.book.title,
              author: player.book.author,
              chapterTitle: player.chapterTitle,
              chapterHref: player.chapterHref,
              selectedText: widget.annoContent.trim(),
              surroundingText: widget.contextText?.trim(),
              capturedAt: DateTime.now().millisecondsSinceEpoch,
              metadata: {'cfi': widget.annoCfi},
            );
            widget.onClose();
            await readingPage.saveReadingDifficulty(snapshot);
          },
          icon: const Icon(Icons.inventory_2_outlined),
          text: '暂存难点',
        ),
      SelectionMenuAction.note => IconAndText(
          compact: true,
          onTap: _captureReadingNote,
          icon: const Icon(EvaIcons.edit_2_outline),
          text: L10n.of(context).contextMenuWriteIdea,
        ),
      SelectionMenuAction.share => IconAndText(
          compact: true,
          onTap: () {
            final player = epubPlayerKey.currentState;
            if (player == null) {
              AnxToast.show(L10n.of(context).commonFailed);
              return;
            }
            widget.onClose();
            ExcerptShareService.showShareExcerpt(
              context: context,
              bookTitle: player.book.title,
              author: player.book.author,
              excerpt: widget.annoContent,
              chapter: player.chapterTitle,
            );
          },
          icon: const Icon(EvaIcons.share_outline),
          text: L10n.of(context).contextMenuShare,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final actionPolicy = _actionPolicy;
    final snapshot = widget.selectionSnapshot;
    final showRangeControls =
        snapshot != null && snapshot.supportsRangeSelection;
    Widget annotationMenu = Container(
      padding: const EdgeInsets.all(6),
      decoration: widget.decoration,
      child: AxisFlex(
        axis: widget.axis,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconButton(
            onPressed: deleteHandler,
            icon: deleteIcon(),
          ),
          for (final type in notesType) typeButton(type.type, type.icon),
          for (String color in notesColors) colorButton(color),
        ],
      ),
    );

    Widget operatorMenu = Container(
      // width: 48,
      decoration: widget.decoration,
      child: AxisFlex(
        axis: widget.axis,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actionPolicy.primaryActions)
            _buildSelectionAction(action),
          if (actionPolicy.moreActions.isNotEmpty) _moreAction(),
          if (_showMoreActions) ...[
            for (final action in actionPolicy.moreActions)
              _buildSelectionAction(action),
          ],
        ],
      ),
    );

    final rangeMenu = Container(
      decoration: widget.decoration,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            children: [
              _rangeButton(
                  SelectionRangeType.word, L10n.of(context).selectionRangeWord),
              _rangeButton(SelectionRangeType.sentence,
                  L10n.of(context).selectionRangeSentence),
              _rangeButton(SelectionRangeType.paragraph,
                  L10n.of(context).selectionRangeParagraph),
            ],
          ),
          Wrap(
            children: [
              _sentenceButton(-1, L10n.of(context).selectionPreviousSentence,
                  snapshot?.canMovePrevious ?? false),
              _sentenceButton(1, L10n.of(context).selectionNextSentence,
                  snapshot?.canMoveNext ?? false),
            ],
          ),
        ],
      ),
    );

    return Expanded(
      child: AxisFlex(
        reverse: widget.reverse,
        axis: flipAxis(widget.axis),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showRangeControls) ...[
            SingleChildScrollView(
              scrollDirection: widget.axis,
              child: rangeMenu,
            ),
            const SizedBox.square(dimension: 8),
          ],
          AxisFlex(
            axis: flipAxis(widget.axis),
            reverse: widget.reverse,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                  scrollDirection: widget.axis, child: operatorMenu),
              const SizedBox.square(dimension: 10),
              if (!widget.footnote)
                SingleChildScrollView(
                  scrollDirection: widget.axis,
                  child: annotationMenu,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
