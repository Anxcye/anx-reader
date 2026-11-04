import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/models/reading_memory.dart';

/// Shared source boundary for practice projections and mutations. A chapter
/// title or the reader's latest progress cannot establish an older source.
abstract final class ReadingMemoryProjection {
  static double? sourceBoundary(
      ReadingMemorySource source, BookMaterialsSnapshot materials) {
    if (source.bookId != materials.bookId || !source.isAvailable) return null;
    double? progress;
    if (source.type == ReadingMemorySourceType.readingNote) {
      final note = materials.items
          .map((item) => item.noteItem)
          .nonNulls
          .where((item) => item.document?.note.id == source.sourceRef)
          .firstOrNull;
      if (note == null) return null;
      progress = 0;
      for (final ref in note.document!.sources) {
        final explicit = ref.metadata['visibleFromProgress'];
        final atSource = ref.metadata['sourceProgress'];
        double? boundary = explicit is num ? explicit.toDouble() : null;
        if (atSource is num && (boundary == null || atSource > boundary)) {
          boundary = atSource.toDouble();
        }
        boundary ??= materials.sourceBoundaries[ref.cfi] ??
            materials.sourceBoundaries[ref.sourceRef];
        if (boundary == null || !boundary.isFinite) return null;
        if (boundary > progress!) progress = boundary;
      }
    } else {
      progress = materials.sourceBoundaries[source.cfi];
    }
    return progress != null &&
            progress.isFinite &&
            progress >= 0 &&
            progress <= materials.visibleAtProgress + .000001
        ? progress
        : null;
  }
}
