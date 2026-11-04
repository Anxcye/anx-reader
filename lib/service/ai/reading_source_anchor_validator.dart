import 'package:anx_reader/models/reading_agent.dart';

abstract final class ReadingSourceAnchorValidator {
  static void validate(ReadingArtifact anchor) {
    final kind = anchor.payload['sourceKind'];
    final id = anchor.payload['sourceId'];
    final cfi = anchor.sourceStartCfi;
    final checkpointBound =
        const {'checkpoint', 'mastery', 'knowledgeCard'}.contains(kind) &&
            anchor.payload['checkpointId'] is String &&
            (anchor.payload['checkpointId'] as String).isNotEmpty &&
            anchor.chapterHref?.isNotEmpty == true;
    if (anchor.kind != ReadingArtifactKinds.sourceAnchor ||
        anchor.bookId <= 0 ||
        kind is! String ||
        kind.trim().isEmpty ||
        id is! String ||
        id.trim().isEmpty ||
        (!checkpointBound &&
            (cfi == null ||
                !cfi.startsWith('epubcfi(') ||
                !cfi.endsWith(')'))) ||
        !anchor.sourceProgress.isFinite ||
        !anchor.visibleFromProgress.isFinite ||
        anchor.sourceProgress < 0 ||
        anchor.visibleFromProgress < anchor.sourceProgress ||
        anchor.visibleFromProgress > 1) {
      throw ArgumentError(
          'A source anchor requires identity, a verified location and progress');
    }
  }
}
