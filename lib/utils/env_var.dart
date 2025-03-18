class EnvVar {
  static const bool cn =
      String.fromEnvironment('cn', defaultValue: 'false') == 'true';
  static const bool isAppStore =
      String.fromEnvironment('isAppStore', defaultValue: 'false') == 'true';
}
