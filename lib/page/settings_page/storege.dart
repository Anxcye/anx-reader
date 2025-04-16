import 'dart:io';
import 'dart:math';

import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';
import 'package:anx_reader/utils/get_path/log_file.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for storage information
final storageInfoProvider = FutureProvider((ref) async {
  return StorageInfo(
    databaseSize: await calculateDatabaseSize(),
    booksSize: await calculateBooksSize(),
    fontSize: await calculateFontSize(),
    cacheSize: await calculateCacheSize(),
    logSize: await calculateLogSize(),
  );
});

class StorageInfo {
  final int databaseSize;
  final int booksSize;
  final int fontSize;
  final int cacheSize;
  final int logSize;

  StorageInfo({
    required this.databaseSize,
    required this.booksSize,
    required this.fontSize,
    required this.cacheSize,
    required this.logSize,
  });

  int get totalSize => databaseSize + booksSize + fontSize + cacheSize + logSize;
}

class StorageSettings extends ConsumerStatefulWidget {
  const StorageSettings({super.key});

  @override
  ConsumerState<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends ConsumerState<StorageSettings> {
  @override
  Widget build(BuildContext context) {
    final storageInfoAsync = ref.watch(storageInfoProvider);

    return settingsSections(sections: [
      SettingsSection(
        title: const Text('应用存储统计'),
        tiles: [
          CustomSettingsTile(
            child: StorageSummaryTile(
              storageInfoAsync: storageInfoAsync,
            ),
          ),
        ],
      ),
      SettingsSection(
        title: const Text('数据库文件'),
        tiles: [
          CustomSettingsTile(
            child: DatabaseStorageTile(
              storageInfoAsync: storageInfoAsync,
            ),
          ),
        ],
      ),
      SettingsSection(
        title: const Text('书籍文件'),
        tiles: [
          CustomSettingsTile(
            child: BooksStorageTile(
              storageInfoAsync: storageInfoAsync,
            ),
          ),
        ],
      ),
      SettingsSection(
        title: const Text('字体文件'),
        tiles: [
          CustomSettingsTile(
            child: FontsStorageTile(
              storageInfoAsync: storageInfoAsync,
            ),
          ),
        ],
      ),
      SettingsSection(
        title: const Text('缓存文件'),
        tiles: [
          CustomSettingsTile(
            child: CacheStorageTile(
              storageInfoAsync: storageInfoAsync,
              onClearCache: () async {
                await clearCache();
                ref.refresh(storageInfoProvider);
              },
            ),
          ),
        ],
      ),
      SettingsSection(
        title: const Text('日志文件'),
        tiles: [
          CustomSettingsTile(
            child: LogStorageTile(
              storageInfoAsync: storageInfoAsync,
            ),
          ),
        ],
      ),
    ]);
  }
}

class StorageSummaryTile extends StatelessWidget {
  final AsyncValue<StorageInfo> storageInfoAsync;

  const StorageSummaryTile({super.key, required this.storageInfoAsync});

  @override
  Widget build(BuildContext context) {
    return storageInfoAsync.when(
      data: (info) {
        return ListTile(
          title: const Text('总存储空间使用'),
          subtitle: Text('${formatSize(info.totalSize)}'),
        );
      },
      loading: () => const ListTile(
        title: Text('总存储空间使用'),
        subtitle: Text('计算中...'),
      ),
      error: (error, _) => ListTile(
        title: const Text('总存储空间使用'),
        subtitle: Text('计算错误: $error'),
      ),
    );
  }
}

class DatabaseStorageTile extends StatelessWidget {
  final AsyncValue<StorageInfo> storageInfoAsync;

  const DatabaseStorageTile({super.key, required this.storageInfoAsync});

