import 'package:flutter/material.dart';
import 'package:anx_reader/main.dart';


Future<dynamic> showSimpleDialog(
    String title, Function saveToPrefs, List<Widget> children) {
  final context = navigatorKey.currentContext!;
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(title),
          children: children,
        );
      });
}

Widget dialogOption(String name, String value, Function saveToPrefs) {
  final context = navigatorKey.currentContext!;
  return SimpleDialogOption(
    onPressed: () async {
      saveToPrefs(value);
      Navigator.pop(context);
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(name),
    ),
  );
}
