import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:anx_reader/main.dart';
import 'package:flutter/material.dart';


void showWebdavStatus() {
  final context = navigatorKey.currentContext!;
  showDialog(
    context: context,
    builder: (context) {
      return const SyncStatusDialog();
    },
  );
}

class SyncStatusDialog extends StatefulWidget {
  const SyncStatusDialog({super.key});

  @override
  _SyncStatusDialogState createState() => _SyncStatusDialogState();
}

class _SyncStatusDialogState extends State<SyncStatusDialog> {
  late int count;
  late int total;
  late String fileName;
  late SyncDirection direction;

  @override
  void initState() {
    super.initState();
    AnxWebdav.syncing.listen((syncing) {
      if (syncing) {
        setState(() {
          fileName = AnxWebdav.fileName;
          direction = AnxWebdav.direction;
          count = AnxWebdav.count;
          total = AnxWebdav.total;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String dir = direction == SyncDirection.upload
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
                  fileName,
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: count / total,
          ),
          Text('${byteToHuman(count)} / ${byteToHuman(total)}'),
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
}
