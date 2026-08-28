import 'package:anx_reader/enums/ai_reasoning_effort.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/providers/ai_providers.dart';
import 'package:anx_reader/service/ai/ai_model_service.dart';
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
  late TextEditingController _timeoutController;

  AiProtocol _selectedProtocol = AiProtocol.openai;
  AiProviderAuthMode _authMode = AiProviderAuthMode.bearer;
  AiProviderDeployment _deployment = AiProviderDeployment.cloud;
  AiReasoningEffort _reasoningEffort = AiReasoningEffort.auto;
  List<AiApiKey> _apiKeys = [];
  bool _isModified = false;
  bool _isFetchingModels = false;
  String? _createdProviderId;
  final GlobalKey _fetchButtonKey = GlobalKey();

  String? get _providerId => widget.providerId ?? _createdProviderId;

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
    _timeoutController = TextEditingController(
      text: (provider?.requestTimeoutSeconds ?? 0).toString(),
    );
    _selectedProtocol = provider?.protocol ?? AiProtocol.openai;
    _authMode = provider?.authMode ?? AiProviderAuthMode.bearer;
    _deployment = provider?.deployment ?? AiProviderDeployment.cloud;
    _reasoningEffort = provider?.reasoningEffort ?? AiReasoningEffort.auto;
    _apiKeys = provider?.apiKeys.toList() ?? [];

    _nameController.addListener(() => setState(() => _isModified = true));
    _urlController.addListener(() => setState(() => _isModified = true));
    _modelController.addListener(() => setState(() => _isModified = true));
    _timeoutController.addListener(() => setState(() => _isModified = true));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _modelController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final providerId = _providerId;
    final provider = providerId != null
        ? ref.watch(aiProvidersProvider).firstWhere((p) => p.id == providerId)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(providerId == null
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
                  if (_selectedProtocol != AiProtocol.openai) {
                    _authMode = AiProviderAuthMode.bearer;
                  }
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
            if (_authMode == AiProviderAuthMode.bearer)
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

            if (_authMode == AiProviderAuthMode.bearer && _apiKeys.isEmpty)
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
            else if (_authMode == AiProviderAuthMode.bearer)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnxButton.outlined(
                      onPressed: _testConnection,
                      child: Text(l10n.settingsAiProviderTestConnection),
                    ),
                  ],
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
          DropdownButtonFormField<AiProviderAuthMode>(
            initialValue: _authMode,
            decoration: const InputDecoration(
              labelText: '认证方式',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: AiProviderAuthMode.bearer,
                child: Text('API Key / Bearer'),
              ),
              DropdownMenuItem(
                value: AiProviderAuthMode.none,
                child: Text('无认证（本地 / 内网）'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _authMode = value;
                if (value == AiProviderAuthMode.none) {
                  _selectedProtocol = AiProtocol.openai;
                  _deployment = AiProviderDeployment.localPrivate;
                }
                _isModified = true;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AiProviderDeployment>(
            initialValue: _deployment,
            decoration: const InputDecoration(
              labelText: '部署位置',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: AiProviderDeployment.cloud,
                child: Text('云端'),
              ),
              DropdownMenuItem(
                value: AiProviderDeployment.localPrivate,
                child: Text('本机 / 局域网 / NAS'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _deployment = value;
                _isModified = true;
              });
            },
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          TextField(
            controller: _timeoutController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _requestTimeoutLabel(context),
              helperText: _requestTimeoutHelp(context),
              border: const OutlineInputBorder(),
            ),
          ),
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
    if ((_authMode == AiProviderAuthMode.bearer && enabledKeys.isEmpty) ||
        _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsAiProviderNoValidKeys)),
      );
      return;
    }

    setState(() => _isFetchingModels = true);

    try {
      final timeout = _parseRequestTimeoutSeconds() <= 0
          ? Duration.zero
          : Duration(seconds: _parseRequestTimeoutSeconds());
      final models = await fetchAiModels(
        url: _urlController.text.trim(),
        apiKey: enabledKeys.isEmpty ? '' : enabledKeys.first.key,
        timeout: timeout,
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
    if (!_validateProviderForm()) return;
    _persistProviderForm();

    setState(() => _isModified = false);
    Navigator.pop(context);
  }

  void _testConnection() {
    final l10n = L10n.of(context);

    // Save any pending changes before testing so the provider has the latest config
    if (_providerId == null || _isModified) {
      if (!_validateProviderForm()) return;
      _persistProviderForm();
      setState(() => _isModified = false);
    }
    final providerId = _providerId;

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
            identifier: providerId,
            regenerate: true,
            allowFallback: false,
          ),
        ),
      ),
    );
  }

  bool _validateProviderForm() {
    if (_nameController.text.trim().isNotEmpty &&
        _urlController.text.trim().isNotEmpty &&
        _modelController.text.trim().isNotEmpty &&
        (_authMode == AiProviderAuthMode.none ||
            _apiKeys.any((key) => key.enabled && key.key.trim().isNotEmpty))) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.of(context).configurationInformationIsIncomplete),
      ),
    );
    return false;
  }

  void _persistProviderForm() {
    final currentId = _providerId;
    final providers = ref.read(aiProvidersProvider);
    AiProvider? existing;
    if (currentId != null) {
      try {
        existing = providers.firstWhere((provider) => provider.id == currentId);
      } catch (_) {}
    }

    final provider = AiProvider(
      id: currentId ?? const Uuid().v4(),
      title: _nameController.text.trim(),
      url: _urlController.text.trim(),
      protocol: _selectedProtocol,
      enabled: existing?.enabled ?? true,
      isBuiltin: existing?.isBuiltin ?? false,
      apiKeys: _apiKeys,
      model: _modelController.text.trim(),
      authMode: _authMode,
      deployment: _deployment,
      reasoningEffort: _reasoningEffort,
      requestTimeoutSeconds: _parseRequestTimeoutSeconds(),
      keyIndex: existing?.keyIndex ?? 0,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(aiProvidersProvider.notifier);
    if (existing == null) {
      _createdProviderId = notifier.addProvider(provider);
    } else {
      notifier.updateProvider(provider);
    }
  }

  int _parseRequestTimeoutSeconds() {
    final parsed = int.tryParse(_timeoutController.text.trim()) ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  String _requestTimeoutLabel(BuildContext context) {
    final isChinese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    return isChinese ? '请求超时（秒）' : 'Request Timeout (seconds)';
  }

  String _requestTimeoutHelp(BuildContext context) {
    final isChinese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    return isChinese
        ? '0 表示不主动超时，适合本地部署 LLM。仅对 OpenAI 兼容协议生效。'
        : '0 disables app-level timeout. Useful for local LLMs. Applies to OpenAI-compatible providers only.';
  }
}
