import 'package:anx_reader/widgets/context_menu/selection_action_policy.dart';
import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('word selection prioritizes explicit mark, lookup, and explanation', () {
    final policy = SelectionActionPolicy.forSelection(
      'reading',
      aiEnabled: true,
      vocabularyEnabled: true,
      footnote: false,
    );

    expect(policy.isDictionaryLookup, isTrue);
    expect(policy.primaryActions, [
      SelectionMenuAction.highlight,
      SelectionMenuAction.lookupOrTranslate,
      SelectionMenuAction.ai,
    ]);
    expect(policy.moreActions, contains(SelectionMenuAction.copy));
    expect(policy.moreActions, contains(SelectionMenuAction.saveDifficulty));
  });

  test(
      'passage selection prioritizes explicit mark, translation, and explanation',
      () {
    final policy = SelectionActionPolicy.forSelection(
      'A selected sentence with several words.',
      aiEnabled: true,
      vocabularyEnabled: true,
      footnote: false,
    );

    expect(policy.isDictionaryLookup, isFalse);
    expect(policy.primaryActions, [
      SelectionMenuAction.highlight,
      SelectionMenuAction.lookupOrTranslate,
      SelectionMenuAction.ai,
    ]);
  });

  test('disabled capabilities and footnotes remove unavailable actions', () {
    final policy = SelectionActionPolicy.forSelection(
      '词语',
      aiEnabled: false,
      vocabularyEnabled: false,
      footnote: true,
    );

    expect(policy.primaryActions, isNot(contains(SelectionMenuAction.ai)));
    expect(
      policy.primaryActions,
      isNot(contains(SelectionMenuAction.addToVocabulary)),
    );
    expect(policy.moreActions, isNot(contains(SelectionMenuAction.note)));
    expect(
      policy.moreActions,
      isNot(contains(SelectionMenuAction.saveDifficulty)),
    );
  });

  test('user configuration hides actions and controls their order', () {
    final policy = SelectionActionPolicy.forSelection(
      'A selected sentence with several words.',
      aiEnabled: true,
      vocabularyEnabled: true,
      footnote: false,
      actionOrder: const [
        SelectionMenuAction.copy,
        SelectionMenuAction.note,
        SelectionMenuAction.ai,
        SelectionMenuAction.webSearch,
        SelectionMenuAction.paragraphTranslate,
        SelectionMenuAction.saveDifficulty,
        SelectionMenuAction.lookupOrTranslate,
        SelectionMenuAction.addToVocabulary,
        SelectionMenuAction.narrate,
        SelectionMenuAction.share,
      ],
      enabledActions: SelectionMenuAction.values
          .where((action) =>
              action != SelectionMenuAction.webSearch &&
              action != SelectionMenuAction.paragraphTranslate &&
              action != SelectionMenuAction.saveDifficulty)
          .toSet(),
    );

    expect(policy.primaryActions, [
      SelectionMenuAction.copy,
      SelectionMenuAction.note,
      SelectionMenuAction.ai,
    ]);
    expect(policy.moreActions, isNot(contains(SelectionMenuAction.webSearch)));
    expect(
      policy.moreActions,
      isNot(contains(SelectionMenuAction.paragraphTranslate)),
    );
    expect(
      policy.moreActions,
      isNot(contains(SelectionMenuAction.saveDifficulty)),
    );
  });
}
