import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/search_display_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/search/search_engine.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';

class SearchEnginesSetting extends StatefulWidget {
  const SearchEnginesSetting({super.key});

  @override
  State<SearchEnginesSetting> createState() => _SearchEnginesSettingState();
}

class _SearchEnginesSettingState extends State<SearchEnginesSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).searchManageEngines),
      ),
      body: settingsSections(
        sections: [
          SettingsSection(
            title: Text(L10n.of(context).searchDisplayMode),
            tiles: [
              SettingsTile(
                title: Column(
                  children: SearchDisplayMode.values.map((mode) {
                    return RadioListTile<SearchDisplayMode>(
                      title: Text(_displayModeLabel(context, mode)),
                      value: mode,
                      groupValue: Prefs().searchDisplayMode,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            Prefs().searchDisplayMode = value;
                          });
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: Text(L10n.of(context).searchDefaultEngine),
            tiles: [
              SettingsTile(
                title: DropdownButton<String>(
                  isExpanded: true,
                  value: Prefs().selectedSearchEngineId,
                  items: Prefs().allSearchEngines.map((engine) {
                    return DropdownMenuItem<String>(
                      value: engine.id,
                      child: Text(engine.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        Prefs().selectedSearchEngineId = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: Text(L10n.of(context).searchManageEngines),
            tiles: [
              ...Prefs().customSearchEngines.map((engine) {
                return SettingsTile(
                  leading: const Icon(Icons.language),
                  title: Text(engine.name),
                  description: Text(engine.urlTemplate),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        Prefs().deleteCustomSearchEngine(engine.id);
                      });
                    },
                  ),
                );
              }),
              SettingsTile.navigation(
                leading: const Icon(Icons.add),
                title: Text(L10n.of(context).searchAddEngine),
                onPressed: (_) => _showAddEngineDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayModeLabel(BuildContext context, SearchDisplayMode mode) {
    switch (mode) {
      case SearchDisplayMode.popup:
        return L10n.of(context).searchDisplayModePopup;
      case SearchDisplayMode.fullScreen:
        return L10n.of(context).searchDisplayModeFullScreen;
      case SearchDisplayMode.external:
        return L10n.of(context).searchDisplayModeExternal;
    }
  }

  void _showAddEngineDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(L10n.of(context).searchAddEngine),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: L10n.of(context).searchEngineName,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return L10n.of(context).searchEngineNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: L10n.of(context).searchEngineUrlTemplate,
                    hintText: 'https://example.com/search?q={query}',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return L10n.of(context).searchEngineUrlRequired;
                    }
                    if (!SearchEngine.isValidUrlTemplate(value.trim())) {
                      return L10n.of(context).searchEngineUrlInvalid;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(L10n.of(context).commonCancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final engine = SearchEngine(
                    id: SearchEngine.generateId(),
                    name: nameController.text.trim(),
                    urlTemplate: urlController.text.trim(),
                  );
                  setState(() {
                    Prefs().addCustomSearchEngine(engine);
                  });
                  Navigator.of(dialogContext).pop();
                  AnxToast.show(L10n.of(context).searchEngineAdded);
                }
              },
              child: Text(L10n.of(context).commonConfirm),
            ),
          ],
        );
      },
    );
  }
}
