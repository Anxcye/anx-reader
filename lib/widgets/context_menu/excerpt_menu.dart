import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/selection_snapshot.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:flutter/material.dart';

String selectionActionLabel(BuildContext context, SelectionMenuAction action,
    {bool dictionary = false, bool generating = false}) {
  final l = L10n.of(context);
  return switch (action) {
    SelectionMenuAction.highlight => l.selectionHighlight,
    SelectionMenuAction.lookupOrTranslate =>
      dictionary ? l.contextMenuLookup : l.contextMenuTranslate,
    SelectionMenuAction.ai =>
      generating ? l.selectionStopAndExplain : l.selectionExplain,
    SelectionMenuAction.bringToQuestion => l.selectionBringToQuestion,
    SelectionMenuAction.addToVocabulary => l.contextMenuAddToVocabulary,
    SelectionMenuAction.copy => l.contextMenuCopy,
    SelectionMenuAction.webSearch => l.contextMenuWebSearch,
    SelectionMenuAction.paragraphTranslate => l.contextMenuParagraphTranslate,
    SelectionMenuAction.narrate => l.contextMenuNarrate,
    SelectionMenuAction.saveDifficulty => l.selectionMenuSaveDifficulty,
    SelectionMenuAction.note => l.contextMenuWriteIdea,
    SelectionMenuAction.share => l.contextMenuShare,
  };
}

IconData selectionActionIcon(SelectionMenuAction action) => switch (action) {
      SelectionMenuAction.highlight => Icons.border_color_outlined,
      SelectionMenuAction.lookupOrTranslate => Icons.menu_book_outlined,
      SelectionMenuAction.ai => Icons.auto_awesome_outlined,
      SelectionMenuAction.bringToQuestion => Icons.chat_bubble_outline,
      SelectionMenuAction.addToVocabulary => Icons.library_add_outlined,
      SelectionMenuAction.copy => Icons.copy,
      SelectionMenuAction.webSearch => Icons.language,
      SelectionMenuAction.paragraphTranslate => Icons.translate,
      SelectionMenuAction.narrate => Icons.headphones,
      SelectionMenuAction.saveDifficulty => Icons.inventory_2_outlined,
      SelectionMenuAction.note => Icons.edit_note,
      SelectionMenuAction.share => Icons.share_outlined,
    };

/// Pure presentation of the shared selection session. No lookup or persistence
/// starts as a side effect of building or updating this toolbar.
class ExcerptMenu extends StatelessWidget {
  const ExcerptMenu({
    super.key,
    required this.controller,
    required this.actions,
    required this.dictionary,
    required this.onAction,
    required this.onMore,
    required this.onClose,
    required this.onRange,
    required this.onAdjust,
    required this.onExtend,
    required this.onUndoExtension,
    required this.onShowEnd,
    this.generating = false,
  });

  final AiWorkspaceController controller;
  final List<SelectionMenuAction> actions;
  final bool dictionary;
  final bool generating;
  final ValueChanged<SelectionMenuAction> onAction;
  final VoidCallback onMore;
  final VoidCallback onClose;
  final ValueChanged<SelectionRangeType> onRange;
  final void Function(String endpoint, int direction, String unit) onAdjust;
  final VoidCallback onExtend;
  final VoidCallback onUndoExtension;
  final VoidCallback onShowEnd;

