import 'dart:math' as math;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/widgets/common/axis_flex.dart';
import 'package:anx_reader/widgets/context_menu/excerpt_menu.dart';
import 'package:anx_reader/widgets/context_menu/reader_note_menu.dart';
import 'package:anx_reader/widgets/context_menu/search_menu.dart';
import 'package:anx_reader/widgets/context_menu/translation_menu.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/models/book_note.dart';

Future<void> showContextMenu(
    BuildContext context,
    double left,
    double top,
    double right,
    double bottom,
    String annoContent,
    String annoCfi,
    int? annoId,
    bool footnote,
    Axis axis,
    {String? contextText}) async {
  final playerKey = epubPlayerKey.currentState;
  if (playerKey == null) return;
  bool isNewNote = false;

  if (Prefs().autoMarkSelection && annoId == null) {
    // Auto-highlight logic
    final String type = Prefs().annotationType;
    final String color = Prefs().annotationColor;

    final BookNote bookNote = BookNote(
      bookId: playerKey.book.id,
      content: annoContent,
      cfi: annoCfi,
      chapter: playerKey.chapterTitle,
      type: type,
      color: color,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
    );

    final id = await bookNoteDao.save(bookNote);
    bookNote.setId(id);
    playerKey.addAnnotation(bookNote);
    annoId = id;
    isNewNote = true;
  }

  final renderBox =
      epubPlayerKey.currentContext?.findRenderObject() as RenderBox?;
  final renderBoxSize = renderBox?.size;

  final mediaQuery = MediaQuery.of(context);
  final double screenHeight = renderBoxSize?.height ?? mediaQuery.size.height;
  final double screenWidth = renderBoxSize?.width ?? mediaQuery.size.width;
  final double keyboardInset = mediaQuery.viewInsets.bottom;

  final Offset localToGlobal =
      renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

  final viewportRect = Rect.fromLTWH(
    localToGlobal.dx,
    localToGlobal.dy,
    screenWidth,
    screenHeight,
  );

  final selectionRect = Rect.fromLTRB(
    localToGlobal.dx + left * screenWidth,
    localToGlobal.dy + top * screenHeight,
    localToGlobal.dx + right * screenWidth,
    localToGlobal.dy + bottom * screenHeight,
  );

  const double horizontalMargin = 16;
  const double verticalMargin = 16;
  const double gap = 12;

  final double maxMenuWidth =
      math.min(350, math.max(120, screenWidth - horizontalMargin * 2));
  final double effectiveHeight = math.max(0, screenHeight - keyboardInset);
  final double maxHeightCandidate = effectiveHeight - verticalMargin * 2;
  final double rawMaxHeight = math.min(
    footnote ? 350 : 550,
    math.max(200, maxHeightCandidate),
  );
  final double maxMenuHeight = math.max(
    0,
    math.min(rawMaxHeight, maxHeightCandidate),
  );

  final menuConstraints = BoxConstraints(
    maxWidth: maxMenuWidth,
    maxHeight: maxMenuHeight,
  );

  final initialPlacement = _resolveMenuPlacement(
    axis: axis,
    selectionRect: selectionRect,
    viewportRect: viewportRect,
    menuSize: Size(maxMenuWidth, maxMenuHeight),
    horizontalMargin: horizontalMargin,
    verticalMargin: verticalMargin,
    gap: gap,
    bottomInset: keyboardInset,
  );

  playerKey.removeOverlay();

  void onClose() {
    playerKey.webViewController.evaluateJavascript(source: 'clearSelection()');
    playerKey.removeOverlay();
  }

  final decoration = BoxDecoration(
    color: Prefs().eInkMode
        ? Colors.white
        : Theme.of(context).colorScheme.secondaryContainer,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      if (!Prefs().eInkMode)
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 5,
          blurRadius: 7,
          offset: const Offset(0, 3),
        ),
      if (Prefs().eInkMode)
        const BoxShadow(
          color: Colors.black,
          spreadRadius: 1,
          blurRadius: 0,
        ),
    ],
  );

  playerKey.contextMenuEntry = OverlayEntry(builder: (context) {
    return _ContextMenuOverlay(
      axis: axis,
      selectionRect: selectionRect,
      viewportRect: viewportRect,
      annoContent: annoContent,
      annoCfi: annoCfi,
      annoId: annoId,
      footnote: footnote,
      contextText: contextText,
      decoration: decoration,
      onClose: onClose,
      menuConstraints: menuConstraints,
      initialPlacement: initialPlacement,
      showTranslationDefault: !isNewNote && Prefs().autoTranslateSelection,
      horizontalMargin: horizontalMargin,
      verticalMargin: verticalMargin,
      gap: gap,
      initialBottomInset: keyboardInset,
    );
  });

  Overlay.of(context).insert(playerKey.contextMenuEntry!);
}

