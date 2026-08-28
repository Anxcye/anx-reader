import 'dart:io';

import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';

void receiveShareIntent(WidgetRef ref) {
  final handler = ShareHandlerPlatform.instance;

  // receive sharing intent
  Future<void> handleShare(SharedMedia? media) async {
    final importId = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    AnxLog.info('BookImport[$importId] stage=intent_received');
    if (media == null ||
        media.attachments == null ||
        media.attachments!.isEmpty) {
      AnxLog.warning('BookImport[$importId] stage=no_attachments');
      return;
    }
    AnxLog.info(
      'BookImport[$importId] stage=attachments_received count=${media.attachments!.length}',
    );

    List<File> files = [];
    for (var item in media.attachments!) {
      if (item != null && item.path.isNotEmpty) {
        final sourceFile = File(item.path);
        final exists = await sourceFile.exists();
        final size = exists ? await sourceFile.length() : -1;
        AnxLog.info(
          'BookImport[$importId] stage=attachment_validated '
          'file=${sourceFile.path.split(Platform.pathSeparator).last} '
          'exists=$exists size=$size',
        );
        if (exists && size > 0) files.add(sourceFile);
      }
    }
    if (files.isEmpty) {
      AnxLog.severe(
        'BookImport[$importId] stage=handoff_failed reason=no_readable_files',
      );
      handler.resetInitialSharedMedia();
      return;
    }
    AnxLog.info(
      'BookImport[$importId] stage=handoff_to_import count=${files.length}',
    );
    importBookList(files, navigatorKey.currentContext!, ref);
    handler.resetInitialSharedMedia();
  }

  handler.sharedMediaStream.listen((SharedMedia media) {
    handleShare(media);
  }, onError: (err) {
    AnxLog.severe('BookImport stage=share_stream_error', err);
  });

  handler.getInitialSharedMedia().then((media) {
    handleShare(media);
  }, onError: (err) {
    AnxLog.severe('BookImport stage=initial_share_error', err);
  });
}
