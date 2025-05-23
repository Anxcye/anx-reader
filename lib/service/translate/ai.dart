import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/translate/index.dart';

class AiTranslateProvider implements TranslateServiceProvider {
  @override
  Stream<String> translate(
      String text, LangListEnum from, LangListEnum to) async* {}

  @override
  List<ConfigItem> getConfigItems() {
    return [
      ConfigItem(
        key: 'tip',
        label: 'Tip',
        type: ConfigItemType.tip,
        defaultValue: L10n.of(navigatorKey.currentContext!).settings_translate_ai_tip,
      ),
    ];
  }

  @override
  Map<String, dynamic> getConfig() {
    return {};
  }

  @override
  Future<void> saveConfig(Map<String, dynamic> config) async {
    return;
  }
}
