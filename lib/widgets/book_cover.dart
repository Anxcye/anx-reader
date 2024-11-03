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
  radius ??= 8;
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
              size: MediaQuery.of(context).size.width / 5,
              color: Theme.of(context).hintColor,
            ),
          ),
        );

  return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            width: 0.3,
            color: Colors.grey,
          )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ));
}
