import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/get_path/log_file.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/save_file_to_download.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

enum _LogFilter { all, severe, warning, info }

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final _searchController = TextEditingController();
  List<AnxLog> _logs = const [];
  _LogFilter _filter = _LogFilter.all;
  bool _loading = true;

  List<AnxLog> get _visibleLogs {
    final query = _searchController.text.trim().toLowerCase();
    return _logs.where((log) {
      final matchesLevel = switch (_filter) {
        _LogFilter.all => true,
        _LogFilter.severe => log.level >= Level.SEVERE,
        _LogFilter.warning => log.level == Level.WARNING,
        _LogFilter.info => log.level < Level.WARNING,
      };
      return matchesLevel &&
          (query.isEmpty || log.message.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (mounted) setState(() => _loading = true);
    final file = await getLogFile();
    final lines = await file.readAsLines();
    if (!mounted) return;
    setState(() {
      _logs = lines.reversed.map(AnxLog.parse).toList(growable: false);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final visibleLogs = _visibleLogs;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsAdvancedLog),
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clearLog();
              if (value == 'export') _exportLog();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Text(l10n.settingsAdvancedLogClearLog),
              ),
              PopupMenuItem(
                value: 'export',
                child: Text(l10n.settingsAdvancedLogExportLog),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.developerLogSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(_LogFilter.all, l10n.developerLogAll),
                _filterChip(_LogFilter.severe, l10n.developerLogError),
                _filterChip(_LogFilter.warning, l10n.developerLogWarning),
                _filterChip(_LogFilter.info, l10n.developerLogInfo),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.developerLogCount(visibleLogs.length, _logs.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visibleLogs.isEmpty
                    ? Center(
                        child: Text(_logs.isEmpty
                            ? l10n.developerLogEmpty
                            : l10n.developerLogNoMatches),
                      )
                    : ListView.separated(
                        itemCount: visibleLogs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _logItem(visibleLogs[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(_LogFilter filter, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filter == filter,
        onSelected: (_) => setState(() => _filter = filter),
      ),
    );
  }

  Widget _logItem(AnxLog log) {
    final color = log.color as Color;
    return ExpansionTile(
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(
        log.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        '${log.level.name}  ${log.time.toLocal()}',
        style: const TextStyle(fontSize: 11),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SelectableText(log.message)),
              IconButton(
                tooltip: L10n.of(context).commonCopy,
                icon: const Icon(Icons.copy_outlined, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: log.raw));
                  AnxToast.show(L10n.of(context).notesPageCopied);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _clearLog() async {
    AnxLog.clear();
    await _loadLogs();
  }

  Future<void> _exportLog() async {
    final logFile = await getLogFile();
    final now = DateTime.now();
    final fileName = 'AnxReader-Log-${now.year}-${now.month}-${now.day}.txt';
    final filePath = await saveFileToDownload(
      bytes: await logFile.readAsBytes(),
      fileName: fileName,
      mimeType: 'text/plain',
    );
    AnxToast.show('saved $filePath');
  }
}
