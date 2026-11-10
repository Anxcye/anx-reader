enum SelectionRangeType {
  character,
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
  swipe,
  contextMenu,
  rangeButton,
  previousSentence,
  nextSentence,
  previousCharacter,
  nextCharacter,
  boundaryAdjustment,
  extendPage,
  undoExtension,
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
    this.revision = 0,
    this.canAdjustStartPrevious = false,
    this.canAdjustStartNext = false,
    this.canAdjustEndPrevious = false,
    this.canAdjustEndNext = false,
    this.canExtendNextPage = false,
    this.canUndoExtension = false,
    this.canShowSelectionEnd = false,
    this.extensionUnavailableReason,
    this.sourceProgress,
    this.visibleFromProgress,
    this.flow = 'paginated',
    this.pointerType = 'unknown',
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
  final int revision;
  final bool canAdjustStartPrevious;
  final bool canAdjustStartNext;
  final bool canAdjustEndPrevious;
  final bool canAdjustEndNext;
  final bool canExtendNextPage;
  final bool canUndoExtension;
  final bool canShowSelectionEnd;
  final String? extensionUnavailableReason;
  final double? sourceProgress;
  final double? visibleFromProgress;
  final String flow;
  final String pointerType;

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
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      canAdjustStartPrevious: json['canAdjustStartPrevious'] == true,
      canAdjustStartNext: json['canAdjustStartNext'] == true,
      canAdjustEndPrevious: json['canAdjustEndPrevious'] == true,
      canAdjustEndNext: json['canAdjustEndNext'] == true,
      canExtendNextPage: json['canExtendNextPage'] == true,
      canUndoExtension: json['canUndoExtension'] == true,
      canShowSelectionEnd: json['canShowSelectionEnd'] == true,
      extensionUnavailableReason:
          json['extensionUnavailableReason']?.toString(),
      sourceProgress: _progress(json['sourceProgress']),
      visibleFromProgress: _progress(json['visibleFromProgress']),
      flow: json['flow']?.toString() ?? 'paginated',
      pointerType: json['pointerType']?.toString() ?? 'unknown',
    );
  }

  static double? _progress(Object? value) =>
      value is num && value.isFinite && value >= 0 && value <= 1
          ? value.toDouble()
          : null;
}
