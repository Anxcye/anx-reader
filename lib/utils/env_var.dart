import 'dart:io';

class EnvVar {
  static bool get isBeian {
    if (!isAppStore) {
      return false;
    }
    return Platform.localeName.length >= 10
        ? Platform.localeName.substring(0, 10) == 'zh_Hans_CN'
        : false;
  }

  static const bool isAppStore =
      String.fromEnvironment('isAppStore', defaultValue: 'false') == 'true';
}
