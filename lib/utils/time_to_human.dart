import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

String timeToHuman(DateTime? date, BuildContext context) {
  final DateTime now = DateTime.now();
  if (date == null) {
    return '';
  }
  final Duration difference = now.difference(date);
  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} ${L10n.of(context).statisticJustNow}';
  } else if (difference.inMinutes < 60) {
    return L10n.of(context).statisticMinutesAgo(difference.inMinutes);
  } else if (difference.inHours < 24) {
    return L10n.of(context).statisticHoursAgo(difference.inHours);
  } else if (difference.inHours < 48) {
    return L10n.of(context).statisticYesterday(difference.inDays);
  } else if (difference.inDays < 30) {
    return L10n.of(context).statisticDaysAgo(difference.inDays);
  } else if (difference.inDays < 365) {
    return L10n.of(context).statisticMonthsAgo(difference.inDays ~/ 30);
  } else {
    return L10n.of(context).statisticYearsAgo(difference.inDays ~/ 365);
  }
}
