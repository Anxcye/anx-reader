import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/book_sync_status.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/sync_state_model.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/bookshelf/book_sync_status_icon.dart';
import 'package:anx_reader/widgets/linear_proportion_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

Future<void> showSyncStatusBottomSheet(BuildContext context) async {
  final dbPath = await getAnxDataBasesPath();
  showModalBottomSheet(
    useSafeArea: true,
    context: navigatorKey.currentContext!,
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
    final syncState = ref.watch(syncProvider);
    final theme = Theme.of(context);
    final l10n = L10n.of(context);

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
            _buildSyncingIndicator(syncState, theme, l10n),
            const SizedBox(height: 10),
            _buildUpdateTimeInfo(localUpdateTime, lastUploadTime, theme, l10n),
            const SizedBox(height: 30),
            _buildBookDistributionChart(localOnlyBooks, remoteOnlyBooks,
                bothBooks, nonExistentBooks, theme),
            _buildBookStats(localOnlyBooks, remoteOnlyBooks, bothBooks,
                nonExistentBooks, theme, l10n),
            const SizedBox(height: 10),
            _buildNonExistentTip(theme, l10n),
            const SizedBox(height: 30),
            _buildActionButtons(context, ref, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildNonExistentTip(ThemeData theme, L10n l10n) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16),
        Expanded(
          child: Text(
            l10n.bookSyncStatusNonExistentTip,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncingIndicator(
    SyncStateModel syncState,
    ThemeData theme,
    L10n l10n,
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
      return Text(
        l10n.bookSyncStatusNotSyncing,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final syncDirection = syncState.direction == SyncDirection.upload
        ? l10n.bookSyncStatusUploadingTitle
        : l10n.bookSyncStatusDownloadingTitle;
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
    L10n l10n,
  ) {
    Widget buildTimeRow(
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
          Text(time, style: theme.textTheme.bodyMedium),
        ],
      );
    }

    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTimeRow(l10n.bookSyncStatusLocalUpdateTime,
            dateFormatter.format(localTime), theme),
        const SizedBox(height: 5),
        buildTimeRow(
            l10n.bookSyncStatusLastSyncTime,
            lastUploadTime != null
                ? dateFormatter.format(lastUploadTime)
                : l10n.bookSyncStatusNoSyncYet,
            theme),
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
    L10n l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildStatRow(
            l10n.bookSyncStatusLocalOnlyBooks,
            l10n.bookSyncStatusBooksCount(localOnly),
            BookSyncStatusEnum.localOnly,
            theme),
        const SizedBox(height: 5),
        _buildStatRow(
            l10n.bookSyncStatusRemoteOnlyBooks,
            l10n.bookSyncStatusBooksCount(remoteOnly),
            BookSyncStatusEnum.remoteOnly,
            theme),
        const SizedBox(height: 5),
        _buildStatRow(
            l10n.bookSyncStatusBothBooks,
            l10n.bookSyncStatusBooksCount(both),
            BookSyncStatusEnum.both,
            theme),
        const SizedBox(height: 5),
        _buildStatRow(
            l10n.bookSyncStatusNonExistentBooks,
            l10n.bookSyncStatusBooksCount(nonExistent),
            BookSyncStatusEnum.nonExistent,
            theme),
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
    L10n l10n,
  ) {
    return Column(
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.download_for_offline),
              label: Text(l10n.downloadAllBooks),
              onPressed: () {
                final remoteOnlyIds = ref
                        .read(syncStatusProvider)
                        .whenData((data) => data.remoteOnly)
                        .valueOrNull ??
                    [];
                if (remoteOnlyIds.isNotEmpty) {
                  ref
                      .read(syncProvider.notifier)
                      .downloadMultipleBooks(remoteOnlyIds);
                  AnxToast.show('');
                } else {
                  AnxToast.show(l10n.allBooksAreDownloaded);
                }
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.sync),
                label: Text(L10n.of(context).syncNow),
                onPressed: () {
                  final isSyncing = ref.watch(syncProvider).isSyncing;
                  if (isSyncing) {
                    AnxToast.show(l10n.webdavSyncing);
                  } else {
                    ref.read(syncProvider.notifier).syncData(
                        SyncDirection.both, ref,
                        trigger: SyncTrigger.manual);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
