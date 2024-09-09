import 'package:flutter/services.dart';

void hideStatusBar() {
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [],
  );

  // SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) =>
  //     Future.delayed(const Duration(seconds: 1), () {
  //       SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  //     }));
}

void showStatusBar() {
  // SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.manual,
  //   overlays: [
  //     SystemUiOverlay.top,
  //     SystemUiOverlay.bottom,
  //   ],
  // );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) =>
  //         Future.delayed(const Duration(seconds: 1), () {
  //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  //         // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)
  //     })
  //     );
}
