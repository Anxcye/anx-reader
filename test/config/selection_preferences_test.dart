import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/long_press_selection_mode.dart';
import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:anx_reader/widgets/context_menu/selection_action_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default gestures separate sentence selection from page animation',
      () async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
    expect(Prefs().swipeToTurnPage, isFalse);
    expect(Prefs().volumeKeyTurnPage, isTrue);

    Prefs().swipeToTurnPage = true;
    Prefs().volumeKeyTurnPage = false;
    Prefs().prefs = await SharedPreferences.getInstance();
    expect(Prefs().swipeToTurnPage, isTrue);
    expect(Prefs().volumeKeyTurnPage, isFalse);
  });

  test('legacy volume choice is retained without enabling swipe page turns',
      () async {
    SharedPreferences.setMockInitialValues({
      'volumeKeyTurnPage': false,
      'pageTurnStyle': 'slide',
      'longPressSelectionMode': 'sentence',
    });
    Prefs().prefs = await SharedPreferences.getInstance();
    expect(Prefs().volumeKeyTurnPage, isFalse);
    expect(Prefs().swipeToTurnPage, isFalse);
    expect(Prefs().pageTurnStyle.name, 'slide');
    expect(Prefs().longPressSelectionMode, LongPressSelectionMode.sentence);
  });

  test('long press selection defaults to word and persists sentence mode',
      () async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();

    expect(Prefs().longPressSelectionMode, LongPressSelectionMode.word);
    Prefs().longPressSelectionMode = LongPressSelectionMode.sentence;

    expect(Prefs().longPressSelectionMode, LongPressSelectionMode.sentence);
    expect(Prefs().prefs.getString('longPressSelectionMode'), 'sentence');
  });

  test('selection menu actions persist order, enabled state, and reset',
      () async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();

    Prefs().selectionMenuActionOrder = const [
      SelectionMenuAction.copy,
      SelectionMenuAction.ai,
    ];
    Prefs().enabledSelectionMenuActions = {
      SelectionMenuAction.copy,
      SelectionMenuAction.ai,
    };

    expect(Prefs().selectionMenuActionOrder.first, SelectionMenuAction.copy);
    expect(Prefs().selectionMenuActionOrder[1], SelectionMenuAction.ai);
    expect(
      Prefs().enabledSelectionMenuActions,
      {SelectionMenuAction.copy, SelectionMenuAction.ai},
    );

    Prefs().resetSelectionMenuActions();
    expect(
      Prefs().enabledSelectionMenuActions,
      SelectionMenuAction.values.toSet(),
    );
  });

  test('legacy custom menu keeps its order and puts new actions in more',
      () async {
    SharedPreferences.setMockInitialValues({
      'selectionMenuActionOrder': [
        'copy',
        'lookupOrTranslate',
        'ai',
        'copy',
        'future'
      ],
      'enabledSelectionMenuActions': ['copy', 'lookupOrTranslate', 'ai'],
    });
    Prefs().prefs = await SharedPreferences.getInstance();
    final order = Prefs().selectionMenuActionOrder;
    final enabled = Prefs().enabledSelectionMenuActions;
    final policy = SelectionActionPolicy.forSelection('word',
        aiEnabled: true,
        vocabularyEnabled: true,
        footnote: false,
        actionOrder: order,
        enabledActions: enabled);

    expect(order.toSet().length, SelectionMenuAction.values.length);
    expect(policy.primaryActions, [
      SelectionMenuAction.copy,
      SelectionMenuAction.lookupOrTranslate,
      SelectionMenuAction.ai,
    ]);
    expect(policy.moreActions, [
      SelectionMenuAction.highlight,
      SelectionMenuAction.bringToQuestion,
    ]);
    expect(enabled, isNot(contains(SelectionMenuAction.note)));
    expect(enabled, isNot(contains(SelectionMenuAction.narrate)));
    expect(Prefs().prefs.getStringList('selectionMenuActionOrder'),
        ['copy', 'lookupOrTranslate', 'ai', 'copy', 'future']);
  });

  test('explicitly disabled new actions stay disabled after reloading prefs',
      () async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
    Prefs().enabledSelectionMenuActions = {SelectionMenuAction.copy};

    Prefs().prefs = await SharedPreferences.getInstance();
    expect(Prefs().enabledSelectionMenuActions, {SelectionMenuAction.copy});
    expect(Prefs().prefs.getStringList('selectionMenuKnownActions'),
        containsAll(['highlight', 'bringToQuestion']));

    Prefs().resetSelectionMenuActions();
    expect(Prefs().prefs.containsKey('selectionMenuKnownActions'), isFalse);
    expect(Prefs().enabledSelectionMenuActions,
        SelectionMenuAction.values.toSet());
    expect(Prefs().selectionMenuActionOrder.take(3), [
      SelectionMenuAction.highlight,
      SelectionMenuAction.lookupOrTranslate,
      SelectionMenuAction.ai,
    ]);
  });
}
