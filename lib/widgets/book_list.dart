import 'package:flutter/material.dart';

import '../models/book.dart';
import 'book_item.dart';

class BookList extends StatelessWidget {
  const BookList({
    super.key,
    required List<Book> books,
    required this.onRefresh,
  }) : _books = books;

  final List<Book> _books;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:(context, constraints) {
        return  GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          itemCount: _books.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth ~/ 150,
            childAspectRatio: 0.55,
            mainAxisSpacing: 30,
            crossAxisSpacing: 20,
          ),
          itemBuilder: (BuildContext context, int index) {
            Book book = _books[index];
            return BookItem(book: book, onRefresh: onRefresh);
          },
        );

      }
    );
  }
}
