import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/constants/note_annotations.dart';
import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/providers/ai_workspace.dart';
import 'package:anx_reader/service/dictionary/reading_lookup_candidate_resolver.dart';
import 'package:anx_reader/service/web_search.dart';
import 'package:anx_reader/widgets/context_menu/excerpt_menu.dart';
import 'package:anx_reader/widgets/context_menu/selection_action_policy.dart';
import 'package:anx_reader/widgets/context_menu/translation_menu.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:flutter/material.dart';

/// Temporary help rendered in the existing reading workspace. The target is a
/// frozen snapshot, independent of subsequent changes to the native selection.
class SelectionPanel extends StatelessWidget {
  const SelectionPanel(
      {super.key,
      required this.controller,
      required this.bookTitle,
      required this.chapterHref,
      required this.chapterTitle,
      required this.offline,
      required this.onAction,
      required this.onSave,
      required this.onDelete,
      required this.onStyle,
      required this.onSearch,
      this.generating = false});

  final AiWorkspaceController controller;
  final String bookTitle;
  final String chapterHref;
  final String chapterTitle;
  final bool offline;
  final ValueChanged<SelectionMenuAction> onAction;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onStyle;
  final ValueChanged<WebSearchEngine> onSearch;
  final bool generating;

  @override
  Widget build(BuildContext context) {
    final target = controller.selectionTarget;
    final page = controller.selectionPanelPage;
    if (target == null || page == null) return const SizedBox.shrink();
    final l = L10n.of(context);
    final min = Prefs().eInkMode ? 56.0 : 48.0;
    final editorUnavailable = controller.selectionTargetAnnotationId != null &&
        controller.selectionEditingAnnotation == null;
    final candidate = ReadingLookupCandidateResolver.resolve(target.text,
        selection: target, offline: offline);
    final policy = SelectionActionPolicy.forSelection(target.text,
        aiEnabled: EnvVar.enableAIFeature,
        vocabularyEnabled: Prefs().bottomNavigatorShowVocabulary,
        footnote: controller.selectionFootnote,
        actionOrder: Prefs().selectionMenuActionOrder,
        enabledActions: Prefs().enabledSelectionMenuActions,
        candidate: candidate);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(chapterTitle, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(target.text, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (controller.selection?.cfi != target.cfi)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.selectionCurrentSource)),
            if (controller.selectionError case final error?)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
          ])),
      const Divider(height: 1),
      Expanded(
          child: switch (page) {
        SelectionPanelPage.lookup => TranslationMenu(
            key: ValueKey(
                'lookup-${controller.bookId}-${target.sessionId}-${target.revision}'),
            content: target.text,
            contextText: target.contextText,
            position: target.cfi,
            decoration: const BoxDecoration(),
            axis: Axis.horizontal,
            candidate: candidate,
            offline: offline,
            embedded: true,
            translateImmediately: !candidate.isDictionaryLookup,
            bookId: controller.bookId,
            bookTitle: bookTitle,
            chapterHref: chapterHref,
            chapterTitle: chapterTitle,
            aiGenerating: generating,
            onExplainWithAi: () => onAction(SelectionMenuAction.ai)),
        SelectionPanelPage.more =>
          ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
            for (final action in policy.moreActions)
              ListTile(
                  minTileHeight: min,
                  leading: Icon(selectionActionIcon(action)),
                  title: Text(selectionActionLabel(context, action,
                      dictionary: policy.isDictionaryLookup,
                      generating: generating)),
                  onTap:
                      controller.selectionBusy ? null : () => onAction(action)),
            if (!controller.selectionFootnote)
              ListTile(
                  minTileHeight: min,
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(l.selectionStyle),
                  onTap: onStyle),
            if (controller.selectionTargetAnnotationId != null)
              ListTile(
                  minTileHeight: min,
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l.selectionDelete),
                  onTap: controller.selectionBusy ? null : onDelete),
          ]),
        SelectionPanelPage.note => controller.selectionBusy
            ? Center(child: Text(l.selectionSaving))
            : ListView(padding: const EdgeInsets.all(16), children: [
                TextFormField(
                    key: ValueKey(
                        'selection-note-${target.sessionId}-${target.revision}'),
                    initialValue: controller.selectionNoteDraft,
                    autofocus: false,
                    minLines: 4,
                    maxLines: null,
                    onTap: () => controller.setSheetExpanded(true),
                    onChanged: (value) => controller.selectionNoteDraft = value,
                    decoration: InputDecoration(
                        labelText: l.contextMenuWriteIdea,
                        hintText: l.selectionNoteHint,
                        border: const OutlineInputBorder())),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: editorUnavailable ? null : onSave,
                    style: FilledButton.styleFrom(minimumSize: Size(48, min)),
                    child: Text(l.commonSave)),
              ]),
        SelectionPanelPage.style => controller.selectionBusy
            ? Center(child: Text(l.selectionSaving))
            : ListView(padding: const EdgeInsets.all(16), children: [
                for (final option in notesType)
                  ListTile(
                      minTileHeight: min,
                      title: Text(option.type == 'underline'
                          ? l.selectionUnderline
                          : l.selectionHighlightStyle),
                      leading: Icon(option.icon),
                      trailing: (controller.selectionStyleType ??
                                  controller.selectionEditingAnnotation?.type ??
                                  Prefs().annotationType) ==
                              option.type
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        controller.selectionStyleType = option.type;
                        controller.setSelectionFeedback();
                      }),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final color in notesColors)
                    OutlinedButton(
                        onPressed: () {
                          controller.selectionStyleColor = color;
                          controller.setSelectionFeedback();
                        },
                        style: OutlinedButton.styleFrom(
                            minimumSize: Size(48, min)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                              (controller.selectionStyleColor ??
                                          controller.selectionEditingAnnotation
                                              ?.color ??
                                          Prefs().annotationColor) ==
                                      color
                                  ? Icons.check_circle
                                  : Icons.circle,
                              color: Prefs().eInkMode
                                  ? Colors.black
                                  : Color(int.parse('0xff$color'))),
                          const SizedBox(width: 8),
                          Text(_colorName(l, color)),
                        ])),
                ]),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: editorUnavailable ? null : onSave,
                    style: FilledButton.styleFrom(minimumSize: Size(48, min)),
                    child: Text(l.commonSave)),
              ]),
        SelectionPanelPage.search => ListView(children: [
            for (final engine in WebSearchEngine.values)
              ListTile(
                  minTileHeight: min,
                  leading: const Icon(Icons.open_in_new),
                  title: Text(engine.label),
                  onTap: () => onSearch(engine)),
          ]),
      }),
    ]);
  }

  String _colorName(L10n l, String color) => switch (color) {
        '66CCFF' => l.selectionColorBlue,
        'FF0000' => l.selectionColorRed,
        '00FF00' => l.selectionColorGreen,
        'EB3BFF' => l.selectionColorPurple,
        _ => l.selectionColorYellow,
      };
}
