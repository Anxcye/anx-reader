import 'dart:io';

import 'package:anx_reader/enums/bgimg_alignment.dart';
import 'package:anx_reader/enums/bgimg_type.dart';
import 'package:anx_reader/models/bgimg.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:file_picker/file_picker.dart';
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
    final bgimgDir = getBgimgDir();
    if (!bgimgDir.existsSync()) {
      return [];
    }
    return bgimgDir.listSync().map((e) {
      return BgimgModel(
          type: BgimgType.localFile,
          path: e.path.split(Platform.pathSeparator).last,
          alignment: BgimgAlignment.center);
    }).toList();
  }

  void deleteBgimg(BgimgModel bgimgModel) {
    final path = getBgimgDir().path + Platform.pathSeparator + bgimgModel.path;
    if (File(path).existsSync()) {
      File(path).deleteSync();
      ref.invalidateSelf();
    }
  }

  Future<void> importImg() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null) {
      return;
    }

    File image = File(result.files.single.path!);

    AnxLog.info('BookDetail: Image path: ${image.path}');

    final extName = image.path.split('.').last;
    final newName = '${DateTime.now().millisecondsSinceEpoch}.$extName';
    final newPath = '${getBgimgDir().path}${Platform.pathSeparator}$newName';

    await image.copy(newPath);
    ref.invalidateSelf();
  }
}