class _MenuPlacement {
  const _MenuPlacement({required this.offset, required this.shouldReverse});

  final Offset offset;
  final bool shouldReverse;
}

double _clampWithin(double value, double min, double max) {
  if (min > max) {
    return min;
  }
  return value.clamp(min, max);
}

_MenuPlacement _resolveMenuPlacement({
  required Axis axis,
  required Rect selectionRect,
  required Rect viewportRect,
  required Size menuSize,
  required double horizontalMargin,
  required double verticalMargin,
  required double gap,
  required double bottomInset,
}) {
  final double menuWidth = menuSize.width;
  final double menuHeight = menuSize.height;

  final double clampedViewportBottom =
      math.max(viewportRect.top, viewportRect.bottom - bottomInset);

  if (axis == Axis.horizontal) {
    final double spaceAbove = selectionRect.top - viewportRect.top;
    final double spaceBelow = clampedViewportBottom - selectionRect.bottom;
    final bool placeBelow =
        (spaceBelow >= menuHeight + gap) || (spaceBelow >= spaceAbove);

    final double minTop = viewportRect.top + verticalMargin;
    final double maxTop = clampedViewportBottom - menuHeight - verticalMargin;
    double desiredTop = placeBelow
        ? selectionRect.bottom + gap
        : selectionRect.top - menuHeight - gap;
    desiredTop = _clampWithin(desiredTop, minTop, maxTop);

    final double minLeft = viewportRect.left + horizontalMargin;
    final double maxLeft = viewportRect.right - menuWidth - horizontalMargin;
    double desiredLeft = selectionRect.center.dx - menuWidth / 2;
    desiredLeft = _clampWithin(desiredLeft, minLeft, maxLeft);

    return _MenuPlacement(
      offset: Offset(desiredLeft, desiredTop),
      shouldReverse: !placeBelow,
    );
  }

  final double spaceLeft = selectionRect.left - viewportRect.left;
  final double spaceRight = viewportRect.right - selectionRect.right;
  final bool placeRight =
      (spaceRight >= menuWidth + gap) || (spaceRight >= spaceLeft);

  final double minLeft = viewportRect.left + horizontalMargin;
  final double maxLeft = viewportRect.right - menuWidth - horizontalMargin;
  double desiredLeft = placeRight
      ? selectionRect.right + gap
      : selectionRect.left - menuWidth - gap;
  desiredLeft = _clampWithin(desiredLeft, minLeft, maxLeft);

  final double minTop = viewportRect.top + verticalMargin;
  final double maxTop = clampedViewportBottom - menuHeight - verticalMargin;
  double desiredTop = selectionRect.center.dy - menuHeight / 2;
  desiredTop = _clampWithin(desiredTop, minTop, maxTop);

  return _MenuPlacement(
    offset: Offset(desiredLeft, desiredTop),
    shouldReverse: !placeRight,
  );
}

class _ContextMenuOverlay extends StatefulWidget {
  const _ContextMenuOverlay({
    required this.axis,
    required this.selectionRect,
    required this.viewportRect,
    required this.annoContent,
    required this.annoCfi,
    required this.annoId,
    required this.footnote,
    this.contextText,
    required this.decoration,
    required this.onClose,
    required this.menuConstraints,
    required this.initialPlacement,
    required this.showTranslationDefault,
    required this.horizontalMargin,
    required this.verticalMargin,
    required this.gap,
    required this.initialBottomInset,
  });

