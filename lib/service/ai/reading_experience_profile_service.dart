import 'package:anx_reader/dao/reading_agent.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';

/// Synchronized per-book profile store with a small session cache for the
/// synchronous reader/UI policy lookup path.
class ReadingExperienceProfileService {
  ReadingExperienceProfileService({
    ReadingAgentDao? dao,
    int Function()? clock,
  })  : _dao = dao ?? readingAgentDao,
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final ReadingAgentDao _dao;
  final int Function() _clock;
  final Map<int, BookReadingProfile> _cache = {};

  BookReadingProfile? cached(int bookId) => _cache[bookId];

  String? pinnedModuleId(int bookId) {
    final profile = cached(bookId);
    return profile?.pinned == true ? profile!.primaryModuleId : null;
  }

  Future<BookReadingProfile> loadOrCreate({
    required int bookId,
    required String detectedModuleId,
    List<String> detectedFacets = const [],
    double confidence = 0.6,
    String? legacyPreference,
  }) async {
    final cachedValue = _cache[bookId];
    if (cachedValue != null) return cachedValue;
    final stored = await _dao.bookReadingProfile(bookId);
    if (stored != null) {
      // Content facets are additive metadata. Upgrade an older profile with
      // newly registered genre signals (notably fiction.suspense) while
      // preserving the user's pinned primary closure and existing confidence.
      final mergedFacets = <String>{...stored.facets, ...detectedFacets};
      if (mergedFacets.length != stored.facets.length) {
        final upgraded = stored.copyWith(
          facets: mergedFacets.toList(growable: false)..sort(),
          updatedAt: _clock(),
        );
        await _dao.saveBookReadingProfile(upgraded);
        _cache[bookId] = upgraded;
        return upgraded;
      }
      _cache[bookId] = stored;
      return stored;
    }
    final now = _clock();
    final legacyId = ReadingClosureIds.normalize(legacyPreference);
    final profile = BookReadingProfile(
      bookId: bookId,
      primaryModuleId: legacyId ?? detectedModuleId,
      facets: detectedFacets,
      confidence: legacyId == null ? confidence.clamp(0, 1) : 1,
      pinned: legacyId != null,
      matchSource: legacyId == null
          ? BookReadingProfileMatchSource.metadata
          : BookReadingProfileMatchSource.legacyPreference,
      createdAt: now,
      updatedAt: now,
    );
    await _dao.saveBookReadingProfile(profile);
    _cache[bookId] = profile;
    return profile;
  }

  Future<BookReadingProfile> setPinned({
    required int bookId,
    required String moduleId,
    List<String>? facets,
  }) async {
    final now = _clock();
    final previous = _cache[bookId] ?? await _dao.bookReadingProfile(bookId);
    final profile = BookReadingProfile(
      bookId: bookId,
      primaryModuleId: ReadingClosureIds.normalize(moduleId) ?? moduleId,
      facets: facets ?? previous?.facets ?? const [],
      confidence: 1,
      pinned: true,
      matchSource: BookReadingProfileMatchSource.user,
      schemaVersion: previous?.schemaVersion ?? 1,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    await _dao.saveBookReadingProfile(profile);
    _cache[bookId] = profile;
    return profile;
  }

  Future<BookReadingProfile> setAutomatic({
    required int bookId,
    required String detectedModuleId,
    List<String> detectedFacets = const [],
    double confidence = 0.6,
  }) async {
    final now = _clock();
    final previous = _cache[bookId] ?? await _dao.bookReadingProfile(bookId);
    final profile = BookReadingProfile(
      bookId: bookId,
      primaryModuleId: detectedModuleId,
      facets: detectedFacets,
      confidence: confidence.clamp(0, 1),
      pinned: false,
      matchSource: BookReadingProfileMatchSource.metadata,
      schemaVersion: previous?.schemaVersion ?? 1,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    await _dao.saveBookReadingProfile(profile);
    _cache[bookId] = profile;
    return profile;
  }

  void invalidate(int bookId) => _cache.remove(bookId);
  void clearCache() => _cache.clear();
}

final readingExperienceProfileService = ReadingExperienceProfileService();