  @override
  Widget build(BuildContext context) {
    return storageInfoAsync.when(
      data: (info) {
        return ListTile(
          title: const Text('数据库大小'),
          subtitle: Text('${formatSize(info.databaseSize)}'),
          trailing: const Icon(Icons.storage),
          onTap: () async {
            // Show database files in dialog
            final databaseFiles = await listDatabaseFiles();
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('数据库文件详情'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: databaseFiles.length,
                      itemBuilder: (context, index) {
                        final file = databaseFiles[index];
                        return ListTile(
                          title: Text(file.path.split(Platform.pathSeparator).last),
                          subtitle: Text(formatSize(file.lengthSync())),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
      loading: () => const ListTile(
        title: Text('数据库大小'),
        subtitle: Text('计算中...'),
      ),
      error: (error, _) => ListTile(
        title: const Text('数据库大小'),
        subtitle: Text('计算错误: $error'),
      ),
    );
  }
}

class BooksStorageTile extends StatelessWidget {
  final AsyncValue<StorageInfo> storageInfoAsync;

  const BooksStorageTile({super.key, required this.storageInfoAsync});

  @override
  Widget build(BuildContext context) {
    return storageInfoAsync.when(
      data: (info) {
        return ListTile(
          title: const Text('书籍文件大小'),
          subtitle: Text('${formatSize(info.booksSize)}'),
          trailing: const Icon(Icons.book),
          onTap: () async {
            // Show book files in dialog
            final bookFiles = await listBookFiles();
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('书籍文件详情'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: bookFiles.length,
                      itemBuilder: (context, index) {
                        final file = bookFiles[index];
                        return ListTile(
                          title: Text(file.path.split(Platform.pathSeparator).last),
                          subtitle: Text(formatSize(file.lengthSync())),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
      loading: () => const ListTile(
        title: Text('书籍文件大小'),
        subtitle: Text('计算中...'),
      ),
      error: (error, _) => ListTile(
        title: const Text('书籍文件大小'),
        subtitle: Text('计算错误: $error'),
      ),
    );
  }
}

class FontsStorageTile extends StatelessWidget {
  final AsyncValue<StorageInfo> storageInfoAsync;

  const FontsStorageTile({super.key, required this.storageInfoAsync});

  @override
  Widget build(BuildContext context) {
    return storageInfoAsync.when(
      data: (info) {
        return ListTile(
          title: const Text('字体文件大小'),
          subtitle: Text('${formatSize(info.fontSize)}'),
          trailing: const Icon(Icons.font_download),
          onTap: () async {
            // Show font files in dialog
            final fontFiles = await listFontFiles();
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('字体文件详情'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: fontFiles.length,
                      itemBuilder: (context, index) {
                        final file = fontFiles[index];
                        return ListTile(
                          title: Text(file.path.split(Platform.pathSeparator).last),
                          subtitle: Text(formatSize(file.lengthSync())),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
      loading: () => const ListTile(
        title: Text('字体文件大小'),
        subtitle: Text('计算中...'),
      ),
      error: (error, _) => ListTile(
        title: const Text('字体文件大小'),
        subtitle: Text('计算错误: $error'),
      ),
    );
  }
}

class CacheStorageTile extends StatelessWidget {
  final AsyncValue<StorageInfo> storageInfoAsync;
  final VoidCallback onClearCache;

  const CacheStorageTile({
    super.key,
    required this.storageInfoAsync,
    required this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    return storageInfoAsync.when(
      data: (info) {
        return ListTile(
          title: const Text('缓存文件大小'),
          subtitle: Text('${formatSize(info.cacheSize)}'),
          trailing: ElevatedButton(
            onPressed: onClearCache,
            child: const Text('清空缓存'),
          ),
        );
      },
      loading: () => const ListTile(
        title: Text('缓存文件大小'),
        subtitle: Text('计算中...'),
      ),
      error: (error, _) => ListTile(
        title: const Text('缓存文件大小'),
        subtitle: Text('计算错误: $error'),
      ),
    );
  }
}

class LogStorageTile extends StatelessWidget {
  final AsyncValue<StorageInfo> storageInfoAsync;

  const LogStorageTile({super.key, required this.storageInfoAsync});

  @override
  Widget build(BuildContext context) {
    return storageInfoAsync.when(
      data: (info) {
        return ListTile(
          title: const Text('日志文件大小'),
          subtitle: Text('${formatSize(info.logSize)}'),
          trailing: const Icon(Icons.article),
        );
      },
      loading: () => const ListTile(
        title: Text('日志文件大小'),
        subtitle: Text('计算中...'),
      ),
      error: (error, _) => ListTile(
        title: const Text('日志文件大小'),
        subtitle: Text('计算错误: $error'),
      ),
    );
  }
}

// Helper functions for calculating storage

Future<int> calculateDatabaseSize() async {
  try {
    final databaseDir = await getAnxDataBasesDir();
    if (!databaseDir.existsSync()) {
      return 0;
    }
    
    int totalSize = 0;
    final entities = databaseDir.listSync();
    for (var entity in entities) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    }
    
    return totalSize;
  } catch (e) {
    debugPrint('Error calculating database size: $e');
    return 0;
  }
}

Future<List<File>> listDatabaseFiles() async {
  final databaseDir = await getAnxDataBasesDir();
  if (!databaseDir.existsSync()) {
    return [];
  }
  
  final files = <File>[];
  final entities = databaseDir.listSync();
  for (var entity in entities) {
    if (entity is File) {
      files.add(entity);
    }
  }
  
  return files;
}

Future<int> calculateBooksSize() async {
  try {
    final fileDir = getFileDir();
    if (!fileDir.existsSync()) {
      return 0;
    }
    
    int totalSize = 0;
    final entities = fileDir.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    }
    
    return totalSize;
  } catch (e) {
    debugPrint('Error calculating books size: $e');
    return 0;
  }
}

Future<List<File>> listBookFiles() async {
  final fileDir = getFileDir();
  if (!fileDir.existsSync()) {
    return [];
  }
  
  final files = <File>[];
  final entities = fileDir.listSync(recursive: true);
  for (var entity in entities) {
    if (entity is File) {
      files.add(entity);
    }
  }
  
  return files;
}

Future<int> calculateFontSize() async {
  try {
    final fontDir = getFontDir();
    if (!fontDir.existsSync()) {
      return 0;
    }
    
    int totalSize = 0;
    final entities = fontDir.listSync();
    for (var entity in entities) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    }
    
    return totalSize;
  } catch (e) {
    debugPrint('Error calculating font size: $e');
    return 0;
  }
}

Future<List<File>> listFontFiles() async {
  final fontDir = getFontDir();
  if (!fontDir.existsSync()) {
    return [];
  }
  
  final files = <File>[];
  final entities = fontDir.listSync();
  for (var entity in entities) {
    if (entity is File) {
      files.add(entity);
    }
  }
  
  return files;
}

Future<int> calculateCacheSize() async {
  try {
    final cacheDir = await getAnxCacheDir();
    if (!cacheDir.existsSync()) {
      return 0;
    }
    
    int totalSize = 0;
    final entities = cacheDir.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    }
    
    return totalSize;
  } catch (e) {
    debugPrint('Error calculating cache size: $e');
    return 0;
  }
}

Future<bool> clearCache() async {
  try {
    final cacheDir = await getAnxCacheDir();
    if (!cacheDir.existsSync()) {
      return true;
    }
    
    final entities = cacheDir.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
      }
    }
    
    return true;
  } catch (e) {
    debugPrint('Error clearing cache: $e');
    return false;
  }
}

Future<int> calculateLogSize() async {
  try {
    final logFile = await getLogFile();
    if (!logFile.existsSync()) {
      return 0;
    }
    
    return logFile.lengthSync();
  } catch (e) {
    debugPrint('Error calculating log size: $e');
    return 0;
  }
}

// Format size in bytes to human-readable format
String formatSize(int bytes) {
  if (bytes <= 0) return '0 B';
  
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
}
