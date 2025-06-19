import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/sync/sync_connection_tester.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

class SyncTestHelper {
  static Widget buildTestConnectionButton({
    required SyncProtocol protocol,
    required Map<String, dynamic> config,
    VoidCallback? onTestStart,
    Function(bool success, String message)? onTestComplete,
  }) {
    return Builder(
      builder: (context) => TextButton.icon(
        onPressed: () => _handleTestConnection(
          context,
          protocol: protocol,
          config: config,
          onTestStart: onTestStart,
          onTestComplete: onTestComplete,
        ),
        icon: const Icon(Icons.wifi_find),
        label: Text(L10n.of(context).settings_sync_webdav_test_connection),
      ),
    );
  }

  static Future<void> _handleTestConnection(
    BuildContext context, {
    required SyncProtocol protocol,
    required Map<String, dynamic> config,
    VoidCallback? onTestStart,
    Function(bool success, String message)? onTestComplete,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(L10n.of(context).testingConnection),
          ],
        ),
      ),
    );

    onTestStart?.call();

    try {
      final result = await SyncConnectionTester.testConnection(
        protocol: protocol,
        config: config,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      _showTestResult(navigatorKey.currentContext!, result);

      onTestComplete?.call(result.isSuccess, result.message);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final result = SyncTestResult.failure(
          L10n.of(navigatorKey.currentContext!)
                  .unknownErrorWhenTestingConnection +
              e.toString());
      _showTestResult(navigatorKey.currentContext!, result);

      onTestComplete?.call(false, result.message);
    }
  }

  static void _showTestResult(BuildContext context, SyncTestResult result) {
    if (result.isSuccess) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(L10n.of(context).common_success),
            ],
          ),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context).common_ok),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(L10n.of(context).common_failed),
            ],
          ),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context).common_ok),
            ),
          ],
        ),
      );
    }
  }

  static Widget buildConfigFormWithTest({
    required Widget configForm,
    required SyncProtocol protocol,
    required Map<String, dynamic> Function() getConfig,
    VoidCallback? onTestSuccess,
  }) {
    return Column(
      children: [
        configForm,
        const SizedBox(height: 16),
        buildTestConnectionButton(
          protocol: protocol,
          config: getConfig(),
          onTestComplete: (success, message) {
            if (success) {
              onTestSuccess?.call();
            }
          },
        ),
      ],
    );
  }
}
