import 'package:anx_reader/main.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
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
    Widget toast = FilledContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
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
  }
}
