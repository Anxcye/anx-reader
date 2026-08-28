import 'dart:convert';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/service/sync/sync_client_factory.dart';
import 'package:anx_reader/service/sync/cloudbase_reading_sync_coordinator.dart';
import 'package:anx_reader/service/sync/cloudbase_reading_sync_transport.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/utils/save_file_to_download.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/sync_test_helper.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/webdav/test_webdav.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:anx_reader/widgets/settings/webdav_switch.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';

const String _prefsBackupFileName = 'anx_shared_prefs.json';

class SyncSetting extends ConsumerStatefulWidget {
  const SyncSetting({super.key});

  @override
  ConsumerState<SyncSetting> createState() => _SyncSettingState();
}

class _SyncSettingState extends ConsumerState<SyncSetting> {
  @override
  Widget build(BuildContext context) {
    final isSyncing = ref.watch(syncProvider).isSyncing;
    return settingsSections(
      sections: [
        SettingsSection(
          title: Text(L10n.of(context).settingsSyncWebdav),
          tiles: [
            webdavSwitch(context, setState, ref),
            SettingsTile.navigation(
                title: Text(L10n.of(context).settingsSyncWebdav),
                leading: const Icon(Icons.cloud),
                value: Text(Prefs().getSyncInfo(SyncProtocol.webdav)['url'] ??
                    'Not set'),
                // enabled: Prefs().webdavStatus,
                onPressed: (context) async {
                  showWebdavDialog(context);
                }),
            CustomSettingsTile(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 20, 10),
                child: GestureDetector(
                  onTap: () async {
                    final failedMessage = L10n.of(context).commonFailed;
                    if (!await launchUrl(
                        Uri.parse('https://anx.anxcye.com/docs/sync/webdav'),
                        mode: LaunchMode.externalApplication)) {
                      AnxToast.show(failedMessage);
                    }
                  },
                  child: Text(
                    L10n.of(context).settingsNarrateClickForHelp,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            SettingsTile.navigation(
                title: Text(L10n.of(context).settingsSyncWebdavSyncNow),
                leading: const Icon(Icons.sync_alt),
                value: isSyncing ? Text(L10n.of(context).webdavSyncing) : null,
                enabled: Prefs().webdavStatus && !isSyncing,
                onPressed: (context) {
                  chooseDirection(ref);
                }),
            SettingsTile.switchTile(
                title: Text(L10n.of(context).webdavOnlyWifi),
                leading: const Icon(Icons.wifi),
                initialValue: Prefs().onlySyncWhenWifi,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().onlySyncWhenWifi = value;
                  });
                }),
            SettingsTile.switchTile(
                title: Text(L10n.of(context).settingsSyncCompletedToast),
                leading: const Icon(Icons.notifications),
                initialValue: Prefs().syncCompletedToast,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().syncCompletedToast = value;
                  });
                }),
            SettingsTile.switchTile(
                title: Text(L10n.of(context).settingsSyncAutoSync),
                leading: const Icon(Icons.sync),
                initialValue: Prefs().autoSync,
                enabled: Prefs().webdavStatus || Prefs().cloudBaseSyncEnabled,
                onToggle: (bool value) {
                  setState(() {
                    Prefs().autoSync = value;
                  });
                }),
            SettingsTile.navigation(
                title: Text(L10n.of(context).restoreBackup),
                leading: const Icon(Icons.restore),
                onPressed: (context) {
                  ref.read(syncProvider.notifier).showBackupManagementDialog();
                })
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).cloudBaseReadingSync),
          tiles: [
            SettingsTile.switchTile(
              title: Text(L10n.of(context).cloudBaseReadingSyncEnable),
              description:
                  Text(L10n.of(context).cloudBaseReadingSyncScopeDescription),
              leading: const Icon(Icons.cloud_sync_outlined),
              initialValue: Prefs().cloudBaseSyncEnabled,
              onToggle: (value) {
                if (value && Prefs().cloudBaseSyncAccountToken.isEmpty) {
                  _showCloudBaseDialog();
                  return;
                }
                setState(() => Prefs().cloudBaseSyncEnabled = value);
              },
            ),
            SettingsTile.navigation(
              title: Text(L10n.of(context).cloudBaseReadingSyncConfigure),
              leading: const Icon(Icons.key_outlined),
              value: Text(Prefs().cloudBaseSyncAccountUsername.isNotEmpty
                  ? Prefs().cloudBaseSyncAccountUsername
                  : L10n.of(context).commonNotSet),
              onPressed: (_) => _showCloudBaseDialog(),
            ),
            SettingsTile.navigation(
              title: Text(L10n.of(context).cloudBaseReadingSyncNow),
              leading: const Icon(Icons.sync),
              enabled: Prefs().cloudBaseSyncEnabled,
              onPressed: (_) => _syncCloudBase(),
            ),
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).exportAndImport),
          tiles: [
            SettingsTile.navigation(
                title: Text(L10n.of(context).exportAndImportExport),
                leading: const Icon(Icons.cloud_upload),
                onPressed: (context) {
                  exportData(context);
                }),
            SettingsTile.navigation(
                title: Text(L10n.of(context).exportAndImportImport),
                leading: const Icon(Icons.cloud_download),
                onPressed: (context) {
                  importData();
                }),
          ],
        ),
      ],
    );
  }

  Future<void> _syncCloudBase() async {
    try {
      await const CloudBaseReadingSyncCoordinator().synchronize();
      if (mounted) AnxToast.show(L10n.of(context).cloudBaseReadingSyncComplete);
    } catch (error) {
      if (mounted) {
        AnxToast.show(L10n.of(context).cloudBaseReadingSyncFailed(error));
      }
    }
  }

  Future<void> _showCloudBaseDialog() async {
    final endpoint = TextEditingController(text: Prefs().cloudBaseSyncEndpoint);
    final username = TextEditingController(
      text: Prefs().cloudBaseSyncAccountUsername,
    );
    final password = TextEditingController();
    final confirmPassword = TextEditingController();
    var registerMode = false;
    var busy = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(L10n.of(context).cloudBaseReadingSyncConfigure),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(L10n.of(context).cloudBaseReadingSyncCredentialHint),
                const SizedBox(height: 16),
                TextField(
                  controller: endpoint,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: L10n.of(context).cloudBaseReadingSyncEndpoint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: username,
                  enabled: Prefs().cloudBaseSyncAccountToken.isEmpty && !busy,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: L10n.of(context).cloudBaseReadingSyncUsername,
                  ),
                ),
                if (Prefs().cloudBaseSyncAccountToken.isEmpty) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(
                          L10n.of(context).cloudBaseReadingSyncLoginMode,
                        ),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(
                          L10n.of(context).cloudBaseReadingSyncRegisterMode,
                        ),
                      ),
                    ],
                    selected: {registerMode},
                    onSelectionChanged: busy
                        ? null
                        : (selection) => setDialogState(() {
                              registerMode = selection.first;
                              password.clear();
                              confirmPassword.clear();
                            }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    enabled: !busy,
                    obscureText: true,
                    textInputAction: registerMode
                        ? TextInputAction.next
                        : TextInputAction.done,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText:
                          L10n.of(context).cloudBaseReadingSyncPasswordHint,
                    ),
                  ),
                  if (registerMode) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassword,
                      enabled: !busy,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: L10n.of(context)
                            .cloudBaseReadingSyncConfirmPassword,
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${L10n.of(context).cloudBaseReadingSyncCurrentAccount}: '
                      '${Prefs().cloudBaseSyncAccountUsername}',
                    ),
                  ),
                ],
                if (busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            if (Prefs().cloudBaseSyncAccountToken.isNotEmpty)
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        setDialogState(() => busy = true);
                        try {
                          await CloudBaseReadingSyncTransport(
                            endpoint: endpoint.text,
                            accessToken: Prefs().cloudBaseSyncAccountToken,
                          ).logoutAccount();
                        } catch (_) {
                          // Local logout must remain available while offline.
                        }
                        Prefs().clearCloudBaseSyncAccount();
                        Prefs().cloudBaseSyncEnabled = false;
                        if (dialogContext.mounted) {
                          setDialogState(() => busy = false);
                        }
                      },
                child: Text(L10n.of(context).cloudBaseReadingSyncLogout),
              ),
            if (Prefs().cloudBaseSyncAccountToken.isEmpty)
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        final name = username.text.trim();
                        if (name.isEmpty || password.text.isEmpty) {
                          AnxToast.show(
                              L10n.of(context).commonInputCannotBeEmpty);
                          return;
                        }
                        if (registerMode &&
                            password.text != confirmPassword.text) {
                          AnxToast.show(L10n.of(context)
                              .cloudBaseReadingSyncPasswordMismatch);
                          return;
                        }
                        setDialogState(() => busy = true);
                        try {
                          final transport = CloudBaseReadingSyncTransport(
                            endpoint: endpoint.text,
                            accessToken: '',
                          );
                          final session = registerMode
                              ? await transport.registerAccount(
                                  username: name,
                                  password: password.text,
                                )
                              : await transport.loginAccount(
                                  username: name,
                                  password: password.text,
                                );
                          Prefs().cloudBaseSyncEndpoint = endpoint.text.trim();
                          Prefs().cloudBaseSyncAccountUsername =
                              session.username;
                          Prefs().cloudBaseSyncAccountToken =
                              session.accessToken;
                          Prefs().cloudBaseSyncEnabled = true;
                          if (context.mounted) {
                            AnxToast.show(
                              registerMode
                                  ? L10n.of(context)
                                      .cloudBaseReadingSyncRegistered
                                  : L10n.of(context)
                                      .cloudBaseReadingSyncLoggedIn,
                            );
                            Navigator.pop(dialogContext);
                          }
                        } catch (error) {
                          if (context.mounted) {
                            AnxToast.show(
                              L10n.of(context)
                                  .cloudBaseReadingSyncFailed(error),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => busy = false);
                          }
                        }
                      },
                child: Text(registerMode
                    ? L10n.of(context).cloudBaseReadingSyncRegister
                    : L10n.of(context).cloudBaseReadingSyncLogin),
              ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() => busy = true);
                      try {
                        final accountToken =
                            Prefs().cloudBaseSyncAccountToken.trim();
                        await CloudBaseReadingSyncTransport(
                          endpoint: endpoint.text,
                          accessToken: accountToken,
                        ).ping();
                        // A successful test confirms the endpoint and makes
                        // it the active endpoint without a second Save action.
                        Prefs().cloudBaseSyncEndpoint = endpoint.text.trim();
                        if (context.mounted) {
                          AnxToast.show(L10n.of(context).commonSuccess);
                        }
                      } catch (error) {
                        if (context.mounted) {
                          AnxToast.show(
                            L10n.of(context).cloudBaseReadingSyncFailed(error),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => busy = false);
                        }
                      }
                    },
              child: Text(L10n.of(context).settingsSyncWebdavTestConnection),
            ),
          ],
        ),
      ),
    );
    endpoint.dispose();
    username.dispose();
    password.dispose();
    confirmPassword.dispose();
    if (mounted) setState(() {});
  }

  void _showDataDialog(String title) {
    Future.microtask(() {
      SmartDialog.show(
        builder: (BuildContext context) => SimpleDialog(
          title: Center(child: Text(title)),
          children: const [
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      );
    });
  }

  Future<void> exportData(BuildContext context) async {
    AnxLog.info('exportData: start');
    if (!mounted) return;

    _showDataDialog(L10n.of(context).exporting);

    final File prefsBackupFile = await _createPrefsBackupFile();

    RootIsolateToken token = RootIsolateToken.instance!;
    final zipPath = await compute(createZipFile, {
      'token': token,
      'prefsBackupFilePath': prefsBackupFile.path,
    });

    final file = File(zipPath);
    SmartDialog.dismiss();
    if (await file.exists()) {
      // SaveFileDialogParams params = SaveFileDialogParams(
      //   sourceFilePath: file.path,
      //   mimeTypesFilter: ['application/zip'],
      // );
      // final filePath = await FlutterFileDialog.saveFile(params: params);
      String fileName =
          'AnxReader-Backup-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}-v3.zip';

      String? filePath = await saveFileToDownload(
          sourceFilePath: file.path,
          fileName: fileName,
          mimeType: 'application/zip');

      await file.delete();

      if (filePath != null) {
        AnxLog.info('exportData: Saved to: $filePath');
        AnxToast.show(L10n.of(navigatorKey.currentContext!).exportTo(filePath));
      } else {
        AnxLog.info('exportData: Cancelled');
        AnxToast.show(L10n.of(navigatorKey.currentContext!).commonCanceled);
      }
    }
  }

  Future<void> importData() async {
    AnxLog.info('importData: start');
    if (!mounted) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null) {
      return;
    }

    String? filePath = result.files.single.path;
    if (filePath == null) {
      AnxLog.info('importData: cannot get file path');
      AnxToast.show(
          L10n.of(navigatorKey.currentContext!).importCannotGetFilePath);
      return;
    }

    File zipFile = File(filePath);
    if (!await zipFile.exists()) {
      AnxLog.info('importData: zip file not found');
      AnxToast.show(
          L10n.of(navigatorKey.currentContext!).importCannotGetFilePath);
      return;
    }
    _showDataDialog(L10n.of(navigatorKey.currentContext!).importing);

    String pathSeparator = Platform.pathSeparator;

    Directory cacheDir = await getAnxTempDir();
    String cachePath = cacheDir.path;
    String extractPath = '$cachePath${pathSeparator}anx_reader_import';

    try {
      await Directory(extractPath).create(recursive: true);

      await compute(extractZipFile, {
        'zipFilePath': zipFile.path,
        'destinationPath': extractPath,
      });

      String docPath = await getAnxDocumentsPath();
      _copyDirectorySync(Directory('$extractPath${pathSeparator}file'),
          getFileDir(path: docPath));
      _copyDirectorySync(Directory('$extractPath${pathSeparator}cover'),
          getCoverDir(path: docPath));
      _copyDirectorySync(Directory('$extractPath${pathSeparator}font'),
          getFontDir(path: docPath));
      _copyDirectorySync(Directory('$extractPath${pathSeparator}bgimg'),
          getBgimgDir(path: docPath));

      DBHelper.close();
      _copyDirectorySync(Directory('$extractPath${pathSeparator}databases'),
          await getAnxDataBasesDir());
      DBHelper().initDB();

      await _restorePrefsFromBackup(extractPath);

      AnxLog.info('importData: import success');
      AnxToast.show(
          L10n.of(navigatorKey.currentContext!).importSuccessRestartApp);
    } catch (e) {
      AnxLog.info('importData: error while unzipping or copying files: $e');
      AnxToast.show(
          L10n.of(navigatorKey.currentContext!).importFailed(e.toString()));
    } finally {
      SmartDialog.dismiss();
      await Directory(extractPath).delete(recursive: true);
    }
  }

  void _copyDirectorySync(Directory source, Directory destination) {
    if (!source.existsSync()) {
      return;
    }
    if (destination.existsSync()) {
      destination.deleteSync(recursive: true);
    }
    destination.createSync(recursive: true);
    source.listSync(recursive: false).forEach((entity) {
      final newPath = destination.path +
          Platform.pathSeparator +
          path.basename(entity.path);
      if (entity is File) {
        entity.copySync(newPath);
      } else if (entity is Directory) {
        _copyDirectorySync(entity, Directory(newPath));
      }
    });
  }
}

