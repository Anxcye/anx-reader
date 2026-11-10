enum SelectionMenuAction {
  highlight,
  lookupOrTranslate,
  ai,
  addToVocabulary,
  copy,
  webSearch,
  paragraphTranslate,
  narrate,
  saveDifficulty,
  note,
  share,
  bringToQuestion;

  static List<SelectionMenuAction> decodeOrder(List<String>? values) {
    final decoded = <SelectionMenuAction>[];
    for (final value in values ?? const <String>[]) {
      for (final action in SelectionMenuAction.values) {
        if (action.name == value && !decoded.contains(action)) {
          decoded.add(action);
          break;
        }
      }
    }
    for (final action in SelectionMenuAction.values) {
      if (!decoded.contains(action)) decoded.add(action);
    }
    return decoded;
  }
}
