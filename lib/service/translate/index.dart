import 'dart:core';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/translate/ai.dart';
import 'package:anx_reader/service/translate/deepl.dart';
import 'package:anx_reader/service/translate/google.dart';
import 'package:anx_reader/service/translate/microsoft.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TranslateService {
  google('Google'),
  microsoft('Microsoft'),
  deepl('DeepL'),
  ai('AI');

  const TranslateService(this.label);

  final String label;
}

TranslateService getTranslateService(String name) {
  return TranslateService.values.firstWhere((e) => e.name == name);
}

enum ConfigItemType {
  text('text input'),
  password('password input'),
  number('number input'),
  select('select'),
  radio('radio'),
  checkbox('checkbox'),
  toggle('toggle'),
  tip('tip');

  const ConfigItemType(this.label);
  final String label;
}

class ConfigItem {
  final String key;
  final String label;
  final String? description;
  final ConfigItemType type;
  final dynamic defaultValue;
  final List<Map<String, dynamic>>? options; // 用于select, radio等类型的选项

  ConfigItem({
    required this.key,
    required this.label,
    this.description,
    required this.type,
    this.defaultValue,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'description': description,
      'type': type.name,
      'defaultValue': defaultValue,
      'options': options,
    };
  }
}

abstract class TranslateServiceProvider {
  Widget translate(String text, LangListEnum from, LangListEnum to);

  List<ConfigItem> getConfigItems();

  Map<String, dynamic> getConfig();

  void saveConfig(Map<String, dynamic> config);

  Widget convertStreamToWidget(Stream<String> stream) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('...');
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(snapshot.data!),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Clipboard.setData(
                          ClipboardData(text: snapshot.data!)),
                      child: Text(L10n.of(context).commonCopy))
                ],
              )
            ],
          );
        } else {
          return const Text('No data');
        }
      },
    );
  }
}

class TranslateFactory {
  static TranslateServiceProvider getProvider(TranslateService service) {
    switch (service) {
      case TranslateService.google:
        return GoogleTranslateProvider();
      case TranslateService.microsoft:
        return MicrosoftTranslateProvider();
      case TranslateService.deepl:
        return DeepLTranslateProvider();
      case TranslateService.ai:
        return AiTranslateProvider();
    }
  }
}

Widget translateText(String text, {TranslateService? service}) {
  service ??= Prefs().translateService;
  final from = Prefs().translateFrom;
  final to = Prefs().translateTo;

  return TranslateFactory.getProvider(service).translate(text, from, to);
}

List<ConfigItem> getTranslateServiceConfigItems(TranslateService service) {
  return TranslateFactory.getProvider(service).getConfigItems();
}

Map<String, dynamic> getTranslateServiceConfig(TranslateService service) {
  return TranslateFactory.getProvider(service).getConfig();
}

void saveTranslateServiceConfig(
    TranslateService service, Map<String, dynamic> config) {
  return TranslateFactory.getProvider(service).saveConfig(config);
}