Future<String> createZipFile(Map<String, dynamic> params) async {
  RootIsolateToken token = params['token'];
  final String prefsBackupFilePath = params['prefsBackupFilePath'];
  final File prefsBackupFile = File(prefsBackupFilePath);
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  final date =
      '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
  final zipPath = '${(await getAnxTempDir()).path}/AnxReader-Backup-$date.zip';
  final docPath = await getAnxDocumentsPath();
  final directoryList = [
    getFileDir(path: docPath),
    getCoverDir(path: docPath),
    getFontDir(path: docPath),
    getBgimgDir(path: docPath),
    if (!AnxPlatform.isOhos) await getAnxDataBasesDir(),
    // await getAnxSharedPrefsDir(),
    // await getAnxShredPrefsFile(),
    prefsBackupFile,
  ];

  AnxLog.info('exportData: directoryList: $directoryList');

  final encoder = ZipFileEncoder();
  encoder.create(zipPath);

  if (AnxPlatform.isOhos) {
    final dbDir = await getAnxDataBasesDir();
    final dbFile = File('${dbDir.path}/app_database.db');
    if (await dbFile.exists()) {
      await encoder.addFile(dbFile, 'databases/app_database.db');
    }
  } else {
    final dbDir = await getAnxDataBasesDir();
    await encoder.addDirectory(dbDir);
  }

  for (final dir in directoryList) {
    if (dir is Directory) {
      await encoder.addDirectory(dir);
    } else if (dir is File) {
      await encoder.addFile(dir);
    }
  }
  encoder.close();
  if (await prefsBackupFile.exists()) {
    await prefsBackupFile.delete();
  }
  return zipPath;
}

