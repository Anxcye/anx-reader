import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

enum ReadingInfoEnum {
  none,
  chapterTitle,
  chapterProgress,
  bookProgress,
  battery,
  time,
  batteryAndTime,
}

extension ReadingInfoL10n on ReadingInfoEnum {
  String getL10n(BuildContext context) {
    switch (this) {
      case ReadingInfoEnum.none:
        return L10n.of(context).commonNone;
      case ReadingInfoEnum.chapterTitle:
        return L10n.of(context).readingPageReadingInfoChapterTitle;
      case ReadingInfoEnum.battery:
        return L10n.of(context).readingPageReadingInfoBattery;
      case ReadingInfoEnum.time:
        return L10n.of(context).readingPageReadingInfoTime;
      case ReadingInfoEnum.batteryAndTime:
        return L10n.of(context).readingPageReadingInfoBatteryAndTime;
      case ReadingInfoEnum.chapterProgress:
        return L10n.of(context).readingPageReadingInfoChapterProgress;
      case ReadingInfoEnum.bookProgress:
        return L10n.of(context).readingPageReadingInfoBookProgress;
    }
  }
}

extension ReadingInfoEnumJson on ReadingInfoEnum {
  String toJson() {
    return name;
  }

  static ReadingInfoEnum fromJson(String json) {
    return ReadingInfoEnum.values.firstWhere((e) => e.name == json);
  }
}
