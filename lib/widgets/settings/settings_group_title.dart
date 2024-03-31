import 'package:flutter/material.dart';

class SettingsGroupTitle extends StatelessWidget {
  const SettingsGroupTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12 ),
      ),
    );
  }
}