  final Axis axis;
  final Rect selectionRect;
  final Rect viewportRect;
  final String annoContent;
  final String annoCfi;
  final int? annoId;
  final bool footnote;
  final String? contextText;
  final BoxDecoration decoration;
  final VoidCallback onClose;
  final BoxConstraints menuConstraints;
  final _MenuPlacement initialPlacement;
  final bool showTranslationDefault;
  final double horizontalMargin;
  final double verticalMargin;
  final double gap;
  final double initialBottomInset;

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with WidgetsBindingObserver {
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey<ReaderNoteMenuState> _readerNoteMenuKey =
      GlobalKey<ReaderNoteMenuState>();

  late Offset _position;
  late bool _reverse;
  late bool _showTranslationMenu;
  bool _showReaderNoteMenu = false;
  bool _showSearchMenu = false;
  String _searchQuery = '';
  bool _waitingForFirstMeasurement = true;
  late BoxConstraints _menuConstraints;
  late double _bottomInset;
  int? _noteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _position = widget.initialPlacement.offset;
    _reverse = widget.initialPlacement.shouldReverse;
    _showTranslationMenu = widget.showTranslationDefault;
    _noteId = widget.annoId;
    _bottomInset = widget.initialBottomInset;
    _menuConstraints = _buildConstraints(widget.initialBottomInset);
    _scheduleRecalculate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    epubPlayerKey.currentState?.setSelectionClearLocked(false);
    super.dispose();
  }

  BoxConstraints _buildConstraints(double bottomInset) {
    final original = widget.menuConstraints;
    final double availableHeight = math.max(
      0,
      widget.viewportRect.height - bottomInset - widget.verticalMargin * 2,
    );

    double maxHeight;
    if (original.hasBoundedHeight) {
      maxHeight = math.min(original.maxHeight, availableHeight);
    } else {
      maxHeight = availableHeight;
    }
    maxHeight = math.max(0, maxHeight);

    final double minHeight = math.min(original.minHeight, maxHeight);

    return BoxConstraints(
      minWidth: original.minWidth,
      maxWidth: original.maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  void _scheduleRecalculate({Duration delay = Duration.zero}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (delay == Duration.zero) {
        _updatePlacement();
      } else {
        Future.delayed(delay, () {
          if (!mounted) return;
          _updatePlacement();
        });
      }
    });
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    _scheduleRecalculate();
  }

  void _updatePlacement() {
    final renderBox = _menuKey.currentContext?.findRenderObject() as RenderBox?;
    final double currentBottomInset = MediaQuery.of(context).viewInsets.bottom;
    final newConstraints = _buildConstraints(currentBottomInset);

    if (renderBox == null) {
      final bool needsStateUpdate =
          (_bottomInset - currentBottomInset).abs() > 0.5 ||
              _menuConstraints.maxHeight != newConstraints.maxHeight;

      if (needsStateUpdate) {
        setState(() {
          _bottomInset = currentBottomInset;
          _menuConstraints = newConstraints;
        });
      }
      return;
    }

    final size = renderBox.size;
    final placement = _resolveMenuPlacement(
      axis: widget.axis,
      selectionRect: widget.selectionRect,
      viewportRect: widget.viewportRect,
      menuSize: size,
      horizontalMargin: widget.horizontalMargin,
      verticalMargin: widget.verticalMargin,
      gap: widget.gap,
      bottomInset: currentBottomInset,
    );

    final bool positionChanged =
        (_position.dx - placement.offset.dx).abs() > 0.5 ||
            (_position.dy - placement.offset.dy).abs() > 0.5;

    final bool bottomInsetChanged =
        (_bottomInset - currentBottomInset).abs() > 0.5;

    final bool constraintsChanged =
        _menuConstraints.maxHeight != newConstraints.maxHeight;

    final bool shouldUpdate = _waitingForFirstMeasurement ||
        positionChanged ||
        _reverse != placement.shouldReverse ||
        bottomInsetChanged ||
        constraintsChanged;

    if (shouldUpdate) {
      setState(() {
        _position = placement.offset;
        _reverse = placement.shouldReverse;
        _bottomInset = currentBottomInset;
        _menuConstraints = newConstraints;
        _waitingForFirstMeasurement = false;
      });
    }
  }

  void _toggleTranslationMenu() {
    setState(() {
      _showTranslationMenu = !_showTranslationMenu;
    });
    _scheduleRecalculate();
  }

