import 'package:anx_reader/models/remote_file.dart';
import 'package:dio/dio.dart';

abstract class SyncClientBase {
  /// Test connection to the remote server
  Future<void> ping();

  /// Create a directory at the given path
  Future<void> mkdir(String path);

  /// List files and directories in the given path
  Future<List<RemoteFile>> readDir(String path);

  /// Remove a file or directory
  Future<void> remove(String path);

  /// Check if a file or directory exists at the given path
  Future<bool> isExist(String path);

  /// Upload a file from local path to remote path
  Future<void> uploadFile(
    String localPath,
    String remotePath, {
    bool replace = true,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  });

  /// Download a file from remote path to local path
  Future<void> downloadFile(
    String remotePath,
    String localPath, {
    void Function(int received, int total)? onProgress,
  });

  /// Safely read directory, create if not exists
  Future<List<RemoteFile>> safeReadDir(String path);

  /// Read file properties, return null if not exists
  Future<RemoteFile?> readProps(String path);

  /// Get the protocol name for this client
  String get protocolName;

  /// Get configuration parameters for this client
  Map<String, dynamic> get config;

  /// Update configuration
  void updateConfig(Map<String, dynamic> newConfig);

  /// Check if the client is properly configured
  bool get isConfigured;
}