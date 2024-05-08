import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../config/shared_preference_provider.dart';
import '../../utils/webdav/common.dart';
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
        // TODO l10n
        title: 'Sync',
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
      // TODO l10n
      title: 'Sync',
      isMobile: widget.isMobile,
      sections: [
        SettingsSection(
          // TODO l10n
          title: Text('WebDAV'),
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
                    }
                  }
                },
                // TODO l10n
                title: const Text('Enable WebDAV')),
            SettingsTile.navigation(
                // TODO l10n
                title: Text('WebDAV'),
                leading: const Icon(Icons.cloud),
                value: Text(Prefs().webdavInfo['url']),
                // enabled: Prefs().webdavStatus,
                onPressed: (context) async {
                  showWebdavDialog(context);
                }),
            // const CustomSettingsTile(child: Divider()),
          ],
        ),
      ],
    );
  }
}

void showWebdavDialog(BuildContext context) {
  // TODO l10n
  final title = 'WebDAV';
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
        obscureText: labelText == 'Password' ? true : false,
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
          // TODO l10n
          buildTextField('URL', webdavUrlController),
          buildTextField('Username', webdavUsernameController),
          buildTextField('Password', webdavPasswordController),

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

                // TODO l10n
                child: const Text('Test'),
              ),
              TextButton(
                onPressed: () {
                  webdavInfo['url'] = webdavUrlController.text;
                  webdavInfo['username'] = webdavUsernameController.text;
                  webdavInfo['password'] = webdavPasswordController.text;
                  prefs(webdavInfo);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      );
    },
  );
}
