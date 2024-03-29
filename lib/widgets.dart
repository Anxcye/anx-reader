import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'models/Book.dart';

class BookItem extends StatelessWidget {
  const BookItem({
    super.key,
    required this.book,
  });

  final Book book;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('openbook');
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              image: DecorationImage(
                image: FileImage(File(book.coverPath)),
                fit: BoxFit.cover,
              ),
            ),
            height: 141,
            width: 100,
          ),
          const SizedBox(height: 5),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
