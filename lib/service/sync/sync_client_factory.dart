import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/service/sync/webdav_client.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';

class SyncClientFactory {
  static final SyncClientFactory _instance = SyncClientFactory._internal();
  factory SyncClientFactory() => _instance;
  SyncClientFactory._internal();

  static SyncClientBase? _currentClient;

  /// Get the current configured sync client
  static SyncClientBase? get currentClient => _currentClient;

  /// Create a sync client based on protocol type and configuration
  static SyncClientBase createClient(
    SyncProtocol protocol,
    Map<String, dynamic> config,
  ) {
    switch (protocol) {
      case SyncProtocol.webdav:
        return WebdavClient(
          url: config['url'] ?? '',
          username: config['username'] ?? '',
          password: config['password'] ?? '',
        );
      case SyncProtocol.ftp:
        throw UnimplementedError('FTP client not implemented yet');
      case SyncProtocol.s3:
        throw UnimplementedError('S3 client not implemented yet');
      case SyncProtocol.googleDrive:
        throw UnimplementedError('Google Drive client not implemented yet');
      case SyncProtocol.oneDrive:
        throw UnimplementedError('OneDrive client not implemented yet');
      case SyncProtocol.dropbox:
        throw UnimplementedError('Dropbox client not implemented yet');
    }
  }

  /// Initialize the current client based on user preferences
  static void initializeCurrentClient() {
    final protocol = getCurrentSyncProtocol();
    final config = getConfigForProtocol(protocol);

    if (config.isNotEmpty) {
      _currentClient = createClient(protocol, config);
    }
  }

  /// Get the currently selected sync protocol from preferences
  static SyncProtocol getCurrentSyncProtocol() {
    final protocolName = Prefs().syncProtocol ?? 'webdav';
    return SyncProtocol.values.firstWhere(
      (p) => p.name == protocolName,
      orElse: () => SyncProtocol.webdav,
    );
  }

  /// Get configuration for a specific protocol
  static Map<String, dynamic> getConfigForProtocol(SyncProtocol protocol) {
    return Prefs().getSyncInfo(protocol);
  }

  /// Update the current client configuration
  static void updateCurrentClientConfig(Map<String, dynamic> newConfig) {
    _currentClient?.updateConfig(newConfig);

    // Save to preferences
    final protocol = getCurrentSyncProtocol();
    saveConfigForProtocol(protocol, newConfig);
  }

  /// Save configuration for a specific protocol
  static void saveConfigForProtocol(
      SyncProtocol protocol, Map<String, dynamic> config) {
    Prefs().setSyncInfo(protocol, config);
  }

  /// Switch to a different sync protocol
  static void switchProtocol(SyncProtocol newProtocol) {
    Prefs().syncProtocol = newProtocol.name;
    initializeCurrentClient();
  }

  /// Check if current client is configured and ready
  static bool get isCurrentClientReady {
    return _currentClient?.isConfigured ?? false;
  }

  /// Get list of available sync protocols
  static List<SyncProtocol> get availableProtocols {
    return [
      SyncProtocol.webdav,
      // Add other protocols as they are implemented
      // SyncProtocol.ftp,
      // SyncProtocol.s3,
      // SyncProtocol.googleDrive,
      // SyncProtocol.oneDrive,
      // SyncProtocol.dropbox,
    ];
  }

  /// Reset current client (for logout or configuration changes)
  static void resetCurrentClient() {
    _currentClient = null;
  }
}
