import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/other_settings.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/reading_settings.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/style_settings.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ReadingSettings extends ConsumerStatefulWidget {
  const ReadingSettings({super.key});

  @override
  ConsumerState<ReadingSettings> createState() => _ReadingSettingsState();
}

class _ReadingSettingsState extends ConsumerState<ReadingSettings> {
  
  @override
  Widget build(BuildContext context) {
    return settingsSections(sections: [
      SettingsSection(
        title:Text(L10n.of(context).reading_page_reading),
        tiles: [
          CustomSettingsTile(child: ReadingMoreSettings()),
        ]
      ),
      SettingsSection(
        title:Text(L10n.of(context).reading_page_style),
        tiles: [
          CustomSettingsTile(child: StyleSettings()),
        ]
      ),
      SettingsSection(
        title:Text(L10n.of(context).reading_page_other),
        tiles: [
          CustomSettingsTile(child: OtherSettings()),

        ]
      ),
      
    ]);
  }
}
