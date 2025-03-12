import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookshelfSettings extends ConsumerStatefulWidget {
  const BookshelfSettings({super.key});

  @override
  ConsumerState<BookshelfSettings> createState() => _BookshelfSettingsState();
}

class _BookshelfSettingsState extends ConsumerState<BookshelfSettings> {
  @override
  Widget build(BuildContext context) {
    return settingsSections(sections: [
      SettingsSection(
          title: Text(L10n.of(context).settings_bookshelf_cover),
          tiles: [
            CustomSettingsTile(
                child: ListTile(
                  title: Text(L10n.of(context).settings_bookshelf_cover_width),
                  subtitle: Slider(
                                value: Prefs().bookCoverWidth,
                                onChanged: (value) {
                  setState(() {
                    Prefs().bookCoverWidth = value;
                  });
                                },
                                max: 260,
                                min: 80,
                                divisions: 18,
                                label: Prefs().bookCoverWidth.toStringAsFixed(0),
                              ),
                )),
          ]),
    ]);
  }
}
