import 'package:flutter/material.dart';

import '../models/book.dart';
import 'book_item.dart';

class BookList extends StatelessWidget {
  const BookList({
    super.key,
    required List<Book> books,
  }) : _books = books;

  final List<Book> _books;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      itemCount: _books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        mainAxisSpacing: 30,
        crossAxisSpacing: 20,
      ),
      itemBuilder: (BuildContext context, int index) {
        Book book = _books[index];
        return BookItem(book: book);
      },
    );
  }
}