Future<void> extractZipFile(Map<String, String> params) async {
  final zipFilePath = params['zipFilePath']!;
  final destinationPath = params['destinationPath']!;

  final input = InputFileStream(zipFilePath);
  try {
    final archive = ZipDecoder().decodeBuffer(input);
    extractArchiveToDiskSync(archive, destinationPath);
    archive.clearSync();
  } finally {
    await input.close();
  }
}

Future<File> _createPrefsBackupFile() async {
  final Directory tempDir = await getAnxTempDir();
  final File backupFile = File('${tempDir.path}/$_prefsBackupFileName');
  final Map<String, dynamic> prefsMap = await Prefs().buildPrefsBackupMap();
  await backupFile.writeAsString(jsonEncode(prefsMap));
  return backupFile;
}

Future<bool> _restorePrefsFromBackup(String extractPath) async {
  final File backupFile = File('$extractPath/$_prefsBackupFileName');
  if (!await backupFile.exists()) {
    return false;
  }
  try {
    final dynamic decoded = jsonDecode(await backupFile.readAsString());
    if (decoded is Map<String, dynamic>) {
      await Prefs().applyPrefsBackupMap(decoded);
      return true;
    }
    AnxLog.info('importData: prefs backup has unexpected format');
  } catch (e) {
    AnxLog.info('importData: failed to restore prefs backup: $e');
  }
  return false;
}

