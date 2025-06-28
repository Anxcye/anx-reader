import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/get_current_language_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Changelog screen for showing app updates
/// Displays version history and new features
class ChangelogScreen extends StatefulWidget {
  final String lastVersion;
  final String currentVersion;
  final VoidCallback onComplete;

  const ChangelogScreen({
    super.key,
    required this.lastVersion,
    required this.currentVersion,
    required this.onComplete,
  });

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  String _changelogContent = '';
  bool _isLoading = true;

  String get currentVersion => widget.currentVersion.split('+').first;
  String get lastVersion => widget.lastVersion.split('+').first;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      // Load changelog from assets
      final String fullChangelog =
          await rootBundle.loadString('assets/CHANGELOG.md');
      _changelogContent = _extractVersionChangelog(fullChangelog);
    } catch (e) {
      AnxLog.warning('Failed to load changelog from assets: $e');
      _changelogContent = _getDefaultChangelog();
    } finally {
      _changelogContent = processChangelogContent(_changelogContent);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String processChangelogContent(String content) {
    bool isChinese() => getCurrentLanguageCode().contains('zh');

    final lines = content.split('\n');
    var processedLines = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        continue;
      }

      if (line.startsWith('- ') || line.startsWith('* ')) {
        processedLines.add(line);
        continue;
      }
    }
    if (isChinese()) {
      processedLines = processedLines.sublist(processedLines.length ~/ 2);
    } else {
      processedLines = processedLines.sublist(0, processedLines.length ~/ 2);
    }

    return processedLines.join('\n');
  }

  String _extractVersionChangelog(String fullChangelog) {
    // Extract version number from currentVersion (e.g., "1.2.3+1234" -> "1.2.3")
    final versionMatch =
        RegExp(r'^(\d+\.\d+\.\d+)').firstMatch(currentVersion);
    if (versionMatch == null) {
      return _getDefaultChangelog();
    }

    final version = versionMatch.group(1)!;
    final versionHeader = '## $version';

    // Find the version section in the changelog
    final lines = fullChangelog.split('\n');
    final startIndex = lines.indexWhere((line) => line.trim() == versionHeader);

    if (startIndex == -1) {
      AnxLog.warning('Version $version not found in changelog');
      return _getDefaultChangelog();
    }

    // Find the end of this version section (next version header or end of file)
    int endIndex = lines.length;
    for (int i = startIndex + 1; i < lines.length; i++) {
      if (lines[i].trim().startsWith('## ') &&
          lines[i].trim() != versionHeader) {
        endIndex = i;
        break;
      }
    }

    // Extract the content for this version (skip the header line)
    final versionContent =
        lines.sublist(startIndex + 1, endIndex).join('\n').trim();

    if (versionContent.isEmpty) {
      return _getDefaultChangelog();
    }

    return versionContent;
  }

  String _getDefaultChangelog() {
    return '''
- Fixed some bugs
- 修复已知问题
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).whats_new),
        elevation: 0,
        actions: [
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.update,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            L10n.of(context).update_from_version(lastVersion),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        L10n.of(context).welcome_to_version(currentVersion),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: MarkdownBody(
                      data: _changelogContent,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(Theme.of(context))
                              .copyWith(
                        h1: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        h2: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        p: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        listBullet: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _onComplete,
                    child: Text(L10n.of(context).common_ok),
                  ),
                ),
              ],
            ),
    );
  }

  void _onComplete() async {
      widget.onComplete();
  }
}
