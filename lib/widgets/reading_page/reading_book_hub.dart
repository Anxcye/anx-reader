import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/next_reading_action.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_outcomes_service.dart';
import 'package:flutter/material.dart';

/// The single, low-distraction entry point for book-level reading state.
///
/// This widget is intentionally a projection only: all actions are delegated
/// to the reader page, while outcomes and atlas data are supplied by services.
class ReadingBookHubContent extends StatelessWidget {
  const ReadingBookHubContent({
    super.key,
    required this.book,
    required this.state,
    required this.closure,
    required this.nextAction,
    required this.atlas,
    required this.syncing,
    required this.syncEnabled,
    this.syncNeedsManualResolution = false,
    required this.onNextAction,
    required this.onOpenOutcomes,
    required this.onOpenWiki,
    this.onOpenContextPack,
    required this.onOpenStoryArchive,
    required this.onSync,
    required this.onOpenReadingSettings,
  });

  final Book book;
  final ReadingOutcomesSnapshot state;
  final ReadingClosurePolicyDefinition closure;
  final NextReadingAction nextAction;
  final FictionStoryAtlas atlas;
  final bool syncing;
  final bool syncEnabled;
  final bool syncNeedsManualResolution;
  final Future<void> Function() onNextAction;
  final Future<void> Function() onOpenOutcomes;
  final Future<void> Function() onOpenWiki;
  final Future<void> Function()? onOpenContextPack;
  final Future<void> Function() onOpenStoryArchive;
  final Future<void> Function() onSync;
  final Future<void> Function() onOpenReadingSettings;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final unresolved = state.unresolvedDifficulties.length;
    final pending =
        state.pendingCheckpoints.length + state.dueCards.length + unresolved;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '本书',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: '阅读 Agent 设置',
              onPressed: onOpenReadingSettings,
              icon: const Icon(Icons.tune_outlined),
            ),
          ],
        ),
        Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),
        Card.filled(
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            leading: Icon(
              nextAction.isPassive
                  ? Icons.menu_book_outlined
                  : Icons.play_circle_outline,
            ),
            title: Text(nextAction.title),
            subtitle: Text(nextAction.reason),
            trailing: nextAction.isPassive
                ? null
                : FilledButton.tonal(
                    onPressed: onNextAction,
                    child: const Text('开始'),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '阅读 ${(book.readingPercentage * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (pending > 0)
              Chip(
                avatar: const Icon(Icons.pending_actions, size: 18),
                label: Text('$pending 待处理'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        _HubTile(
          icon: Icons.auto_graph_outlined,
          title: '阅读成果',
          subtitle: '目标、章节检查、难点和记忆',
          onTap: onOpenOutcomes,
        ),
        _HubTile(
          icon: Icons.menu_book_outlined,
          title: '书籍 Wiki',
          subtitle: '按当前阅读边界浏览书籍百科',
          onTap: onOpenWiki,
        ),
        if (onOpenContextPack != null)
          _HubTile(
            icon: Icons.memory_outlined,
            title: 'AI 上下文',
            subtitle: '按已读范围建立可复用的本书上下文包',
            onTap: onOpenContextPack!,
          ),
        if (closure.supports(ReadingClosureCapability.storyAtlas))
          _HubTile(
            icon: Icons.account_tree_outlined,
            title: '故事档案',
            subtitle:
                '${atlas.characters.length} 人物 · ${atlas.timeline.length} 个事件',
            onTap: onOpenStoryArchive,
          ),
        const Divider(height: 28),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            syncEnabled ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          ),
          title: const Text('同步状态'),
          subtitle: Text(
            syncEnabled
                ? syncing
                    ? '正在获取远端进度…'
                    : syncNeedsManualResolution
                        ? '检测到冲突，请手动选择同步方向'
                        : '自动同步在阅读结束或空闲时执行'
                : '未启用同步',
          ),
          trailing: syncEnabled
              ? IconButton(
                  tooltip: '手动同步',
                  onPressed: syncing ? null : onSync,
                  icon: syncing && !disableAnimations
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(syncing ? Icons.sync_disabled : Icons.sync),
                )
              : null,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.auto_stories_outlined),
          title: Text(closure.title),
          subtitle: Text(closure.description),
          onTap: onOpenReadingSettings,
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
