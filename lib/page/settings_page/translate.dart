import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/settings/service_config_form.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

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
      title: Text(L10n.of(context).readingPageAutoTranslateSelection),
    );
  }

  @override
  Widget build(BuildContext context) {
    return settingsSections(
      sections: [
        SettingsSection(
          title: Text(L10n.of(context).underlineTranslation),
          tiles: [
            CustomSettingsTile(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TranslationConfig(setState: () => setState(() {})),
                    _TranslationHint(
                      icon: Icons.touch_app_outlined,
                      text: L10n.of(context).underlineTranslationTip,
                    ),
                  ],
                ),
              ),
            ),
            CustomSettingsTile(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: autoTranslateSelection(),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).fullTextTranslation),
          tiles: [
            CustomSettingsTile(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    FullTextTranslationConfig(
                      setState: () => setState(() {}),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.panorama, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          L10n.of(context).translationMargin,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: Prefs().translationMargin,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 800,
                          child: Text(
                            L10n.of(context).translationMargin1Page,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 1600,
                          child: Text(
                            L10n.of(context).translationMargin2Pages,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2400,
                          child: Text(
                            L10n.of(context).translationMargin3Pages,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3200,
                          child: Text(
                            L10n.of(context).translationMargin5Pages,
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          Prefs().translationMargin = value;
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      L10n.of(context).translationMarginTip,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    _TranslationHint(
                      icon: Icons.library_books_outlined,
                      text: L10n.of(context).fullTextTranslationTip,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).translationFallbackTitle),
          tiles: const [
            CustomSettingsTile(child: _TranslationFallbackSummary()),
          ],
        ),
        SettingsSection(
          title: Text(L10n.of(context).translationServiceConfiguration),
          tiles: [
            for (final service in const [
              TranslateService.microsoftApi,
              TranslateService.googleApi,
              TranslateService.deepl,
            ])
              CustomSettingsTile(child: TranslateSettingItem(service: service)),
          ],
        ),
      ],
    );
  }
}

class _TranslationHint extends StatelessWidget {
  const _TranslationHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _TranslationFallbackSummary extends StatelessWidget {
  const _TranslationFallbackSummary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.alt_route_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              L10n.of(context).translationFallbackTip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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
                Prefs().translateService.getLabel(context),
                style: currentServiceTextStyle,
              ),
            ),
            Text(L10n.of(context).settingsTranslateCurrentService),
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
                    builder: (context) => const TranslateLangPicker(
                      isFrom: true,
                      isWebView: false,
                    ),
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
                    builder: (context) => const TranslateLangPicker(
                      isFrom: false,
                      isWebView: false,
                    ),
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

class FullTextTranslationConfig extends StatelessWidget {
  const FullTextTranslationConfig({super.key, required this.setState});

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
                  builder: (context) => const FullTextTranslateServicePicker(),
                ).then((value) {
                  setState();
                });
              },
              child: Text(
                Prefs().fullTextTranslateService.getLabel(context),
                style: currentServiceTextStyle,
              ),
            ),
            Text(L10n.of(context).settingsTranslateCurrentService),
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
                    builder: (context) => const TranslateLangPicker(
                      isFrom: true,
                      isWebView: true,
                    ),
                  ).then((value) {
                    setState();
                  });
                },
                child: Text(Prefs().fullTextTranslateFrom.getNative(context)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
            Expanded(
              child: TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => const TranslateLangPicker(
                      isFrom: false,
                      isWebView: true,
                    ),
                  ).then((value) {
                    setState();
                  });
                },
                child: Text(
                  Prefs().fullTextTranslateTo.getNative(context),
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
      itemCount: TranslateService.activeValues.length,
      itemBuilder: (context, index) {
        final service = TranslateService.activeValues.elementAt(index);
        return ListTile(
          title: Text(service.getLabel(context)),
          onTap: () {
            Prefs().translateService = service;
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class FullTextTranslateServicePicker extends StatelessWidget {
  const FullTextTranslateServicePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final services =
        TranslateService.activeValues.where((s) => !s.isWebView).toList();

    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(services[index].getLabel(context)),
        onTap: () {
          Prefs().fullTextTranslateService = services[index];
          Navigator.pop(context);
        },
      ),
    );
  }
}

class TranslateLangPicker extends StatelessWidget {
  const TranslateLangPicker({
    super.key,
    required this.isFrom,
    this.isWebView = false,
  });

  final bool isFrom;
  final bool isWebView;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: LangListEnum.values.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(LangListEnum.values[index].getNative(context)),
        subtitle: Text(
          LangListEnum.values[index].name[0].toUpperCase() +
              LangListEnum.values[index].name.substring(1),
        ),
        onTap: () {
          if (isWebView) {
            if (isFrom) {
              Prefs().fullTextTranslateFrom = LangListEnum.values[index];
            } else {
              Prefs().fullTextTranslateTo = LangListEnum.values[index];
            }
          } else {
            if (isFrom) {
              Prefs().translateFrom = LangListEnum.values[index];
            } else {
              Prefs().translateTo = LangListEnum.values[index];
            }
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
      child: Text(text, style: languageTextStyle, textAlign: TextAlign.center),
    );
  }

  void _saveConfig() {
    try {
      saveTranslateServiceConfig(widget.service, _currentConfig);
      AnxToast.show(L10n.of(context).commonSaved);
    } catch (e) {
      AnxToast.show(L10n.of(context).commonFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configItems = getTranslateServiceConfigItems(context, widget.service);

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
            title: Text(widget.service.getLabel(context)),
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
                        ServiceConfigForm(
                          configItems: configItems,
                          initialConfig: _currentConfig,
                          onConfigChanged: (newConfig) {
                            _currentConfig = newConfig;
                          },
                        ),
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
                                              Prefs().translateFrom.getNative(
                                                    context,
                                                  ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios),
                                            languageText(
                                              Prefs().translateTo.getNative(
                                                    context,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const Divider(),
                                        const Text(testText),
                                        const Icon(Icons.arrow_downward),
                                        translateText(
                                          testText,
                                          service: widget.service,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Text(L10n.of(context).commonTest),
                            ),
                            TextButton(
                              onPressed: () {
                                _saveConfig();
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              child: Text(L10n.of(context).commonSave),
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
