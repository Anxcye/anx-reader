import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/page/settings_page/ai_provider_detail_page.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:anx_reader/service/ai/ai_extraction_engine.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

enum AiProviderListMode { general, translation, extraction }

class AiProviderListPage extends ConsumerWidget {
  const AiProviderListPage({
    super.key,
    this.mode = AiProviderListMode.general,
  });

  final AiProviderListMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    final providers = ref.watch(aiProvidersProvider);
    final notifier = ref.read(aiProvidersProvider.notifier);
    final selectedId = switch (mode) {
      AiProviderListMode.general => notifier.getSelectedProvider()?.id,
      AiProviderListMode.translation =>
        notifier.getDedicatedTranslationProvider()?.id,
      AiProviderListMode.extraction => notifier.getExtractionProvider()?.id,
    };
    final generalProvider = notifier.getRunnableSelectedProvider();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (mode) {
            AiProviderListMode.translation =>
              l10n.settingsAiTranslationProviders,
            AiProviderListMode.extraction => '轻量提取与摘要引擎',
            AiProviderListMode.general => l10n.settingsAiGeneralProviders,
          },
        ),
        actions: [
          if (mode == AiProviderListMode.extraction)
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: '配置帮助',
              onPressed: () => _showExtractionHelp(context),
            ),
          if (mode == AiProviderListMode.extraction)
            IconButton(
              icon: const Icon(Icons.science_outlined),
              tooltip: '测试结构化提取',
              onPressed: () => _testExtraction(context, ref),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addProvider(context),
            tooltip: l10n.settingsAiProvidersAdd,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              switch (mode) {
                AiProviderListMode.translation =>
                  l10n.settingsAiTranslationProvidersTip,
                AiProviderListMode.extraction =>
                  '本地候选提取器 + 证据筛选器：用于故事档案、内部摘要和阅读记忆。完整正文只进入此引擎，最终结果还会经过确定性校验。',
                AiProviderListMode.general =>
                  l10n.settingsAiGeneralProvidersTip,
              },
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          if (mode == AiProviderListMode.translation)
            _FollowGeneralProviderTile(
              selected: selectedId == null,
              generalProvider: generalProvider,
              onSelected: () => notifier.setTranslationProvider(null),
            ),
          if (mode == AiProviderListMode.extraction)
            _DisableExtractionTile(
              selected: selectedId == null,
              onSelected: () => notifier.setExtractionProvider(null),
            ),
          for (final provider in providers)
            _ProviderTile(
              provider: provider,
              selected: provider.id == selectedId,
              selectedLabel: switch (mode) {
                AiProviderListMode.general => l10n.settingsAiProviderDefault,
                AiProviderListMode.translation =>
                  l10n.aiTranslationProviderSelected,
                AiProviderListMode.extraction => '已用于轻量提取',
              },
              runnable: notifier.isRunnableProvider(provider),
              onSelected: () {
                if (mode == AiProviderListMode.translation) {
                  notifier.setTranslationProvider(provider.id);
                } else if (mode == AiProviderListMode.extraction) {
                  notifier.setExtractionProvider(provider.id);
                } else {
                  notifier.setSelectedProvider(provider.id);
                }
              },
              onEnabledChanged: (value) {
                notifier.toggleProvider(provider.id, value);
              },
              onEdit: () => _editProvider(context, provider.id),
              onDelete: provider.isBuiltin
                  ? null
                  : () => _deleteProvider(context, ref, provider),
            ),
        ],
      ),
    );
  }

  Future<void> _addProvider(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AiProviderDetailPage(providerId: null),
      ),
    );
  }

  Future<void> _showExtractionHelp(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('轻量提取引擎配置'),
          content: const SingleChildScrollView(
            child: SelectableText(
              'LM Studio\n'
              '选择 OpenAI 兼容协议，地址使用 '
              'http://<主机IP>:1234/v1/chat/completions，认证选“无认证”。\n'
              'Qwen 模板首行可加：{%- set enable_thinking = false %}\n\n'
              'Ollama\n'
              '启动示例：ollama run qwen3.5:4b --think=false\n'
              '兼容地址：http://<主机IP>:11434/v1/chat/completions\n\n'
              'Android 上 localhost 指手机本身。连接电脑或 NAS '
              '时请使用局域网 IP，并只在受信任网络中启用无认证服务。\n\n'
              '定位是“本地候选提取器 + 证据筛选器”，不是全书关系图生成器。完整正文默认只发送到此引擎；通用线上模型只复核疑难候选和短证据。',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );

  Future<void> _testExtraction(BuildContext context, WidgetRef ref) async {
    final provider =
        ref.read(aiProvidersProvider.notifier).getExtractionProvider();
    if (provider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择可用的提取 Provider')),
      );
      return;
    }
    SmartDialog.showLoading(msg: '正在测试 ${provider.model}…');
    try {
      final result = await aiExtractionEngine.extract(
        taskId: AiExtractionTaskIds.fictionStoryAtlas,
        prompt: '只返回严格 JSON：{"character":"第五伦","evidence":"第五伦走进屋内"}',
        ref: ref,
      );
      if (!result.isValid) {
        ref.read(aiProvidersProvider.notifier).setExtractionProvider(null);
      }
      SmartDialog.dismiss();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result.isValid ? '提取引擎可用' : '提取结果不合格'),
          content: Text(
            'Provider：${provider.title}\n'
            '模型：${result.model}\n'
            '部署：${result.deployment == AiProviderDeployment.localPrivate ? '本地/内网' : '云端'}\n'
            '耗时：${result.elapsed.inMilliseconds} ms\n'
            '输入：${result.inputTokens} Token${result.usageEstimated ? '（含估算）' : ''}\n'
            '输出：${result.outputTokens} Token\n'
            'JSON：${result.isValid ? '合格' : result.validationErrors.join('；')}\n'
            'Thinking：${result.raw.contains('<think>') ? '检测到思考标记，请在服务端关闭' : '未在正文检测到'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    } catch (error) {
      SmartDialog.dismiss();
      ref.read(aiProvidersProvider.notifier).setExtractionProvider(null);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('测试失败：$error')),
      );
    }
  }

  Future<void> _editProvider(BuildContext context, String providerId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiProviderDetailPage(providerId: providerId),
      ),
    );
  }

  Future<void> _deleteProvider(
    BuildContext context,
    WidgetRef ref,
    AiProvider provider,
  ) async {
    final l10n = L10n.of(context);
    var confirmed = false;

    await SmartDialog.show(
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.commonConfirm),
        content: Text(l10n.settingsAiProviderDeleteConfirm),
        actions: [
          TextButton(
            onPressed: SmartDialog.dismiss,
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              confirmed = true;
              SmartDialog.dismiss();
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmed && context.mounted) {
      ref.read(aiProvidersProvider.notifier).deleteProvider(provider.id);
    }
  }
}

