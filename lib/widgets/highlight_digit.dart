import 'package:flutter/material.dart';

Widget highlightDigit(BuildContext context, String str, TextStyle textStyle,
    TextStyle digitStyle) {
  final String beforeDigit = str.split(RegExp(r'\d')).first;
  final String digit = str.replaceAll(RegExp(r'[^0-9]'), '');
  if (digit.isEmpty) return Text(str, style: textStyle);
  final String afterDigit = str.split(RegExp(r'\d')).last;

  return RichText(
    text: TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: <TextSpan>[
        TextSpan(text: beforeDigit, style: textStyle),
        TextSpan(text: digit, style: digitStyle),
        TextSpan(text: afterDigit, style: textStyle),
      ],
    ),
    textAlign: TextAlign.center,
  );
}