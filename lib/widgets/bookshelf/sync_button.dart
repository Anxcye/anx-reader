import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:anx_reader/widgets/bookshelf/sync_status_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncButton extends ConsumerStatefulWidget {
  const SyncButton({super.key});

  @override
  ConsumerState createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<SyncButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _syncAnimationController;

  @override
  void dispose() {
    _syncAnimationController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(anxWebdavProvider);

    if (syncState.isSyncing) {
      _syncAnimationController?.repeat();
      return IconButton(
        icon: RotationTransition(
          turns: Tween(begin: 1.0, end: 0.0).animate(_syncAnimationController!),
          child: const Icon(Icons.sync),
        ),
        onPressed: () {
          showSyncStatusBottomSheet(context);
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.sync),
        onPressed: () {
          showSyncStatusBottomSheet(context);
        },
      );
    }
  }
}
