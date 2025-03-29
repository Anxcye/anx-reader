import 'package:anx_reader/enums/reading_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_info.freezed.dart';
part 'reading_info.g.dart';

@freezed
abstract class ReadingInfoModel with _$ReadingInfoModel {
  const factory ReadingInfoModel({
    @Default(ReadingInfoEnum.chapterTitle) ReadingInfoEnum headerLeft,
    @Default(ReadingInfoEnum.none) ReadingInfoEnum headerCenter,
    @Default(ReadingInfoEnum.none) ReadingInfoEnum headerRight,
    @Default(ReadingInfoEnum.batteryAndTime) ReadingInfoEnum footerLeft,
    @Default(ReadingInfoEnum.chapterProgress) ReadingInfoEnum footerCenter,
    @Default(ReadingInfoEnum.bookProgress) ReadingInfoEnum footerRight,
  }) = _ReadingInfoModel;

  factory ReadingInfoModel.fromJson(Map<String, dynamic> json) =>
      _$ReadingInfoModelFromJson(json);
}
