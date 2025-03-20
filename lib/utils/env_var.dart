import 'dart:io';

class EnvVar {
  static bool isCn = (Platform.localeName.length >= 7 ? Platform.localeName.substring(0, 7) == 'zh_Hans' : false);
  static const bool isAppStore =
      String.fromEnvironment('isAppStore', defaultValue: 'false') == 'true';
}
