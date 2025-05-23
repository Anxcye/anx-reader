import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';

class TranslateSetting extends StatefulWidget {
  const TranslateSetting({super.key});

  @override
  State<TranslateSetting> createState() => _TranslateSettingState();
}

class _TranslateSettingState extends State<TranslateSetting> {
  Widget autoTranslateSelection() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      trailing: Switch(
        value: Prefs().autoTranslateSelection,
        onChanged: (bool value) => setState(() {
          Prefs().autoTranslateSelection = value;
        }),
      ),
      title: Text(L10n.of(context).reading_page_auto_translate_selection),
    );
  }

  @override
  Widget build(BuildContext context) {
    return settingsSections(
      sections: [
        SettingsSection(
          tiles: [
            CustomSettingsTile(
              child: Card(
                shadowColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TranslationConfig(
                    setState: () => setState(() {}),
                  ),
                ),
              ),
            ),
            CustomSettingsTile(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: autoTranslateSelection(),
              ),
            ),
            for (var service in TranslateService.values)
              CustomSettingsTile(
                child: TranslateSettingItem(service: service),
              ),
          ],
        )
      ],
    );
  }
}

class TranslationConfig extends StatelessWidget {
  const TranslationConfig({super.key, required this.setState});

  final VoidCallback setState;

  static const currentServiceTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const TranslateServicePicker(),
                ).then((value) {
                  setState();
                });
              },
              child: Text(
                Prefs().translateService.label,
                style: currentServiceTextStyle,
              ),
            ),
            Text(L10n.of(context).settings_translate_current_service),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        const TranslateLangPicker(isFrom: true),
                  ).then((value) {
                    setState();
                  });
                },
                child: Text(Prefs().translateFrom.getNative(context)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
            Expanded(
              child: TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) =>
                        const TranslateLangPicker(isFrom: false),
                  ).then((value) {
                    setState();
                  });
                },
                child: Text(
                  Prefs().translateTo.getNative(context),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TranslateServicePicker extends StatelessWidget {
  const TranslateServicePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: TranslateService.values.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(TranslateService.values[index].label),
        onTap: () {
          Prefs().translateService = TranslateService.values[index];
          Navigator.pop(context);
        },
      ),
    );
  }
}

class TranslateLangPicker extends StatelessWidget {
  const TranslateLangPicker({super.key, required this.isFrom});

  final bool isFrom;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: LangListEnum.values.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(LangListEnum.values[index].getNative(context)),
        subtitle: Text(LangListEnum.values[index].name[0].toUpperCase() +
            LangListEnum.values[index].name.substring(1)),
        onTap: () {
          if (isFrom) {
            Prefs().translateFrom = LangListEnum.values[index];
          } else {
            Prefs().translateTo = LangListEnum.values[index];
          }
          Navigator.pop(context);
        },
      ),
    );
  }
}

class TranslateSettingItem extends StatefulWidget {
  const TranslateSettingItem({super.key, required this.service});

  final TranslateService service;

  @override
  State<TranslateSettingItem> createState() => _TranslateSettingItemState();
}

