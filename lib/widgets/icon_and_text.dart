import 'package:flutter/material.dart';

class IconAndText extends StatelessWidget {
  final Widget icon;
  final String text;
  final Function()? onTap;
  final double? fontSize;
  final bool useIconButton;

  const IconAndText({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
    this.fontSize,
    this.useIconButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useIconButton) {
      return IconButton(
        onPressed: onTap,
        icon: icon,
        color: Colors.white,
        tooltip: text,
      );
    }

    Widget content = SizedBox(
      width: 48,
      height: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                text,
                style: TextStyle(fontSize: fontSize),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );

    return onTap != null
        ? IconButton(
            onPressed: onTap,
            icon: content,
          )
        : content;
  }
}
