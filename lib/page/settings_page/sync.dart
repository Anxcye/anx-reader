import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/widgets/settings/theme_mode.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../config/shared_preference_provider.dart';
import '../../utils/webdav/common.dart';
import '../../widgets/settings/simple_dialog.dart';
import '../../widgets/settings/settings_app_bar.dart';

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
    return ListTile(
      leading: const Icon(Icons.sync),
      // TODO l10n
      title: Text('Sync'),
      trailing: const Icon(Icons.chevron_right),
      selected: selectedIndex == id,
      onTap: () {
        if (!isMobile) {
          setDetail(SubSyncSettings(isMobile: isMobile), id);
          return;
        }
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => SubSyncSettings(isMobile: isMobile)),
        );
      },
    );
  }
}

class SubSyncSettings extends StatelessWidget {
  const SubSyncSettings({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isMobile ? settingsAppBar(context.appearance, context) : null,
      body: SettingsList(
        lightTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          titleTextColor: Theme.of(context).colorScheme.primary,
        ),
        sections: [
          SettingsSection(
            // TODO l10n
            title: Text('WebDAV'),
            tiles: [
              SettingsTile.switchTile(
                  leading: const Icon(Icons.cached),
                  initialValue: true,
                  onToggle: (bool value) {
                    // TODO
                  },
                  title: const Text('Enable WebDAV')),
              SettingsTile.navigation(
                  // TODO l10n
                  title: Text('WebDAV'),
                  leading: const Icon(Icons.cloud),
                  onPressed: (context) async {
                    showWebdavDialog(context);
                  }),
              // const CustomSettingsTile(child: Divider()),
            ],
          ),
        ],
      ),
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
