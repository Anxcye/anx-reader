import 'dart:io';

import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void receiveShareIntent(WidgetRef ref) {
  // receive sharing intent
  Future<void> handleShare(List<SharedMediaFile> value) async {
    List<File> files = [];
    for (var item in value) {
      final sourceFile = File(item.path);
      files.add(sourceFile);
    }
    importBookList(files, navigatorKey.currentContext!, ref);
    ReceiveSharingIntent.instance.reset();
  }

  ReceiveSharingIntent.instance.getMediaStream().listen((value) {
    AnxLog.info('share: Receive share intent: ${value.map((e) => e.toMap())}');
    if (value.isNotEmpty) {
      handleShare(value);
    }
  }, onError: (err) {
    AnxLog.severe('share: Receive share intent');
  });

  ReceiveSharingIntent.instance.getInitialMedia().then((value) {
    AnxLog.info('share: Receive share intent: ${value.map((e) => e.toMap())}');
    if (value.isNotEmpty) {
      handleShare(value);
    }
  }, onError: (err) {
    AnxLog.severe('share: Receive share intent');
  });
}
