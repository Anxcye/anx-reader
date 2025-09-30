import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/chapter_split_presets.dart';
import 'package:anx_reader/models/chapter_split_rule.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:flutter/material.dart';

class ChapterSplitRulesPage extends StatefulWidget {
  const ChapterSplitRulesPage({super.key});

  @override
  State<ChapterSplitRulesPage> createState() => _ChapterSplitRulesPageState();
}

class _RuleEntry {
  _RuleEntry({required this.rule, required this.evaluation});

  final ChapterSplitRule rule;
  final ChapterSplitRuleEvaluation evaluation;
}

class _ChapterSplitRulesPageState extends State<ChapterSplitRulesPage> {
  late String _selectedRuleId;
  List<_RuleEntry> _builtinRules = const <_RuleEntry>[];
  List<_RuleEntry> _customRules = const <_RuleEntry>[];

  @override
  void initState() {
    super.initState();
    _refreshRules();
  }

  Future<void> _refreshRules() async {
    final prefs = Prefs();
    final activeRule = prefs.activeChapterSplitRule;
    final storedId = prefs.chapterSplitSelectedRuleId;

    setState(() {
      _selectedRuleId = storedId ?? activeRule.id;
      _builtinRules = builtinChapterSplitRules
          .map((rule) => _RuleEntry(
                rule: rule,
                evaluation: rule.evaluateSamples(),
              ))
          .toList(growable: false);
      _customRules = prefs.chapterSplitCustomRules
          .map((rule) => _RuleEntry(
                rule: rule,
                evaluation: rule.evaluateSamples(),
              ))
          .toList(growable: false);
    });
  }

  Future<void> _onAddRule() async {
    final rule = await Navigator.of(context).push<ChapterSplitRule>(
      MaterialPageRoute(
        builder: (context) => const ChapterSplitRuleEditorPage(),
      ),
    );

    if (rule == null) {
      return;
    }

    Prefs().saveCustomChapterSplitRule(rule);
    await _refreshRules();
  }

  Future<void> _onEditRule(ChapterSplitRule rule) async {
    final updatedRule = await Navigator.of(context).push<ChapterSplitRule>(
      MaterialPageRoute(
        builder: (context) => ChapterSplitRuleEditorPage(rule: rule),
      ),
    );

    if (updatedRule == null) {
      return;
    }

    Prefs().saveCustomChapterSplitRule(updatedRule);
    await _refreshRules();
  }

