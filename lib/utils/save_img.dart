import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/save_file_to_download.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

class SaveImg {
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
            title: Text(L10n.of(context).storagePermissionDenied),
            content: Text(L10n.of(context).storagePermissionDenied),
            actions: [
              TextButton(
                onPressed: () async {
                  openAppSettings();
                },
                child: Text(L10n.of(context).gotoAuthorize),
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
            title: Text(L10n.of(context).commonAttention),
            content: Text(L10n.of(context).galleryPermissionDenied),
            actions: [
              TextButton(
                onPressed: () async {
                  openAppSettings();
                },
                child: Text(L10n.of(context).gotoAuthorize),
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

  static Future<bool> saveImg(
    Uint8List img,
    String extension,
    String name,
  ) async {
    try {
      SmartDialog.showLoading(
          msg: L10n.of(navigatorKey.currentContext!).commonSaving);

      final SaveResult result = await SaverGallery.saveImage(
        img,
        fileName: '$name.$extension',
        skipIfExists: false,
        androidRelativePath: "Pictures/AnxReader",
      );

      SmartDialog.dismiss();
      if (result.isSuccess) {
        await SmartDialog.showToast(
            '「${'$name.$extension'}」${L10n.of(navigatorKey.currentContext!).commonSaved}');
      }
      return true;
    } catch (err) {
      SmartDialog.dismiss();
      AnxToast.show(L10n.of(navigatorKey.currentContext!).commonFailed);
      AnxLog.severe("saveImage: saveImage error: $err");
      return true;
    }
  }

  static Future<bool> androidImgSaver(
    Uint8List img,
    String extension,
    String name,
  ) async {
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
      return await saveImg(img, extension, name);
    } catch (err) {
      SmartDialog.dismiss();
      AnxToast.show(L10n.of(navigatorKey.currentContext!).commonFailed);
      AnxLog.severe("saveImage: saveImage error: $err");
      return true;
    }
  }

  // windows just save the image to the download path
  static Future<bool> windowsImgSaver(
    Uint8List img,
    String extension,
    String name,
  ) async {
    String? path = await saveFileToDownload(
      bytes: img,
      fileName: '$name.$extension',
      mimeType: 'image/$extension',
    );
    if (path == null) {
      return false;
    }
    AnxToast.show(
        '「$name.$extension」${L10n.of(navigatorKey.currentContext!).commonSaved}');
    return true;
  }

  static Future<bool> iosImgSaver(
    Uint8List img,
    String extension,
    String name,
  ) async {
    return await saveImg(img, extension, name);
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
      case TargetPlatform.macOS:
        return await windowsImgSaver(img, extension, picName);
      case TargetPlatform.iOS:
        return await iosImgSaver(img, extension, name);
      default:
        throw Exception('Unsupported platform');
    }
  }
}
