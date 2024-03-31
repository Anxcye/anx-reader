import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/material.dart';

AppBar settingsAppBar(String title, BuildContext context) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
    title: Text(title),
  );
}
