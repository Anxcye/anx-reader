/// Best-effort structural parser for long books. It never assumes that an
/// EPUB has a reliable TOC: when volume/arc headings cannot be recognised it
/// returns ordinary chapters and the extraction pipeline can continue.
class ReadingStructureParser {
  const ReadingStructureParser();

  ReadingStructure parse(Iterable<ReadingStructureChapter> chapters) {
    final input = chapters.toList(growable: false);
    final seriesCounts = <String, int>{};
    for (final chapter in input) {
      final base = _seriesWorkBase(chapter.title.trim());
      if (base != null && chapter.tocDepth == 0) {
        seriesCounts.update(base, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final result = <ReadingStructureUnit>[];
    String? workId;
    String? workTitle;
    String? volumeId;
    String? arcId;
    var volumeIndex = 0;
    var arcIndex = 0;
    for (final chapter in input) {
      final title = chapter.title.trim();
      final seriesBase = _seriesWorkBase(title);
      final startsWork = chapter.tocDepth == 0 &&
          !isNonStoryTitle(title) &&
          !_volumePattern.hasMatch(title) &&
          (chapter.hasChildren ||
              (seriesBase != null && (seriesCounts[seriesBase] ?? 0) >= 2));
      if (startsWork) {
        workId = 'work-${_stableHrefToken(chapter.href)}';
        workTitle = title;
        volumeId = null;
        arcId = null;
        volumeIndex = 0;
        arcIndex = 0;
      }
      final volume = _volumePattern.firstMatch(title);
      if (volume != null) {
        volumeIndex++;
        arcIndex = 0;
        volumeId = 'volume-$volumeIndex';
        arcId = null;
      }
      final arc =
          (workId == null ? _legacyArcPattern : _casePattern).firstMatch(title);
      if (arc != null) {
        arcIndex++;
        arcId = [
          if (workId != null) workId,
          volumeId ?? 'volume-1',
          'arc-$arcIndex',
        ].join('-');
      }
      result.add(ReadingStructureUnit(
        chapter: chapter,
        workId: workId,
        workTitle: workTitle,
        volumeId: volumeId,
        arcId: arcId,
        sceneId: 'scene-${chapter.href.split('#').first}',
      ));
    }
    return ReadingStructure(result);
  }

  static final _volumePattern = RegExp(
    r'(?:第\s*[一二三四五六七八九十百\d]+\s*[册卷部篇]|(?:卷|册|部)\s*[一二三四五六七八九十\d]+|(?:上|中|下)部|[（(]\s*[一二三四五六七八九十\d]+\s*[）)])',
    caseSensitive: false,
  );
  static final _casePattern = RegExp(
    r'(?:第\s*[一二三四五六七八九十百\d]+\s*案|(?:案件|案)\s*[一二三四五六七八九十\d]+)',
    caseSensitive: false,
  );
  static final _legacyArcPattern = RegExp(
    r'(?:第\s*[一二三四五六七八九十百\d]+\s*(?:案|章|节|回)|(?:案件|案)\s*[一二三四五六七八九十\d]+)',
    caseSensitive: false,
  );

  static bool isNonStoryTitle(String title) {
    final normalized = title.replaceAll(RegExp(r'\s+'), '').trim();
    return const {
          '封面',
          '版权',
          '版权信息',
          '目录',
          '前言',
          '序言',
          '作者简介',
          '译者序',
          '编者按',
          '后记',
          'Contents',
          'contents',
        }.contains(title) ||
        {'序言', '前言', '目录'}.contains(normalized);
  }

  static String? _seriesWorkBase(String title) {
    final match = RegExp(
      r'^(.{1,40}?)\s*(?:[ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ]+|I{1,3}|IV|V|VI{0,3}|IX|X)(?:\s*[·:：—-].*)?$',
      caseSensitive: false,
    ).firstMatch(title);
    final base = match?.group(1)?.trim().toLowerCase();
    return base == null || base.isEmpty ? null : base;
  }

  static String _stableHrefToken(String href) {
    final path = href.split('#').first.trim().toLowerCase();
    final token = path
        .replaceAll(RegExp(r'[^a-z0-9\u3400-\u9fff]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return token.isEmpty ? 'unknown' : token;
  }
}

class ReadingStructureChapter {
  const ReadingStructureChapter({
    required this.href,
    required this.title,
    this.startProgress = 0,
    this.tocDepth = 0,
    this.hasChildren = false,
  });
  final String href;
  final String title;
  final double startProgress;
  final int tocDepth;
  final bool hasChildren;
}

class ReadingStructureUnit {
  const ReadingStructureUnit({
    required this.chapter,
    required this.workId,
    required this.workTitle,
    required this.volumeId,
    required this.arcId,
    required this.sceneId,
  });
  final ReadingStructureChapter chapter;
  final String? workId;
  final String? workTitle;
  final String? volumeId;
  final String? arcId;
  final String sceneId;
}

class ReadingStructure {
  const ReadingStructure(this.units);
  final List<ReadingStructureUnit> units;
  bool get hasHierarchy =>
      units.any((item) => item.volumeId != null || item.arcId != null);
  bool get usedFallback => !hasHierarchy && units.isNotEmpty;
}
