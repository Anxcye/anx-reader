import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../enums/sync_direction.dart';

void showWebdavStatus(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return const SyncStatusDialog();
    },
  );
}

class SyncStatusDialog extends ConsumerStatefulWidget {
  const SyncStatusDialog({super.key});

  @override
  SyncStatusDialogState createState() => SyncStatusDialogState();
}

class SyncStatusDialogState extends ConsumerState<SyncStatusDialog> {
  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);

    String dir = syncState.direction == SyncDirection.upload
        ? L10n.of(context).common_uploading
        : L10n.of(context).common_downloading;
    return AlertDialog(
      title: Text(dir),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  syncState.fileName,
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: syncState.count / syncState.total,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(L10n.of(context).common_ok),
        ),
      ],
    );
  }
}