  @override
  Widget build(BuildContext context) {
    final selection = controller.selection;
    if (selection == null) return const SizedBox.shrink();
    final l = L10n.of(context);
    final minimum = Prefs().eInkMode ? 56.0 : 48.0;
    final adjusting = controller.selectionToolPage == SelectionToolPage.range;
    final style = OutlinedButton.styleFrom(
        minimumSize: Size(48, minimum),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8));
    final inheritedTheme = Theme.of(context);
    final theme = Prefs().eInkMode
        ? inheritedTheme.copyWith(
            colorScheme: const ColorScheme.light(
                primary: Colors.black,
                onPrimary: Colors.white,
                secondary: Colors.black,
                onSecondary: Colors.white,
                secondaryContainer: Colors.white,
                onSecondaryContainer: Colors.black,
                surface: Colors.white,
                onSurface: Colors.black,
                outline: Colors.black,
                error: Colors.black),
          )
        : inheritedTheme;
    return Theme(
        data: theme,
        child: Material(
          color: Prefs().eInkMode
              ? Colors.white
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Prefs().eInkMode ? 0 : 8),
              side: BorderSide(
                  color: Prefs().eInkMode
                      ? Colors.black
                      : Theme.of(context).colorScheme.outline)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                if (adjusting)
                  IconButton(
                      tooltip: l.selectionReturn,
                      constraints:
                          BoxConstraints(minWidth: minimum, minHeight: minimum),
                      onPressed: () => controller
                          .setSelectionToolPage(SelectionToolPage.actions),
                      icon: const Icon(Icons.arrow_back)),
                Expanded(
                    child: Text(selection.text,
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (!adjusting && selection.supportsRangeSelection)
                  TextButton(
                      onPressed: () => controller
                          .setSelectionToolPage(SelectionToolPage.range),
                      style:
                          TextButton.styleFrom(minimumSize: Size(48, minimum)),
                      child: Text(l.selectionAdjustRange)),
                IconButton(
                    tooltip: l.selectionContinue,
                    constraints:
                        BoxConstraints(minWidth: minimum, minHeight: minimum),
                    onPressed: onClose,
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 8),
              if (!adjusting)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final action in actions) ...[
                    Expanded(
                        child: OutlinedButton(
                      key: ValueKey('selection-action-${action.name}'),
                      style: style,
                      onPressed: controller.selectionBusy
                          ? null
                          : () => onAction(action),
                      child: Text(
                          selectionActionLabel(context, action,
                              dictionary: dictionary, generating: generating),
                          textAlign: TextAlign.center),
                    )),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                      child: OutlinedButton(
                          style: style,
                          onPressed: controller.selectionBusy ? null : onMore,
                          child: Text(l.contextMenuMore,
                              textAlign: TextAlign.center))),
                ])
              else ...[
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final type in [
                    SelectionRangeType.word,
                    SelectionRangeType.sentence,
                    SelectionRangeType.paragraph
                  ])
                    OutlinedButton(
                        style: style,
                        onPressed: () => onRange(type),
                        child: Text(switch (type) {
                          SelectionRangeType.word => l.selectionRangeWord,
                          SelectionRangeType.sentence =>
                            l.selectionRangeSentence,
                          _ => l.selectionRangeParagraph,
                        })),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final endpoint in ['start', 'end'])
                    ChoiceChip(
                        visualDensity: Prefs().eInkMode
                            ? const VisualDensity(vertical: 4)
                            : VisualDensity.standard,
                        side: Prefs().eInkMode
                            ? const BorderSide(color: Colors.black)
                            : null,
                        label: Text(endpoint == 'start'
                            ? l.selectionAdjustStart
                            : l.selectionAdjustEnd),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        selected: controller.selectionEndpoint == endpoint,
                        onSelected: (_) => controller.setSelectionRangeOptions(
                            endpoint: endpoint)),
                  SizedBox(
                      height: minimum,
                      child: DropdownButton<String>(
                        value: controller.selectionUnit,
                        itemHeight: minimum,
                        items: [
                          DropdownMenuItem(
                              value: 'character',
                              child: Text(l.selectionUnitCharacter)),
                          DropdownMenuItem(
                              value: 'word', child: Text(l.selectionUnitWord)),
                          DropdownMenuItem(
                              value: 'sentence',
                              child: Text(l.selectionUnitSentence)),
                        ],
                        onChanged: (value) =>
                            controller.setSelectionRangeOptions(unit: value),
                      )),
                ]),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final direction in [-1, 1])
                    OutlinedButton.icon(
                        style: style,
                        onPressed: _canAdjust(selection, direction)
                            ? () => onAdjust(controller.selectionEndpoint,
                                direction, controller.selectionUnit)
                            : null,
                        icon: Icon(direction < 0
                            ? Icons.chevron_left
                            : Icons.chevron_right),
                        label: Text(direction < 0
                            ? l.selectionMoveEarlier
                            : l.selectionMoveLater)),
                  OutlinedButton(
                      style: style,
                      onPressed: selection.canExtendNextPage ? onExtend : null,
                      child: Text(selection.flow == 'scrolled'
                          ? l.selectionExtendScreen
                          : l.selectionExtendPage)),
                  if (selection.canUndoExtension)
                    OutlinedButton(
                        style: style,
                        onPressed: onUndoExtension,
                        child: Text(l.selectionUndoExtension)),
                  OutlinedButton(
                      style: style,
                      onPressed:
                          selection.canShowSelectionEnd ? onShowEnd : null,
                      child: Text(l.selectionShowEnd)),
                ]),
                if (!selection.canExtendNextPage)
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                          selection.extensionUnavailableReason == 'chapterEnd'
                              ? l.selectionChapterEnd
                              : l.selectionExtensionUnsupported)),
              ],
              if (controller.selectionBusy)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(l.selectionSaving)),
              if (controller.selectionError case final error?)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
            ]),
          ),
        ));
  }

  bool _canAdjust(SelectionSnapshot selection, int direction) =>
      controller.selectionEndpoint == 'start'
          ? direction < 0
              ? selection.canAdjustStartPrevious
              : selection.canAdjustStartNext
          : direction < 0
              ? selection.canAdjustEndPrevious
              : selection.canAdjustEndNext;
}
