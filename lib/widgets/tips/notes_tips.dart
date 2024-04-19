import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/material.dart';

class NotesTips extends StatelessWidget {
  const NotesTips({super.key});

  final TextStyle textStyleBig = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  final TextStyle textStyle = const TextStyle(
    fontSize: 15,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('o(TヘTo) ',
              style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 50),
          Text(
            context.notesTips1,
            style: textStyleBig,
          ),
          const SizedBox(height: 10),
          Text(
            context.notesTips2,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
