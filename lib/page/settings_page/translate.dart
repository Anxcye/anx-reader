import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/translate/index.dart';
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
            const CustomSettingsTile(
              child: Card(
                shadowColor: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TranslationConfig(),
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
  const TranslationConfig({super.key});

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
                );
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
                  );
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
                  );
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
      itemCount: LangList.values.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(LangList.values[index].getNative(context)),
        subtitle: Text(LangList.values[index].name[0].toUpperCase() +
            LangList.values[index].name.substring(1)),
        onTap: () {
          if (isFrom) {
            Prefs().translateFrom = LangList.values[index];
          } else {
            Prefs().translateTo = LangList.values[index];
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

  Widget languageText(String text) {
    return Expanded(
      child: Text(
        text,
        style: languageTextStyle,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Card(
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
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            translateText(
                              testText,
                              service: widget.service,
                            ).then((value) {
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
                                      Text(value),
                                    ],
                                  ),
                                ),
                              );
                            }).catchError((error) {
                              SmartDialog.show(
                                useSystem: true,
                                animationType:
                                    SmartAnimationType.centerFade_otherSlide,
                                builder: (context) => AlertDialog(
                                  title: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error),
                                        Text(L10n.of(context).common_failed),
                                      ],
                                    ),
                                  ),
                                  content: Text(error.toString()),
                                ),
                              );
                            });
                          },
                          child: Text(L10n.of(context).common_test),
                        ),
                        TextButton(
                          onPressed: () {
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
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
