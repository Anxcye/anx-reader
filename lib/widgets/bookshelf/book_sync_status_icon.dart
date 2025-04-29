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

  Color get color {
    switch (syncStatus) {
      case BookSyncStatusEnum.localOnly:
        return Colors.orangeAccent;
      case BookSyncStatusEnum.remoteOnly:
        return Colors.grey;
      case BookSyncStatusEnum.both:
        return Colors.green;
      case BookSyncStatusEnum.nonExistent:
        return Colors.red;
      case BookSyncStatusEnum.downloading:
        return Colors.blue;
      case BookSyncStatusEnum.uploading:
        return Colors.blue;
      case BookSyncStatusEnum.checking:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = switch (syncStatus) {
      BookSyncStatusEnum.localOnly => Stack(
          children: [
            Center(
              child: Icon(
                Bootstrap.cloud,
                color: color,
                size: iconSize,
              ),
            ),
            Center(
              child: Icon(
                Bootstrap.x,
                color: color,
                size: iconSize * 0.7,
              ),
            ),
          ],
        ),
      BookSyncStatusEnum.remoteOnly => Stack(
          children: [
            Center(
              child: Icon(
                Bootstrap.cloud,
                color: color,
                size: iconSize,
              ),
            ),
            Center(
              child: Icon(
                Icons.sync,
                color: color,
                size: iconSize * 0.5,
              ),
            ),
          ],
        ),
      BookSyncStatusEnum.both => Icon(
          Bootstrap.cloud_check,
          color: color,
          size: iconSize,
        ),
      BookSyncStatusEnum.nonExistent => Icon(
          OctIcons.x_circle,
          color: color,
          size: iconSize * 0.8,
        ),
      BookSyncStatusEnum.downloading => Stack(
          children: [
            Center(
              child: SpiningSyncIcon(
                size: iconSize,
                color: color,
              ),
            ),
            Center(
              child: Icon(
                Bootstrap.arrow_down_short,
                color: color,
                size: iconSize * 0.7,
              ),
            ),
          ],
        ),
      BookSyncStatusEnum.uploading => Stack(
          children: [
            Center(
              child: SpiningSyncIcon(
                size: iconSize,
                color: color,
              ),
            ),
            Center(
              child: Icon(
                Bootstrap.arrow_up_short,
                color: color,
                size: iconSize * 0.7,
              ),
            ),
          ],
        ),
      BookSyncStatusEnum.checking => CircularProgressIndicator.adaptive(
          strokeWidth: 2,
        ),
    };
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: child,
    );
  }
}
