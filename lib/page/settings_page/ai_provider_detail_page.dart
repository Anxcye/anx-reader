import 'package:anx_reader/enums/ai_reasoning_effort.dart';
import 'package:anx_reader/enums/ai_thinking_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:anx_reader/service/ai/ai_model_service.dart';
import 'package:anx_reader/service/ai/deepseek_compatibility.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/widgets/ai/ai_stream.dart';
import 'package:anx_reader/widgets/common/anx_button.dart';
import 'package:anx_reader/widgets/common/anx_segmented_button.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:uuid/uuid.dart';

class AiProviderDetailPage extends ConsumerStatefulWidget {
  final String? providerId; // null for new provider

  const AiProviderDetailPage({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<AiProviderDetailPage> createState() =>
      _AiProviderDetailPageState();
}

class _AiProviderDetailPageState extends ConsumerState<AiProviderDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _modelController;

  AiProtocol _selectedProtocol = AiProtocol.openai;
  AiReasoningEffort _reasoningEffort = AiReasoningEffort.auto;
  AiThinkingMode _thinkingMode = AiThinkingMode.auto;
  List<AiApiKey> _apiKeys = [];
  bool _isModified = false;
  bool _isFetchingModels = false;
  final GlobalKey _fetchButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    final provider = widget.providerId != null
        ? ref
            .read(aiProvidersProvider)
            .firstWhere((p) => p.id == widget.providerId)
        : null;

    _nameController = TextEditingController(text: provider?.title ?? '');
    _urlController = TextEditingController(text: provider?.url ?? '');
    _modelController = TextEditingController(text: provider?.model ?? '');
    _selectedProtocol = provider?.protocol ?? AiProtocol.openai;
    _reasoningEffort = provider?.reasoningEffort ?? AiReasoningEffort.auto;
    _thinkingMode = provider?.thinkingMode ?? AiThinkingMode.auto;
    _apiKeys = provider?.apiKeys.toList() ?? [];

    _nameController.addListener(() => setState(() => _isModified = true));
    _urlController.addListener(() => setState(() => _isModified = true));
    _modelController.addListener(() => setState(() => _isModified = true));
  }

