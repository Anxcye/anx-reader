enum LongPressSelectionMode {
  word,
  sentence;

  static LongPressSelectionMode fromCode(String? value) {
    return values.firstWhere(
      (item) => item.name == value,
      orElse: () => LongPressSelectionMode.sentence,
    );
  }
}
