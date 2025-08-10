import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:flutter/cupertino.dart';

String weekOfYear(DateTime date) {
  BuildContext context = navigatorKey.currentContext!;
  final int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  final int weekOfYear = (dayOfYear - date.weekday + 10) ~/ 7;
  return '${date.year}-${L10n.of(context).commonNthWeek(weekOfYear)}';
}
