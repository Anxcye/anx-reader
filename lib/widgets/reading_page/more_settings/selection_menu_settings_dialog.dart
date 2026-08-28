import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

Future<void> showSelectionMenuSettingsDialog(BuildContext context) async {
  var order = Prefs().selectionMenuActionOrder;
  var enabled = Prefs().enabledSelectionMenuActions;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        String label(SelectionMenuAction action) {
          final l10n = L10n.of(context);
          return switch (action) {
            SelectionMenuAction.lookupOrTranslate =>
              l10n.selectionMenuLookupOrTranslate,
            SelectionMenuAction.addToVocabulary =>
              l10n.contextMenuAddToVocabulary,
            SelectionMenuAction.ai => l10n.navBarAI,
            SelectionMenuAction.copy => l10n.contextMenuCopy,
            SelectionMenuAction.webSearch => l10n.contextMenuWebSearch,
            SelectionMenuAction.paragraphTranslate =>
              l10n.contextMenuParagraphTranslate,
            SelectionMenuAction.narrate => l10n.contextMenuNarrate,
            SelectionMenuAction.saveDifficulty =>
              l10n.selectionMenuSaveDifficulty,
            SelectionMenuAction.note => l10n.contextMenuWriteIdea,
            SelectionMenuAction.share => l10n.contextMenuShare,
          };
        }

        void persist() {
          Prefs().selectionMenuActionOrder = order;
          Prefs().enabledSelectionMenuActions = enabled;
        }

        void move(int index, int offset) {
          final target = index + offset;
          if (target < 0 || target >= order.length) return;
          setDialogState(() {
            final next = List<SelectionMenuAction>.from(order);
            final item = next.removeAt(index);
            next.insert(target, item);
            order = next;
            persist();
          });
        }

        return AlertDialog(
          title: Text(L10n.of(context).selectionMenuSettingsTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context).selectionMenuSettingsTips),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: order.length,
                    itemBuilder: (context, index) {
                      final action = order[index];
                      return CheckboxListTile(
                        key: ValueKey('selection-menu-${action.name}'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: enabled.contains(action),
                        title: Text(label(action)),
                        onChanged: (value) {
                          setDialogState(() {
                            enabled = Set<SelectionMenuAction>.from(enabled);
                            if (value == true) {
                              enabled.add(action);
                            } else {
                              enabled.remove(action);
                            }
                            persist();
                          });
                        },
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: L10n.of(context).selectionMenuMoveUp,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed:
                                  index == 0 ? null : () => move(index, -1),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: L10n.of(context).selectionMenuMoveDown,
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed: index == order.length - 1
                                  ? null
                                  : () => move(index, 1),
                              icon: const Icon(Icons.arrow_downward),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Prefs().resetSelectionMenuActions();
                setDialogState(() {
                  order = Prefs().selectionMenuActionOrder;
                  enabled = Prefs().enabledSelectionMenuActions;
                });
              },
              child: Text(L10n.of(context).selectionMenuReset),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(L10n.of(context).commonConfirm),
            ),
          ],
        );
      },
    ),
  );
}
