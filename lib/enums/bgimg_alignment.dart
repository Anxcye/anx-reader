import 'package:flutter/material.dart';

enum BgimgAlignment {
  center,
  top,
  bottom,
  left,
  right;

  Alignment get alignment => switch (this) {
        center => Alignment.center,
        top => Alignment.topCenter,
        bottom => Alignment.bottomCenter,
        left => Alignment.centerLeft,
        right => Alignment.centerRight,
      };
}
