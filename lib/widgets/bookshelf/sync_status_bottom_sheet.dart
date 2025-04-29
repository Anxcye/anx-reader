import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/book_sync_status.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/models/sync_state_model.dart';
import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/widgets/bookshelf/book_sync_status_icon.dart';
import 'package:anx_reader/widgets/linear_proportion_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

Future<void> showSyncStatusBottomSheet(BuildContext context) async {
  final dbPath = await getAnxDataBasesPath();
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SyncStatusBottomSheet(dbPath: dbPath),
  );
}

class SyncStatusBottomSheet extends ConsumerWidget {
  const SyncStatusBottomSheet({super.key, required this.dbPath});

  final String dbPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(anxWebdavProvider);
    final theme = Theme.of(context);

    final int localOnlyBooks = ref.watch(syncStatusProvider).whenOrNull(
              data: (data) => data.localOnly.length,
            ) ??
        0;
    final int remoteOnlyBooks = ref.watch(syncStatusProvider).whenOrNull(
              data: (data) => data.remoteOnly.length,
            ) ??
        0;
    final int bothBooks = ref.watch(syncStatusProvider).whenOrNull(
              data: (data) => data.both.length,
            ) ??
        0;
    final int nonExistentBooks = ref.watch(syncStatusProvider).whenOrNull(
              data: (data) => data.nonExistent.length,
            ) ??
        0;
    File localDb = File(join((dbPath), 'app_database.db'));
    final DateTime localUpdateTime = localDb.lastModifiedSync();

    final DateTime? lastUploadTime = Prefs().lastUploadBookDate;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSyncingIndicator(syncState, theme),
            _buildUpdateTimeInfo(localUpdateTime, lastUploadTime, theme),
            const SizedBox(height: 30),
            _buildBookDistributionChart(localOnlyBooks, remoteOnlyBooks,
                bothBooks, nonExistentBooks, theme),
            const SizedBox(height: 30),
            _buildBookStats(localOnlyBooks, remoteOnlyBooks, bothBooks,
                nonExistentBooks, theme),
            const SizedBox(height: 10),
            _buildNonExistentTip(theme),
            const SizedBox(height: 30),
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildNonExistentTip(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16),
        Expanded(
          child: Text(
            '本地和远程均不存在: 指书架上有这本书，但是这台设备和远程文件中没有这本书籍的文件，需要从有这个文件的设备上进行一次同步',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncingIndicator(
    SyncStateModel syncState,
    ThemeData theme,
  ) {
    String byteToHuman(int byte) {
      if (byte < 1024) {
        return '$byte B';
      } else if (byte < 1024 * 1024) {
        return '${(byte / 1024).toStringAsFixed(2)} KB';
      } else if (byte < 1024 * 1024 * 1024) {
        return '${(byte / 1024 / 1024).toStringAsFixed(2)} MB';
      } else {
        return '${(byte / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
      }
    }

    if (!syncState.isSyncing) {
      return Text('未在同步', style: theme.textTheme.titleMedium);
    }

    final syncDirection =
        syncState.direction == SyncDirection.upload ? '上传' : '下载';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(syncDirection, style: theme.textTheme.titleMedium),
        Text(syncState.fileName, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: syncState.total > 0 ? syncState.count / syncState.total : 0,
        ),
        const SizedBox(height: 5),
        Text(
            '${byteToHuman(syncState.count)} / ${byteToHuman(syncState.total)}'),
        const SizedBox(height: 20),
        const Divider(),
      ],
    );
  }

  Widget _buildUpdateTimeInfo(
    DateTime localTime,
    DateTime? lastUploadTime,
    ThemeData theme,
  ) {
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('数据更新时间', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        _buildTimeRow('本地数据更新时间:', dateFormatter.format(localTime), theme),
        const SizedBox(height: 5),
        _buildTimeRow(
            '上次同步时间:',
            lastUploadTime != null
                ? dateFormatter.format(lastUploadTime)
                : '此设备还没有同步过数据',
            theme),
      ],
    );
  }

  Widget _buildTimeRow(
    String label,
    String time,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          flex: 3,
          child: Text(time,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  List<BookSyncStatusEnum> _getBookDistributionStatus(
    bool showUploading,
    bool showChecking,
  ) {
    return [
      BookSyncStatusEnum.localOnly,
      BookSyncStatusEnum.remoteOnly,
      BookSyncStatusEnum.both,
      BookSyncStatusEnum.nonExistent,
      if (showUploading) BookSyncStatusEnum.uploading,
      if (showChecking) BookSyncStatusEnum.checking,
    ];
  }

  List<Color> _getBookDistributionColors() {
    return _getBookDistributionStatus(false, false)
        .map((e) => BookSyncStatusIcon(syncStatus: e).color)
        .toList();
  }

  Widget _buildBookDistributionChart(
    int localOnly,
    int remoteOnly,
    int both,
    int nonExistent,
    ThemeData theme,
  ) {
    final total = localOnly + remoteOnly + both + nonExistent;

    return LinearProportionBar(segments: [
      SegmentData(
        proportion: total > 0 ? localOnly / total : 0,
        color: _getBookDistributionColors()[0],
        showLabel: true,
      ),
      SegmentData(
        proportion: total > 0 ? remoteOnly / total : 0,
        color: _getBookDistributionColors()[1],
        showLabel: true,
      ),
      SegmentData(
        proportion: total > 0 ? both / total : 0,
        color: _getBookDistributionColors()[2],
        showLabel: true,
      ),
      SegmentData(
        proportion: total > 0 ? nonExistent / total : 0,
        color: _getBookDistributionColors()[3],
        showLabel: true,
      ),
    ]);
  }

  Widget _buildBookStats(
    int localOnly,
    int remoteOnly,
    int both,
    int nonExistent,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('书籍统计', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        _buildStatRow(
            '仅本地书籍:', '$localOnly 本', BookSyncStatusEnum.localOnly, theme),
        const SizedBox(height: 5),
        _buildStatRow(
            '仅远程书籍:', '$remoteOnly 本', BookSyncStatusEnum.remoteOnly, theme),
        const SizedBox(height: 5),
        _buildStatRow('两端共有书籍:', '$both 本', BookSyncStatusEnum.both, theme),
        const SizedBox(height: 5),
        _buildStatRow('本地和远程均不存在:', '$nonExistent 本',
            BookSyncStatusEnum.nonExistent, theme),
      ],
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    BookSyncStatusEnum syncStatus,
    ThemeData theme,
  ) {
    return Row(
      children: [
        BookSyncStatusIcon(syncStatus: syncStatus),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text('上传'),
            onPressed: () {
              ref
                  .read(anxWebdavProvider.notifier)
                  .syncData(SyncDirection.upload, ref);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.cloud_download),
            label: const Text('下载'),
            onPressed: () {
              ref
                  .read(anxWebdavProvider.notifier)
                  .syncData(SyncDirection.download, ref);
            },
          ),
        ),
      ],
    );
  }
}