class _DisableExtractionTile extends StatelessWidget {
  const _DisableExtractionTile({
    required this.selected,
    required this.onSelected,
  });

  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.pause_circle_outline_rounded),
        title: const Text('不使用轻量提取引擎'),
        subtitle: const Text('默认关闭；不会自动将完整正文改发到线上模型'),
        trailing: selected ? const Icon(Icons.check_circle_rounded) : null,
        onTap: onSelected,
      );
}

class _FollowGeneralProviderTile extends StatelessWidget {
  const _FollowGeneralProviderTile({
    required this.selected,
    required this.generalProvider,
    required this.onSelected,
  });

  final bool selected;
  final AiProvider? generalProvider;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final model = generalProvider?.model.trim();

    return FilledContainer(
      radius: 20,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        minVerticalPadding: 12,
        leading: _SelectionButton(
          selected: selected,
          enabled: true,
          onPressed: onSelected,
        ),
        title: Text(l10n.aiTranslationProviderDefault),
        subtitle: Text(
          generalProvider == null
              ? l10n.aiProviderNoRunnable
              : [
                  generalProvider!.title,
                  if (model != null && model.isNotEmpty) model,
                ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onSelected,
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.selected,
    required this.selectedLabel,
    required this.runnable,
    required this.onSelected,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final AiProvider provider;
  final bool selected;
  final String selectedLabel;
  final bool runnable;
  final VoidCallback onSelected;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final model = provider.model.trim();

    return FilledContainer(
      radius: 20,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onEdit,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(
            children: [
              _SelectionButton(
                selected: selected,
                enabled: runnable,
                onPressed: onSelected,
              ),
              _ProviderLogo(provider: provider),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Text(
                            selectedLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      model.isEmpty ? provider.url : model,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!runnable)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          !provider.enabled
                              ? l10n.settingsAiProviderDisabled
                              : !provider.hasValidKey
                                  ? l10n.settingsAiProviderNoValidKeys
                                  : l10n.configurationInformationIsIncomplete,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onDelete != null)
                SizedBox.square(
                  dimension: 48,
                  child: IconButton(
                    tooltip: l10n.commonDelete,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              Switch(
                value: provider.enabled,
                onChanged: onEnabledChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
        ),
      ),
    );
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({required this.provider});

  final AiProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.logoAsset != null) {
      return Image.asset(
        provider.logoAsset!,
        width: 32,
        height: 32,
        errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return CircleAvatar(
      radius: 16,
      child: Text(
        provider.title.isEmpty ? '?' : provider.title[0].toUpperCase(),
      ),
    );
  }
}
