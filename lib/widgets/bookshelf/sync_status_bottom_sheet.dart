import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/models/sync_state_model.dart';
import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/widgets/linear_proportion_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void showSyncStatusBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const SyncStatusBottomSheet(),
  );
}

class SyncStatusBottomSheet extends ConsumerWidget {
  const SyncStatusBottomSheet({super.key});

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

    final DateTime localUpdateTime =
        DateTime.now().subtract(const Duration(hours: 2));
    final DateTime lastUploadTime =
        DateTime.now().subtract(const Duration(days: 1));

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 同步状态指示器
            _buildSyncingIndicator(syncState, theme),

            // 数据更新时间
            _buildUpdateTimeInfo(localUpdateTime, lastUploadTime, theme),
            const SizedBox(height: 30),

            // 书籍分布图表
            _buildBookDistributionChart(localOnlyBooks, remoteOnlyBooks,
                bothBooks, nonExistentBooks, theme),
            const SizedBox(height: 30),

            // 书籍统计
            _buildBookStats(localOnlyBooks, remoteOnlyBooks, bothBooks,
                nonExistentBooks, theme),
            const SizedBox(height: 30),

            // 操作按钮
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncingIndicator(
    SyncStateModel syncState,
    ThemeData theme,
  ) {
    if (!syncState.isSyncing) {
      return Text('未在同步', style: theme.textTheme.titleMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('正在同步: ${syncState.fileName}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: syncState.total > 0 ? syncState.count / syncState.total : 0,
        ),
        const SizedBox(height: 5),
        Text('${syncState.count}/${syncState.total}',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 20),
        const Divider(),
      ],
    );
  }

  Widget _buildUpdateTimeInfo(
    DateTime localTime,
    DateTime lastUploadTime,
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
        _buildTimeRow('上次上传时间:', dateFormatter.format(lastUploadTime), theme),
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
        color: Colors.green,
        showLabel: true,
      ),
      SegmentData(
        proportion: total > 0 ? remoteOnly / total : 0,
        color: Colors.blue,
        showLabel: true,
      ),
      SegmentData(
        proportion: total > 0 ? both / total : 0,
        color: Colors.purple,
        showLabel: true,
      ),
      SegmentData(
        proportion: total > 0 ? nonExistent / total : 0,
        color: Colors.grey,
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
    final total = localOnly + remoteOnly + both + nonExistent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('书籍统计', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        _buildStatRow('仅本地书籍:', '$localOnly 本', Colors.green, theme),
        const SizedBox(height: 5),
        _buildStatRow('仅远程书籍:', '$remoteOnly 本', Colors.blue, theme),
        const SizedBox(height: 5),
        _buildStatRow('两端共有书籍:', '$both 本', Colors.purple, theme),
        const SizedBox(height: 5),
        _buildStatRow('待同步书籍:', '$nonExistent 本', Colors.grey, theme),
        const SizedBox(height: 5),
        _buildStatRow('书籍总数:', '$total 本', theme.colorScheme.primary, theme),
      ],
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          flex: 1,
          child: Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
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
