import 'package:anx_reader/main.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AnxToast {
  static FToast fToast = FToast();

  static void init(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fToast.init(context);
    });
  }

  static void show(String message, {Icon? icon, int duration = 2000}) {
    Widget toast = Container(
      // width: MediaQuery.of(navigatorKey.currentContext!).size.width * 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Theme.of(navigatorKey.currentContext!).colorScheme.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon ?? const Icon(Icons.info_outline),
          const SizedBox(
            width: 12.0,
          ),
          Flexible(
            child: Text(
              message,
              // wrap
              style: TextStyle(
                color: Theme.of(navigatorKey.currentContext!)
                    .colorScheme
                    .onSurface,
              ),
            ),
          ),
        ],
      ),
    );

    // close previous toast
    fToast.removeQueuedCustomToasts();

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(milliseconds: duration),
    );

    // // Custom Toast Position
    // fToast.showToast(
    //     child: toast,
    //     toastDuration: Duration(seconds: 2),
    //     positionedToastBuilder: (context, child) {
    //       return Positioned(
    //         child: child,
    //         top: 16.0,
    //         left: 16.0,
    //       );
    //     });
  }
}
