import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:uuid/uuid.dart';

class ReadingDeviceIdentity {
  ReadingDeviceIdentity({Prefs? prefs, Uuid? uuid})
      : _prefs = prefs ?? Prefs(),
        _uuid = uuid ?? const Uuid();

  static const preferenceKey = 'readingAgentSyncDeviceId';

  final Prefs _prefs;
  final Uuid _uuid;

  Future<String> getOrCreate() async {
    final existing = _prefs.prefs.getString(preferenceKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _uuid.v4();
    await _prefs.prefs.setString(preferenceKey, created);
    return created;
  }
}