  Future<void> _onDeleteRule(ChapterSplitRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).deleteCustomRule),
        content: Text(L10n.of(context).removeRule(rule.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(L10n.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(L10n.of(context).commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    Prefs().deleteCustomChapterSplitRule(rule.id);
    await _refreshRules();
  }

  void _onSelectRule(String id) {
    Prefs().selectChapterSplitRule(id);
    setState(() {
      _selectedRuleId = id;
    });
  }

  Widget _buildRuleSection({
    required String title,
    required List<_RuleEntry> rules,
    required bool allowActions,
  }) {
    if (rules.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...rules.map((entry) => _buildRuleTile(
                entry: entry,
                allowActions: allowActions,
              )),
        ],
      ),
    );
  }

  Widget _buildRuleTile({
    required _RuleEntry entry,
    required bool allowActions,
  }) {
    final rule = entry.rule;
    final evaluation = entry.evaluation;
    final isSelected = _selectedRuleId == rule.id;

    return FilledContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<String>(
                  value: rule.id,
                  groupValue: _selectedRuleId,
                  onChanged: (_) => _onSelectRule(rule.id),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        rule.pattern,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                      if (!evaluation.isValid)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            evaluation.errorMessage ??
                                L10n.of(context).invalidPattern,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (allowActions)
                  Column(
                    children: [
                      IconButton(
                        tooltip: L10n.of(context).commonEdit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _onEditRule(rule),
                      ),
                      IconButton(
                        tooltip: L10n.of(context).commonDelete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _onDeleteRule(rule),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 20),
            Text(
              L10n.of(context).samples,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            ...evaluation.sampleMatches.map(
              (sample) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      evaluation.isValid
                          ? (sample.isMatch
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined)
                          : Icons.error_outline,
                      color: evaluation.isValid
                          ? (sample.isMatch
                              ? Colors.green
                              : Theme.of(context).colorScheme.error)
                          : Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sample.sample,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (evaluation.sampleMatches.isEmpty)
              Text(L10n.of(context).noSamplesProvided),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  L10n.of(context).currentlyInUse,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).chapterSplitting),
      ),
      body: ListView(
        children: [
          _buildRuleSection(
            title: L10n.of(context).builtInRules,
            rules: _builtinRules,
            allowActions: false,
          ),
          _buildRuleSection(
            title: L10n.of(context).customRules,
            rules: _customRules,
            allowActions: true,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _onAddRule,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(L10n.of(context).addCustomRule),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class ChapterSplitRuleEditorPage extends StatefulWidget {
  const ChapterSplitRuleEditorPage({super.key, this.rule});

  final ChapterSplitRule? rule;

  @override
  State<ChapterSplitRuleEditorPage> createState() =>
      _ChapterSplitRuleEditorPageState();
}

class _ChapterSplitRuleEditorPageState
    extends State<ChapterSplitRuleEditorPage> {
  late TextEditingController _nameController;
  late TextEditingController _patternController;
  late TextEditingController _samplesController;
  late bool _caseSensitive;
  late bool _multiLine;
  late String _ruleId;
  ChapterSplitRuleEvaluation? _evaluation;
  bool _localizedDefaultsApplied = false;
  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    if (rule == null) {
      _ruleId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      _nameController = TextEditingController();
      _patternController = TextEditingController();
      _samplesController = TextEditingController();
      _caseSensitive = false;
      _multiLine = true;
    } else {
      _ruleId = rule.id;
      _nameController = TextEditingController(text: rule.name);
      _patternController = TextEditingController(text: rule.pattern);
      _samplesController = TextEditingController(text: rule.samples.join('\n'));
      _caseSensitive = rule.caseSensitive;
      _multiLine = rule.multiLine;
    }

    _evaluate();

    _patternController.addListener(_evaluate);
    _samplesController.addListener(_evaluate);
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultsApplied) {
      return;
    }

    if (widget.rule == null) {
      final l10n = L10n.of(context);
      if (_nameController.text.isEmpty) {
        _nameController.text = l10n.newCustomRule;
      }
      if (_samplesController.text.isEmpty) {
        _samplesController.text = 'Chapter 1: Beginning';
      }
    }

    _localizedDefaultsApplied = true;
    _evaluate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _patternController.dispose();
    _samplesController.dispose();
    super.dispose();
  }

  void _evaluate() {
    final samples = _currentSamples;
    final rule = ChapterSplitRule(
      id: _ruleId,
      name: _nameController.text,
      pattern: _patternController.text,
      samples: samples,
      caseSensitive: _caseSensitive,
      multiLine: _multiLine,
      isBuiltin: false,
    );
    setState(() {
      _evaluation = rule.evaluateSamples();
    });
  }

  List<String> get _currentSamples {
    return _samplesController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  bool get _canSave {
    if (_nameController.text.trim().isEmpty) {
      return false;
    }
    if (_patternController.text.trim().isEmpty) {
      return false;
    }
    if (_currentSamples.isEmpty) {
      return false;
    }
    final evaluation = _evaluation;
    return evaluation != null && evaluation.isValid;
  }

  void _onToggleCaseSensitive(bool? value) {
    setState(() {
      _caseSensitive = value ?? false;
    });
    _evaluate();
  }

  void _onToggleMultiLine(bool? value) {
    setState(() {
      _multiLine = value ?? true;
    });
    _evaluate();
  }

  void _onSave() {
    if (!_canSave) {
      return;
    }

    final rule = ChapterSplitRule(
      id: _ruleId,
      name: _nameController.text.trim(),
      pattern: _patternController.text.trim(),
      samples: _currentSamples,
      caseSensitive: _caseSensitive,
      multiLine: _multiLine,
      isBuiltin: false,
    );

    Navigator.of(context).pop(rule);
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = _evaluation;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null
            ? L10n.of(context).newCustomRule
            : L10n.of(context).editCustomRule),
        actions: [
          TextButton(
            onPressed: _canSave ? _onSave : null,
            child: Text(L10n.of(context).commonSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: L10n.of(context).ruleName,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _patternController,
            decoration: InputDecoration(
              labelText: L10n.of(context).regularExpression,
              errorText: evaluation != null && !evaluation.isValid
                  ? evaluation.errorMessage ?? L10n.of(context).invalidPattern
                  : null,
              helperText: L10n.of(context).dartStyleRegularExpression,
            ),
            maxLines: 3,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _caseSensitive,
                  onChanged: _onToggleCaseSensitive,
                  title: Text(L10n.of(context).caseSensitive),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CheckboxListTile(
                  value: _multiLine,
                  onChanged: _onToggleMultiLine,
                  title: Text(L10n.of(context).multiLine),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _samplesController,
            decoration: InputDecoration(
              labelText: L10n.of(context).samplesOnePerLine,
              alignLabelWithHint: true,
            ),
            minLines: 5,
            maxLines: 10,
          ),
          const SizedBox(height: 24),
          if (evaluation != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.of(context).testResults,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...evaluation.sampleMatches.map(
                  (sample) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          evaluation.isValid
                              ? (sample.isMatch
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined)
                              : Icons.error_outline,
                          color: evaluation.isValid
                              ? (sample.isMatch
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error)
                              : Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(sample.sample),
                        ),
                      ],
                    ),
                  ),
                ),
                if (evaluation.sampleMatches.isEmpty)
                  Text(L10n.of(context).noSamples),
              ],
            ),
        ],
      ),
    );
  }
}
