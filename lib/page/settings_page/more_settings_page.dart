import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/settings_page/ai.dart';
import 'package:anx_reader/page/settings_page/advanced.dart';
import 'package:anx_reader/page/settings_page/appearance.dart';
import 'package:anx_reader/page/settings_page/narrate.dart';
import 'package:anx_reader/page/settings_page/reading.dart';
import 'package:anx_reader/page/settings_page/settings_page.dart';
import 'package:anx_reader/page/settings_page/storege.dart';
import 'package:anx_reader/page/settings_page/sync.dart';
import 'package:anx_reader/page/settings_page/translate.dart';
import 'package:anx_reader/widgets/settings/about.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class MoreSettings extends StatelessWidget {
  const MoreSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings_outlined),
      title: Text(L10n.of(context).settings_moreSettings),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
              fullscreenDialog: false,
              builder: (context) => const SubMoreSettings()),
        );
      },
    );
  }
}

class SubMoreSettings extends StatefulWidget {
  const SubMoreSettings({super.key});

  @override
  State<SubMoreSettings> createState() => _SubMoreSettingsState();
}

class _SubMoreSettingsState extends State<SubMoreSettings> {
  int selectedIndex = 0;
  Widget? settingsDetail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(L10n.of(context).settings_moreSettings),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        List<Map<String, dynamic>> settings = [
          {
            "title": L10n.of(context).settings_appearance,
            "icon": Icons.color_lens_outlined,
            "sections": const AppearanceSetting(),
            "subtitles": [
              L10n.of(context).settings_appearance_theme,
              L10n.of(context).settings_appearance_display,
              L10n.of(context).settings_bookshelf_cover,
            ],
          },
          {
            "title": L10n.of(context).settings_reading,
            "icon": Icons.book_rounded,
            "sections": const ReadingSettings(),
            "subtitles": [
              L10n.of(context).reading_page_reading,
              L10n.of(context).download_fonts,
              L10n.of(context).reading_page_style,
              L10n.of(context).reading_page_other,
            ],
          },
          {
            "title": L10n.of(context).settings_sync,
            "icon": Icons.sync_outlined,
            "sections": const SyncSetting(),
            "subtitles": [
              L10n.of(context).settings_sync_webdav,
              L10n.of(context).export_and_import,
            ],
          },
          {
            "title": L10n.of(context).settings_narrate,
            "icon": EvaIcons.headphones,
            "sections": const NarrateSettings(),
            "subtitles": [
              L10n.of(context).settings_narrate_voice,
              L10n.of(context).settings_narrate_voice_model,
            ],
          },
          {
            "title": L10n.of(context).settings_translate,
            "icon": Icons.translate_outlined,
            "sections": const TranslateSetting(),
            "subtitles": [
              L10n.of(context).settings_translate,
            ],
          },
          {
            "title": L10n.of(context).settings_ai,
            "icon": Icons.auto_awesome,
            "sections": const AISettings(),
            "subtitles": [
              L10n.of(context).settings_ai_services,
              L10n.of(context).settings_ai_prompt,
            ],
          },
          {
            "title": L10n.of(context).storage,
            "icon": Icons.storage_outlined,
            "sections": const StorageSettings(),
            "subtitles": [
              L10n.of(context).storage_info,
              L10n.of(context).storage_data_file_details,
            ],
          },
          {
            "title": L10n.of(context).settings_advanced,
            "icon": Icons.shield_outlined,
            "sections": const AdvancedSetting(),
            "subtitles": [
              L10n.of(context).settings_advanced_log,
            ],
          },
        ];

        settingsDetail ??= SettingsPageBody(
          isMobile: false,
          title: settings[0]["title"],
          sections: settings[0]["sections"],
        );

        void setDetail(Widget detail, int id) {
          setState(() {
            settingsDetail = detail;
            selectedIndex = id;
          });
        }

        Widget settingsList(bool isMobile) {
          return ListView.builder(
            itemCount: settings.length + 1,
            itemBuilder: (context, index) {
              if (index == settings.length) {
                return const About(leadingColor: true);
              }
              return SettingsPageBuilder(
                isMobile: isMobile,
                id: index,
                selectedIndex: selectedIndex,
                setDetail: setDetail,
                icon: Icon(
                  settings[index]["icon"],
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: settings[index]["title"],
                sections: settings[index]["sections"],
                subTitles: settings[index]["subtitles"],
              );
            },
          );
        }

        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(
                flex: 1,
                child: settingsList(false),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                flex: 2,
                child: settingsDetail!,
              ),
            ],
          );
        } else {
          return settingsList(true);
        }
      }),
    );
  }
}
