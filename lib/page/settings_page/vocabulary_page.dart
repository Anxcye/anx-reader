import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/vocabulary_item.dart';
import 'package:anx_reader/providers/vocabulary.dart';
import 'package:anx_reader/service/dictionary/pronunciation_player.dart';
import 'package:anx_reader/service/vocabulary_webdav_sync_service.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VocabularyPage extends ConsumerStatefulWidget {
  const VocabularyPage({super.key});

  @override
  ConsumerState<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends ConsumerState<VocabularyPage> {
  bool _dueOnly = false;
  bool _isBackingUp = false;
  bool _isSyncing = false;
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final vocabularyState = ref.watch(vocabularyProvider);
    final summaryState = ref.watch(vocabularySummaryProvider);

    return settingsSections(
      sections: [
        CustomSettingsSection(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
            child: _VocabularySummary(summaryState: summaryState),
          ),
        ),
        CustomSettingsSection(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _VocabularyWebdavPanel(
              webdavEnabled: Prefs().webdavStatus,
              isBackingUp: _isBackingUp,
              isSyncing: _isSyncing,
              onBackup: _backupToWebdav,
              onSync: _syncWithWebdav,
            ),
          ),
        ),
        CustomSettingsSection(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.list_alt_outlined),
                  label: Text(L10n.of(context).vocabularyAllWords),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(L10n.of(context).vocabularyDueReview),
                ),
              ],
              selected: {_dueOnly},
              onSelectionChanged: (selection) {
                final dueOnly = selection.first;
                setState(() {
                  _dueOnly = dueOnly;
                  _expandedIds.clear();
                });
                ref.read(vocabularyProvider.notifier).load(dueOnly: dueOnly);
              },
            ),
          ),
        ),
        CustomSettingsSection(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: vocabularyState.when(
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyVocabulary(dueOnly: _dueOnly);
                }

                return _VocabularyCardFlow(
                  items: items,
                  expandedIds: _expandedIds,
                  onToggle: _toggleExpanded,
                  onHard: (item) => _review(
                    () => ref.read(vocabularyProvider.notifier).markHard(item),
                  ),
                  onFamiliar: (item) => _review(
                    () => ref
                        .read(vocabularyProvider.notifier)
                        .markFamiliar(item),
                  ),
                  onMastered: (item) => _review(
                    () => ref
                        .read(vocabularyProvider.notifier)
                        .markMastered(item),
                    message: L10n.of(context).vocabularyMarkedMastered,
                  ),
                  onRemove: (item) => _review(
                    () => ref.read(vocabularyProvider.notifier).remove(item),
                    message: L10n.of(context).vocabularyRemoved,
                  ),
                );
              },
              error: (error, stackTrace) => FilledContainer(
                padding: const EdgeInsets.all(16),
                child: Text('${L10n.of(context).commonFailed}: $error'),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (!_expandedIds.remove(id)) {
        _expandedIds.add(id);
      }
    });
  }

  Future<void> _review(
    Future<void> Function() action, {
    String? message,
  }) async {
    await action();
    ref.invalidate(vocabularySummaryProvider);
    if (message != null) {
      AnxToast.show(message);
    }
  }

  Future<void> _backupToWebdav() async {
    if (_isBackingUp || _isSyncing) return;
    final successMessage = _vocabularyBackupSuccessMessage(context);
    final failedPrefix = _vocabularyBackupFailedPrefix(context);

    setState(() {
      _isBackingUp = true;
    });

    try {
      final result = await VocabularyWebdavSyncService.backup();
      if (!mounted) return;
      AnxToast.show(successMessage(result.finalCount));
    } catch (e) {
      if (!mounted) return;
      AnxToast.show('$failedPrefix: ${_friendlySyncError(context, e)}');
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _syncWithWebdav() async {
    if (_isBackingUp || _isSyncing) return;
    final successMessage = _vocabularySyncSuccessMessage(context);
    final failedPrefix = _vocabularySyncFailedPrefix(context);

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await VocabularyWebdavSyncService.sync();
      if (!mounted) return;
      await ref.read(vocabularyProvider.notifier).load(dueOnly: _dueOnly);
      ref.invalidate(vocabularySummaryProvider);
      AnxToast.show(successMessage(result.changedCount, result.finalCount));
    } catch (e) {
      if (!mounted) return;
      AnxToast.show('$failedPrefix: ${_friendlySyncError(context, e)}');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
}

class _VocabularyWebdavPanel extends StatelessWidget {
  const _VocabularyWebdavPanel({
    required this.webdavEnabled,
    required this.isBackingUp,
    required this.isSyncing,
    required this.onBackup,
    required this.onSync,
  });

  final bool webdavEnabled;
  final bool isBackingUp;
  final bool isSyncing;
  final VoidCallback onBackup;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = isBackingUp || isSyncing;
    final enabled = webdavEnabled && !busy;

    return FilledContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_sync_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _vocabularyWebdavTitle(context),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            webdavEnabled
                ? _vocabularyWebdavEnabledTip(context)
                : _vocabularyWebdavDisabledTip(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: enabled ? onBackup : null,
                icon: isBackingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  isBackingUp
                      ? _vocabularyBackingUp(context)
                      : _vocabularyBackupAction(context),
                ),
              ),
              FilledButton.icon(
                onPressed: enabled ? onSync : null,
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_outlined),
                label: Text(
                  isSyncing
                      ? L10n.of(context).webdavSyncing
                      : L10n.of(context).settingsSyncWebdavSyncNow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VocabularySummary extends StatelessWidget {
  const _VocabularySummary({required this.summaryState});

  final AsyncValue<VocabularySummary> summaryState;

  @override
  Widget build(BuildContext context) {
    return summaryState.when(
      data: (summary) {
        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: L10n.of(context).vocabularyTotal,
                value: summary.total.toString(),
                icon: Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: L10n.of(context).vocabularyDueToday,
                value: summary.due.toString(),
                icon: Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                label: L10n.of(context).vocabularyMastered,
                value: summary.mastered.toString(),
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        );
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FilledContainer(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyVocabulary extends StatelessWidget {
  const _EmptyVocabulary({required this.dueOnly});

  final bool dueOnly;

  @override
  Widget build(BuildContext context) {
    return FilledContainer(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          dueOnly
              ? L10n.of(context).vocabularyNoDueWords
              : L10n.of(context).vocabularyEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _VocabularyCardFlow extends StatelessWidget {
  const _VocabularyCardFlow({
    required this.items,
    required this.expandedIds,
    required this.onToggle,
    required this.onHard,
    required this.onFamiliar,
    required this.onMastered,
    required this.onRemove,
  });

  final List<VocabularyItem> items;
  final Set<String> expandedIds;
  final ValueChanged<String> onToggle;
  final ValueChanged<VocabularyItem> onHard;
  final ValueChanged<VocabularyItem> onFamiliar;
  final ValueChanged<VocabularyItem> onMastered;
  final ValueChanged<VocabularyItem> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = _columnCountForWidth(constraints.maxWidth);
        final buckets = List.generate(columnCount, (_) => <VocabularyItem>[]);
        for (var i = 0; i < items.length; i++) {
          buckets[i % columnCount].add(items[i]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < buckets.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final item in buckets[index])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _VocabularyCard(
                          item: item,
                          isExpanded: expandedIds.contains(item.id),
                          onToggle: () => onToggle(item.id),
                          onHard: () => onHard(item),
                          onFamiliar: () => onFamiliar(item),
                          onMastered: () => onMastered(item),
                          onRemove: () => onRemove(item),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  int _columnCountForWidth(double width) {
    if (width >= 1040) return 3;
    if (width >= 680) return 2;
    return 1;
  }
}

class _VocabularyCard extends StatelessWidget {
  const _VocabularyCard({
    required this.item,
    required this.isExpanded,
    required this.onToggle,
    required this.onHard,
    required this.onFamiliar,
    required this.onMastered,
    required this.onRemove,
  });

  final VocabularyItem item;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onHard;
  final VoidCallback onFamiliar;
  final VoidCallback onMastered;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final definition = _preferredDefinition(context, item);

    return FilledContainer(
      padding: EdgeInsets.zero,
      color: isExpanded
          ? colorScheme.primaryContainer.withValues(alpha: 0.35)
          : colorScheme.surfaceContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VocabularyCardHeader(
                  item: item,
                  isExpanded: isExpanded,
                  definition: definition,
                ),
                const SizedBox(height: 10),
                Text(
                  item.sourceSentence,
                  maxLines: isExpanded ? 6 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _FamiliarityChip(item: item),
                    _MetaChip(
                      icon: Icons.event_available_outlined,
                      label: _formatNextReview(context, item),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const Divider(height: 24),
                  _VocabularyExpandedDetails(item: item),
                  const SizedBox(height: 12),
                  _VocabularyActions(
                    onHard: onHard,
                    onFamiliar: onFamiliar,
                    onMastered: onMastered,
                    onRemove: onRemove,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VocabularyCardHeader extends StatelessWidget {
  const _VocabularyCardHeader({
    required this.item,
    required this.isExpanded,
    required this.definition,
  });

  final VocabularyItem item;
  final bool isExpanded;
  final String definition;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    item.word,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (_present(item.partOfSpeech))
                    _Pill(label: item.partOfSpeech!),
                ],
              ),
              if (_present(item.phonetic)) ...[
                const SizedBox(height: 4),
                Text(
                  item.phonetic!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontFeatures: const [],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                definition,
                maxLines: isExpanded ? 8 : 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: colorScheme.primary,
        ),
      ],
    );
  }
}

class _VocabularyExpandedDetails extends StatelessWidget {
  const _VocabularyExpandedDetails({required this.item});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailBlock(
          icon: Icons.record_voice_over_outlined,
          title: l10n.vocabularyPronunciation,
          body: _present(item.phonetic) ? item.phonetic! : '-',
          trailing: _PronunciationButton(item: item),
        ),
        _DetailBlock(
          icon: Icons.auto_stories_outlined,
          title: l10n.vocabularyContextSentence,
          body: item.sourceSentence,
        ),
        _DetailBlock(
          icon: Icons.translate_outlined,
          title: l10n.vocabularySentenceTranslation,
          body: _textOrFallback(
            item.sourceSentenceTranslation,
            l10n.vocabularyNoTranslation,
          ),
        ),
        _DetailBlock(
          icon: Icons.psychology_alt_outlined,
          title: l10n.vocabularyContextMeaning,
          body: _preferredDefinition(context, item),
        ),
        _DetailBlock(
          icon: Icons.format_quote_outlined,
          title: l10n.vocabularyExamples,
          body: _exampleText(context, item),
        ),
        _LearningStatusBlock(item: item),
        _SourceBlock(item: item),
      ],
    );
  }

  String _exampleText(BuildContext context, VocabularyItem item) {
    final sentence = _textOrFallback(
      item.exampleSentence,
      L10n.of(context).vocabularyNoExample,
    );
    if (!_present(item.exampleTranslation)) {
      return sentence;
    }
    return '$sentence\n${item.exampleTranslation}';
  }
}

class _LearningStatusBlock extends StatelessWidget {
  const _LearningStatusBlock({required this.item});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final lines = [
      '${l10n.vocabularyLearningStatus}: ${_familiarityLabel(context, item)}',
      '${l10n.vocabularyReviewStage}: ${item.reviewStage}',
      '${l10n.vocabularyCorrectWrong}: ${item.correctCount}/${item.wrongCount}',
      '${l10n.vocabularyDueReview}: ${_formatNextReview(context, item)}',
      if (item.lastReviewedAt != null)
        '${l10n.vocabularyLastReviewed}: ${_formatDate(item.lastReviewedAt!)}',
    ];

    return _DetailBlock(
      icon: Icons.insights_outlined,
      title: l10n.vocabularyLearningStatus,
      body: lines.join('\n'),
    );
  }
}

class _SourceBlock extends StatelessWidget {
  const _SourceBlock({required this.item});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    final sourceLines = [
      if (_present(item.bookTitle)) item.bookTitle!,
      if (_present(item.chapterTitle)) item.chapterTitle!,
      if (_present(item.position)) item.position!,
    ];

    if (sourceLines.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DetailBlock(
      icon: Icons.book_outlined,
      title: L10n.of(context).vocabularySource,
      body: sourceLines.join('\n'),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledContainer(
        padding: const EdgeInsets.all(12),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PronunciationButton extends StatelessWidget {
  const _PronunciationButton({required this.item});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.volume_up_outlined, size: 18),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      tooltip: L10n.of(context).vocabularyPronunciation,
      onPressed: () async {
        try {
          await PronunciationPlayer().play(
            text: item.word,
            audioUrl: item.audioUrl,
          );
        } catch (_) {
          if (context.mounted) {
            AnxToast.show(L10n.of(context).commonFailed);
          }
        }
      },
    );
  }
}

class _VocabularyActions extends StatelessWidget {
  const _VocabularyActions({
    required this.onHard,
    required this.onFamiliar,
    required this.onMastered,
    required this.onRemove,
  });

  final VoidCallback onHard;
  final VoidCallback onFamiliar;
  final VoidCallback onMastered;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onHard,
          icon: const Icon(Icons.refresh_outlined),
          label: Text(L10n.of(context).vocabularyHard),
        ),
        FilledButton.tonalIcon(
          onPressed: onFamiliar,
          icon: const Icon(Icons.check_outlined),
          label: Text(L10n.of(context).vocabularyFamiliar),
        ),
        FilledButton.icon(
          onPressed: onMastered,
          icon: const Icon(Icons.done_all_outlined),
          label: Text(L10n.of(context).vocabularyMarkMastered),
        ),
        TextButton.icon(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
          label: Text(L10n.of(context).vocabularyRemove),
        ),
      ],
    );
  }
}

class _FamiliarityChip extends StatelessWidget {
  const _FamiliarityChip({required this.item});

  final VocabularyItem item;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (item.familiarity) {
      VocabularyFamiliarity.newWord => (
          L10n.of(context).vocabularyNewWord,
          Icons.fiber_new_outlined,
        ),
      VocabularyFamiliarity.hard => (
          L10n.of(context).vocabularyHard,
          Icons.refresh_outlined,
        ),
      VocabularyFamiliarity.familiar => (
          L10n.of(context).vocabularyFamiliar,
          Icons.check_outlined,
        ),
      VocabularyFamiliarity.mastered => (
          L10n.of(context).vocabularyMastered,
          Icons.done_all_outlined,
        ),
    };

    return _MetaChip(icon: icon, label: label);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

String _preferredDefinition(BuildContext context, VocabularyItem item) {
  return _textOrFallback(
    item.contextualDefinition ?? item.definitionCn ?? item.definitionEn,
    L10n.of(context).vocabularyNoDefinition,
  );
}

String _textOrFallback(String? text, String fallback) {
  return _present(text) ? text!.trim() : fallback;
}

bool _present(String? text) => text != null && text.trim().isNotEmpty;

String _formatNextReview(BuildContext context, VocabularyItem item) {
  if (item.isMastered) {
    return L10n.of(context).vocabularyMastered;
  }

  final now = DateTime.now();
  final difference = item.nextReviewAt.difference(now);
  if (difference.inMinutes <= 0) {
    return L10n.of(context).vocabularyReviewNow;
  }
  if (difference.inHours < 24) {
    return L10n.of(context).vocabularyReviewInHours(difference.inHours + 1);
  }
  return L10n.of(context).vocabularyReviewInDays(difference.inDays + 1);
}

String _familiarityLabel(BuildContext context, VocabularyItem item) {
  return switch (item.familiarity) {
    VocabularyFamiliarity.newWord => L10n.of(context).vocabularyNewWord,
    VocabularyFamiliarity.hard => L10n.of(context).vocabularyHard,
    VocabularyFamiliarity.familiar => L10n.of(context).vocabularyFamiliar,
    VocabularyFamiliarity.mastered => L10n.of(context).vocabularyMastered,
  };
}

bool _isChineseLocale(BuildContext context) {
  return L10n.of(context).localeName.startsWith('zh');
}

String _vocabularyWebdavTitle(BuildContext context) {
  return _isChineseLocale(context) ? 'WebDAV 备份与同步' : 'WebDAV Backup & Sync';
}

String _vocabularyWebdavEnabledTip(BuildContext context) {
  return _isChineseLocale(context)
      ? '仅同步单词本数据。备份会覆盖云端单词本；同步会下载云端单词并按更新时间合并后回传。'
      : 'Syncs vocabulary data only. Backup overwrites the cloud vocabulary; Sync downloads remote words, merges by update time, then uploads the merged copy.';
}

String _vocabularyWebdavDisabledTip(BuildContext context) {
  return _isChineseLocale(context)
      ? '请先在同步设置中配置并启用 WebDAV。单词本关闭时此功能不可用。'
      : 'Configure and enable WebDAV in Sync settings first. This is unavailable when Vocabulary is disabled.';
}

String _vocabularyBackupAction(BuildContext context) {
  return _isChineseLocale(context) ? '备份到 WebDAV' : 'Back up to WebDAV';
}

String _vocabularyBackingUp(BuildContext context) {
  return _isChineseLocale(context) ? '备份中...' : 'Backing up...';
}

String Function(int count) _vocabularyBackupSuccessMessage(
  BuildContext context,
) {
  final isChinese = _isChineseLocale(context);
  return (count) => isChinese
      ? '单词本已备份到 WebDAV，共 $count 个单词'
      : 'Vocabulary backed up to WebDAV: $count words';
}

String Function(int changed, int total) _vocabularySyncSuccessMessage(
  BuildContext context,
) {
  final isChinese = _isChineseLocale(context);
  return (changed, total) => isChinese
      ? '单词本同步完成，更新 $changed 个，共 $total 个单词'
      : 'Vocabulary sync complete: $changed updated, $total words total';
}

String _vocabularyBackupFailedPrefix(BuildContext context) {
  return _isChineseLocale(context) ? '单词本备份失败' : 'Vocabulary backup failed';
}

String _vocabularySyncFailedPrefix(BuildContext context) {
  return _isChineseLocale(context) ? '单词本同步失败' : 'Vocabulary sync failed';
}

String _friendlySyncError(BuildContext context, Object error) {
  final l10n = L10n.of(context);
  final message =
      error is VocabularyWebdavSyncException ? error.message : error.toString();

  return switch (message) {
    'Vocabulary is disabled' => _isChineseLocale(context)
        ? '请先在外观设置中开启单词本功能'
        : 'Enable Vocabulary in Appearance settings first',
    'WebDAV is not enabled' => l10n.webdavWebdavNotEnabled,
    'Wi-Fi is required' => l10n.webdavOnlyWifi,
    'Please set WebDAV information first' => l10n.webdavSetInfoFirst,
    _ => message,
  };
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
