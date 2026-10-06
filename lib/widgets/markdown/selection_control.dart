import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:anx_reader/utils/platform_utils.dart';

TextSelectionControls selectionControls() {
  switch (AnxPlatform.type) {
    case AnxPlatformEnum.ios:
    case AnxPlatformEnum.macos:
      return CupertinoTextSelectionControls();
    case AnxPlatformEnum.android:
    case AnxPlatformEnum.ohos:
    case AnxPlatformEnum.windows:
    case AnxPlatformEnum.linux:
      return MaterialTextSelectionControls();
  }
}
