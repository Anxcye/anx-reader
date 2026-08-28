enum SelectionRangeType {
  word,
  sentence,
  paragraph,
  custom;

  static SelectionRangeType fromCode(Object? value) {
    return values.firstWhere(
      (item) => item.name == value,
      orElse: () => SelectionRangeType.custom,
    );
  }
}

enum SelectionTrigger {
  manual,
  doubleTap,
  longPress,
  contextMenu,
  rangeButton,
  previousSentence,
  nextSentence,
  api;

  static SelectionTrigger fromCode(Object? value) {
    return values.firstWhere(
      (item) => item.name == value,
      orElse: () => SelectionTrigger.manual,
    );
  }
}

class SelectionSnapshot {
  const SelectionSnapshot({
    required this.sessionId,
    required this.rangeType,
    required this.trigger,
    required this.text,
    required this.cfi,
    required this.contextText,
    required this.chapterIndex,
    required this.canMovePrevious,
    required this.canMoveNext,
    required this.supportsRangeSelection,
  });

  final int sessionId;
  final SelectionRangeType rangeType;
  final SelectionTrigger trigger;
  final String text;
  final String cfi;
  final String? contextText;
  final int chapterIndex;
  final bool canMovePrevious;
  final bool canMoveNext;
  final bool supportsRangeSelection;

  factory SelectionSnapshot.fromJson(Map<String, dynamic> json) {
    final context = json['contextText']?.toString();
    return SelectionSnapshot(
      sessionId: (json['sessionId'] as num?)?.toInt() ?? 0,
      rangeType: SelectionRangeType.fromCode(json['rangeType']),
      trigger: SelectionTrigger.fromCode(json['trigger']),
      text: json['text']?.toString().trim() ?? '',
      cfi: json['cfi']?.toString() ?? '',
      contextText: context == null || context.trim().isEmpty ? null : context,
      chapterIndex: (json['index'] as num?)?.toInt() ?? -1,
      canMovePrevious: json['canMovePrevious'] == true,
      canMoveNext: json['canMoveNext'] == true,
      supportsRangeSelection: json['supportsRangeSelection'] == true,
    );
  }
}
