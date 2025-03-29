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
        return L10n.of(context).common_none;
      case ReadingInfoEnum.chapterTitle:
        return L10n.of(context).reading_page_reading_info_chapter_title;
      case ReadingInfoEnum.battery:
        return L10n.of(context).reading_page_reading_info_battery;
      case ReadingInfoEnum.time:
        return L10n.of(context).reading_page_reading_info_time;
      case ReadingInfoEnum.batteryAndTime:
        return L10n.of(context).reading_page_reading_info_battery_and_time;
      case ReadingInfoEnum.chapterProgress:
        return L10n.of(context).reading_page_reading_info_chapter_progress;
      case ReadingInfoEnum.bookProgress:
        return L10n.of(context).reading_page_reading_info_book_progress;
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
