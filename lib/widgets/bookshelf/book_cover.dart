import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:flutter/material.dart';

Widget bookCover(
  BuildContext context,
  Book book, {
  double? height,
  double? width,
  double? radius,
}) {
  final double effectiveRadius = radius ?? 8;
  final BorderRadius borderRadius = BorderRadius.circular(effectiveRadius);
  File file = File(book.coverFullPath);
  Widget child = file.existsSync()
      ? Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        )
      : Container(
          color: Colors.primaries[book.title.hashCode % Colors.primaries.length]
              .shade200,
          child: Center(
            child: Icon(
              Icons.book,
              size: 40,
              color: Theme.of(context).hintColor,
            ),
          ),
        );

  final RoundedSuperellipseBorder borderShape = RoundedSuperellipseBorder(
    borderRadius: borderRadius,
    side: const BorderSide(
      width: 0.3,
      color: Colors.grey,
    ),
  );

  return SizedBox(
    height: height,
    width: width,
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(
        shape: borderShape,
      ),
      child: ClipRSuperellipse(
        borderRadius: borderRadius,
        child: child,
      ),
    ),
  );
}
