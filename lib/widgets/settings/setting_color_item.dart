
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/shared_preference_provider.dart';

class SettingsColorItem extends StatelessWidget {
  const SettingsColorItem({
    super.key,
    // required this.colorName,
    required this.colorValue,
  });

  // final String colorName;
  final int colorValue;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () async {
        final prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
        // prefsProvider.themeColor = Color(colorValue);
        await prefsProvider.saveThemeToPrefs(colorValue);

        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          color: Color(colorValue),
          height: 50,
        ),
      ),
    );
  }
}
