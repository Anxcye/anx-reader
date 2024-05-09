import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../config/shared_preference_provider.dart';
import '../../utils/webdav/test_webdav.dart';
import '../../widgets/settings/settings_title.dart';

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
        title: context.settingsSync,
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
      title: context.settingsSync,
      isMobile: widget.isMobile,
      sections: [
        SettingsSection(
          title: Text(context.settingsSyncWebdav),
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
                title: Text(context.settingsSyncEnableWebdav)),
            SettingsTile.navigation(
                title: Text(context.settingsSyncWebdav),
                leading: const Icon(Icons.cloud),
                value: Text(Prefs().webdavInfo['url'] ?? 'Not set'),
                // enabled: Prefs().webdavStatus,
                onPressed: (context) async {
                  showWebdavDialog(context);
                }),
            SettingsTile.navigation(
                title: Text(context.settingsSyncWebdavSyncNow),
                leading: const Icon(Icons.sync_alt),
                // value: Text(Prefs().syncDirection),
                enabled: Prefs().webdavStatus,
                onPressed: (context) {
                  chooseDirection();
                })
          ],
        ),
      ],
    );
  }
}

void showWebdavDialog(BuildContext context) {
  final title = context.settingsSyncWebdav;
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
        obscureText: labelText == context.settingsSyncWebdavPassword ? true : false,
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
          buildTextField(context.settingsSyncWebdavUrl, webdavUrlController),
          buildTextField(context.settingsSyncWebdavUsername, webdavUsernameController),
          buildTextField(context.settingsSyncWebdavPassword, webdavPasswordController),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  webdavInfo['url'] = webdavUrlController.text;
                  webdavInfo['username'] = webdavUsernameController.text;
                  webdavInfo['password'] = webdavPasswordController.text;
                  testWebdav(webdavInfo);
                },

                child: Text(context.settingsSyncWebdavTestConnection),
              ),
              TextButton(
                onPressed: () {
                  webdavInfo['url'] = webdavUrlController.text;
                  webdavInfo['username'] = webdavUsernameController.text;
                  webdavInfo['password'] = webdavPasswordController.text;
                  prefs(webdavInfo);
                  Navigator.pop(context);
                },
                child: Text(context.commonSave),
              ),
            ],
          ),
        ],
      );
    },
  );
}
