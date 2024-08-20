import 'package:flutter/material.dart';

Widget iconAndText({
  required Widget icon,
  required String text,
  Function()? onTap,
}) {
  return onTap != null
      ? IconButton(
          onPressed: onTap,
          icon: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icon,
              Text(text),
            ],
          ),
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            Text(text),
          ],
        );
}
