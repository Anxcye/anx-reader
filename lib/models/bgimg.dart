import 'package:anx_reader/enums/bgimg_alignment.dart';
import 'package:anx_reader/enums/bgimg_type.dart';
import 'package:flutter/material.dart';
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

  String get url => type == BgimgType.assets ? 'assets/$path' : path;

  ImageProvider get image =>
      type == BgimgType.assets ? AssetImage(path) : NetworkImage(url);
}
