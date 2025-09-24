import 'package:anx_reader/providers/sync.dart';
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
  late final AnimationController _syncAnimationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween(begin: 1.0, end: 0.0).animate(_syncAnimationController);
  }

  @override
  void dispose() {
    _syncAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncProvider.select((value) => value.isSyncing), (_, isSyncing) {
      if (isSyncing) {
        _syncAnimationController.repeat();
      } else {
        _syncAnimationController.stop();
      }
    });

    final isSyncing = ref.watch(syncProvider.select((s) => s.isSyncing));

    return IconButton(
      icon: isSyncing
          ? RepaintBoundary(
              child: RotationTransition(
                turns: _animation,
                child: const Icon(Icons.sync),
              ),
            )
          : const Icon(Icons.sync),
      onPressed: () {
        showSyncStatusBottomSheet(context);
      },
    );
  }
}