void showWebdavDialog(BuildContext context) {
  final title = L10n.of(context).settingsSyncWebdav;
  // final prefs = Prefs().saveWebdavInfo;
  final webdavInfo = Prefs().getSyncInfo(SyncProtocol.webdav);
  final webdavUrlController = TextEditingController(text: webdavInfo['url']);
  final webdavUsernameController =
      TextEditingController(text: webdavInfo['username']);
  final webdavPasswordController =
      TextEditingController(text: webdavInfo['password']);
  Widget buildTextField(String labelText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        obscureText: labelText == L10n.of(context).settingsSyncWebdavPassword
            ? true
            : false,
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: labelText,
        ),
      ),
    );
  }

  showDialog(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.all(20),
        children: [
          buildTextField(
              L10n.of(context).settingsSyncWebdavUrl, webdavUrlController),
          buildTextField(L10n.of(context).settingsSyncWebdavUsername,
              webdavUsernameController),
          buildTextField(L10n.of(context).settingsSyncWebdavPassword,
              webdavPasswordController),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => SyncTestHelper.handleFullTestConnection(
                  context,
                  protocol: SyncProtocol.webdav,
                  config: {
                    'url': webdavUrlController.text.trim(),
                    'username': webdavUsernameController.text,
                    'password': webdavPasswordController.text,
                  },
                ),
                icon: const Icon(Icons.wifi_find),
                label: Text(L10n.of(context).settingsSyncWebdavTestConnection),
              ),
              TextButton(
                onPressed: () {
                  webdavInfo['url'] = webdavUrlController.text.trim();
                  webdavInfo['username'] = webdavUsernameController.text;
                  webdavInfo['password'] = webdavPasswordController.text;
                  Prefs().setSyncInfo(SyncProtocol.webdav, webdavInfo);
                  SyncClientFactory.initializeCurrentClient();
                  Navigator.pop(context);
                },
                child: Text(L10n.of(context).commonSave),
              ),
            ],
          ),
        ],
      );
    },
  );
}
