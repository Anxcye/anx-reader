import 'package:flutter/services.dart';

void hideStatusBar() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) =>
      Future.delayed(const Duration(seconds: 1), () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }));
}

void showStatusBar() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) =>
      // Future.delayed(const Duration(seconds: 1), () {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)
      // })
      );
}
