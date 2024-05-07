import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/main.dart';
import 'package:flutter/cupertino.dart';

BuildContext context = navigatorKey.currentContext!;

String convertSeconds(int seconds) {
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  final int second = seconds % 60;
  if (hours > 0) {
    return '${hours.toString()} ${context.commonHours} ${minutes.toString()} ${context.commonMinutes}';
  } else if (minutes > 0) {
    return '${minutes.toString()} ${context.commonMinutesFull}';
  } else {
    return '${second.toString()} ${context.commonSecondsFull}';
  }
}