class _TranslateSettingItemState extends State<TranslateSettingItem> {
  bool isExpanded = false;
  static const testText = "Hello, world!";
  static const languageTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  Map<String, dynamic> _currentConfig = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    _currentConfig = getTranslateServiceConfig(widget.service);
    setState(() {});
  }

  Widget languageText(String text) {
    return Expanded(
      child: Text(
        text,
        style: languageTextStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildConfigItem(ConfigItem item) {
    switch (item.type) {
      case ConfigItemType.text:
      case ConfigItemType.password:
        return TextField(
          obscureText: item.type == ConfigItemType.password,
          decoration: InputDecoration(
            labelText: item.label,
            helperText: item.description,
            border: const OutlineInputBorder(),
          ),
          controller: TextEditingController(
              text: _currentConfig[item.key]?.toString() ??
                  item.defaultValue?.toString() ??
                  ''),
          onChanged: (value) {
            _currentConfig[item.key] = value;
          },
        );

      case ConfigItemType.number:
        return TextField(
          decoration: InputDecoration(
            labelText: item.label,
            helperText: item.description,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          controller: TextEditingController(
              text: _currentConfig[item.key]?.toString() ??
                  item.defaultValue?.toString() ??
                  ''),
          onChanged: (value) {
            _currentConfig[item.key] = int.tryParse(value) ?? 0;
          },
        );

      case ConfigItemType.toggle:
        return SwitchListTile(
          title: Text(item.label),
          subtitle: item.description != null ? Text(item.description!) : null,
          value: _currentConfig[item.key] ?? item.defaultValue ?? false,
          onChanged: (value) {
            setState(() {
              _currentConfig[item.key] = value;
            });
          },
        );

      case ConfigItemType.select:
        if (item.options == null || item.options!.isEmpty) {
          return const Text('None options');
        }

        final String currentValue = _currentConfig[item.key]?.toString() ??
            item.defaultValue?.toString() ??
            item.options!.first['value']?.toString() ??
            '';

        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: item.label,
            helperText: item.description,
            border: const OutlineInputBorder(),
          ),
          value: currentValue,
          items: item.options!.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'].toString(),
              child: Text(option['label'].toString()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _currentConfig[item.key] = value;
              });
            }
          },
        );

      case ConfigItemType.radio:
        if (item.options == null || item.options!.isEmpty) {
          return const Text('None options');
        }

        final currentValue = _currentConfig[item.key] ?? item.defaultValue;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                item.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (item.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(item.description!),
              ),
            ...item.options!.map((option) {
              return RadioListTile<dynamic>(
                title: Text(option['label'].toString()),
                value: option['value'],
                groupValue: currentValue,
                onChanged: (value) {
                  setState(() {
                    _currentConfig[item.key] = value;
                  });
                },
              );
            }),
          ],
        );

      case ConfigItemType.checkbox:
        return CheckboxListTile(
          title: Text(item.label),
          subtitle: item.description != null ? Text(item.description!) : null,
          value: _currentConfig[item.key] ?? item.defaultValue ?? false,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _currentConfig[item.key] = value;
              });
            }
          },
        );
      case ConfigItemType.tip:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
              ),
              Expanded(
                child: Text(
                  item.defaultValue.toString(),
                ),
              ),
            ],
          ),
        );
    }
  }

  void _saveConfig() {
    try {
      saveTranslateServiceConfig(widget.service, _currentConfig);
      AnxToast.show(L10n.of(context).common_saved);
    } catch (e) {
      AnxToast.show(L10n.of(context).common_failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configItems = getTranslateServiceConfigItems(widget.service);

    return Card(
      margin: const EdgeInsets.all(10),
      color: isExpanded
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.transparent,
      shadowColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.translate_outlined),
            title: Text(widget.service.label),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.bounceInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...configItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: _buildConfigItem(item),
                          );
                        }),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _saveConfig();
                                SmartDialog.show(
                                  useSystem: true,
                                  animationType:
                                      SmartAnimationType.centerFade_otherSlide,
                                  builder: (context) => AlertDialog(
                                    title: const Center(
                                      child: Icon(Icons.check_circle),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            languageText(
                                              Prefs()
                                                  .translateFrom
                                                  .getNative(context),
                                            ),
                                            const Icon(Icons.arrow_forward_ios),
                                            languageText(
                                              Prefs()
                                                  .translateTo
                                                  .getNative(context),
                                            ),
                                          ],
                                        ),
                                        const Divider(),
                                        const Text(testText),
                                        const Icon(Icons.arrow_downward),
                                        StreamBuilder<String>(
                                          stream: translateText(testText,
                                              service: widget.service),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            } else if (snapshot.hasError) {
                                              return Text(
                                                'Error: ${snapshot.error}',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                              );
                                            } else if (snapshot.hasData) {
                                              return Text(snapshot.data!);
                                            } else {
                                              return const Text('...');
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Text(L10n.of(context).common_test),
                            ),
                            TextButton(
                              onPressed: () {
                                _saveConfig();
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              child: Text(L10n.of(context).common_save),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
