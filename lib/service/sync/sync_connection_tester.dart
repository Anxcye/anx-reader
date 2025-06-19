import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/service/sync/sync_client_factory.dart';
import 'package:anx_reader/utils/log/common.dart';

/// 用于测试同步连接的工具类
class SyncConnectionTester {
  /// 测试连接结果
  static Future<SyncTestResult> testConnection({
    required SyncProtocol protocol,
    required Map<String, dynamic> config,
  }) async {
    try {
      // 使用临时配置创建客户端
      final client = SyncClientFactory.createClient(protocol, config);
      
      // 验证配置是否完整
      if (!client.isConfigured) {
        return SyncTestResult.failure('配置信息不完整');
      }
      
      // 执行ping测试
      await client.ping();
      
      AnxLog.info('${protocol.displayName} connection test successful');
      return SyncTestResult.success('连接成功');
      
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      AnxLog.severe('${protocol.displayName} connection test failed: $errorMessage');
      return SyncTestResult.failure(errorMessage);
    }
  }
  
  /// 获取用户友好的错误信息
  static String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('timeout') || errorStr.contains('connection timeout')) {
      return '连接超时，请检查网络或服务器地址';
    }
    
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return '用户名或密码错误';
    }
    
    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return '访问被拒绝，请检查权限设置';
    }
    
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return '服务器地址不存在或路径错误';
    }
    
    if (errorStr.contains('connection refused') || errorStr.contains('connection failed')) {
      return '无法连接到服务器，请检查网络和服务器状态';
    }
    
    if (errorStr.contains('certificate') || errorStr.contains('ssl') || errorStr.contains('tls')) {
      return 'SSL证书验证失败，请检查HTTPS配置';
    }
    
    if (errorStr.contains('dns') || errorStr.contains('resolve')) {
      return 'DNS解析失败，请检查域名是否正确';
    }
    
    // 返回原始错误信息（但去掉过于技术性的部分）
    return error.toString().replaceAll(RegExp(r'Exception: |Error: '), '');
  }
}

/// 测试结果类
class SyncTestResult {
  final bool isSuccess;
  final String message;
  
  const SyncTestResult._({
    required this.isSuccess,
    required this.message,
  });
  
  /// 创建成功结果
  factory SyncTestResult.success(String message) {
    return SyncTestResult._(isSuccess: true, message: message);
  }
  
  /// 创建失败结果
  factory SyncTestResult.failure(String message) {
    return SyncTestResult._(isSuccess: false, message: message);
  }
}