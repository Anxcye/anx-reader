import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/md5_statistics.dart';
import 'package:anx_reader/page/settings_page/subpage/log_page.dart';
import 'package:anx_reader/service/md5_service.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdvancedSetting extends StatefulWidget {
  const AdvancedSetting({super.key});

  @override
  State<AdvancedSetting> createState() => _AdvancedSettingState();
}

class _AdvancedSettingState extends State<AdvancedSetting> {
  MD5Statistics? _md5Stats;
  bool _isCalculating = false;
  double _progress = 0.0;
  String _currentFile = '';

  @override
  void initState() {
    super.initState();
    _loadMd5Statistics();
  }

  Future<void> _loadMd5Statistics() async {
    final stats = await MD5Service.getMd5Statistics();
    setState(() {
      _md5Stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return settingsSections(
      sections: [
        SettingsSection(
          title: Text(L10n.of(context).settings_advanced_log),
          tiles: [
            SettingsTile.switchTile(
              title:
                  Text(L10n.of(context).settings_advanced_clear_log_when_start),
              leading: const Icon(Icons.delete_forever_outlined),
              initialValue: Prefs().clearLogWhenStart,
              onToggle: (value) {
                Prefs().saveClearLogWhenStart(value);
                setState(() {});
              },
            ),
            SettingsTile.navigation(
                leading: const Icon(Icons.bug_report),
                title: Text(L10n.of(context).settings_advanced_log),
                onPressed: onLogPressed),
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).md5_management),
          tiles: [
            if (_md5Stats != null)
              SettingsTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L10n.of(context).md5_statistics),
                    const SizedBox(height: 4),
                    Text(
                      L10n.of(context).md5_total_books(_md5Stats!.totalBooks),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      L10n.of(context)
                          .md5_books_with_md5(_md5Stats!.booksWithMd5),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      L10n.of(context)
                          .md5_books_without_md5(_md5Stats!.booksWithoutMd5),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      L10n.of(context)
                          .md5_local_files(_md5Stats!.localFilesCount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      L10n.of(context).md5_local_files_without_md5(
                          _md5Stats!.localFilesWithoutMd5),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                leading: const Icon(Icons.fingerprint),
              ),
            if (_isCalculating)
              SettingsTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L10n.of(context).md5_calculating),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 4),
                    Text(
                      '${(_progress * 100).toStringAsFixed(1)}% - $_currentFile',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                leading: const Icon(Icons.calculate),
              )
            else
              SettingsTile.navigation(
                title: Text(L10n.of(context).md5_calculate_missing),
                leading: const Icon(Icons.calculate),
                onPressed: _calculateMd5,
                // enabled: _md5Stats?.booksWithoutMd5 != 0,
              ),
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).settings_advanced_javascript),
          tiles: [
            SettingsTile.switchTile(
              title: Text(L10n.of(context)
                  .settings_advanced_enable_javascript_for_epub),
              leading: const Icon(Icons.code),
              initialValue: Prefs().enableJsForEpub,
              onToggle: (value) {
                Prefs().enableJsForEpub = value;
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _calculateMd5(BuildContext context) async {
    if (_isCalculating) return;

    if (_md5Stats?.localFilesWithoutMd5 == 0) {
      AnxToast.show(L10n.of(context).md5_no_calculation_needed);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).md5_calculate_confirm_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.of(context).md5_calculate_confirm_content),
            const SizedBox(height: 8),
            if (_md5Stats!.localFilesWithoutMd5 < _md5Stats!.booksWithoutMd5)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                     Icon(Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        L10n.of(context).md5_missing_files_tip,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(L10n.of(context).common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(L10n.of(context).common_confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCalculating = true;
      _progress = 0.0;
      _currentFile = '';
    });

    try {
      final booksToCalculate = await getBooksWithoutMd5();

      final result = await MD5Service.batchCalculateMd5(
        booksToCalculate,
        onProgress: (current, total, currentFile) {
          setState(() {
            _progress = current / total;
            _currentFile = currentFile;
          });
        },
      );

      await _loadMd5Statistics();

      setState(() {
        _isCalculating = false;
        _progress = 0.0;
        _currentFile = '';
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(L10n.of(context).md5_calculation_complete),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context)
                    .md5_calculation_result_calculated(result.calculated)),
                Text(L10n.of(context)
                    .md5_calculation_result_skipped(result.skipped)),
                Text(L10n.of(context)
                    .md5_calculation_result_failed(result.failed)),
                if (result.missingFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    L10n.of(context).md5_missing_files,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...result.missingFiles.take(5).map((file) => Text('• $file')),
                  if (result.missingFiles.length > 5)
                    Text(L10n.of(context)
                        .md5_and_more(result.missingFiles.length - 5)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(L10n.of(context).common_ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCalculating = false;
        _progress = 0.0;
        _currentFile = '';
      });

      if (context.mounted) {
        AnxToast.show(L10n.of(context).md5_calculation_error(e.toString()));
      }
    }
  }
}

void onLogPressed(BuildContext context) {
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => const LogPage(),
    ),
  );
}
