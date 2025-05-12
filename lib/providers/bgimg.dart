import 'package:anx_reader/enums/bgimg_alignment.dart';
import 'package:anx_reader/enums/bgimg_type.dart';
import 'package:anx_reader/models/bgimg.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bgimg.g.dart';

@Riverpod(keepAlive: true)
class Bgimg extends _$Bgimg {
  static const assetsImgPrefix = 'assets/images/bgimg/';

  @override
  List<BgimgModel> build() {
    final localImg = listLocal();

    return [
      BgimgModel(
          type: BgimgType.none, path: 'none', alignment: BgimgAlignment.center),
      ...localImg,
      BgimgModel(
          type: BgimgType.assets,
          path: '${assetsImgPrefix}bg1.jpg',
          alignment: BgimgAlignment.bottom),
      BgimgModel(
          type: BgimgType.assets,
          path: '${assetsImgPrefix}bg2.jpg',
          alignment: BgimgAlignment.center),
      BgimgModel(
          type: BgimgType.assets,
          path: '${assetsImgPrefix}bg3.jpg',
          alignment: BgimgAlignment.center),
      BgimgModel(
          type: BgimgType.assets,
          path: '${assetsImgPrefix}bg4.jpg',
          alignment: BgimgAlignment.center),
      BgimgModel(
          type: BgimgType.assets,
          path: '${assetsImgPrefix}bg5.jpg',
          alignment: BgimgAlignment.center),
      BgimgModel(
          type: BgimgType.assets,
          path: '${assetsImgPrefix}bg6.jpg',
          alignment: BgimgAlignment.bottom),
    ];
  }

  List<BgimgModel> listLocal() {
    return [];
  }
}
