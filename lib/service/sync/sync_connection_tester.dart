import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/sync/sync_client_factory.dart';
import 'package:anx_reader/utils/log/common.dart';

/// Utility class for testing sync connections
class SyncConnectionTester {
  /// Test connection result
  static Future<SyncTestResult> testConnection({
    required SyncProtocol protocol,
    required Map<String, dynamic> config,
  }) async {
    try {
      // Create client with temporary configuration
      final client = SyncClientFactory.createClient(protocol, config);

      // Verify if configuration is complete
      if (!client.isConfigured) {
        return SyncTestResult.failure(L10n.of(navigatorKey.currentContext!)
            .configurationInformationIsIncomplete);
      }

      // Execute ping test
      await client.ping();

      AnxLog.info('${protocol.displayName} connection test successful');
      return SyncTestResult.success(L10n.of(navigatorKey.currentContext!)
          .connectionSuccessful);
    } catch (e) {
      final errorMessage = '${_getErrorMessage(e)}\n$e';
      AnxLog.severe(
          '${protocol.displayName} connection test failed: $errorMessage');
      return SyncTestResult.failure(errorMessage);
    }
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    final context = navigatorKey.currentContext!;

    if (errorStr.contains('timeout') ||
        errorStr.contains('connection timeout')) {
      return L10n.of(context).connectionTimeout;
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return L10n.of(context).testUnauthorized;
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return L10n.of(context).testForbidden;
    }

    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return L10n.of(context).testNotFound;
    }

    if (errorStr.contains('connection refused') ||
        errorStr.contains('connection failed')) {
      return L10n.of(context).testRefused;
    }

    if (errorStr.contains('certificate') ||
        errorStr.contains('ssl') ||
        errorStr.contains('tls')) {
      return L10n.of(context).testSsl;
    }

    if (errorStr.contains('dns') || errorStr.contains('resolve')) {
      return L10n.of(context).testDnd;
    }

    // Return original error message (but remove overly technical parts)
    return L10n.of(context).testOther;
  }
}

/// Test result class
class SyncTestResult {
  final bool isSuccess;
  final String message;

  const SyncTestResult._({
    required this.isSuccess,
    required this.message,
  });

  /// Create success result
  factory SyncTestResult.success(String message) {
    return SyncTestResult._(isSuccess: true, message: message);
  }

  /// Create failure result
  factory SyncTestResult.failure(String message) {
    return SyncTestResult._(isSuccess: false, message: message);
  }
}
