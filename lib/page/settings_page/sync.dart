import 'dart:io';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/get_path/cache_path.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/shared_prefs_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/webdav/test_webdav.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:settings_ui/settings_ui.dart';

class SyncSetting extends StatelessWidget {
  const SyncSetting(
      {super.key,
      required this.isMobile,
      required this.id,
      required this.selectedIndex,
      required this.setDetail});

  final bool isMobile;
  final int id;
  final int selectedIndex;
  final void Function(Widget detail, int id) setDetail;

  @override
  Widget build(BuildContext context) {
    return settingsTitle(
        icon: const Icon(Icons.sync),
        title: L10n.of(context).settings_sync,
        isMobile: isMobile,
        id: id,
        selectedIndex: selectedIndex,
        setDetail: setDetail,
        subPage: SubSyncSettings(isMobile: isMobile));
  }
}

class SubSyncSettings extends StatefulWidget {
  const SubSyncSettings({super.key, required this.isMobile});

  final bool isMobile;

  @override
  State<SubSyncSettings> createState() => _SubSyncSettingsState();
}

class _SubSyncSettingsState extends State<SubSyncSettings> {
  @override
  Widget build(BuildContext context) {
    return settingsBody(
      title: L10n.of(context).settings_sync,
      isMobile: widget.isMobile,
      sections: [
        SettingsSection(
          title: Text(L10n.of(context).settings_sync_webdav),
          tiles: [
            SettingsTile.switchTile(
                leading: const Icon(Icons.cached),
                initialValue: Prefs().webdavStatus,
                onToggle: (bool value) async {
                  setState(() {
                    Prefs().saveWebdavStatus(value);
                  });
                  if (value) {
                    bool result = await testEnableWebdav();
                    if (!result) {
                      setState(() {
                        Prefs().saveWebdavStatus(!value);
                      });
                    } else {
                      AnxWebdav.init();
                      chooseDirection();
                    }
                  }
                },
                title: Text(L10n.of(context).settings_sync_enable_webdav)),
            SettingsTile.navigation(
                title: Text(L10n.of(context).settings_sync_webdav),
                leading: const Icon(Icons.cloud),
                value: Text(Prefs().webdavInfo['url'] ?? 'Not set'),
                // enabled: Prefs().webdavStatus,
                onPressed: (context) async {
                  showWebdavDialog(context);
                }),
            SettingsTile.navigation(
                title: Text(L10n.of(context).settings_sync_webdav_sync_now),
                leading: const Icon(Icons.sync_alt),
                // value: Text(Prefs().syncDirection),
                enabled: Prefs().webdavStatus,
                onPressed: (context) {
                  chooseDirection();
                })
          ],
        ),
        SettingsSection(
          title: Text("Export/Import"),
          tiles: [
            SettingsTile.navigation(
                title: Text("Export"),
                leading: const Icon(Icons.cloud_upload),
                onPressed: (context) {
                  exportData(context);
                }),
            SettingsTile.navigation(
                title: Text("Import"),
                leading: const Icon(Icons.cloud_download),
                onPressed: (context) {
                  importData();
                }),
          ],
        ),
      ],
    );
  }

  void _showDataDialog(BuildContext context, String title) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => SimpleDialog(
              title: Center(child: Text(title)),
              children: const [
                Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ));
  }

  Future<void> exportData(BuildContext context) async {
    AnxLog.info('exportData: start');
    if (!mounted) return;

    Future.microtask(() {
      _showDataDialog(context, "Exporting");
    });

    RootIsolateToken token = RootIsolateToken.instance!;
    final zipPath = await compute(createZipFile, token);

    final file = File(zipPath);
    Navigator.of(context).pop('dialog');
    if (await file.exists()) {
      SaveFileDialogParams params = SaveFileDialogParams(
        sourceFilePath: file.path,
        mimeTypesFilter: ['application/zip'],
      );
      final filePath = await FlutterFileDialog.saveFile(params: params);
      if (filePath != null) {
        AnxLog.info('exportData: Saved to: $filePath');
        AnxToast.show("saved to: $filePath");
      } else {
        AnxLog.info('exportData: Cancelled');
        AnxToast.show("Cancelled");
      }
    }
  }

  void importData() {}
}

Future<String> createZipFile(RootIsolateToken token) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  final date =
      '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
  final zipPath = '${(await getAnxCacheDir()).path}/AnxReader-Backup-$date.zip';
  final docPath = await getAnxDocumentsPath();
  final directoryList = [
    getFileDir(path: docPath),
    getCoverDir(path: docPath),
    getFontDir(path: docPath),
    await getAnxDataBasesDir(),
    await getAnxSharedPrefsDir(),
  ];

  AnxLog.info('exportData: directoryList: $directoryList');

  final encoder = ZipFileEncoder();
  encoder.create(zipPath);
  for (final dir in directoryList) {
    await encoder.addDirectory(dir);
  }
  encoder.close();
  return zipPath;
}

void showWebdavDialog(BuildContext context) {
  final title = L10n.of(context).settings_sync_webdav;
  final prefs = Prefs().saveWebdavInfo;
  final webdavInfo = Prefs().webdavInfo;
  final webdavUrlController = TextEditingController(text: webdavInfo['url']);
  final webdavUsernameController =
      TextEditingController(text: webdavInfo['username']);
  final webdavPasswordController =
      TextEditingController(text: webdavInfo['password']);
  Widget buildTextField(String labelText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        obscureText: labelText == L10n.of(context).settings_sync_webdav_password
            ? true
            : false,
        controller: controller,
        decoration: InputDecoration(
            border: const OutlineInputBorder(), labelText: labelText),
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
              L10n.of(context).settings_sync_webdav_url, webdavUrlController),
          buildTextField(L10n.of(context).settings_sync_webdav_username,
              webdavUsernameController),
          buildTextField(L10n.of(context).settings_sync_webdav_password,
              webdavPasswordController),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  webdavInfo['url'] = webdavUrlController.text.trim();
                  webdavInfo['username'] = webdavUsernameController.text;
                  webdavInfo['password'] = webdavPasswordController.text;
                  testWebdav(webdavInfo);
                },
                child:
                    Text(L10n.of(context).settings_sync_webdav_test_connection),
              ),
              TextButton(
                onPressed: () {
                  webdavInfo['url'] = webdavUrlController.text.trim();
                  webdavInfo['username'] = webdavUsernameController.text;
                  webdavInfo['password'] = webdavPasswordController.text;
                  prefs(webdavInfo);
                  Navigator.pop(context);
                },
                child: Text(L10n.of(context).common_save),
              ),
            ],
          ),
        ],
      );
    },
  );
}
