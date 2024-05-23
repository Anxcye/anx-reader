import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Widget linkIcon({
  required IconData icon,
  required String url,
  required LaunchMode mode,
  double size = 30,
}) {
  return IconButton(
    onPressed: () => launchUrl(
      Uri.parse(url),
      mode: mode,
    ),
    icon: Icon(
      icon,
      size: size,
    ),
  );
}
