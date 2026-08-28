import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/long_press_selection_mode.dart';
import 'package:anx_reader/enums/selection_menu_action.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('long press selection defaults to sentence and persists word mode',
      () async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();

    expect(Prefs().longPressSelectionMode, LongPressSelectionMode.sentence);
    Prefs().longPressSelectionMode = LongPressSelectionMode.word;

    expect(Prefs().longPressSelectionMode, LongPressSelectionMode.word);
    expect(Prefs().prefs.getString('longPressSelectionMode'), 'word');
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
}
