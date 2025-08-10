import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:flutter/cupertino.dart';

String convertSeconds(int seconds) {
  BuildContext context = navigatorKey.currentContext!;
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  final int second = seconds % 60;
  if (hours > 0) {
    return '${L10n.of(context).commonHours(hours)} ${L10n.of(context).commonMinutes(minutes)}';
  } else if (minutes > 0) {
    return L10n.of(context).commonMinutesFull(minutes);
  } else {
    return L10n.of(context).commonSecondsFull(second);
  }
}
