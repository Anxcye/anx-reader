import 'package:flutter/services.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

Future<String> getAppVersion() async {
  final pubspecContent = await rootBundle.loadString('pubspec.yaml');
  final pubspec = Pubspec.parse(pubspecContent);
  return pubspec.version.toString();
}
