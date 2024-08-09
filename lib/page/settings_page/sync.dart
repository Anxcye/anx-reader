import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/webdav/test_webdav.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
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
      ],
    );
  }
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
        obscureText:
            labelText == L10n.of(context).settings_sync_webdav_password ? true : false,
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
          buildTextField(L10n.of(context).settings_sync_webdav_url, webdavUrlController),
          buildTextField(
              L10n.of(context).settings_sync_webdav_username, webdavUsernameController),
          buildTextField(
              L10n.of(context).settings_sync_webdav_password, webdavPasswordController),
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
                child: Text(L10n.of(context).settings_sync_webdav_test_connection),
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
