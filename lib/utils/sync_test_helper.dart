import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/service/sync/sync_connection_tester.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';

/// 同步测试辅助工具
class SyncTestHelper {
  /// 在UI中显示测试连接按钮和处理逻辑
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
        label: Text(L10n.of(context).common_test),
      ),
    );
  }

  /// 处理测试连接逻辑
  static Future<void> _handleTestConnection(
    BuildContext context, {
    required SyncProtocol protocol,
    required Map<String, dynamic> config,
    VoidCallback? onTestStart,
    Function(bool success, String message)? onTestComplete,
  }) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('Testting connection...'),
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

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 显示结果
      _showTestResult(context, result);
      
      onTestComplete?.call(result.isSuccess, result.message);

    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      final result = SyncTestResult.failure('测试连接时发生未知错误: $e');
      _showTestResult(context, result);
      
      onTestComplete?.call(false, result.message);
    }
  }

  /// 显示测试结果
  static void _showTestResult(BuildContext context, SyncTestResult result) {
    if (result.isSuccess) {
      AnxToast.show('✅ ${result.message}');
      
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
      AnxToast.show('❌ ${result.message}');
      
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

  /// 为配置表单添加测试连接功能
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