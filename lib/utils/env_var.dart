import 'dart:io';

class EnvVar {
  static bool get isBeian {
    if (!isAppStore) {
      return false;
    }
    return Platform.localeName == 'zh_Hans_CN';
  }

  static const bool isAppStore =
      String.fromEnvironment('isAppStore', defaultValue: 'false') == 'true';

  static const String sharingSecret =
      String.fromEnvironment('sharingSecret', defaultValue: '');
}
