import 'dart:io';
import 'dart:math';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/providers/storage_info.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageSettings extends ConsumerStatefulWidget {
  const StorageSettings({super.key});

  @override
  ConsumerState<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends ConsumerState<StorageSettings>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storageInfoAsync = ref.watch(storageInfoProvider);

    Widget fileSizeTriling(String? size) {
      if (size == null) {
        return const CircularProgressIndicator.adaptive();
      }
      return Text(
        size,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    Widget cacheSizeTriling(String? size) {
      if (size == null) {
        return const CircularProgressIndicator.adaptive();
      }
      return ElevatedButton(
        onPressed: () async {
          await ref.read(storageInfoProvider.notifier).clearCache();
          ref.invalidate(storageInfoProvider);
        },
        child: Text('清空缓存 $size'),
      );
    }

    return settingsSections(sections: [
      SettingsSection(
        title: const Text('存储信息'),
        tiles: [
          CustomSettingsTile(
            child: Column(
              children: [
                ListTile(
                  title: Text('数据库文件'),
                  trailing:
                      fileSizeTriling(storageInfoAsync.value?.databaseSizeStr),
                ),
                ListTile(
                  title: Text('日志文件'),
                  trailing: fileSizeTriling(storageInfoAsync.value?.logSizeStr),
                ),
                ListTile(
                  title: Text('缓存文件'),
                  trailing:
                      cacheSizeTriling(storageInfoAsync.value?.cacheSizeStr),
                ),
                Column(
                  children: [
                    ListTile(
                      title: Text('数据文件'),
                      trailing: fileSizeTriling(
                          storageInfoAsync.value?.dataFilesSizeStr),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('书籍文件'),
                            trailing: fileSizeTriling(
                                storageInfoAsync.value?.booksSizeStr),
                          ),
                          ListTile(
                            title: Text('封面文件'),
                            trailing: fileSizeTriling(
                                storageInfoAsync.value?.coverSizeStr),
                          ),
                          ListTile(
                            title: Text('字体文件'),
                            trailing: fileSizeTriling(
                                storageInfoAsync.value?.fontSizeStr),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // // Tab view for data files details
      SettingsSection(title: const Text('数据文件详情'), tiles: [
        CustomSettingsTile(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '书籍', icon: Icon(Icons.book)),
                    Tab(text: '封面', icon: Icon(Icons.image)),
                    Tab(text: '字体', icon: Icon(Icons.font_download)),
                  ],
                ),
                SizedBox(
                  height: 300, // Fixed height for tab view content
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Books tab
                      storageInfoAsync.when(
                        data: (_) => DataFilesDetailTab(
                          title: '书籍文件',
                          icon: Icons.book,
                          listFiles: ref
                              .read(storageInfoProvider.notifier)
                              .listBookFiles(),
                        ),
                        loading: () => const Center(
                            child: CircularProgressIndicator.adaptive()),
                        error: (_, __) =>
                            Center(child: Text(L10n.of(context).common_error)),
                      ),
                      // Covers tab
                      storageInfoAsync.when(
                        data: (_) => DataFilesDetailTab(
                          title: '封面文件',
                          icon: Icons.image,
                          listFiles: ref
                              .read(storageInfoProvider.notifier)
                              .listCoverFiles(),
                        ),
                        loading: () => const Center(
                            child: CircularProgressIndicator.adaptive()),
                        error: (_, __) =>
                            Center(child: Text(L10n.of(context).common_error)),
                      ),
                      // Fonts tab
                      storageInfoAsync.when(
                        data: (_) => DataFilesDetailTab(
                          title: '字体文件',
                          icon: Icons.font_download,
                          listFiles: ref
                              .read(storageInfoProvider.notifier)
                              .listFontFiles(),
                        ),
                        loading: () => const Center(
                            child: CircularProgressIndicator.adaptive()),
                        error: (_, __) =>
                            Center(child: Text(L10n.of(context).common_error)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ])
    ]);
    //   ],
    // );
  }
}

// Tab content for data files details
class DataFilesDetailTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<File> listFiles;
  // final AsyncValue<StorageInfo> storageInfoAsync;

  const DataFilesDetailTab({
    super.key,
    required this.title,
    required this.icon,
    required this.listFiles,
    // required this.storageInfoAsync,
  });

  @override
  Widget build(BuildContext context) {
    String formatSize(int bytes) {
      if (bytes <= 0) return '0 B';

      const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
      var i = (log(bytes) / log(1024)).floor();
      return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          child: ListView.builder(
        itemCount: listFiles.length,
        itemBuilder: (context, index) {
          final file = listFiles[index];
          return ListTile(
            title: Text(file.path.split(Platform.pathSeparator).last),
            subtitle: Text(formatSize(file.lengthSync())),
          );
        },
      ))
    ]);
  }
}
