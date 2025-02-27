import 'package:flutter/services.dart';

void hideStatusBar() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [],
  );
}

void showStatusBar() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
}

void showStatusBarWithoutResize() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
}

void onlyStatusBar() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [
      SystemUiOverlay.top,
    ],
  );
}