  bool get _isDeepSeekLikeProvider => isDeepSeekProvider(
        identifier: widget.providerId ?? '',
        model: _modelController.text,
        baseUrl: _urlController.text,
      );

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final provider = widget.providerId != null
        ? ref
            .watch(aiProvidersProvider)
            .firstWhere((p) => p.id == widget.providerId)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.providerId == null
            ? l10n.settingsAiProvidersAdd
            : l10n.settingsAiProviderName),
        actions: [
          if (_isModified)
            TextButton(
              onPressed: _saveProvider,
              child: Text(l10n.commonSave),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.settingsAiProviderName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Protocol Type
            Text(l10n.settingsAiProviderProtocol,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            AnxSegmentedButton<AiProtocol>(
              selected: {_selectedProtocol},
              segments: [
                SegmentButtonItem(
                  value: AiProtocol.openai,
                  label: l10n.settingsAiProviderProtocolOpenai,
                ),
                SegmentButtonItem(
                  value: AiProtocol.claude,
                  label: l10n.settingsAiProviderProtocolClaude,
                ),
                SegmentButtonItem(
                  value: AiProtocol.gemini,
                  label: l10n.settingsAiProviderProtocolGemini,
                ),
              ],
              onSelectionChanged: (Set<AiProtocol> selection) {
                setState(() {
                  _selectedProtocol = selection.first;
                  _isModified = true;
                });
              },
            ),
            const SizedBox(height: 16),

            // API URL
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: l10n.settingsAiProviderUrl,
                border: const OutlineInputBorder(),
                helperText: _selectedProtocol == AiProtocol.openai
                    ? l10n.settingsAiProviderUrlHint
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Model
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: l10n.settingsAiProviderModel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_selectedProtocol == AiProtocol.openai) ...[
                  const SizedBox(width: 8),
                  AnxButton(
                    key: _fetchButtonKey,
                    onPressed: _isFetchingModels ? null : _fetchModels,
                    isLoading: _isFetchingModels,
                    child: Text(l10n.settingsAiProviderFetchModels),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            _buildAdvancedSettingsCard(context),
            const SizedBox(height: 16),

            // API Keys Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.settingsAiProviderApiKeys,
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addApiKey,
                  tooltip: l10n.settingsAiProviderAddKey,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_apiKeys.isEmpty)
              FilledContainer(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.key_off_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(120),
                      ),
                      Text(
                        l10n.settingsAiProviderNoValidKeys,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(150),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      AnxButton.icon(
                        onPressed: _addApiKey,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.settingsAiProviderAddKey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._apiKeys.asMap().entries.map((entry) {
                final index = entry.key;
                final apiKey = entry.value;
                return _buildApiKeyTile(apiKey, index);
              }),

            const SizedBox(height: 24),

            // Test Connection Button (at bottom)
            if (provider != null)
              SizedBox(
                width: double.infinity,
                child: AnxButton.outlined(
                  onPressed: _testConnection,
                  child: Text(l10n.settingsAiProviderTestConnection),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsCard(BuildContext context) {
    final l10n = L10n.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.secondary;
    return FilledContainer(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.all(16),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: accent,
        collapsedIconColor: accent.withValues(alpha: 0.82),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 18,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsAdvanced,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          DropdownButtonFormField<AiReasoningEffort>(
            initialValue: _reasoningEffort,
            decoration: InputDecoration(
              labelText: l10n.settingsAiProviderReasoningEffort,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: AiReasoningEffort.auto,
                child: Text(l10n.settingsAiProviderReasoningEffortAuto),
              ),
              DropdownMenuItem(
                value: AiReasoningEffort.low,
                child: Text(l10n.settingsAiProviderReasoningEffortLow),
              ),
              DropdownMenuItem(
                value: AiReasoningEffort.medium,
                child: Text(l10n.settingsAiProviderReasoningEffortMedium),
              ),
              DropdownMenuItem(
                value: AiReasoningEffort.high,
                child: Text(l10n.settingsAiProviderReasoningEffortHigh),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _reasoningEffort = value;
                _isModified = true;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.settingsAiProviderReasoningEffortHelp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (_isDeepSeekLikeProvider) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<AiThinkingMode>(
              initialValue: _thinkingMode,
              decoration: InputDecoration(
                labelText: l10n.settingsAiProviderThinkingMode,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: AiThinkingMode.auto,
                  child: Text(l10n.settingsAiProviderThinkingModeAuto),
                ),
                DropdownMenuItem(
                  value: AiThinkingMode.enabled,
                  child: Text(l10n.settingsAiProviderThinkingModeEnabled),
                ),
                DropdownMenuItem(
                  value: AiThinkingMode.disabled,
                  child: Text(l10n.settingsAiProviderThinkingModeDisabled),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _thinkingMode = value;
                  _isModified = true;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.settingsAiProviderThinkingModeHelp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiKeyTile(AiApiKey apiKey, int index) {
    final l10n = L10n.of(context);
    bool obscureKey = true;

    return FilledContainer(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    apiKey.label?.isNotEmpty == true
                        ? apiKey.label!
                        : 'API Key ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Switch(
                  value: apiKey.enabled,
                  onChanged: (value) {
                    setState(() {
                      _apiKeys[index] = AiApiKey(
                        id: apiKey.id,
                        key: apiKey.key,
                        enabled: value,
                        label: apiKey.label,
                        createdAt: apiKey.createdAt,
                      );
                      _isModified = true;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteApiKey(index),
                  tooltip: l10n.commonDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setModalState) {
                return TextFormField(
                  initialValue: apiKey.key,
                  obscureText: obscureKey,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscureKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setModalState(() => obscureKey = !obscureKey);
                      },
                    ),
                  ),
                  onChanged: (value) {
                    _apiKeys[index] = AiApiKey(
                      id: apiKey.id,
                      key: value,
                      enabled: apiKey.enabled,
                      label: apiKey.label,
                      createdAt: apiKey.createdAt,
                    );
                    _isModified = true;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addApiKey() {
    final l10n = L10n.of(context);
    final labelController = TextEditingController();
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsAiProviderAddKey),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: l10n.settingsAiProviderKeyLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                setState(() {
                  _apiKeys.add(AiApiKey(
                    id: const Uuid().v4(),
                    key: keyController.text,
                    enabled: true,
                    label: labelController.text.isNotEmpty
                        ? labelController.text
                        : null,
                    createdAt: DateTime.now(),
                  ));
                  _isModified = true;
                });
                Navigator.pop(context);
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteApiKey(int index) async {
    final l10n = L10n.of(context);
    bool confirmed = false;

    await SmartDialog.show(
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.commonConfirm),
        content: Text(l10n.commonDelete),
        actions: [
          TextButton(
            onPressed: () {
              confirmed = false;
              SmartDialog.dismiss();
            },
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

    if (confirmed) {
      setState(() {
        _apiKeys.removeAt(index);
        _isModified = true;
      });
    }
  }

  Future<void> _fetchModels() async {
    final l10n = L10n.of(context);
    final enabledKeys = _apiKeys.where((k) => k.enabled && k.key.isNotEmpty);
    if (enabledKeys.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsAiProviderNoValidKeys)),
      );
      return;
    }

    setState(() => _isFetchingModels = true);

    try {
      final models = await fetchAiModels(
        url: _urlController.text.trim(),
        apiKey: enabledKeys.first.key,
      );

      if (!mounted) return;
      setState(() => _isFetchingModels = false);

      if (models.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsAiProviderNoModelsFound)),
        );
        return;
      }

      // Position the dropdown below the fetch button
      final renderBox =
          _fetchButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
      final size = renderBox?.size ?? Size.zero;

      final selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy + size.height,
          offset.dx + size.width,
          offset.dy + size.height + 1,
        ),
        constraints: BoxConstraints(
          minWidth: 220,
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        items: models
            .map(
              (modelId) => PopupMenuItem<String>(
                value: modelId,
                child: Text(modelId),
              ),
            )
            .toList(),
      );

      if (selected != null) {
        _modelController.text = selected;
        setState(() => _isModified = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingModels = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n.settingsAiProviderFetchModelsFailed(e.toString())),
          ),
        );
      }
    }
  }

  void _saveProvider() {
    final l10n = L10n.of(context);

    if (_nameController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonFailed)),
      );
      return;
    }

    final provider = AiProvider(
      id: widget.providerId ?? const Uuid().v4(),
      title: _nameController.text,
      url: _urlController.text,
      protocol: _selectedProtocol,
      enabled: true,
      isBuiltin: widget.providerId != null
          ? ref
              .read(aiProvidersProvider)
              .firstWhere((p) => p.id == widget.providerId)
              .isBuiltin
          : false,
      apiKeys: _apiKeys,
      model: _modelController.text,
      reasoningEffort: _reasoningEffort,
      thinkingMode: _thinkingMode,
      keyIndex: 0,
      createdAt: widget.providerId != null
          ? ref
              .read(aiProvidersProvider)
              .firstWhere((p) => p.id == widget.providerId)
              .createdAt
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.providerId == null) {
      ref.read(aiProvidersProvider.notifier).addProvider(provider);
    } else {
      ref.read(aiProvidersProvider.notifier).updateProvider(provider);
    }

    setState(() => _isModified = false);
    Navigator.pop(context);
  }

  void _testConnection() {
    final l10n = L10n.of(context);

    // Save any pending changes before testing so the provider has the latest config
    if (_isModified) {
      if (_nameController.text.isEmpty || _urlController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonFailed)),
        );
        return;
      }
      final provider = AiProvider(
        id: widget.providerId ?? const Uuid().v4(),
        title: _nameController.text,
        url: _urlController.text,
        protocol: _selectedProtocol,
        enabled: true,
        isBuiltin: widget.providerId != null
            ? ref
                .read(aiProvidersProvider)
                .firstWhere((p) => p.id == widget.providerId)
                .isBuiltin
            : false,
        apiKeys: _apiKeys,
        model: _modelController.text,
        reasoningEffort: _reasoningEffort,
        thinkingMode: _thinkingMode,
        keyIndex: 0,
        createdAt: widget.providerId != null
            ? ref
                .read(aiProvidersProvider)
                .firstWhere((p) => p.id == widget.providerId)
                .createdAt
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (widget.providerId == null) {
        ref.read(aiProvidersProvider.notifier).addProvider(provider);
      } else {
        ref.read(aiProvidersProvider.notifier).updateProvider(provider);
      }
      setState(() => _isModified = false);
    }

    SmartDialog.show(
      onDismiss: () {
        cancelActiveAiRequest();
      },
      builder: (context) => AlertDialog(
        title: Text(l10n.commonTest),
        content: SizedBox(
          width: double.maxFinite,
          child: AiStream(
            prompt: generatePromptTest(),
            identifier: widget.providerId,
            regenerate: true,
          ),
        ),
      ),
    );
  }
}
