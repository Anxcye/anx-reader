import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

Widget errorHandler(Object error, {StackTrace? stack}) {
  if (kDebugMode) {
    throw error;
  } else {
    return Center(
      child: Text('Error: $error'),
    );
  }
}
