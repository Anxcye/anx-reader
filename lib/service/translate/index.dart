import 'dart:core';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/service/translate/google.dart';
import 'package:anx_reader/service/translate/microsoft.dart';

enum TranslateService {
  google('Google'),
  microsoft('Microsoft');

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
  toggle('toggle');

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
  Stream<String> translate(String text, LangListEnum from, LangListEnum to);

  List<ConfigItem> getConfigItems();

  Map<String, dynamic> getConfig();

  void saveConfig(Map<String, dynamic> config);
}

class TranslateFactory {
  static TranslateServiceProvider getProvider(TranslateService service) {
    switch (service) {
      case TranslateService.google:
        return GoogleTranslateProvider();
      case TranslateService.microsoft:
        return MicrosoftTranslateProvider();
    }
  }
}

Stream<String> translateText(String text, {TranslateService? service}) {
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
