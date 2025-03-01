import 'package:freezed_annotation/freezed_annotation.dart';

part 'window_info.freezed.dart';
part 'window_info.g.dart';

@freezed
abstract class WindowInfo with _$WindowInfo {
  const factory WindowInfo({
    required double x,
    required double y,
    required double width,
    required double height,
  }) = _WindowInfo;

  factory WindowInfo.fromJson(Map<String, dynamic> json) =>
      _$WindowInfoFromJson(json);
}
