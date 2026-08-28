import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/ai/reading_device_identity.dart';
import 'package:anx_reader/service/sync/cloudbase_reading_sync_transport.dart';
import 'package:anx_reader/service/sync/reading_agent_sync_service.dart';

class CloudBaseReadingSyncCoordinator {
  const CloudBaseReadingSyncCoordinator();

  static Future<void>? _inFlight;

  Future<void> synchronize() {
    return _inFlight ??= _synchronize().whenComplete(() => _inFlight = null);
  }

  Future<void> _synchronize() async {
    final prefs = Prefs();
    if (!prefs.cloudBaseSyncEnabled) return;
    final endpoint = prefs.cloudBaseSyncEndpoint.trim();
    final accountToken = prefs.cloudBaseSyncAccountToken.trim();
    if (endpoint.isEmpty || accountToken.isEmpty) {
      throw StateError('CloudBase Reading Sync is not configured');
    }
    final deviceId = await ReadingDeviceIdentity().getOrCreate();
    final transport = CloudBaseReadingSyncTransport(
      endpoint: endpoint,
      accessToken: accountToken,
    );
    await ReadingAgentSyncService(deviceId: deviceId)
        .synchronizeWithTransport(transport);
  }
}
