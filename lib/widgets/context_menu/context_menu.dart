import 'dart:math' as math;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/service/dictionary/reading_lookup_candidate_resolver.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/widgets/context_menu/excerpt_menu.dart';
import 'package:anx_reader/widgets/context_menu/selection_action_policy.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Installs one toolbar per reader. Subsequent DOM range revisions update the
/// workspace controller, preserving the toolbar and its chosen screen edge.
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
  Axis axis, {
  String? contextText,
  SelectionSnapshot? selectionSnapshot,
  bool offlineDictionaryMode = false,
  bool Function()? isCurrentRequest,
}) async {
  final player = epubPlayerKey.currentState;
  final page = readingPageKey.currentState;
  if (player == null ||
      page == null ||
      !context.mounted ||
      isCurrentRequest?.call() == false) {
    return;
  }
  final controller = page.aiWorkspaceController;
  final snapshot = selectionSnapshot ??
      SelectionSnapshot(
        sessionId: -(annoId ?? 0) - 1,
        rangeType: SelectionRangeType.custom,
        trigger: SelectionTrigger.contextMenu,
        text: annoContent,
        cfi: annoCfi,
        contextText: contextText,
        chapterIndex: -1,
        canMovePrevious: false,
        canMoveNext: false,
        supportsRangeSelection: false,
      );
  if (!controller.updateSelection(snapshot,
      annotationId: annoId,
      footnote: footnote,
      dockAtTop: bottom > .72,
      nearbyMenu: !Prefs().eInkMode &&
          (snapshot.pointerType == 'mouse' ||
              (snapshot.pointerType == 'unknown' && AnxPlatform.isDesktop)))) {
    return;
  }
  player.setSelectionClearLocked(controller.selectionPanelPage != null);
  if (player.contextMenuEntry?.mounted == true) return;
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
      builder: (context) => ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (!controller.selectionDockVisible ||
                  controller.selection == null) {
                return const SizedBox.shrink();
              }
              final renderBox = epubPlayerKey.currentContext?.findRenderObject()
                  as RenderBox?;
              final origin =
                  renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
              final size = renderBox?.size ?? MediaQuery.sizeOf(context);
              final width = math.min(
                  controller.selectionUsesMouse ? 440.0 : 640.0,
                  size.width - 16);
              final selected = controller.selection!;
              final candidate = ReadingLookupCandidateResolver.resolve(
                  selected.text,
                  selection: selected);
              final policy = SelectionActionPolicy.forSelection(selected.text,
                  aiEnabled: EnvVar.enableAIFeature,
                  vocabularyEnabled: Prefs().bottomNavigatorShowVocabulary,
                  footnote: controller.selectionFootnote,
                  actionOrder: Prefs().selectionMenuActionOrder,
                  enabledActions: Prefs().enabledSelectionMenuActions,
                  candidate: candidate);
              final keyboard = MediaQuery.viewInsetsOf(context).bottom;
              final safe = MediaQuery.paddingOf(context);
              // Mouse menus use their initial nearby edge; touch docks stay fixed for
              // the session even when the selected text or toolbar height changes.
              final atTop = controller.selectionDockAtTop;
              final nearbyTop = controller.selectionUsesMouse
                  ? origin.dy +
                      math.min(size.height * .55, bottom * size.height + 12)
                  : origin.dy + safe.top + 8;
              return Positioned(
                left: origin.dx + (size.width - width) / 2,
                top: atTop || controller.selectionUsesMouse ? nearbyTop : null,
                bottom: !atTop && !controller.selectionUsesMouse
                    ? math.max(
                            safe.bottom,
                            MediaQuery.sizeOf(context).height -
                                origin.dy -
                                size.height) +
                        keyboard +
                        8
                    : null,
                width: width,
                child: PointerInterceptor(
                    child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: math.max(
                          80, size.height - keyboard - safe.vertical - 24)),
                  child: SingleChildScrollView(
                      child: ExcerptMenu(
                    controller: controller,
                    actions: policy.primaryActions,
                    dictionary: policy.isDictionaryLookup,
                    generating: page.selectionAiGenerating,
                    onAction: (action) => page.handleSelectionAction(action),
                    onMore: () =>
                        page.openSelectionPanel(SelectionPanelPage.more),
                    onClose: page.finishSelection,
                    onRange: player.changeSelectionRange,
                    onAdjust: player.adjustSelectionBoundary,
                    onExtend: player.extendSelectionPage,
                    onUndoExtension: player.undoSelectionExtension,
                    onShowEnd: player.showSelectionEnd,
                  )),
                )),
              );
            },
          ));
  player.contextMenuEntry = entry;
  overlay.insert(entry);
}
