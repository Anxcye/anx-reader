import 'dart:io';
import 'dart:math';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/providers/storage_info.dart';
import 'package:anx_reader/widgets/delete_confirm.dart';
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
        child: Text('${L10n.of(context).storageClearCache} $size'),
      );
    }

    return settingsSections(sections: [
      SettingsSection(
        title: Text(L10n.of(context).storageInfo),
        tiles: [
          CustomSettingsTile(
            child: Column(
              children: [
                ListTile(
                  title: Text(L10n.of(context).storageTotalSize),
                  trailing:
                      fileSizeTriling(storageInfoAsync.value?.totalSizeStr),
                ),
                ListTile(
                  title: Text(L10n.of(context).storageDatabaseFile),
                  trailing:
                      fileSizeTriling(storageInfoAsync.value?.databaseSizeStr),
                ),
                ListTile(
                  title: Text(L10n.of(context).storageLogFile),
                  trailing: fileSizeTriling(storageInfoAsync.value?.logSizeStr),
                ),
                ListTile(
                  title: Text(L10n.of(context).storageCacheFile),
                  trailing:
                      cacheSizeTriling(storageInfoAsync.value?.cacheSizeStr),
                ),
                Column(
                  children: [
                    ListTile(
                      title: Text(L10n.of(context).storageDataFile),
                      trailing: fileSizeTriling(
                          storageInfoAsync.value?.dataFilesSizeStr),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(L10n.of(context).storageBookFile),
                            trailing: fileSizeTriling(
                                storageInfoAsync.value?.booksSizeStr),
                          ),
                          ListTile(
                            title: Text(L10n.of(context).storageCoverFile),
                            trailing: fileSizeTriling(
                                storageInfoAsync.value?.coverSizeStr),
                          ),
                          ListTile(
                            title: Text(L10n.of(context).storageFontFile),
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

      // Tab view for data files details
      SettingsSection(
          title: Text(L10n.of(context).storageDataFileDetails),
          tiles: [
            CustomSettingsTile(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(
                            text: L10n.of(context).storageBookFile,
                            icon: const Icon(Icons.book)),
                        Tab(
                            text: L10n.of(context).storageCoverFile,
                            icon: const Icon(Icons.image)),
                        Tab(
                            text: L10n.of(context).storageFontFile,
                            icon: const Icon(Icons.font_download)),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          kToolbarHeight -
                          140,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Books tab
                          storageInfoAsync.when(
                            data: (_) => DataFilesDetailTab(
                              title: L10n.of(context).storageBookFile,
                              icon: Icons.book,
                              listFiles: ref
                                  .read(storageInfoProvider.notifier)
                                  .listBookFiles(),
                              showDelete: false,
                              ref: ref,
                            ),
                            loading: () => const Center(
                                child: CircularProgressIndicator.adaptive()),
                            error: (_, __) => Center(
                                child: Text(L10n.of(context).commonError)),
                          ),
                          // Covers tab
                          storageInfoAsync.when(
                            data: (_) => DataFilesDetailTab(
                              title: L10n.of(context).storageCoverFile,
                              icon: Icons.image,
                              listFiles: ref
                                  .read(storageInfoProvider.notifier)
                                  .listCoverFiles(),
                              showDelete: false,
                              ref: ref,
                            ),
                            loading: () => const Center(
                                child: CircularProgressIndicator.adaptive()),
                            error: (_, __) => Center(
                                child: Text(L10n.of(context).commonError)),
                          ),
                          // Fonts tab
                          storageInfoAsync.when(
                            data: (_) => DataFilesDetailTab(
                              title: L10n.of(context).storageFontFile,
                              icon: Icons.font_download,
                              listFiles: ref
                                  .read(storageInfoProvider.notifier)
                                  .listFontFiles(),
                              showDelete: true,
                              ref: ref,
                            ),
                            loading: () => const Center(
                                child: CircularProgressIndicator.adaptive()),
                            error: (_, __) => Center(
                                child: Text(L10n.of(context).commonError)),
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
  }
}

// Tab content for data files details
class DataFilesDetailTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final Future<List<File>> listFiles;
  final bool showDelete;
  final WidgetRef ref;

  const DataFilesDetailTab({
    super.key,
    required this.title,
    required this.icon,
    required this.listFiles,
    this.showDelete = false,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    String formatSize(int bytes) {
      if (bytes <= 0) return '0 B';

      const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
      var i = (log(bytes) / log(1024)).floor();
      return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
    }

    Widget fileSizeWidget(File file) {
      return FutureBuilder<int>(
        future: file.length(),
        builder: (context, snapshot) {
          return Text(formatSize(snapshot.data ?? 0));
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FutureBuilder<List<File>>(
            future: listFiles,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final files = snapshot.data!;
                files.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return ListTile(
                      title: Text(file.path.split(Platform.pathSeparator).last),
                      subtitle: showDelete ? fileSizeWidget(file) : null,
                      trailing: showDelete
                          ? file.path.endsWith('SourceHanSerifSC-Regular.otf')
                              ? null
                              : DeleteConfirm(
                                  delete: () {
                                    snapshot.data!.remove(file);
                                    ref
                                        .read(storageInfoProvider.notifier)
                                        .deleteFile(file);
                                  },
                                  deleteIcon: const Icon(Icons.delete),
                                  confirmIcon: const Icon(Icons.check),
                                )
                          : fileSizeWidget(file),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator.adaptive());
            },
          ),
        ),
      ],
    );
  }
}