  void _toggleReaderNoteMenu({bool? show}) {
    final target = show ?? !_showReaderNoteMenu;
    epubPlayerKey.currentState?.setSelectionClearLocked(target);
    setState(() {
      _showReaderNoteMenu = target;
    });
    _scheduleRecalculate(
      delay: _showReaderNoteMenu
          ? const Duration(milliseconds: 300)
          : Duration.zero,
    );
  }

  void _toggleSearchMenu({bool? show, String? query}) {
    final target = show ?? !_showSearchMenu;
    epubPlayerKey.currentState?.setSelectionClearLocked(target);
    setState(() {
      _showSearchMenu = target;
      if (query != null) _searchQuery = query;
    });
    _scheduleRecalculate(
      delay: _showSearchMenu
          ? const Duration(milliseconds: 300)
          : Duration.zero,
    );
  }

  Future<void> _openReaderNoteMenu(int noteId) async {
    _toggleReaderNoteMenu(show: true);
    if (_readerNoteMenuKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    await _readerNoteMenuKey.currentState?.showNoteDialog(noteId);
    _scheduleRecalculate(delay: const Duration(milliseconds: 300));
  }

  void _handleNoteCreated(int noteId) {
    if (_noteId == noteId) {
      return;
    }
    setState(() {
      _noteId = noteId;
    });
  }

  void _handleReaderNoteVisibilityChange(bool visible) {
    epubPlayerKey.currentState?.setSelectionClearLocked(visible);
    if (_showReaderNoteMenu == visible) {
      return;
    }
    setState(() {
      _showReaderNoteMenu = visible;
    });
    _scheduleRecalculate(
      delay: visible ? const Duration(milliseconds: 300) : Duration.zero,
    );
  }

  void _handleReaderNoteSizeChanged() {
    _scheduleRecalculate();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: PointerInterceptor(
        child: Stack(
          children: [
            GestureDetector(
              onTap: widget.onClose,
              child: IgnorePointer(
                ignoring: _waitingForFirstMeasurement,
                child: Opacity(
                  opacity: _waitingForFirstMeasurement ? 0 : 1,
                  child: Container(
                    key: _menuKey,
                    color: Colors.transparent,
                    constraints: _menuConstraints,
                    child: AxisFlex(
                      axis: flipAxis(widget.axis),
                      reverse: _reverse,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AxisFlex(
                          axis: flipAxis(widget.axis),
                          reverse: _reverse,
                          children: [
                            AxisFlex(
                              axis: widget.axis,
                              children: [
                                ExcerptMenu(
                                  annoCfi: widget.annoCfi,
                                  annoContent: widget.annoContent,
                                  id: widget.annoId,
                                  onClose: widget.onClose,
                                  footnote: widget.footnote,
                                  decoration: widget.decoration,
                                  toggleTranslationMenu: _toggleTranslationMenu,
                                  toggleReaderNoteMenu: _toggleReaderNoteMenu,
                                  toggleSearchMenu: _toggleSearchMenu,
                                  openReaderNoteMenu: _openReaderNoteMenu,
                                  onNoteCreated: _handleNoteCreated,
                                  axis: widget.axis,
                                  reverse: _reverse,
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_showReaderNoteMenu) ...[
                          const SizedBox.square(dimension: 10),
                          AxisFlex(
                            axis: widget.axis,
                            children: [
                              ReaderNoteMenu(
                                key: _readerNoteMenuKey,
                                noteId: _noteId,
                                decoration: widget.decoration,
                                axis: widget.axis,
                                onVisibilityChange:
                                    _handleReaderNoteVisibilityChange,
                                onSizeChanged: _handleReaderNoteSizeChanged,
                              ),
                            ],
                          ),
                        ],
                        if (_showTranslationMenu) ...[
                          const SizedBox.square(dimension: 10),
                          AxisFlex(
                            axis: widget.axis,
                            children: [
                              TranslationMenu(
                                content: widget.annoContent,
                                decoration: widget.decoration,
                                axis: widget.axis,
                                contextText: widget.contextText,
                              ),
                            ],
                          ),
                        ],
                        if (_showSearchMenu) ...[
                          const SizedBox.square(dimension: 10),
                          AxisFlex(
                            axis: widget.axis,
                            children: [
                              SearchMenu(
                                query: _searchQuery,
                                decoration: widget.decoration,
                                axis: widget.axis,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
