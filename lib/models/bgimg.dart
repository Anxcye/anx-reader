import 'package:anx_reader/enums/bgimg_alignment.dart';
import 'package:anx_reader/enums/bgimg_type.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bgimg.freezed.dart';
part 'bgimg.g.dart';

@freezed
abstract class BgimgModel with _$BgimgModel {
  const factory BgimgModel({
    required BgimgType type,
    required String path,
    required BgimgAlignment alignment,
  }) = _BgimgModel;

  factory BgimgModel.fromJson(Map<String, dynamic> json) =>
      _$BgimgModelFromJson(json);

  const BgimgModel._();

  String get url => switch (type) {
        BgimgType.none => 'none',
        BgimgType.assets => 'http://localhost:${Server().port}/bgimg/assets/$path',
        BgimgType.localFile => 'http://localhost:${Server().port}/bgimg/local/$path',
      };
}
