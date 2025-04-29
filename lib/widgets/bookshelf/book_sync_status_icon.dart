import 'package:anx_reader/enums/book_sync_status.dart';
import 'package:anx_reader/widgets/bookshelf/spining_sync_icon.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class BookSyncStatusIcon extends StatelessWidget {
  const BookSyncStatusIcon({
    super.key,
    required this.syncStatus,
    this.iconSize = 16,
  });

  final BookSyncStatusEnum syncStatus;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    switch (syncStatus) {
      case BookSyncStatusEnum.localOnly:
        return Stack(
          children: [
            Center(
              child: Icon(
                Bootstrap.cloud,
                color: Colors.orangeAccent,
                size: iconSize,
              ),
            ),
            Center(
              child: Icon(
                Bootstrap.x,
                color: Colors.orangeAccent,
                size: iconSize * 0.7,
              ),
            ),
          ],
        );
      case BookSyncStatusEnum.remoteOnly:
        return Stack(
          children: [
            Center(
              child: Icon(
                Bootstrap.cloud,
                color: Colors.grey,
                size: iconSize,
              ),
            ),
            Center(
              child: Icon(
                Icons.sync,
                color: Colors.grey,
                size: iconSize * 0.5,
              ),
            ),
          ],
        );
      case BookSyncStatusEnum.both:
        return Icon(
          Bootstrap.cloud_check,
          color: Colors.green,
          size: iconSize,
        );
      case BookSyncStatusEnum.nonExistent:
        return Icon(
          OctIcons.x_circle,
          color: Colors.red,
          size: iconSize * 0.8,
        );
      case BookSyncStatusEnum.downloading:
        return Stack(
          children: [
            Center(
              child: SpiningSyncIcon(
                size: iconSize,
                color: Colors.blue,
              ),
            ),
            Center(
              child: Icon(
                Bootstrap.arrow_down_short,
                color: Colors.blue,
                size: iconSize * 0.7,
              ),
            ),
          ],
        );
      case BookSyncStatusEnum.uploading:
        return Stack(
          children: [
            Center(
              child: SpiningSyncIcon(
                size: iconSize,
                color: Colors.blue,
              ),
            ),
            Center(
              child: Icon(
                Bootstrap.arrow_up_short,
                color: Colors.blue,
                size: iconSize * 0.7,
              ),
            ),
          ],
        );
      case BookSyncStatusEnum.checking:
        return CircularProgressIndicator.adaptive(
          strokeWidth: 2,
        );
    }
  }
}
