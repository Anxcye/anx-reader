import 'dart:io';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/service/iap_service.dart';
import 'package:anx_reader/service/sync/sync_client_factory.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/save_file_to_download.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/shared_prefs_path.dart';
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

class SyncSetting extends ConsumerStatefulWidget {
  const SyncSetting({super.key});

  @override
  ConsumerState<SyncSetting> createState() => _SyncSettingState();
}

class _SyncSettingState extends ConsumerState<SyncSetting> {
  @override
  Widget build(BuildContext context) {
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
            SettingsTile.navigation(
                title: Text(L10n.of(context).settingsSyncWebdavSyncNow),
                leading: const Icon(Icons.sync_alt),
                // value: Text(Prefs().syncDirection),
                enabled: Prefs().webdavStatus,
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
                enabled: Prefs().webdavStatus,
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

    RootIsolateToken token = RootIsolateToken.instance!;
    final zipPath = await compute(createZipFile, token);

    final file = File(zipPath);
    SmartDialog.dismiss();
    if (await file.exists()) {
      // SaveFileDialogParams params = SaveFileDialogParams(
      //   sourceFilePath: file.path,
      //   mimeTypesFilter: ['application/zip'],
      // );
      // final filePath = await FlutterFileDialog.saveFile(params: params);
      String fileName =
          'AnxReader-Backup-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}-v2.zip';

      String? filePath = await saveFileToDownload(
          sourceFilePath: file.path,
          fileName: fileName,
          mimeType: 'application/zip');

      await file.delete();

      if (filePath != null) {
        AnxLog.info('exportData: Saved to: $filePath');
        AnxToast.show(
            L10n.of(navigatorKey.currentContext!).exportTo(filePath));
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

      _copyFileSync(File('$extractPath/${getSharedPrefsFileName()}'),
          await getAnxShredPrefsFile());

      if (EnvVar.isAppStore) {
        Prefs().iapPurchaseStatus = false;
        IAPService().refresh();
        final _ = IAPService().isPurchased;
      }

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

  void _copyFileSync(File source, File destination) {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    } else {
      destination.delete();
    }
    source.copySync(destination.path);
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

Future<String> createZipFile(RootIsolateToken token) async {
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
    await getAnxDataBasesDir(),
    // await getAnxSharedPrefsDir(),
    await getAnxShredPrefsFile(),
  ];

  AnxLog.info('exportData: directoryList: $directoryList');

  final encoder = ZipFileEncoder();
  encoder.create(zipPath);
  for (final dir in directoryList) {
    if (dir is Directory) {
      await encoder.addDirectory(dir);
    } else if (dir is File) {
      await encoder.addFile(dir);
    }
  }
  encoder.close();
  return zipPath;
}

Future<void> extractZipFile(Map<String, String> params) async {
  final zipFilePath = params['zipFilePath']!;
  final destinationPath = params['destinationPath']!;

  final bytes = File(zipFilePath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File('$destinationPath/$filename')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory('$destinationPath/$filename').createSync(recursive: true);
    }
  }
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
                onPressed: () => SyncTestHelper.handleTestConnection(
                  context,
                  protocol: SyncProtocol.webdav,
                  config: {
                    'url': webdavUrlController.text.trim(),
                    'username': webdavUsernameController.text,
                    'password': webdavPasswordController.text,
                  },
                ),
                icon: const Icon(Icons.wifi_find),
                label:
                    Text(L10n.of(context).settingsSyncWebdavTestConnection),
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
