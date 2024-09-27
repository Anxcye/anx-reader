import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/file_saver.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

/// From https://github.com/guozhigq/pilipala which is GPL-3.0 Licensed
class DownloadUtil {
  static Future<bool> requestStoragePer() async {
    await Permission.storage.request();
    PermissionStatus status = await Permission.storage.status;
    if (status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied) {
      SmartDialog.show(
        useSystem: true,
        animationType: SmartAnimationType.centerFade_otherSlide,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(L10n.of(context).storage_permission_denied),
            content: Text(L10n.of(context).storage_permission_denied),
            actions: [
              TextButton(
                onPressed: () async {
                  openAppSettings();
                },
                child: Text(L10n.of(context).goto_authorize),
              )
            ],
          );
        },
      );
      return false;
    } else {
      return true;
    }
  }

  static Future<bool> requestPhotoPer() async {
    await Permission.photos.request();
    PermissionStatus status = await Permission.photos.status;
    if (status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied) {
      SmartDialog.show(
        useSystem: true,
        animationType: SmartAnimationType.centerFade_otherSlide,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(L10n.of(context).common_attention),
            content: Text(L10n.of(context).gallery_permission_denied),
            actions: [
              TextButton(
                onPressed: () async {
                  openAppSettings();
                },
                child: Text(L10n.of(context).goto_authorize),
              )
            ],
          );
        },
      );
      return false;
    } else {
      return true;
    }
  }

  static Future<bool> androidImgSaver(
      Uint8List img, String extension, String name) async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) return true;
      final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      AnxLog.info('sdkInt: $sdkInt');

      if (sdkInt > 33) {
        if (!await requestPhotoPer()) {
          return false;
        }
      } else {
        if (!await requestStoragePer()) {
          return false;
        }
      }
      SmartDialog.showLoading(
          msg: L10n.of(navigatorKey.currentContext!).common_saving);


      final SaveResult result = await SaverGallery.saveImage(
        img,
        name: '$name.$extension',
        androidRelativePath: "Pictures/AnxReader",
        androidExistNotSave: false,
      );

      SmartDialog.dismiss();
      if (result.isSuccess) {
        await SmartDialog.showToast(
            '「${'$name.$extension'}」${L10n.of(navigatorKey.currentContext!).common_saved}');
      }
      return true;
    } catch (err) {
      SmartDialog.dismiss();
      AnxToast.show(L10n.of(navigatorKey.currentContext!).common_failed);
      AnxLog.severe("saveImage: saveImage error: $err");
      return true;
    }
  }

  // windows just save the image to the download path
  static Future<bool> windowsImgSaver(
      Uint8List img, String extension, String name) async {
    String? path = await fileSaver(
      bytes: img,
      fileName: '$name.$extension',
      mimeType: 'image/$extension',
    );
    if (path == null) {
      return false;
    }
    AnxToast.show(
        '「$name.$extension」${L10n.of(navigatorKey.currentContext!).common_saved}');
    return true;
  }

  static Future<bool> downloadImg(
    Uint8List img,
    String extension,
    String name,
  ) async {
    String picName =
        "AnxReader_${name}_${DateTime.now().toString().replaceAll(RegExp(r'[- :]'), '').split('.').first}";
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await androidImgSaver(img, extension, picName);
      case TargetPlatform.windows:
        return await windowsImgSaver(img, extension, picName);
      default:
        return true;
    }
  }
}
