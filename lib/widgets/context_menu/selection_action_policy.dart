import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:anx_reader/service/dictionary/chinese_dictionary.dart';
import 'package:anx_reader/service/dictionary/english_dictionary.dart';

class SelectionActionPolicy {
  const SelectionActionPolicy._({
    required this.isDictionaryLookup,
    required this.primaryActions,
    required this.moreActions,
  });

  final bool isDictionaryLookup;
  final List<SelectionMenuAction> primaryActions;
  final List<SelectionMenuAction> moreActions;

  factory SelectionActionPolicy.forSelection(
    String text, {
    required bool aiEnabled,
    required bool vocabularyEnabled,
    required bool footnote,
    List<SelectionMenuAction>? actionOrder,
    Set<SelectionMenuAction>? enabledActions,
  }) {
    final isDictionaryLookup = EnglishDictionaryService.isEnglishWord(text) ||
        ChineseDictionaryService.isLookupCandidate(text);
    final enabled = enabledActions ?? SelectionMenuAction.values.toSet();
    final ordered = actionOrder ?? SelectionMenuAction.values;
    final eligible = ordered.where((action) {
      if (!enabled.contains(action)) return false;
      if (action == SelectionMenuAction.addToVocabulary) {
        return isDictionaryLookup && vocabularyEnabled;
      }
      if (action == SelectionMenuAction.ai) return aiEnabled;
      if (footnote &&
          (action == SelectionMenuAction.saveDifficulty ||
              action == SelectionMenuAction.note)) {
        return false;
      }
      return true;
    }).toList(growable: false);
    final primary = eligible.take(3).toList(growable: false);
    final more = eligible.skip(3).toList(growable: false);
    return SelectionActionPolicy._(
      isDictionaryLookup: isDictionaryLookup,
      primaryActions: List.unmodifiable(primary),
      moreActions: List.unmodifiable(more),
    );
  }
}
